LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

ENTITY mem IS
   PORT (MemRead	: IN std_logic;
	 MemWrite	: IN std_logic;
	 d_in		: IN   word;		 
	 address	: IN   word;
	 d_out		: OUT  word 
	 );
END mem;


ARCHITECTURE mem_arch OF mem IS

-- component declaration
-- given in Glob_dcls.vhd
-- component specification
-- signal declaration

	signal addr: unsigned(29 downto 0);
	
	signal MEM : RAM:=("10001100000000010000000001010000",	--   lw   r1, 80(r0) -- r1 <= Mem[80], word addr:20 (value = 4)
	                   "00100000001000100000000000000101",	--   addi r2, r1, 5  -- r2 <= r1+5            r1=4 so r2 <= 9
	                   "00000000010000100001100001000010",	--   srl  r3, r2, 1  -- r3 <= r2 >>1          r3=4
	                   "00010100001000110000000000000011",	--   bne  r1, r3, 3  -- r1=4, r3=4    continue, no branch
	                   "00010000001000110000000000000001",	--   beq  r1, r3, 1  -- r1=4, r3=4    branch +1
	                   "00000000011000100010000000100000",	-- 5 skipped
	                   "00000000011000100010000000100010",	--   sub  r4, r3, r2 -- r4=r3-r2      -5
	                   "10101100000001000000000001011100",	--   sw   r4, 92(r0) -- Mem[23] <= r4
	                   "00001000000000000000000000001010",	--   jmp  40		      -- jmp to mem 10 (this was modified)
	                   "11111111111111111111111111111111",	--
	                   "00000000011000100010000000100000",	-- 10 add r4,r3,r2 -- r4=r3+r2   (4+9) 13
	                   "00000000010000100010100001000000",	--    sll r5,r2,1  -- r5 <= r2 << 1    18
	                   "00110100011001100000000001011000",	--    ori r3,r6,88 (1011000)b -- r3<=(1011100)b (92)
	                   "00110000110001110000000000011000",	--    andi r6,r7,24 (11000)b  -- r7<=24, (11000)b
	                   "00000000101001000100000000100101",	--    or r8,r4,r5             -- r8<=(11111)b (31)
	                   "00000000011001000100100000100100",	-- 15 and r9,r3,r4            -- r9<=(100)b (4)
	                   "00001000000000000000000000010000",	--    jmp 64 (16)             -- loop back here forever
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",	--
	                   "11111111111111111111111111111111",	--
	                   "00000000000000000000000000000100",	-- 20
	                   "00000000000000000000000000000001",	--
	                   "00000000000000000000000000000010",	--
	                   "00000000000000000000000000000011",	--
	                   "00000000000000000000000000000010",	--
	                   "00000000000000000000000000000000",	-- 25
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",	--
	                   "00000000000000000000000000000000",	-- 30
	                   "00000000000000000000000000000000"  --
                      );
	
BEGIN

addr <= unsigned(address(31 downto 2));

memory: process(MemRead, MemWrite)
	
begin
	if MemWrite'event and MemWrite = '1' then
     		MEM(TO_INTEGER(addr)) <= d_in after WR_LATENCY;
	elsif MemRead'event and MemRead = '1' then
     		d_out <= MEM(TO_INTEGER(addr)) after RD_LATENCY;
	else
     		null;
	end if;
end process memory;

END mem_arch;


