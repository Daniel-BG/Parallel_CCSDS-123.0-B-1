library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity weight_storage is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_WIDTH: integer := 4;
		Z_MAX: integer := 10;
		P_STAR: integer := 6;
		OMEGA: integer := 10;
		ENCODING: encoding_order := BAND_INTERLEAVED_LINE--;
		--WEIGHT_INIT: weight_init_vector_t := WEIGHT_INIT
	);
	port (
		curr_z: in unsigned(Z_WIDTH - 1 downto 0);
		rst, clk, enable: in std_logic;
		t_zero, x_high: in boolean;
		w_in: in std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
		w_out: out std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0)
		
	);
end weight_storage;

architecture Behavioral of weight_storage is
begin

	
	weight_seq: if ENCODING = BAND_SEQUENTIAL generate
		weight_strg_seq: entity work.weight_storage_sequential
			generic map(Z_WIDTH, P_STAR, OMEGA)--, WEIGHT_INIT)
			port map(t_zero, clk, enable, curr_z, w_out, w_in);
	end generate;
	
	weight_bil: if ENCODING = BAND_INTERLEAVED_LINE generate
		weight_strg_bil: entity work.weight_storage_interleaved_line
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_MAX, Z_WIDTH, P_STAR, OMEGA)--, WEIGHT_INIT)
			port map(x_high, rst, clk, enable, t_zero, curr_z, w_out, w_in);
	end generate;
	
	weight_bip: if ENCODING = BAND_INTERLEAVED_PIXEL generate
		weight_strg_bip: entity work.weight_storage_interleaved_pixel
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, P_STAR, OMEGA)--, WEIGHT_INIT)
			port map(rst, clk, enable, t_zero, curr_z, w_out, w_in);
	end generate;
	

end Behavioral;