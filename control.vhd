-- Student name: Bianca Tang
-- Student ID number: 38478644
-- Branch instructions are currently 4 cycles. Think of a way to make it 3 cycles

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity control is 
   port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 

	--Changed below from "opcode" to "op" to avoid naming error        
        op          : IN opcode;     -- declare type for the 6 most significant bits of IR
        funct       : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC;
        
     	PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     	IorD        : OUT STD_LOGIC;
     	MemRead     : OUT STD_LOGIC;
     	MemWrite    : OUT STD_LOGIC;

     	IRWrite     : OUT STD_LOGIC;
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC;
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0);
     	ALUcontrol  : OUT ALU_opcode;
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
end control;

architecture control_arch of control is
-- MIPS Opcodes from https://opencores.org/projects/plasma/opcodes
type states is (IFetch, IDecode, Jump, Branch, MemAddrComp, LoadAccess, LoadCompletion, StoreAccess, RTypeExec, Immediate, RICompletion);
SIGNAL currState, nextState : states;
SIGNAL nextMemRead, nextALUSrcA, nextIorD, nextMemWrite, nextIRWrite, nextRegWrite : STD_LOGIC;
SIGNAL nextMemToReg, nextRegDst, nextALUSrcB: STD_LOGIC_VECTOR (1 downto 0);
SIGNAL nextALUControl : ALU_opcode;
-- signal declaration

begin

--STD_Logics
--PC can only update on reset, Fetches (PC+4), Jumps, or successful branches
PCUpdate <= '1' WHEN reset_N = '1' OR currState = IFetch OR currState = Jump OR (currState = Branch AND ((op = "000100" AND Zero = '1') OR (op = "000101" AND Zero = '0'))) ELSE '0';
--Instruction or Data
nextIorD <= '1' WHEN (nextState = IFetch) ELSE '0';
nextMemRead <= '1' WHEN (nextState = LoadAccess OR nextState = IFetch) ELSE '0';
nextMemWrite <= '1' WHEN (nextState = StoreAccess)ELSE '0'; 
--Write new instruction into IR only on IFetch
nextIRWrite <= '1' WHEN (nextState = IFetch) ELSE '0';
--Write into register file at the end of Loads, Rtypes, and Immediates
nextRegWrite <= '1' WHEN (nextState = LoadCompletion OR nextState = RICompletion) ELSE '0';
--PC value is 0, RegA value is 1
nextALUSrcA <= '1' WHEN (nextState = IFetch OR nextState = IDecode) ELSE '0';

--STD_LOGIC_VECTORs
--Chooses what's stored into RF
nextMemToReg <= "00" WHEN (nextState = RICompletion) ELSE --ALUOut
		"01" WHEN (nextState = LoadCompletion) ELSE --MDROut
		"10"; --PCOut
--Chooses which register in RF is written into
nextRegDst <=   "00" WHEN (nextState = LoadCompletion OR nextState = Immediate OR (nextState = RICompletion AND currState = Immediate)) ELSE --rt
		"10"; --rd
--Chooses value of ALU's 2nd input
nextALUSrcB <=  "00" WHEN (nextState = Branch OR nextState = RTypeExec) ELSE --RegB
		"01" WHEN (nextState = IFetch) ELSE --The number 4 (PC+4)
		"10" WHEN (nextState = MemAddrComp OR nextState = Immediate)ELSE --Imm value
		"11"; --Shifted imm value
--Chooses source of PC's value -> Jump, Branch, or +4
PCSource <= "00" WHEN currState = Jump ELSE --Jump address
		"01" WHEN currState = Branch AND ((op = "000100" AND Zero = '1') OR (op = "000101" AND Zero = '0')) ELSE --Branch address
		"10"; --PC+4

--ALU_ctrl for R-types
nextALUControl <= "000" WHEN (nextState = IFetch OR nextState = IDecode OR nextState = MemAddrComp OR (nextState = RTypeExec AND (funct = "100000")) OR (nextState = Immediate AND (op = "001000"))) ELSE --add
		"001" WHEN (nextState = RTypeExec AND (funct = "100010")) OR (nextState = Branch) ELSE--sub
		"010" WHEN (nextState = RTypeExec AND (funct = "000000")) ELSE --sll
		"011" WHEN (nextState = RTypeExec AND (funct = "000010")) ELSE --srl
		"100" WHEN ((nextState = RTypeExec AND (funct = "100100")) OR (nextState = Immediate AND (op = "001100")))ELSE --and
		"101" WHEN ((nextState = RTypeExec AND (funct = "100101")) OR (nextState = Immediate AND (op = "001101"))) ELSE --or
		"110" WHEN ((nextState = RTypeExec AND (funct = "100110")) OR (nextState = Immediate AND (op = "001110"))) ELSE --xor
		"111"; --nor

StateCase : PROCESS (CurrState, op, funct)
BEGIN
  CASE currState IS
    WHEN IFetch =>
      nextState <= IDecode;
    WHEN IDecode =>
      IF (op = "000010") THEN --jmp
	nextState <= Jump;
      ELSIF (op = "000101" OR op = "000100") THEN --bne or beq
	nextState <= Branch;
      ELSIF (op = "100011" OR op = "101011") THEN --lw or sw
	nextState <= MemAddrComp;
      ELSIF (op = "001000" OR op = "001101" OR op = "001100" OR op = "001110") THEN --001000 addi, 001101 ori, 001100 andi, 001110 xori
	nextState <= Immediate;
      ELSIF (op = "000000") THEN --rType
	nextState <= RTypeExec;
      END IF;
    WHEN Jump =>
      nextState <= IFetch;
    WHEN Branch =>
      nextState <= IFetch;
    WHEN MemAddrComp => --100011 lw, 101011 sw
      IF (op = "100011") THEN
        nextState <= LoadAccess;
      ELSIF (op = "101011") THEN
	nextState <= StoreAccess;
      END IF;
    WHEN LoadAccess =>
      nextState <= LoadCompletion;
    WHEN LoadCompletion =>
      nextState <= IFetch;
    WHEN StoreAccess =>
      nextState <= IFetch;
    WHEN RTypeExec =>
      nextState <= RICompletion;
    WHEN Immediate =>
      nextState <= RICompletion;
    WHEN RICompletion =>
      nextState <= IFetch;
    WHEN OTHERS =>
      nextState <= IFetch;
    END CASE;
END PROCESS StateCase;

Regs : PROCESS (clk, reset_N)
BEGIN
  IF (reset_N = '1') THEN
    currState <= IFetch;
    IorD <= '1';
    MemRead <= '1';
    MemWrite <= '0';
    IRWrite <= '1';
    MemToReg <= "10";
    RegDst <= "10";
    RegWrite <= '0';
    ALUSrcA <= '1';
    ALUSrcB <= "01";
    ALUControl <= "000";
    --PCSource <= "10";
  ELSE
    IF (clk'EVENT AND clk = '1') THEN
      currState <= nextState;
      IorD <= nextIorD;
      MemRead <= nextMemRead;
      MemWrite <= nextMemWrite;
      IRWrite <= nextIRWrite;
      MemtoReg <= nextMemToReg;
      RegDst <= nextRegDst;
      RegWrite <= nextRegWrite;
      ALUSrcA <= nextALUSrcA;
      ALUSrcB <= nextALUSrcB;
      ALUcontrol <= nextALUControl;
    END IF;	
  END IF;
END PROCESS Regs;
end control_arch;



