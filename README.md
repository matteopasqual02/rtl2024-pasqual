The specification of the "Final Exam (Logical Networks Project)" for the Academic Year 2023/2024 asks to implement an HW module (described in VHDL) 
that interfaces with a memory and complies with the instructions outlined in the following specification.

At a high level, the system reads a message consisting of a sequence of K words W whose value ranges from 0 to 255. The value 0 within the sequence should be considered not as a value but as information 
that "the value is not specified." The sequence of K words W to be processed is stored starting from a specified address (ADD), every 2 bytes (e.g. ADD, ADD+2, ADD+4, …, ADD+2*(K-1)). 
The missing byte must be completed as described below.
The module to be designed is tasked with completing the sequence, replacing zeros wherever present with the last non-zero value read, 
and inserting a "credibility" value C in the missing byte for each value in the sequence. The substitution of zeros is done by copying the last valid (non-zero) value read previously and belonging to the sequence. 
The credibility value C is 31 whenever the value W of the sequence is non-zero, while it is decremented compared to the previous value whenever a zero is encountered in W. 
The value C associated with each word W is stored in memory in the immediately following byte (i.e. ADD+1 for W in ADD, ADD+3 for W in ADD+2,…). The value C is always greater than or equal 
to 0 and is reset to 31 whenever a value W different from zero is encountered. When C reaches the value 0, it is not further decremented.

Example
-	Starting
128 0 64 0 0 0 0 0 0 0 0 0 0 0 100 0 1 0 0 0 5 0 23 0 200 0 0 0
-	Final
128 31 64 31 64 30 64 29 64 28 64 27 64 26 100 31 1 31 1 30 5 31 23 31 200 31 200 30
