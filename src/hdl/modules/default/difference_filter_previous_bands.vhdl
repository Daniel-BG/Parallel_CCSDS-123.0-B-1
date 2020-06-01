----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:55:35 04/25/2016 
-- Design Name: 
-- Module Name:    weight_filter_previous_bands - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;


entity difference_filter_previous_bands is
	generic (
		Z_WIDTH: integer := 8;
		D: integer := 8;
		P_STAR: integer := 6;
		P: integer := 3
	);
	port (
		z: in unsigned(Z_WIDTH - 1 downto 0);
		diff_in_port: in std_logic_vector(P_STAR*(D + 3) - 1 downto 0);
		diff_out_port: out std_logic_vector(P_STAR*(D + 3) - 1 downto 0)
	);
end difference_filter_previous_bands;

architecture Behavioral of difference_filter_previous_bands is

begin
	dir_weights: if P_STAR > P generate
		diff_out_port(P_STAR*(D + 3) - 1 downto P*(D + 3))
			<= diff_in_port(P_STAR*(D + 3) - 1 downto P*(D + 3));
	end generate;
	
	fill_zeros: for i in 0 to P - 1 generate
		diff_out_port((i + 1)*(D + 3) - 1 downto i*(D + 3)) <=
			diff_in_port((i + 1)*(D + 3) - 1 downto i*(D + 3))
				when z > P - 1 - i else
			(others => '0');
	end generate;
	

end Behavioral;