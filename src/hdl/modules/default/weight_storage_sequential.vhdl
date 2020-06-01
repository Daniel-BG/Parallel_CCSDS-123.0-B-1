----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:52:42 04/23/2016 
-- Design Name: 
-- Module Name:    weight_storage_sequential - Behavioral 
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

entity weight_storage_sequential is
	generic (
		Z_WIDTH: integer := Z_WIDTH;
		P_STAR: integer := P_STAR;
		OMEGA: integer := OMEGA--;
		--WEIGHT_INIT: weight_init_vector_t := WEIGHT_INIT
	);
	port (
		t_zero: in boolean;
		clk, enable: in std_logic;
		z: in unsigned(Z_WIDTH - 1 downto 0);
		w_out: out std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
		w_in: in std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0)
	);
end weight_storage_sequential;

architecture Behavioral of weight_storage_sequential is
		
	signal w_vectors: std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0) := (others => '0');
	
begin
	w_out <= w_vectors;


	update_values: process(clk, t_zero, w_in, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			if t_zero then
				--reset w_vectors to default values (this should be done after each band pass)
				for i in 0 to P_STAR - 1 loop
					w_vectors((i + 1)*(OMEGA + 3) - 1 downto i*(OMEGA + 3))
						<= std_logic_vector(to_unsigned(WEIGHT_INIT(to_integer(z), i), OMEGA + 3));
				end loop;
			else
				w_vectors <= w_in;
			end if;
		end if;
	end process;


end Behavioral;

