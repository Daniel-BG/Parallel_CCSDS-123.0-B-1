----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:58:56 04/23/2016 
-- Design Name: 
-- Module Name:    difference_storage_interleaved_line - Behavioral 
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

entity difference_storage_interleaved_line is
	generic(
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		D: integer := 16;
		P: integer := 3
	);
	port(
		clk, enable: in std_logic;
		diff: in signed(D + 2 downto 0);
		out_diff: out std_logic_vector(P*(D + 3) - 1 downto 0)
	);
end difference_storage_interleaved_line;

architecture Behavioral of difference_storage_interleaved_line is

	signal diff_storage: std_logic_vector(P*(D + 3) - 1 downto 0);
	
begin

	out_diff <= diff_storage;
	--we keep a shift register for each previous P lines feeding one
	--into the next. The output of each shift register is the value
	--for the previous band's difference
	storage_0_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		mem_0: entity work.fifo_buffer
			generic map(D + 3, X_MAX)
			port map(clk, enable,
				std_logic_vector(diff),
				diff_storage(P*(D + 3) - 1 downto (P - 1)*(D + 3)));
	end generate;
			
	storage_0_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		shift_reg_0: entity work.shift_reg
			generic map(D + 3, X_MAX)
			port map(clk, enable,
				std_logic_vector(diff),
				diff_storage(P*(D + 3) - 1 downto (P - 1)*(D + 3)));
	end generate;

	gen_rest: for i in 0 to P - 2 generate
		gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
			mem_i: entity work.fifo_buffer
				generic map(D + 3, X_MAX)
				port map(clk, enable, 
					diff_storage((i + 2)*(D + 3) - 1 downto (i + 1)*(D + 3)),
					diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)));		
		end generate;
		
		gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
			shift_reg_i: entity work.shift_reg
				generic map(D + 3, X_MAX)
				port map(clk, enable, 
					diff_storage((i + 2)*(D + 3) - 1 downto (i + 1)*(D + 3)),
					diff_storage((i + 1)*(D + 3) - 1 downto i*(D + 3)));
		end generate;
	end generate;
	
	


end Behavioral;

