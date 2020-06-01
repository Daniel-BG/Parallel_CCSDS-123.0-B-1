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

entity local_sum_generator_column is
	generic(
		D: integer := 16
	);
	port(
		sample_west, sample_north: in unsigned(D - 1 downto 0);
		y_low: in boolean;
		local_sum: out unsigned(D + 1 downto 0)
	);
end local_sum_generator_column;

architecture Behavioral of local_sum_generator_column is

begin
	local_sum <= 
		sample_west & "00"
			when y_low else
		sample_north & "00";


end Behavioral;

