library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

--entity of project_reti_logiche
entity project_reti_logiche is
    Port ( 
        i_clk : in std_logic;       --in clock signal
        i_rst : in std_logic;       --in rst signal
        i_start : in std_logic;     --in start signal
        i_add : in std_logic_vector(15 downto 0);   --in starting address
        i_k   : in std_logic_vector(9 downto 0);    --in number of iteration
                    
        o_done : out std_logic;     --out done signal
                    
        o_mem_addr : out std_logic_vector(15 downto 0);     --set address in RAM 
        i_mem_data : in  std_logic_vector(7 downto 0);      --read data from RAM at address o_mem_addr
        o_mem_data : out std_logic_vector(7 downto 0);      --write data in RAM at address o_mem_addr
        o_mem_we   : out std_logic;     --RAM Write enable
        o_mem_en   : out std_logic      --RAM memory enable
    );
end project_reti_logiche;
--end entity of project_reti_logiche

--architecture of project_reti_logiche
architecture Behavioral of project_reti_logiche is
    
    type state_type is (S_RST,      --reset state
                        S_ZERO,S_ZERO_READ,S_ZERO_CHOICE,     --Starting 0
                        S_READ_MEM,S_CHOICE,      --read state:read + choiche_on_read_data
                        S_R2W_31,S_WRITE_MEM_CRED31,    --write 1 case state: ready_to_write + write31 
                        S_R2W_NUMPREC,S_WRITE_MEM_NUMPREC,  --write 2ndA case state: ready_to_write + write_current_word 
                        S_R2W_CREDX,S_WRITE_MEM_CREDX,      --write 2ndB case state: ready_to_write + write_current_credibility
                        S_MOVE_ADD2,        --update address state + o_done = 1
                        S_END        --end state: set o_done to 0 when i_start returns to 0
                        );
    signal current_state : state_type := S_RST;  --current state

--begin process          
begin
    programfunction : process (i_clk,i_rst)    --only when current_state or i_start is updated
        variable current_credibility : std_logic_vector (7 downto 0);  --current credibility
        variable next_credibility : std_logic_vector (7 downto 0);     --next credibility = current credibility -1
        
        variable current_word : std_logic_vector (7 downto 0);         --word read
      
        variable current_temp_add : std_logic_vector(15 downto 0);     --current RAM address (from i_add to i_add + i_k)
        variable next_temp_add : std_logic_vector(15 downto 0);        --next RAM address = current RAM address +2
        
    begin
            
        if i_rst = '1' then
        -- reset signal: all signals set at 0 and when i_start is setted to 1: (next_state <= S_R2R;)
            o_done <= '0';
            o_mem_en <= '0';
            o_mem_we <= '0';
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            current_credibility :=(others => '0');
            current_word := (others => '0');
            current_temp_add := (others => '0'); 
            next_credibility := (others => '0');
            next_temp_add := (others => '0'); 
            current_state <= S_RST;
            
        elsif rising_edge(i_clk) then
            case current_state is
            
                when S_RST =>
                --RESET STATE: wait i_start then RAM memory Ready To Read
                    if i_start = '1' then
                        o_mem_addr <= i_add;
                        current_temp_add := i_add;
                        o_mem_en <= '1';
                        o_mem_we <= '0';
                        current_state <= S_READ_MEM;
                    else current_state <= S_RST;
                    end if;

               when S_READ_MEM =>
               --RAM memory Read and freeze ram: (o_mem_en <= '0' + o_mem_we <= '0')
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                    current_state <= S_CHOICE;
                    
               when S_CHOICE =>  
               --RAM data available: make the choice
                    if i_mem_data = "00000000" and current_temp_add = i_add then
                    --sequence starts with 0
                        current_state <= S_ZERO;
                    elsif i_mem_data = "00000000" then
                    --current word is 0
                        current_state <= S_R2W_NUMPREC;
                        current_credibility := next_credibility;
                    else
                    -- current word is a number
                        current_state <= S_R2W_31;
                        current_word := i_mem_data;
                        next_credibility := "00011110";
                        current_credibility := "00011111";
                    end if;
                    
                when S_R2W_31 =>
                --set memory read to write at ADD +1
                    o_mem_addr <= std_logic_vector(SIGNED(current_temp_add) + 1);
                    o_mem_en <= '1';
                    o_mem_we <= '1';
                    current_state <= S_WRITE_MEM_CRED31;
                                   
                when S_WRITE_MEM_CRED31 =>
                --write credibility = 31 and update next temp add
                    o_mem_data <= "00011111";
                    o_mem_en <= '1';
                    o_mem_we <= '1';
                    next_temp_add := std_logic_vector(SIGNED(current_temp_add) + 2);
                    current_state <= S_MOVE_ADD2; 
                    
                when S_R2W_NUMPREC =>
                --set memory read to write at ADD 
                     o_mem_en <= '1';
                     o_mem_we <= '1';
                     current_state <= S_WRITE_MEM_NUMPREC;
                                    
                when S_WRITE_MEM_NUMPREC =>
                --write the previous word
                     o_mem_data <= current_word;
                     o_mem_en <= '1';
                     o_mem_we <= '1';
                     next_temp_add := std_logic_vector(SIGNED(current_temp_add) + 2);
                     current_state <= S_R2W_CREDX;
                                                    
                when S_R2W_CREDX =>
                --set memory read to write at ADD +1
                     o_mem_addr <= std_logic_vector(SIGNED(current_temp_add) + 1);
                     o_mem_en <= '1';
                     o_mem_we <= '1';
                     current_state <= S_WRITE_MEM_CREDX;
                                    
                when S_WRITE_MEM_CREDX =>
                --write credibility = 31 and update next temp add
                     o_mem_data <= current_credibility;
                     if current_credibility >= "00000001" then
                        next_credibility := std_logic_vector(SIGNED(current_credibility) - 1);
                     end if;  
                     o_mem_en <= '1';
                     o_mem_we <= '1';
                     current_state <= S_MOVE_ADD2;
                                    
                when S_MOVE_ADD2 =>
                --check if the sequence is finished ADD' >= ADD + K
                     if SIGNED(next_temp_add) >= 2*SIGNED(i_k) + SIGNED(i_add)  then
                     --set o_done to 1 and go to the end
                        current_state <= S_END;
                        o_mem_en <= '0';
                        o_mem_we <= '0';
                        o_done <= '1';                 
                     else
                     --restart with a new read 
                        current_temp_add := next_temp_add;
                        o_mem_addr <=next_temp_add;
                        o_mem_en <= '1';
                        o_mem_we <= '0';
                        current_state <= S_READ_MEM;
                        o_done <= '0';
                        end if;
                                        
                when S_END =>
                --wait that i_start coe back to 0 then reset o_done to 0
                        if i_start <= '0' then 
                              o_done <= '0';
                        end if;
                        current_state <= S_END;
                        
                when S_ZERO =>
                --Check if the sequence is finisshed 
                    if SIGNED(current_temp_add) >= 2*SIGNED(i_k) + SIGNED(i_add) -2  then
                    --go to end state 
                        current_state <= S_END;
                        o_done <= '1'; 
                    else
                    --ready to read a new value
                        next_temp_add := std_logic_vector(SIGNED(current_temp_add) + 2);
                        o_mem_addr <=next_temp_add;
                        o_mem_en <= '1';
                        o_mem_we <= '0';  
                        current_state <= S_ZERO_READ;
                    end if;
                    
                when S_ZERO_READ =>
                --read + freeze
                    current_temp_add := next_temp_add;
                    o_mem_en <= '0';
                    o_mem_we <= '0';
                    current_state <= S_ZERO_CHOICE;
                
                when S_ZERO_CHOICE =>
                --make the choice again
                    if i_mem_data = "00000000" then
                        current_state <= S_ZERO;
                    else
                        current_state <= S_R2W_31;
                        current_word := i_mem_data;
                        next_credibility := "00011110";
                        current_credibility := "00011111";
                   end if;
                
            end case;
        end if;
        
    end process;
        
end Behavioral;
--end architecture of project_reti_logiche