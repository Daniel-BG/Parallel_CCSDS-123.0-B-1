----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:23:38 04/22/2016 
-- Design Name: 
-- Module Name:    local_sum_generator - Behavioral 
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
use work.ccsds_types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity local_sum_generator_neighbor is
	generic(
		D: integer := 16
	);
	port(
		sample_west, sample_northwest, sample_north, sample_northeast: in unsigned(D - 1 downto 0);
		y_low, x_low, x_high: in boolean;
		local_sum: out unsigned(D + 1 downto 0)
	);
end local_sum_generator_neighbor;

architecture Behavioral of local_sum_generator_neighbor is

begin

	--local sum
	--------------------
	local_sum <=
		sample_west & "00"
			when y_low else
		(("0" & sample_north) + ("0" & sample_northeast)) & "0"
			when x_low else
		(("0" & sample_north & "0") + ("00" & sample_northwest)) + ("00" & sample_west)
			when x_high else
		(("00" & sample_north) + ("00" & sample_northwest))
		+ (("00" & sample_northeast) + ("00" & sample_west));	



end Behavioral;

