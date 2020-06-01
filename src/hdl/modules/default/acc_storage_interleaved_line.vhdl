library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity acc_storage_interleaved_line is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_MAX: integer := 10;
		Z_WIDTH: integer := 4;
		GAMMA_STAR: integer := GAMMA_STAR;
		D: integer := D
	);
	port (
		x_high: in boolean;
		clk, enable: in std_logic;
		t_zero: in boolean;
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		acc_out: out std_logic_vector(D + GAMMA_STAR - 1 downto 0);
		acc_in: in std_logic_vector(D + GAMMA_STAR - 1 downto 0)
	);
end acc_storage_interleaved_line;

architecture Behavioral of acc_storage_interleaved_line is

	signal acc_mem_out, acc_reset, acc_prev: std_logic_vector(D + GAMMA_STAR - 1 downto 0);

	signal enable_mem: std_logic;
	
	signal x_low: boolean;

begin
	
	acc_reset <= std_logic_vector(to_unsigned(ACCUMULATOR_INIT(to_integer(z_curr)), D + GAMMA_STAR));
	
	--no es en x_high sino al siguiente
	acc_out <= 
		acc_reset when t_zero else 
		acc_mem_out when x_low else
		acc_prev;
	
	
	update_weights: process(clk, acc_in, x_high)
	begin
		--if rst = '1' then
		--	x_low <= true;
		--els
		if rising_edge(clk) then
			if enable = '1' then
				x_low <= x_high;
				if t_zero then
					acc_prev <= acc_reset;
				else
					acc_prev <= acc_in;
				end if;
			end if;
		end if;
	end process;
	
	enable_mem <= '1' when enable = '1' and x_high else '0';
	
	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.fifo_buffer
			generic map(D + GAMMA_STAR, Z_MAX)
			port map(clk, enable_mem, 
				acc_in, acc_mem_out);
	end generate;


	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		shift_reg: entity work.shift_reg
			generic map(D + GAMMA_STAR, Z_MAX)
			port map(clk, enable_mem, 
				acc_in, acc_mem_out);
	end generate;

end Behavioral;