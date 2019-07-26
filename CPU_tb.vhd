-- Student name: Bianca Tang
-- Student ID number: 38478644

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU_tb is
end CPU_tb;

architecture CPU_test of CPU_tb is
-- component declaration
	-- CPU (you just built)
COMPONENT CPU
  PORT (
    clk     : in std_logic;
    reset_N : in std_logic);            -- active-low signal for reset
END COMPONENT;

-- component specification
-- signal declaration
	-- You'll need clock and reset.
SIGNAL clk_s : std_logic := '0';
SIGNAL reset_N_s : std_logic := '1';

begin
TestCPU : CPU PORT MAP (clk_s, reset_N_s);

clkProc : PROCESS --Clock period is 40 ns in lab description
BEGIN
	WAIT FOR 20 NS;
	clk_s <= NOT clk_s;
END PROCESS clkProc;

testProc : PROCESS
BEGIN
	WAIT FOR 21 NS;
	reset_N_s <= '0';
--New mem file (64 long)
	--   addi r1, r0, 1 -- r1 = 1; -> start @ 20, finish @ 180
	--   add  r2, r1, r1  -- r2 = r1*2 -> start @ 180, finish @ 340
	--   lw   r3, 124(r0) -- r3 = 111....11 -> finish @ 540
	--   and r4, r0, r0   -> finish @ 700
	--   beq  r4, r2, 3 -> r4 = 0, r2 = 2, no branch -> finish @ 820, pc should go to 20
	--   srl r3, r3, 1 -> finish @ 980
 	--   addi r4, r4, 1 -> finish @ 1140 -> r4 goes to 1
 	--   j 4 -> finish @ 1260 -> PC goes from 32 to 16 (instr 4 is beq --> does this twice, until r4 = r2 at 1700)
	--   andi r4, r0, 7   -- gets here at 1940, finishes at 2100
	--   beq  r4, r1, 3 -> 1st run finishes at 2220, no branch -> branches at 2780
	--   sll r3, r3, 1 -> 2380
	--   addi r4, r4, 1 -> 2540, r4 becomes 1
	--   j 9 -> goes back to beq (PC = 36) at 2660
	--   sll r4, r1, 1    -- r4 = r1*4 -->Gets here at 2780, finishes at 2940
	--   sll r4, r4, 1    -- r4 = 4 @ 3100
	--   lw r5, 124(r4)   -- r5 = mem[31+1] -> stores all 0s @ 3300
	--   or r5, r5, r3    -- r5 = r5 or r3	-> 3460, 7FFFFFFE
	--   sw r5, 124(r4)   -- mem[31+r1] = r5 -> 3620	              	             
	--   sub r4, r0, r4   -- r4 = -r4   --3780
	--   sw r5, 252(r4)   -- mem[63-r1] = r5 --3940
	--   addi r1, r1, 1   -- r1 = r1 + 1  --4100
	--   ori r2, r0, 16   -- r2 = 16 --4260
	--   bne r1, r2, -22  -- if (r1 != 16) jump back 22 instruction	to mem[1] --First branch made at 4380                   
	--   j 23             -- loop back here forever --> gets here at 239700



--Old mem file (32 long)
	--Line 1 LW begins at 20 and should end at 220ns -> should see (4) in REG(1)
	--Line 2 addi begins at 220 and should end at 380ns (4 cyc) -> should see (9) in REG(2)
	--Line 3 srl begins at 380 and should end at 540 -> should see (4) in REG(3)
	--Line 4 bne begins at 540 and should end at 660 -> should NOT branch. PC goes to 16 normally
	--Line 5 beq begins at 660 and should end at 780 -> should branch. PC goes to 24 instead of 20
        --Line 7 sub begins at 780 and should end at 940 -> should see (-5) in REG(4)
	--Line 8 sw begins at 940 and should end at 1100 -> should see (-5) in MEM(23)
	--Line 9 jmp begins at 1100 and should end at 1220 -> should see PC go to 40 instead of 36
	--Line 10 add begins at 1220 should end at 1380 -> should see (13) in REG(4)
	--Line 11 sll begins at 1380 should end at 1540 -> should see (18) in REG(5)
	--Line 12 ori begins at 1540 should end at 1700 -> should see (92) in REG(3)
	--Line 13 andi begins at 1700 should end at 1860 -> should see (24) in REG(7)
	--Line 14 or begins at 1860 should end at 2020 ->  should see (31) in REG(8)
	--Line 15 and begins at 2020 shoudl end at 2180 -> should see (4) in REG(9)
	--Line 16 jmp begins at 2180 should end at 2300 -> should see PC go to 64 instead of 68
	--PC should stay 64 forever after this point

	--Mem has 16 different instructions, and the 16th one loops back to itself forever
	WAIT;
END PROCESS testProc;
end CPU_test;
