----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:07:45 11/28/2016 
-- Design Name: 
-- Module Name:    accelerated_encoder - Behavioral 
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
use work.ccsds_functions.all;
use work.ccsds_types.all;



entity accelerated_encoder is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		Z_MAX: integer := 200;
		Z_WIDTH: integer := 8;
		GAMMA_ZERO: integer := 3;
		GAMMA_STAR: integer := 6;
		T_WIDTH: integer := 8;
		D: integer := 16;
		D_PLUS_ONE_LOG: integer := 4;
		K_Z: integer := 4;
		U_MAX: integer := 20;
		U_MAX_LOG: integer := 5;
		C: integer := 4
	);
--	generic (
--		LINEAR_STORAGE_AS_SHIFT_REG: boolean;
--		Z_MAX: integer;
--		Z_WIDTH: integer;
--		GAMMA_ZERO: integer;
--		GAMMA_STAR: integer;
--		T_WIDTH: integer;
--		D: integer;
--		D_PLUS_ONE_LOG: integer;
--		K_Z: integer;
--		U_MAX: integer;
--		U_MAX_LOG: integer;
--		C: integer
--	);
	port (
		t: in unsigned(T_WIDTH - 1 downto 0);
		clk, enable: in std_logic;
		t_zero: in boolean;
		mpr: in std_logic_vector(C*D - 1 downto 0);
		z_base: in unsigned(Z_WIDTH - 1 downto 0);
		--one extra bit for a potential 1 when u < UMAX
		codeword: out std_logic_vector(C*(D + 1) - 1 downto 0);
		preceding_zeros: out std_logic_vector(C*U_MAX_LOG - 1 downto 0);
		word_size: out std_logic_vector(C*D_PLUS_ONE_LOG - 1 downto 0)
	);
end accelerated_encoder;

architecture Behavioral of accelerated_encoder is
	type vv_acc is array(0 to C - 1) of unsigned(D + GAMMA_STAR - 1 downto 0);
	type vv_k_prev is array(0 to C - 1) of unsigned(D + GAMMA_STAR downto 0);
	type vv_k is array(0 to C - 1) of unsigned(bits(D - 2) - 1 downto 0);
	type vv_u is array(0 to C - 1) of unsigned(D - 1 downto 0);

	signal prev_acc, accumulator: vv_acc;
	signal prev_acc_stdlv, accumulator_stdlv: std_logic_vector(C*(D + GAMMA_STAR) - 1 downto 0);
	
	signal counter: unsigned(GAMMA_STAR - 1 downto 0);
	signal counter_threshold: unsigned(GAMMA_STAR - 1 downto 0);
	signal counter_overflow: unsigned(GAMMA_STAR - 2 downto 0);
	
	--guardamos la parte derecha de (44) 
	signal k_prev: vv_k_prev;
	signal k: vv_k;
	signal u: vv_u;
	

begin


	--update accumulator values
	---------------------------
	acc_storage: entity work.accelerated_acc_storage
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, GAMMA_STAR, D, C)
		port map(clk, enable, t_zero, z_base, accumulator_stdlv, prev_acc_stdlv);
		
	--combinational current counter calculation
	-------------------------------------------
	--time it takes for the counter to start looping from starting value
	counter_threshold <= 
		to_unsigned(2**GAMMA_STAR - 2**GAMMA_ZERO, GAMMA_STAR);
	counter_overflow <= 
		resize(t - to_unsigned(2**GAMMA_STAR - 2**GAMMA_ZERO + 1, GAMMA_STAR), GAMMA_STAR - 1);
	counter <= 
		to_unsigned(2**GAMMA_ZERO - 1, GAMMA_STAR) + resize(t, GAMMA_STAR) 
			when t <= counter_threshold else 
		to_unsigned(2**(GAMMA_STAR-1), GAMMA_STAR) + counter_overflow;
	
	gen_acc_encoder: for i in 0 to C - 1 generate
		--vector translations
		accumulator_stdlv((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)) <= std_logic_vector(accumulator(i));
		prev_acc(i) <= unsigned(prev_acc_stdlv((i + 1)*(D + GAMMA_STAR) - 1 downto i*(D + GAMMA_STAR)));
	
		--accumulator calculation
		-------------------------
		accumulator(i) <= 
			prev_acc(i) --acc_init
				when t = 0 else
			shift_right(prev_acc(i) + resize(unsigned(mpr((i + 1)*D - 1 downto i*D)), prev_acc(i)'length) 
											+ to_unsigned(1, prev_acc(i)'length), 1)
				when counter = to_unsigned(2**GAMMA_STAR - 1, GAMMA_STAR) else
			prev_acc(i) + resize(unsigned(mpr((i + 1)*D - 1 downto i*D)), prev_acc(i)'length);
			
			
		--k and u calculation
		-------------------
		k_prev(i) <= 
			resize(shift_right(to_unsigned(49, 6) * resize(counter, counter'length + 6), 7), k_prev(i)'length) + ("0" & prev_acc(i));
			
		calc_k: process(counter, k_prev(i))
		begin
			--overflow taken as default
			k(i) <= to_unsigned(D - 2, k(i)'length);
			--underflow case
			if counter > k_prev(i) then
				k(i) <= (others => '0');
			else
				--every other case: check until greater
				for j in 1 to D - 2 loop
					if shift_left(resize(counter, D + GAMMA_STAR + 1), j) > k_prev(i) then
						k(i) <= to_unsigned(j - 1, k(i)'length);
						exit;
					end if;
				end loop;
			end if;
		end process;

		u(i) <= shift_right(unsigned(mpr((i + 1)*D - 1 downto i*D)), to_integer(k(i)));
		
		
		--final codeword calculation
		----------------------------
		calc_output: process(mpr((i + 1)*D - 1 downto i*D), k(i), u(i), t)
		begin
			if t = to_unsigned(0, t'length) then
				codeword((i + 1)*(D + 1) - 1 downto i*(D + 1))
					<= std_logic_vector(resize(unsigned(mpr((i + 1)*D - 1 downto i*D)), D + 1));
				preceding_zeros((i + 1)*U_MAX_LOG - 1 downto i*U_MAX_LOG) 
					<= (others => '0');
				word_size((i + 1)*D_PLUS_ONE_LOG - 1 downto i*D_PLUS_ONE_LOG)
					<= std_logic_vector(to_unsigned(D, D_PLUS_ONE_LOG));
			elsif u(i) < to_unsigned(U_MAX, u(i)'length) then
				codeword((i + 1)*(D + 1) - 1 downto i*(D + 1)) 
					<= std_logic_vector(shift_right("1" & shift_left(unsigned(mpr((i + 1)*D - 1 downto i*D)), D - to_integer(k(i))), D - to_integer(k(i))));
				preceding_zeros((i + 1)*U_MAX_LOG - 1 downto i*U_MAX_LOG) 
					<= std_logic_vector(resize(u(i), U_MAX_LOG));
				word_size((i + 1)*D_PLUS_ONE_LOG - 1 downto i*D_PLUS_ONE_LOG)
					<= std_logic_vector(k(i) + to_unsigned(1, D_PLUS_ONE_LOG));
			else
				codeword((i + 1)*(D + 1) - 1 downto i*(D + 1)) 
					<= std_logic_vector(resize(unsigned(mpr((i + 1)*D - 1 downto i*D)), D + 1));
				preceding_zeros((i + 1)*U_MAX_LOG - 1 downto i*U_MAX_LOG) 
					<= std_logic_vector(to_unsigned(U_MAX, U_MAX_LOG));
				word_size((i + 1)*D_PLUS_ONE_LOG - 1 downto i*D_PLUS_ONE_LOG)
					<= std_logic_vector(to_unsigned(D, D_PLUS_ONE_LOG));
			end if;
		end process;
			
	end generate;
	


end Behavioral;

