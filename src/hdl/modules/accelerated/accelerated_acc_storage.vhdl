----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:45:04 11/28/2016 
-- Design Name: 
-- Module Name:    accelerated_acc_storage - Behavioral 
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
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity accelerated_acc_storage is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_WIDTH: integer := Z_WIDTH;
		Z_MAX: integer := Z_MAX;
		GAMMA_STAR: integer := GAMMA_STAR;
		D: integer := D;
		C: integer := C
	);
	port (
		clk, enable: in std_logic;
		t_zero: in boolean;
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		acc_in: in std_logic_vector(C*(D + GAMMA_STAR) - 1 downto 0);
		acc_out: out std_logic_vector(C*(D + GAMMA_STAR) - 1 downto 0)
	);
end accelerated_acc_storage;

architecture Behavioral of accelerated_acc_storage is

	signal acc_mem_out, acc_mem_in, acc_reset: std_logic_vector(C*(D + GAMMA_STAR) - 1 downto 0);

begin

	gen_reset: for i in 0 to C - 1 generate
		acc_reset((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR))
			<= std_logic_vector(to_unsigned(ACCUMULATOR_INIT(to_integer(z_curr + i)), D + GAMMA_STAR));
			
		acc_out((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)) 
			<= acc_reset((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)) when t_zero 
				else acc_mem_out((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR));
	
		acc_mem_in((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)) 
			<= acc_reset((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)) when t_zero 
				else acc_in((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR));
	end generate;
	
	
				
	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.fifo_buffer
			generic map(C*(D + GAMMA_STAR), Z_MAX/C)
			port map(clk, enable, acc_mem_in, acc_mem_out);
	end generate;


	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		shift_reg: entity work.shift_reg
			generic map(C*(D + GAMMA_STAR), Z_MAX/C)
			port map(clk, enable, acc_mem_in, acc_mem_out);
	end generate;

	

end Behavioral;