----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:47:12 04/21/2016 
-- Design Name: 
-- Module Name:    sample_storage_sequential - Behavioral 
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
use ieee.numeric_std.all;


--FOR FULL MODE PREDICTION (MORE PORTS)
entity sample_storage_sequential_neighbor is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		D: integer := 16
	);
	port(
		clk, enable: in std_logic;
		sample: in unsigned(D - 1 downto 0);
		sample_west, sample_northwest, sample_north, sample_northeast: 
			out unsigned(D - 1 downto 0)
	);
end sample_storage_sequential_neighbor;

architecture Behavioral of sample_storage_sequential_neighbor is

	signal local_sample_west, local_sample_northwest, 
		local_sample_north, local_sample_northeast: std_logic_vector(D - 1 downto 0) := (others => '0');

begin
	--just output the saved value
	sample_west <= unsigned(local_sample_west);
	sample_northwest <= unsigned(local_sample_northwest);
	sample_north <= unsigned(local_sample_north);
	sample_northeast <= unsigned(local_sample_northeast);
	
	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		sample_mem: entity work.fifo_buffer
			generic map(D, X_MAX - 2)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;
	
	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		sample_shift_reg: entity work.shift_reg
			generic map(D, X_MAX - 2)
			port map(clk, enable, local_sample_west, local_sample_northeast);
	end generate;
	
	update_values: process(clk, sample, local_sample_northeast, local_sample_north, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			local_sample_west <= std_logic_vector(sample);
			local_sample_north <= local_sample_northeast;
			local_sample_northwest <= local_sample_north;
		end if;
	end process;

end Behavioral;
