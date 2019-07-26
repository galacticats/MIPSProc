-- Student name: Bianca Tang
-- Student ID number: 38478644

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity RegFile is 
  port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  );
end RegFile;

architecture RF_arch of RegFile is
-- REG_addr is std_logic_vector(4 downto 0)
-- word is std_logic_vector(word_size-1 downto 0)
-- component declaration
-- signal declaration
TYPE RF IS ARRAY (0 TO 31) of word; --Changed from DOWNTO to TO so that RF[0] is 0 and to stay consistent with MEM addressing
--The RF is a collection of 16 words due to its 5-bit address
--INITIALIZED RF TO MEM(32 to 63), as the datapath in lab 6 uses both an RF and a Mem
SIGNAL RFile : RF :=(	--   DATA MEMORY (index 32 of RAM)
	                   "00000000000000000000000000000000",	--
	                   "00000000000000001000000000000000",	--
	                   "00000000000000000000000000000000",	--
	                   "00000000000000001000000000000000",	--
	                   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
	                   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
	                   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
	                   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--              
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--              
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--
			   "00000000000000000000000000000000",	--
			   "00000000000000001000000000000000",	--              
			   "00000000000000000000000000000000",	--
			   "11111111111111111111111111111111"	-- 
                      ); 

begin
  d_out_1 <= RFile(to_integer(unsigned(rd_addr_1))); --asynch reads
  d_out_2 <= RFile(to_integer(unsigned(rd_addr_2)));
  PROCESS (clk)
  BEGIN
    IF (clk = '1' AND clk'EVENT) THEN --on the rising edge only
      IF (wr_en = '1') THEN
        RFile((to_integer(unsigned(wr_addr)))) <= d_in; --synch writes
      END IF;
    END IF;
  END PROCESS;
end RF_arch;
