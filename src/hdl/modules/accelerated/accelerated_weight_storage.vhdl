----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:50:04 11/25/2016 
-- Design Name: 
-- Module Name:    accelerated_weight_storage - Behavioral 
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


entity accelerated_weight_storage is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := true;
		Z_WIDTH: integer := 7;
		Z_MAX: integer := 3;
		P_STAR: integer := 6;
		OMEGA: integer := 10;
		C: integer := 4--;
		--WEIGHT_INIT: weight_init_vector_t := WEIGHT_INIT
	);
	port (
		clk, enable: in std_logic;
		t_zero: in boolean;
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		w_in: in std_logic_vector(C * P_STAR * (OMEGA + 3) - 1 downto 0);
		w_out: out std_logic_vector(C * P_STAR * (OMEGA + 3) - 1 downto 0)
	);
end accelerated_weight_storage;

architecture Behavioral of accelerated_weight_storage is
	
	signal w_mem_out, w_mem_in, w_reset: std_logic_vector(C * P_STAR * (OMEGA + 3) - 1 downto 0);
	constant MEM_SIZE: integer := Z_MAX / C;

begin
	
	reset_values: for i in 0 to P_STAR - 1 generate
		multi_band: for j in 0 to C - 1 generate
			w_reset(j*(P_STAR * (OMEGA + 3)) + (i + 1)*(OMEGA + 3) - 1 downto j*(P_STAR * (OMEGA + 3)) + i*(OMEGA + 3))
				<= std_logic_vector(to_signed(WEIGHT_INIT(to_integer(z_curr + j), i), OMEGA + 3));
		end generate;
	end generate;
	
	--no es en x_high sino al siguiente
	w_out <= w_reset when t_zero else w_mem_out;
	
	w_mem_in <= w_reset when t_zero else w_in;

	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.fifo_buffer
			generic map(C * P_STAR * (OMEGA + 3), MEM_SIZE)
			port map(clk, enable, 
				w_mem_in, w_mem_out);
	end generate;
	
	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.shift_reg
			generic map(C * P_STAR * (OMEGA + 3), MEM_SIZE)
			port map(clk, enable, 
				w_mem_in, w_mem_out);
	end generate;

end Behavioral;