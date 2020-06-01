library IEEE;
use work.ccsds_types.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity coordinate_generator is
	generic (
		X_WIDTH: integer := 4;
		X_MAX: integer := 16;
		Y_WIDTH: integer := 4;
		Y_MAX: integer := 16;
		Z_WIDTH: integer := 4;
		Z_MAX: integer := 10;
		T_WIDTH: integer := 8;
		--encoding order used to change how counters are incremented
		ENCODING: encoding_order := BAND_SEQUENTIAL
	);
	port (
		clk, rst, enable: in std_logic;
		--output values. they come out delayed with respect to the internal counter to allow
		--for outputting at the same time the current and next coordinate values,
		--in hopes that this allows for segmentation in further modules thus reducing clock
		--cycle
		x_out: out unsigned(X_WIDTH - 1 downto 0);
		y_out: out unsigned(Y_WIDTH - 1 downto 0);
		z_out: out unsigned(Z_WIDTH - 1 downto 0);
		t_out: out unsigned(T_WIDTH - 1 downto 0);
		done: out boolean
	);
end coordinate_generator;

architecture Behavioral of coordinate_generator is
	signal x: unsigned(X_WIDTH - 1 downto 0) := (others => '0');
	signal y: unsigned(Y_WIDTH - 1 downto 0) := (others => '0');
	signal z: unsigned(Z_WIDTH - 1 downto 0) := (others => '0');
	signal t: unsigned(T_WIDTH - 1 downto 0) := (others => '0');
begin

	x_out <= x;
	y_out <= y;
	z_out <= z;
	t_out <= t;

	
	--order x -> y -> z
	counter_bsq: if ENCODING = BAND_SEQUENTIAL generate
		coordinate_counter: entity work.coordinate_generator_counter
			generic map(X_WIDTH, X_MAX, Y_WIDTH, Y_MAX, Z_WIDTH, Z_MAX)
			port map(clk, rst, enable, x, y, z, done);
	end generate;
	
	--order x -> z -> y
	counter_bil: if ENCODING = BAND_INTERLEAVED_LINE generate
		coordinate_counter: entity work.coordinate_generator_counter
			generic map(X_WIDTH, X_MAX, Z_WIDTH, Z_MAX, Y_WIDTH, Y_MAX)
			port map(clk, rst, enable, x, z, y, done);
	end generate;
	
	--order z -> x -> y
	counter_bip: if ENCODING = BAND_INTERLEAVED_PIXEL generate
		coordinate_counter: entity work.coordinate_generator_counter
			generic map(Z_WIDTH, Z_MAX, X_WIDTH, X_MAX, Y_WIDTH, Y_MAX)
			port map(clk, rst, enable, z, x, y, done);
	end generate;
	
	--t is just a function of current y and x. if X_MAX is power of two, t calculation becomes trivial
	t <= resize(resize(y, t'length) * to_unsigned(X_MAX, t'length), t'length) + resize(x, t'length);


	



end Behavioral;
	