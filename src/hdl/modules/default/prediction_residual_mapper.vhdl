library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.ccsds_types.all;

entity prediction_residual_mapper is
	generic(
		R: integer := 40;
		PRED_DIFF_LEN: integer := 34;
		OMEGA: integer := 10;
		D: integer := 16;
		P: integer := 3;
		SPSV_MODE: spsv_calculation := SPSV_PRECISE
	);
	port(
		sample_current, sample_previous: in unsigned(D - 1 downto 0);
		predicted_local_difference: in signed(PRED_DIFF_LEN - 1 downto 0);
		t_zero: in boolean;
		local_sum: in unsigned(D + 1 downto 0);
		z_zero: in boolean;
		mapped_prediction_residual: out unsigned(D - 1 downto 0);
		scaled_err: out signed(D + 1 downto 0)
	);
end prediction_residual_mapper;

architecture Behavioral of prediction_residual_mapper is
	--asummes samples are always signed, if not, they can be mapped to 
	--unsigned values by adding the minimum sample value as referenced
	--by ccsds 120.2-g-1
	constant s_mid: integer := 2**(D - 1);
	constant s_max: integer := 2**D - 1;

	signal scaled_pred_temp, scaled_pred_unbound: 
		signed(R - 1 downto 0);
		

	--one extra bit needed
	signal scaled_pred, scaled_pred_bound: unsigned(D downto 0); 
	signal delta: signed(D downto 0);
	signal theta, sample_pred: unsigned(D - 1 downto 0);
	
	signal omega_zeros: std_logic_vector(OMEGA - 1 downto 0);
	

begin
	omega_zeros <= (others => '0');
	
	
	--scaled predicted sample value
	-------------------------------
	precise_calc: if SPSV_MODE = SPSV_PRECISE generate
		scaled_pred_temp <=
			resize(predicted_local_difference, R) + 
			resize(signed(std_logic_vector(signed(local_sum) + to_signed(- s_mid*4, D + 2)) & omega_zeros), R);
	
		scaled_pred_unbound <= 
			resize(signed(scaled_pred_temp(R - 1 downto OMEGA + 1)) + to_signed(s_mid*2 + 1, D + 2), R);
	end generate;
	
	fast_calc: if SPSV_MODE = SPSV_FAST generate
		scaled_pred_temp <=
			resize(predicted_local_difference, R) + 
			resize(shift_right(signed(local_sum) + to_signed(-s_mid*4, D + 2), 1), R);
		
		scaled_pred_unbound <= 
			resize(scaled_pred_temp + s_mid*2 + 1, R);
	end generate;
	
	
	scaled_pred_bound <= 
		(others => '0')
			when scaled_pred_unbound(R - 1) = '1'
		else to_unsigned(s_max*2 + 1, D + 1)
			when scaled_pred_unbound > to_signed(s_max*2 + 1, R - 1) 
		else unsigned(std_logic_vector(scaled_pred_unbound(D downto 0)));
		
	--faster and smaller than a process
	scaled_pred <= 
		to_unsigned(s_mid*2, D + 1)
			when t_zero and (P = 0 or z_zero) 
		else sample_previous & "0"
			when t_zero
		else resize(scaled_pred_bound, D + 1);
		
		
	--predicted sample value
	------------------------
	sample_pred <= scaled_pred(D downto 1);
	
	
	--scaled prediction error
	-------------------------
	scaled_err <= signed("0" & sample_current & "0") - signed("0" & scaled_pred);
	
	
	--mapped prediction residual
	----------------------------
	delta <= signed("0" & sample_current) - signed("0" & sample_pred);
	
	--theta = min(sample_pred - s_min, s_max - sample_pred)
	theta <=
		sample_pred 
			when sample_pred < to_unsigned(s_max, D) - sample_pred else
		to_unsigned(s_max, D) - sample_pred;

		
	compute_mpr: process(delta, theta, scaled_pred)
		variable abs_delta: unsigned(D downto 0);
	begin
		abs_delta := unsigned(abs(delta));
		
		if abs_delta > theta then
			mapped_prediction_residual <= resize(abs_delta + theta, D);
		--check sign of delta with MSB instead of comparing with zero
		elsif (scaled_pred(0) = '0' and delta(D) = '0' and signed(theta) >= delta) or
				(scaled_pred(0) = '1' and delta(D) = '1' and signed(theta) >= (-delta)) or
				delta = to_signed(0, D + 1)
				then
			mapped_prediction_residual <= abs_delta(D - 2 downto 0) & "0";
		else
			mapped_prediction_residual <= (abs_delta(D - 2 downto 0) & "0") - to_unsigned(1, D);
		end if;
	end process;
	
		
end Behavioral;