----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:10:32 04/23/2016 
-- Design Name: 
-- Module Name:    sample_storage_interleaved_line_neighbor - Behavioral 
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

entity sample_storage_interleaved_line_neighbor is
	generic(
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		Z_MAX: integer := 200;
		D: integer := 16
	);
	port(
		clk, enable: in std_logic;
		sample_in: in unsigned(D - 1 downto 0);
		sample_west, sample_northwest, sample_north, sample_northeast: out unsigned(D - 1 downto 0)
	);
end sample_storage_interleaved_line_neighbor;

architecture Behavioral of sample_storage_interleaved_line_neighbor is

	signal local_sample_west, local_sample_northwest, local_sample_north,
		local_sample_northeast: std_logic_vector(D - 1 downto 0);
	
	
begin
	sample_west <= unsigned(local_sample_west);
	sample_northwest <= unsigned(local_sample_northwest);
	sample_north <= unsigned(local_sample_north);
	sample_northeast <= unsigned(local_sample_northeast);
	
	update_samples: process(clk, sample_in, local_sample_north, local_sample_northeast)
	begin
		if rising_edge(clk) and enable = '1' then
			local_sample_west <= std_logic_vector(sample_in);
			local_sample_northwest <= local_sample_north;
			local_sample_north <= local_sample_northeast;
		end if;
	end process;
	
	gen_mem: if not QUADRIC_STORAGE_AS_SHIFT_REG generate
		sample_mem: entity work.fifo_buffer
			generic map(D, X_MAX*Z_MAX - 2)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;
	
	gen_shift_reg: if QUADRIC_STORAGE_AS_SHIFT_REG generate
		sample_shift_reg: entity work.shift_reg
			generic map(D, X_MAX*Z_MAX - 2)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;


end Behavioral;

