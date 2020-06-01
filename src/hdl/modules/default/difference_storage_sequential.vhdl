----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:15:39 04/21/2016 
-- Design Name: 
-- Module Name:    difference_storage_sequential - Behavioral 
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
use work.ccsds_types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity difference_storage_sequential is
	generic (
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		Y_MAX: integer := 200;
		D: integer := 16; 
		P: integer := 3
	);
	port(
		clk, enable: in std_logic;
		--next coordinates
		diff: in signed(D + 2 downto 0);
		out_diff: out std_logic_vector(P*(D + 3) - 1 downto 0)
	);
end difference_storage_sequential;

architecture Behavioral of difference_storage_sequential is

	signal curr_contents: std_logic_vector(P*(D + 3) - 1 downto 0) := (others => '0');

begin

	out_diff <= curr_contents;

	--output saved values and connect RAM modules
	strg_mem_0: if not QUADRIC_STORAGE_AS_SHIFT_REG generate
		mem_0: entity work.fifo_buffer
			generic map(D + 3, X_MAX*Y_MAX)
			port map(clk, enable,
				std_logic_vector(diff),
				curr_contents(P*(D + 3) - 1 downto (P - 1)*(D + 3)));
	end generate;
	
	strg_shift_reg_0: if QUADRIC_STORAGE_AS_SHIFT_REG generate
		shift_reg_0: entity work.shift_reg
			generic map(D + 3, X_MAX*Y_MAX)
			port map(clk, enable,
				std_logic_vector(diff),
				curr_contents(P*(D + 3) - 1 downto (P - 1)*(D + 3)));
	end generate;
			
	create_memory: for i in 1 to P - 1 generate
		strg_mem_i: if not QUADRIC_STORAGE_AS_SHIFT_REG generate
			mem_i: entity work.fifo_buffer
				generic map(D + 3, X_MAX*Y_MAX)
				port map(clk, enable,
					curr_contents((i + 1)*(D + 3) - 1 downto i*(D + 3)),
					curr_contents(i*(D + 3) - 1 downto (i - 1)*(D + 3)));
		end generate;
		
		strg_shift_reg_i: if QUADRIC_STORAGE_AS_SHIFT_REG generate
			shift_reg_i: entity work.shift_reg
				generic map(D + 3, X_MAX*Y_MAX)
				port map(clk, enable,
					curr_contents((i + 1)*(D + 3) - 1 downto i*(D + 3)),
					curr_contents(i*(D + 3) - 1 downto (i - 1)*(D + 3)));
		end generate;
	end generate;


end Behavioral;

