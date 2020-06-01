library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_constants.all;
use work.ccsds_types.all;


entity acc_storage is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_WIDTH: integer := 4;
		Z_MAX: integer := 10;
		GAMMA_STAR: integer := 6;
		D: integer := 16;
		ENCODING: encoding_order := BAND_SEQUENTIAL
	);
	port (
		curr_z: in unsigned(Z_WIDTH - 1 downto 0);
		clk, enable: in std_logic;
		t_zero, x_high: in boolean;
		acc_port_in: in unsigned(GAMMA_STAR + D - 1 downto 0);
		acc_port_out: out unsigned(GAMMA_STAR + D - 1 downto 0)
	);
end acc_storage;

architecture Behavioral of acc_storage is
	signal acc_in: std_logic_vector(GAMMA_STAR + D - 1 downto 0);
	signal acc_out: std_logic_vector(GAMMA_STAR + D - 1 downto 0);
begin

	acc_in <= std_logic_vector(acc_port_in);
	acc_port_out <= unsigned(acc_out);
	
	acc_seq: if ENCODING = BAND_SEQUENTIAL generate
		acc_strg_seq: entity work.acc_storage_sequential
			generic map(Z_WIDTH, GAMMA_STAR, D)
			port map(t_zero, clk, enable, curr_z, acc_out, acc_in);
	end generate;
	
	acc_bil: if ENCODING = BAND_INTERLEAVED_LINE generate
		acc_strg_bil: entity work.acc_storage_interleaved_line
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_MAX, Z_WIDTH, GAMMA_STAR, D)
			port map(x_high, clk, enable, t_zero, curr_z, acc_out, acc_in);
	end generate;
	
	acc_bip: if ENCODING = BAND_INTERLEAVED_PIXEL generate
		acc_strg_bip: entity work.acc_storage_interleaved_pixel
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, GAMMA_STAR, D)
			port map(clk, enable, t_zero, curr_z, acc_out, acc_in);
	end generate;
	

end Behavioral;