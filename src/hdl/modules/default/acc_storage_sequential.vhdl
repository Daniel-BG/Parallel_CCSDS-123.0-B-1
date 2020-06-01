----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:52:42 04/23/2016 
-- Design Name: 
-- Module Name:    acc_storage_sequential - Behavioral 
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
use work.ccsds_constants.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity acc_storage_sequential is
	generic (
		Z_WIDTH: integer := Z_WIDTH;
		GAMMA_STAR: integer := GAMMA_STAR;
		D: integer := D
	);
	port (
		t_zero: in boolean;
		clk, enable: in std_logic;
		z: in unsigned(Z_WIDTH - 1 downto 0);
		acc_out: out std_logic_vector(D + GAMMA_STAR - 1 downto 0);
		acc_in: in std_logic_vector(D + GAMMA_STAR - 1 downto 0)
	);
end acc_storage_sequential;

architecture Behavioral of acc_storage_sequential is
		
	signal accumulator: std_logic_vector(D + GAMMA_STAR - 1 downto 0);
	
begin
	acc_out <= accumulator;

	update_values: process(clk, t_zero, acc_in, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			if t_zero then
				--reset w_vectors to default values (this should be done after each band pass)
				accumulator
					<= std_logic_vector(to_unsigned(ACCUMULATOR_INIT(to_integer(z)), D + GAMMA_STAR));
			else
				accumulator <= acc_in;
			end if;
		end if;
	end process;


end Behavioral;

