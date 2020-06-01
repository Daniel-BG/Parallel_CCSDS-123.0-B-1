library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use work.ccsds_types.all;

--this module performs the scalar product between the difference and the 
--weight vector. Please note that it doesn't take into account the fact that 
--when the current band z < P_STAR, the lower values of the vector are not taken into 
--account because they are non-existent. This, being hardware, WILL multiply whatever
--is in there. To solve it, either the difference vector or the weight vector must
--have zeros on unused positions. 
entity central_local_difference_predictor is
	generic(
		P_STAR: integer := 6;
		PRED_DIFF_LEN: integer := 34;
		D: integer := 16;
		OMEGA: integer := 10;
		SPSV_MODE: spsv_calculation := SPSV_PRECISE
	);
	port(
		diff_vector_in: in std_logic_vector(P_STAR * (D + 3) - 1 downto 0);
		weight_vector_in: in std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
		predicted_central_local_diff: out signed(PRED_DIFF_LEN - 1 downto 0)
	);
end central_local_difference_predictor;

architecture Behavioral of central_local_difference_predictor is

	type diff_vector_t is array(0 to P_STAR - 1) of signed(D + 2 downto 0);
	type weight_vector_t is array(0 to P_STAR - 1) of signed(OMEGA + 2 downto 0);

	signal diff_vector: diff_vector_t;
	signal weight_vector: weight_vector_t;

begin
	--translate std_logic_vector
	----------------------------
	assign_arrays:
		for i in 0 to P_STAR - 1 generate
			diff_vector(i) <= signed(diff_vector_in((D + 3)*(i + 1) - 1 downto (D + 3)*i));
			weight_vector(i) <= signed(weight_vector_in((OMEGA + 3)*(i + 1) - 1 downto (OMEGA + 3)*i));
		end generate;

	--dot product of U and W
	------------------------
	precise_calc: if SPSV_MODE = SPSV_PRECISE generate
		multiply_and_sum_precise: process(diff_vector, weight_vector)
			variable temp_sum: signed(PRED_DIFF_LEN - 1 downto 0);
		begin
			temp_sum := (others => '0');
			for i in 0 to P_STAR - 1 loop
				temp_sum := temp_sum + diff_vector(i) * weight_vector(i);
			end loop;
			
			predicted_central_local_diff <= temp_sum;
		end process;
	end generate;
	
	fast_calc: if SPSV_MODE = SPSV_FAST generate
		multiply_and_sum_fast: process(diff_vector, weight_vector)
			variable temp_sum: signed(PRED_DIFF_LEN - 1 downto 0);
		begin
			temp_sum := (others => '0');
			for i in 0 to P_STAR - 1 loop
				temp_sum := temp_sum + resize(shift_right(diff_vector(i), (OMEGA + 1) / 2) * shift_right(weight_vector(i), (OMEGA + 2) / 2), temp_sum'length);
			end loop;
			
			predicted_central_local_diff <= temp_sum;
	end process;
	end generate;



end Behavioral;