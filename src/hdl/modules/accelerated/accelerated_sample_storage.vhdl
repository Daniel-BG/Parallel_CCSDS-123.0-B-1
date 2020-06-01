----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:46:12 04/23/2016 
-- Design Name: 
-- Module Name:    accelerated_sample_storage - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity accelerated_sample_storage is
	generic(
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		Z_MAX: integer := 200;
		D: integer := 16;
		C: integer := 4
	);
	port(
		clk, enable: in std_logic;
		sample_in: in std_logic_vector(C*D - 1 downto 0);
		sample_west, sample_northwest, sample_north, sample_northeast: out std_logic_vector(C*D - 1 downto 0)
	);
end accelerated_sample_storage;

architecture Behavioral of accelerated_sample_storage is
	
	signal local_sample_west, local_sample_northwest, local_sample_north,
		local_sample_northeast: std_logic_vector(C*D - 1 downto 0);
	
	
begin
	sample_west <= local_sample_west;
	sample_northwest <= local_sample_northwest;
	sample_north <= local_sample_north;
	sample_northeast <= local_sample_northeast;


	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		--input shift register to store west samples
		west_mem: entity work.fifo_buffer
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, sample_in, local_sample_west);
		
		--two more shift registers to store samples until they are in the
		--northwest postition
		north_mem: entity work.fifo_buffer
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, local_sample_northeast, local_sample_north);
			
		northwest_mem: entity work.fifo_buffer
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, local_sample_north, local_sample_northwest);
	end generate;
	
	gen_mem_2: if not QUADRIC_STORAGE_AS_SHIFT_REG generate
		--need to store one less column since we start with the northeast sample
		--also 1 less value is stored since the output latch of RAM will take care
		--of storing that value
		northeast_mem: entity work.fifo_buffer
			generic map(C*D, (X_MAX - 2)*Z_MAX/C)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;
	
	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		west_shift_reg: entity work.shift_reg
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, sample_in, local_sample_west);
		north_shift_reg: entity work.shift_reg
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, local_sample_northeast, local_sample_north);
		northwest_shift_reg: entity work.shift_reg
			generic map(C*D, Z_MAX/C)
			port map(clk, enable, local_sample_north, local_sample_northwest);
	end generate;
	
	gen_shift_reg_2: if QUADRIC_STORAGE_AS_SHIFT_REG generate
		northeast_mem: entity work.shift_reg
			generic map(C*D, (X_MAX - 2)*Z_MAX/C)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;


end Behavioral;

