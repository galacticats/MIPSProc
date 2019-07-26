-- Student name: Bianca Tang
-- Student ID number: 38478644

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath is
  
  port (
    clk        : in  std_logic;
    reset_N    : in  std_logic;
    
    PCUpdate   : in  std_logic;         -- write_enable of PC

    IorD       : in  std_logic;         -- Address selection for memory (PC vs. store address)
    MemRead    : in  std_logic;		-- read_enable for memory
    MemWrite   : in  std_logic;		-- write_enable for memory

    IRWrite    : in  std_logic;         -- write_enable for Instruction Register
    MemtoReg   : in  std_logic_vector(1 downto 0);  -- selects ALU or MEMORY or PC to write to register file.
    RegDst     : in  std_logic_vector(1 downto 0);  -- selects rt, rd, or "31" as destination of operation
    RegWrite   : in  std_logic;         -- Register File write-enable
    ALUSrcA    : in  std_logic;         -- selects source of A port of ALU
    ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
    
    ALUControl : in  ALU_opcode;	-- receives ALU opcode from the controller
    PCSource   : in  std_logic_vector(1 downto 0);  -- selects source of PC

    opcode_out : out opcode;		-- send opcode to controller
    func_out   : out opcode;		-- send func field to controller
    zero       : out std_logic; -- send zero to controller (cond. branch)
    Equals	: out std_logic); --not part of original ports list. Added to enable BEQ/BNE completion in 3 cycles	

end datapath;


architecture datapath_arch of datapath is
-- component declaration
COMPONENT ALU IS
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount -> it's now instruction[10-6]	
        ALUout   : out word; --word: std_logic_vector (31 DOWNTO 0)
        Zero     : out std_logic); --generates 1 when ALUout = '0'
END COMPONENT;

COMPONENT RegFile IS
  PORT(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  );
END COMPONENT;

COMPONENT mem IS
   PORT (MemRead	: IN std_logic;
	 MemWrite	: IN std_logic;
	 d_in		: IN   word;	--d_in is always RegB output (SIGNAL B_to_Mux)	 
	 address	: IN   word;	--can be PC out, or ALUOut out -> name the MUX output MemAddr
	 d_out		: OUT  word 
	 );
END COMPONENT;

-- signal declaration--------------------------------------------------------------------------------------------------------------------------------
--REGISTER SIGNALS
SIGNAL PCReg : word := "00000000000000000000000000000000";
SIGNAL AReg, BReg, ALUOutReg, MDR, IR : word;

--INTERNAL SIGNALS - OTHER
SIGNAL RF_to_A, RF_to_B, Mem_to_MDR, sign_ext_out, imm_shift_out, final_target: word; --internal DP signals
SIGNAL J_ext: std_logic_vector(27 DOWNTO 0);

--MUX INPUT SIGNALS
--Signals that are instruction parts (rs, rt, rd, etc, are in the INSTRUCTION OUTPUTS section)
SIGNAL B_to_Mux, A_to_Mux, ALUReg_to_Mux, ALU_to_Mux, PCOut, MDROut : word; --32 bits long

--MUX OUTPUT SIGNALS -> 6 muxes total, 6 signals
SIGNAL MemAddr, A_Mux_to_ALU, B_Mux_to_ALU, RF_in, Mux_to_PC: word; -- 32 bits long
SIGNAL RFWriteAddr : reg_addr; --5 bits long

--INSTRUCTION OUTPUTS
SIGNAL rs, rt, rd, shamt : reg_addr; --Instruction 5-bit wide outputs (shamt is not a reg address, but C, the shift amount. It's also 5 bits long)
SIGNAL imm : offset; --Imm 16-bit offset or ALU value
SIGNAL JTarget : target; --J instruction 26bit target
----------------------------------------------------------------------------------------------------------------------------------------------------------

begin
--Initialize components: memory, register file, and ALU---------------------------------------------------------------
CompALU : ALU PORT MAP(ALUControl, A_Mux_to_ALU, B_Mux_to_ALU, shamt, ALU_to_Mux, Zero);
CompRF : RegFile PORT MAP(clk, RegWrite, rs, rt, RFWriteAddr, RF_in, RF_to_A, RF_to_B);
CompMem: Mem PORT MAP(MemRead, MemWrite, B_to_Mux, MemAddr, Mem_to_MDR);
----------------------------------------------------------------------------------------------------------------------

--ASSIGNMENTS THAT ALWAYS RUN-----------------------------------------------------------------------------------------
--Register outputs
ALUReg_to_Mux <= ALUOutReg;
A_to_Mux <= AReg;
B_to_Mux <= BReg; 
MDROut <= MDR;
PCOut <= PCReg;

--Instruction breakdown
rs <= IR(25 DOWNTO 21);
rt <= IR(20 DOWNTO 16);
rd <= IR(15 DOWNTO 11);
shamt <= IR(10 DOWNTO 6);
imm <= IR(15 DOWNTO 0);
JTarget <= IR(25 DOWNTO 0);
func_out <= IR (5 DOWNTO 0); --external output
opcode_out <= IR (31 DOWNTO 26); --external output

--J target 26 to 32 bits
J_ext <= JTarget & "00";
final_target <= PCOut(31 DOWNTO 28) & J_ext;

--Equals flag
Equals <= '1' WHEN A_to_Mux = B_to_Mux ELSE '0';
-------------------------------------------------------------------------------------------------------------------------

--MUXES--------------------------------------------------------------------------------------------------------------------------------------
--MemAddr, A_Mux_to_ALU, B_Mux_to_ALU, RF_in, Mux_to_PC, RFWriteAddr

--MemAddr MUX chooses between PC instruction or I-type Memory access from ALUOut
MemAddr <= ALUReg_to_Mux WHEN (IorD = '0') ELSE 
		PCOut;

--Input A of the ALU is either the read out from register A or the PC value
A_Mux_to_ALU <= A_to_Mux WHEN (ALUSrcA = '0') ELSE 
		PCOut;

--Input B of the ALU is either Register B, the number 4, the sign-extended imm value, or the sign extended and shifted imm value
B_Mux_to_ALU <= B_to_Mux WHEN (ALUSrcB = "00") ELSE 
		"00000000000000000000000000000100" WHEN (ALUSrcB = "01") ELSE
		sign_ext_out WHEN (ALUSrcB = "10") ELSE
		imm_shift_out;

--RF_in chooses the data stored into memory. It's either ALUOut, MDROut, or the PC value
RF_in <= ALUReg_to_Mux WHEN (MemToReg = "00") ELSE
		MDROut WHEN (MemToReg = "01") ELSE
		PCOut WHEN (MemToReg = "10");

--Chooses the next PC value. Can be jump address, branch address, or PC+4
Mux_to_PC <= final_target WHEN (PCSource = "00") ELSE
		ALUReg_to_Mux WHEN (PCSource = "01") ELSE
		ALU_to_Mux WHEN (PCSource = "10");

--Chooses the write address. Can be rt, 31, or rd
RFWriteAddr <= rt WHEN (RegDst = "00") ELSE
		"11111" WHEN (RegDst = "01") ELSE
		rd WHEN (RegDst = "10");
---------------------------------------------------------------------------------------------------------------------------------------------

SignExt : PROCESS (imm)
BEGIN
  sign_ext_out <= (others => imm(15));
  sign_ext_out(15 DOWNTO 0) <= imm;
END PROCESS SignExt;

ImmShift : PROCESS (sign_ext_out)
BEGIN
  imm_shift_out (31 DOWNTO 2) <= sign_ext_out(29 DOWNTO 0);
  imm_shift_out (1 DOWNTO 0) <= "00";
END PROCESS ImmShift;

RegUpdates : PROCESS (clk, reset_N) --Updates each register by loading new value at the rising edge of the clock
BEGIN
  IF (reset_N = '1') THEN
    PCReg <= (OTHERS => '0');
  ELSE
    IF (clk = '1' AND clk'EVENT) THEN
      IF (PCUpdate = '1') THEN
	      PCReg <= Mux_to_PC;
      END IF;
      AReg <= RF_to_A;
      BReg <= RF_to_B;
      ALUOutReg <= ALU_to_Mux;
      MDR <= Mem_to_MDR;
      IF (IRWrite = '1') THEN
        IR <= Mem_to_MDR;
      END IF;
    END IF;
  END IF;
END PROCESS RegUpdates;
  
end datapath_arch;
