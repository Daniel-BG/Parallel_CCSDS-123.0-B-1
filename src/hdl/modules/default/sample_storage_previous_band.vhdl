----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:05:25 04/24/2016 
-- Design Name: 
-- Module Name:    sample_storage_previous_band - Behavioral 
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

entity sample_storage_previous_band is
	generic(
		D: integer := 16
	);
	port(
		clk, enable: in std_logic;
		t_zero: in boolean;
		sample_in: in unsigned(D - 1 downto 0);
		sample_out: out unsigned(D - 1 downto 0)
	);
end sample_storage_previous_band;

architecture Behavioral of sample_storage_previous_band is
	signal sample_prev_band: unsigned(D - 1 downto 0);

begin
	sample_out <= sample_prev_band;
	
	update: process(clk, sample_in, t_zero, enable)
	begin
		if rising_edge(clk) and enable = '1' and t_zero then
				sample_prev_band <= sample_in;
		end if;
	end process;


end Behavioral;

