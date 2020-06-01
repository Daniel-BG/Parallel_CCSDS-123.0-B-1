----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:48:13 04/23/2016 
-- Design Name: 
-- Module Name:    difference_storage_interleaved_pixel - Behavioral 
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

entity difference_storage_interleaved_pixel is
	generic(
		D: integer := 16;
		P: integer := 3
	);
	port(
		clk, enable: in std_logic;
		diff: in signed(D + 2 downto 0);
		out_diff: out std_logic_vector(P*(D + 3) - 1 downto 0)
	);
end difference_storage_interleaved_pixel;

architecture Behavioral of difference_storage_interleaved_pixel is
	--since we process all bands of each pixel continuously, we only need
	--storage for the previous P samples. If we are on z < P, we output some
	--dummy values that futher units should ignore
	signal diff_storage: std_logic_vector(P*(D + 3) - 1 downto 0);
	
begin
	out_diff <= diff_storage;
	
	
	update: process(diff, clk, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			for i in 0 to P - 2 loop
				diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)) 
					<= diff_storage((i + 2)*(D + 3) - 1 downto (i + 1)*(D + 3));
			end loop;
			diff_storage(P*(D + 3) - 1 downto (P - 1)*(D + 3)) <= std_logic_vector(diff);
		end if;
	end process;




end Behavioral;

