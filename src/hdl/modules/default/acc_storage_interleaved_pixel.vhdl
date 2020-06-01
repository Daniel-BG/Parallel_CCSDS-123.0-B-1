library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity acc_storage_interleaved_pixel is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_WIDTH: integer := 7;
		Z_MAX: integer := 100;
		GAMMA_STAR: integer := GAMMA_STAR;
		D: integer := D
	);
	port (
		clk, enable: in std_logic;
		t_zero: in boolean;
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		acc_out: out std_logic_vector(D + GAMMA_STAR - 1 downto 0);
		acc_in: in std_logic_vector(D + GAMMA_STAR - 1 downto 0)
	);
end acc_storage_interleaved_pixel;

architecture Behavioral of acc_storage_interleaved_pixel is

	signal acc_mem_out, acc_mem_in, acc_reset: std_logic_vector(D + GAMMA_STAR - 1 downto 0);

begin
	
	acc_reset <= std_logic_vector(to_unsigned(ACCUMULATOR_INIT(to_integer(z_curr)), D + GAMMA_STAR));
	
	
	--no es en x_high sino al siguiente
	acc_out <= acc_reset when t_zero else acc_mem_out;
	
	acc_mem_in <= acc_reset when t_zero else acc_in;
				
	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.fifo_buffer
			generic map(D + GAMMA_STAR, Z_MAX)
			port map(clk, enable, 
				acc_mem_in, acc_mem_out);
	end generate;


	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		shift_reg: entity work.shift_reg
			generic map(D + GAMMA_STAR, Z_MAX)
			port map(clk, enable, 
				acc_mem_in, acc_mem_out);
	end generate;

	

end Behavioral;