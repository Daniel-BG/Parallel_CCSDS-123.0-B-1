library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity weight_storage_interleaved_pixel is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_WIDTH: integer := 7;
		Z_MAX: integer := 100;
		P_STAR: integer := 6;
		OMEGA: integer := 10--;
		--WEIGHT_INIT: weight_init_vector_t := WEIGHT_INIT
	);
	port (
		rst, clk, enable: in std_logic;
		t_zero: in boolean;
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		w_out: out std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
		w_in: in std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0)
	);
end weight_storage_interleaved_pixel;

architecture Behavioral of weight_storage_interleaved_pixel is

	type w_vectors_storage is array(0 to Z_MAX - 1) of std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
	
	signal w_vectors: w_vectors_storage;
	
	signal w_mem_out, w_mem_in, w_reset: std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);

begin
--	w_out <= w_vectors(0);
--
--	update_values: process(clk, rst, w_in)
--	begin
--		if rising_edge(clk) then
--			if rst = '1' then
--				for z in 0 to Z_MAX - 1 loop
--					for i in 0 to P_STAR - 1 loop
--						w_vectors(z)((i + 1)*(OMEGA + 3) - 1 downto i*(OMEGA + 3))
--							<= std_logic_vector(to_signed(WEIGHT_INIT(z, i), OMEGA + 3));
--					end loop;
--				end loop;
--			elsif enable = '1' and (not t_zero) then
--				for z in 0 to Z_MAX - 2 loop
--					w_vectors(z) <= w_vectors(z + 1);
--				end loop;
--				w_vectors(Z_MAX - 1) <= w_in;
--			end if;
--		end if;
--	end process;
	
	
	reset_values: for i in 0 to P_STAR - 1 generate
		w_reset((i + 1)*(OMEGA + 3) - 1 downto i*(OMEGA + 3))
				<= std_logic_vector(to_signed(WEIGHT_INIT(to_integer(z_curr), i), OMEGA + 3));
	end generate;
	
	--no es en x_high sino al siguiente
	w_out <= w_reset when t_zero else w_mem_out;
	
	w_mem_in <= w_reset when t_zero else w_in;

	gen_mem: if not LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.fifo_buffer
			generic map(P_STAR * (OMEGA + 3), Z_MAX)
			port map(clk, enable, 
				w_mem_in, w_mem_out);
	end generate;
	
	gen_shift_reg: if LINEAR_STORAGE_AS_SHIFT_REG generate
		fifo_buff: entity work.shift_reg
			generic map(P_STAR * (OMEGA + 3), Z_MAX)
			port map(clk, enable, 
				w_mem_in, w_mem_out);
	end generate;

end Behavioral;