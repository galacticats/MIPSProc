-- Student name: Bianca Tang
-- Student ID number: 38478644

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  port (
    clk     : in std_logic;
    reset_N : in std_logic);            -- active-low signal for reset

end CPU;

architecture CPU_arch of CPU is
-- component declaration
	
	-- Datapath (from Lab 5)
component datapath
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
    zero       : out std_logic);	-- send zero to controller (cond. branch)
end component;

	-- Controller (you just built)
component control is 
   port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 
        
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
end component;

-- signal declaration
-- Connecting wires (_w)
SIGNAL PCUpdate_w, IorD_w, MemRead_w, MemWrite_w, IRWrite_w, RegWrite_w, ALUSrcA_w, zero_w : STD_LOGIC;
SIGNAL MemtoReg_w, RegDst_w, PCSource_w, ALUSrcB_w : STD_LOGIC_VECTOR(1 downto 0);
SIGNAL ALUcontrol_w : ALU_opcode;
SIGNAL opcode_w, funct_w : opcode;

begin
--Init components
Ctrl : control PORT MAP (clk, reset_N, opcode_w, funct_w, zero_w, PCUpdate_w, IorD_w, MemRead_w, MemWrite_w, IRWrite_w, MemToReg_w, RegDst_w, RegWrite_w, ALUSrcA_w, ALUSrcB_w, ALUControl_w, PCSource_w);
DPath : datapath PORT MAP (clk, reset_N, PCUpdate_w, IorD_w, MemRead_w, MemWrite_w, IRWrite_w, MemToReg_w, RegDst_w, RegWrite_w, ALUSrcA_w, ALUSrcB_w, ALUControl_w, PCSource_w, opcode_w, funct_w, zero_w);

end CPU_arch;
