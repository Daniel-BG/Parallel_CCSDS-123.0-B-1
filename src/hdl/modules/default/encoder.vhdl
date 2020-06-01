library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_functions.all;
use work.ccsds_types.all;



entity encoder is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_MAX: integer := 200;
		Z_WIDTH: integer := 8;
		GAMMA_ZERO: integer := 3;
		GAMMA_STAR: integer := 5;
		T_WIDTH: integer := 8;
		D: integer := 16;
		D_PLUS_ONE_LOG: integer := 4;
		K_Z: integer := 4;
		U_MAX: integer := 20;
		U_MAX_LOG: integer := 5;
		ENCODING: encoding_order := BAND_SEQUENTIAL
	);
	port (
		t: in unsigned(T_WIDTH - 1 downto 0);
		clk, enable: in std_logic;
		t_zero, x_high: in boolean;
		mpr: in unsigned(D - 1 downto 0);
		z: in unsigned(Z_WIDTH - 1 downto 0);
		--one extra bit for a potential 1 when u < UMAX
		codeword: out unsigned(D downto 0);
		preceding_zeros: out unsigned(U_MAX_LOG - 1 downto 0);
		word_size: out unsigned(D_PLUS_ONE_LOG - 1 downto 0)
	);
end encoder;

architecture Behavioral of encoder is
	--type accumulator_t is array(0 to Z_MAX - 1) of unsigned(D + GAMMA_STAR - 1 downto 0);
	--signal accumulator_storage: accumulator_t := (others => (others => '0'));
	--signal acc_init: unsigned(D + GAMMA_STAR - 1 downto 0) := (others => '0');
	signal prev_acc, accumulator: unsigned(D + GAMMA_STAR - 1 downto 0) := (others => '0');
	
	signal counter: unsigned(GAMMA_STAR - 1 downto 0) := (others => '0');
	signal counter_threshold: unsigned(GAMMA_STAR - 1 downto 0) := (others => '0');
	signal counter_overflow: unsigned(GAMMA_STAR - 2 downto 0) := (others => '0');
	
	--guardamos la parte derecha de (44) 
	signal k_prev: unsigned(D + GAMMA_STAR downto 0) := (others => '0');
	signal k: unsigned(bits(D - 2) - 1 downto 0) := (others => '0');
	signal u: unsigned(D - 1 downto 0) := (others => '0');
	

	--signal index: integer range 0 to Z_MAX := 0;

begin

	--combinational current counter calculation
	-------------------------------------------
	--time it takes for the counter to start looping from starting value
	--if t <= 2**GAMMA_STAR - 2**GAMMA_ZERO
	--	counter(t) = (2**GAMMA_ZERO + t) - 1
	--else
	--	counter(t) = 2**GAMMA_ZERO + (t - (2**GAMMA_STAR - 2**GAMMA_ZERO + 1) mod 2**(GAMMA_STAR - 1)
	counter_threshold <= 
		to_unsigned(2**GAMMA_STAR - 2**GAMMA_ZERO, GAMMA_STAR);
	counter_overflow <= 
		resize(t - to_unsigned(2**GAMMA_STAR - 2**GAMMA_ZERO + 1, GAMMA_STAR), GAMMA_STAR - 1);
	counter <= 
		to_unsigned(2**GAMMA_ZERO - 1, GAMMA_STAR) + resize(t, GAMMA_STAR) 
			when t <= counter_threshold else 
		to_unsigned(2**(GAMMA_STAR-1), GAMMA_STAR) + counter_overflow;
	
	
	--accumulator calculation
	-------------------------
	
--	index <= to_integer(z);
--	prev_acc <= accumulator_storage(index);
--	
	--save on signal in to allow multi_initialization
	--acc_init <= to_unsigned((3*2**(K_Z + 6) - 49)*2**GAMMA_ZERO/2**7, D + GAMMA_STAR);
	accumulator <= 
		prev_acc --acc_init
			when t = 0 else
		shift_right(prev_acc + resize(mpr, prev_acc'length) + to_unsigned(1, prev_acc'length), 1)
			when counter = to_unsigned(2**GAMMA_STAR - 1, GAMMA_STAR) else
		prev_acc + resize(mpr, prev_acc'length);
--		
--	--update accumulator values
--	---------------------------
--	update_acc: process(accumulator, clk, index, enable)
--	begin
--		if rising_edge(clk) and enable = '1' then
--			accumulator_storage(index) <= accumulator;
--		end if;
--	end process;

	acc_storage: entity work.acc_storage
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, GAMMA_STAR, D, ENCODING)
		port map(z, clk, enable, t_zero, x_high, accumulator, prev_acc);

		

	--k and u calculation
	-------------------
	k_prev <= 
		resize(shift_right(to_unsigned(49, 6) * resize(counter, counter'length + 6), 7), k_prev'length) + ("0" & prev_acc);
		
	calc_k: process(counter, k_prev)
	begin
		--overflow taken as default
		k <= to_unsigned(D - 2, k'length);
		--underflow case
		if counter > k_prev then
			k <= (others => '0');
		else
			--every other case: check until greater
			for i in 1 to D - 2 loop
				if shift_left(resize(counter, D + GAMMA_STAR + 1), i) > k_prev then
					k <= to_unsigned(i - 1, k'length);
					exit;
				end if;
			end loop;
		end if;
	end process;

	u <= shift_right(mpr, to_integer(k));
	
	
	--final codeword calculation
	----------------------------
	calc_output: process(mpr, k, u, t)
	begin
		if t = to_unsigned(0, t'length) then
			codeword <= resize(mpr, codeword'length);
			preceding_zeros <= (others => '0');
			word_size <= to_unsigned(D, word_size'length);
		elsif u < to_unsigned(U_MAX, u'length) then
			codeword <= shift_right("1" & shift_left(mpr, D - to_integer(k)), D - to_integer(k));
			preceding_zeros <= resize(u, U_MAX_LOG);
			word_size <= k + to_unsigned(1, word_size'length);
		else
			codeword <= resize(mpr, codeword'length);
			preceding_zeros <= to_unsigned(U_MAX, U_MAX_LOG);
			word_size <= to_unsigned(D, word_size'length);
		end if;
	end process;
	
	


end Behavioral;

