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

entity accelerated_difference_storage is
	generic(
		D: integer := 16;
		P: integer := 3;
		C: integer := 4
	);
	port(
		clk, enable: in std_logic;
		diff: in std_logic_vector(C*(D + 3) - 1 downto 0);
		out_diff: out std_logic_vector(P*(D + 3) - 1 downto 0)
	);
end accelerated_difference_storage;

architecture Behavioral of accelerated_difference_storage is
	signal diff_storage: std_logic_vector(P*(D + 3) - 1 downto 0);
	
begin
	out_diff <= diff_storage;
	
	max_0: if P - C <= 0 generate
		update: process(diff, clk, enable)
		begin
			if rising_edge(clk) and enable = '1' then
				for i in 0 to P - 1 loop
					diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)) 
						<= diff((i + C - P + 1)*(D + 3) - 1 downto (i + C - P)*(D + 3));
				end loop;
			end if;
		end process;
	end generate;
	
	max_p_c: if P - C > 0 generate
		update: process(diff, clk)
		begin
			if rising_edge(clk) and enable = '1' then
				for i in 0 to P - C - 1 loop
					diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)) 
						<= diff_storage((i + C + 1)*(D + 3) - 1 downto (i + C)*(D + 3));
				end loop;
				for i in P - C to P - 1 loop
					diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)) 
						<= diff((i + C - P + 1)*(D + 3) - 1 downto (i + C - P)*(D + 3));
				end loop;
			end if;
		end process;
	end generate;




end Behavioral;

