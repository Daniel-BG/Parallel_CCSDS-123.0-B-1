--
--	Constants Package
--
--	Purpose: Used to parametrize tests and allow for easy change of testing
-- 			parameters
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.ccsds_types.all;
use work.ccsds_functions.all;

package ccsds_constants is
	--OPTIMIZATIONS
	---------------
	--this is faster (if set to SPSV_FAST) but the output is not standard-compliant. 
	--use only only for testing purposes! for normal use, type SPSV_PRECISE
	constant SPSV_MODE: spsv_calculation := SPSV_PRECISE;
	--PIPELINING IMPROVEMENTS
	--improves speed by pipelining the predictor and the encoder. note that output values
	--will be delayed by one cycle until the pipeline is full. Better pipelining is not
	--possible since the critical path loops onto itself.
	constant PIPELINE_ENCODER: boolean := false;
	constant PIPELINE_PREDICTOR: boolean := false;
	--STORAGE IMPROVEMENTS: every storage can be implemented as a fifo queue. By default
	--it is implemented in RAM modules. You can force its implementation as distributed
	--RAM in your synthesis tool's options. HOWEVER a shift register is even faster and 
	--has a smaller footprint. You can force all memory modules to be implemented as such
	--from here. 
	--implement linear storage (size approx of the order of max(X_MAX, Z_MAX)
	--as shift registers instead of memory modules.
	constant LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
	--implement quadric storage (size up to max(Z_MAX*X_MAX, X_MAX*Y_MAX))
	--as shift registers insteead of memory modules.
	constant QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;

	--user defined constants
	----------------
	constant C: integer := 7; --concurrency: samples calculated at the same time
	constant D: integer := 16;
	constant X_MAX: integer := 614; --614; --number of pixels per frame
	constant Y_MAX: integer := 512; --number of frames
	constant Z_MAX: integer := 224; --number of samples per pixel
	--64 128 192 256 320 384 448 512
	constant SUM_MODE: local_sum_mode := NEIGHBOR_ORIENTED;
	constant PRED_MODE: prediction_mode := FULL_PREDICTION; 
	constant ENCODING: encoding_order := BAND_INTERLEAVED_PIXEL;
	
	
	constant V_MIN: integer := -1;
	constant V_MAX: integer := 3;
	constant T_INC: integer := 6;
	
	constant OMEGA: integer := 6;
	constant P : integer := 3;
	
	constant GAMMA_ZERO: integer := 1;
	constant GAMMA_STAR: integer := 6;
	constant K_Z: integer := 3; --3e;
	constant U_MAX: integer := 18;--18; -- 16;
	
	constant Q: integer := 3; -- 3 <= W <= OMEGA + 3
	constant WEIGHT_MODE: weight_initialization_mode := WEIGHT_DEFAULT;
	constant ACCUMULATOR_MODE: acc_initialization_mode := ACCUMULATOR_DEFAULT;
	
	--algorithm constants
	---------------------
	function calculate_p_star(P: integer; PRED_MODE: prediction_mode) return integer;
	constant P_STAR: integer := calculate_p_star(P, PRED_MODE);

	--typed constants
	-------------------
	type weight_init_vector_t is array(0 to Z_MAX - 1, 0 to P_STAR - 1) of integer;
	
	constant LAMBDA: weight_init_vector_t := (others => (others => 0));
	
	type acc_init_vector_t is array(0 to Z_MAX - 1) of integer;
	
	constant K_VEC: acc_init_vector_t := (others => 0);
	
	
	--function declarations
	-----------------------
	function init_weights(
		bands: integer; weights: integer;
		scale_factor: integer; lambda: weight_init_vector_t;
		pred_mode: prediction_mode;
		mode: weight_initialization_mode) 
			return weight_init_vector_t;
	function init_weights_default(
		bands: integer; weights: integer; pred_mode: prediction_mode) 
			return weight_init_vector_t;
	function init_weights_custom(
		bands: integer; weights: integer; scale_factor: integer;
		lambda: weight_init_vector_t)
			return weight_init_vector_t;
			
	function init_accumulator(bands: integer;
		k_init: acc_init_vector_t;
		k_z: integer;
		mode: acc_initialization_mode) 
			return acc_init_vector_t;
			
	function calculate_pred_diff_len(OMEGA, P, D: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer;
	function calculate_pred_diff_max(OMEGA, P, D: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer;
	function calculate_reg_size(OMEGA, D, P: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer;



	--non primitive constants
	-------------------------
	constant T_MAX: integer := X_MAX*Y_MAX;
	constant X_WIDTH: integer := bits(X_MAX - 1);
	constant Y_WIDTH: integer := bits(Y_MAX - 1);
	constant Z_WIDTH: integer := bits(Z_MAX - 1); 
	constant T_WIDTH: integer := bits(T_MAX - 1);

	constant PRED_DIFF_LEN: integer := calculate_pred_diff_len(OMEGA, P, D, PRED_MODE, SPSV_MODE);
	--constant PRED_DIFF_MAX: integer := calculate_pred_diff_max(OMEGA, P, D, PRED_MODE, SPSV_MODE);
	
	constant RHO_WIDTH: integer := 6; --6 ensures no overflow
	constant	R_WEIGHT: integer := maximum(OMEGA + 3, D + 3 + minimum(1, V_MIN + D - OMEGA)) + 1; --this value ensures no overflow in weight update
	
	--the value of R given by calculate_reg_size ensures no overflow occurs.
	--it can be lowered at the expense of allowing potential overflows,
	--which might lower compression rates, but still allow for the compressed
	--image to be recovered. It also reduces the computation time by lowering
	--the bits needed for some operations that lie on the critical path. 
	constant	R: integer := calculate_reg_size(OMEGA, D, P, PRED_MODE, SPSV_MODE);
	
	--ENCODER
	constant U_MAX_LOG: integer := bits(U_MAX);
	constant D_PLUS_ONE_LOG: integer := bits(D + 1);
	constant CCSDS_DATA_WIDTH: integer := D+1+U_MAX_LOG+D_PLUS_ONE_LOG;
	
	constant	BUF_LEN: integer := 7 + U_MAX + D + 1;
	constant BUF_LEN_LOG: integer := bits(BUF_LEN);
	
	--WEIGHT AND ACCUMULATOR INITIALIZATION VECTORS
			
	constant WEIGHT_INIT: weight_init_vector_t := 
		init_weights(Z_MAX, P_STAR, OMEGA + 3 - Q, LAMBDA, PRED_MODE, WEIGHT_MODE);
		
	constant ACCUMULATOR_INIT: acc_init_vector_t :=
		init_accumulator(Z_MAX, K_VEC, K_Z, ACCUMULATOR_MODE);
		
end ccsds_constants;

package body ccsds_constants is

	function init_weights(bands: integer; weights: integer;
			scale_factor: integer; lambda: weight_init_vector_t;
			pred_mode: prediction_mode;
			mode: weight_initialization_mode) 
			return weight_init_vector_t is
	begin
		if mode = WEIGHT_DEFAULT then
			return init_weights_default(bands, weights, pred_mode);
		else
			return init_weights_custom(bands, weights, scale_factor, lambda);
		end if;
	end function;


	function init_weights_default(bands: integer; weights: integer; pred_mode: prediction_mode) return weight_init_vector_t is
		variable res: weight_init_vector_t;
		variable currweight: integer;
		variable end_i: integer := weights - 1;
	begin
		currweight := 7*2**(OMEGA - 3);
		
		if pred_mode = FULL_PREDICTION then
			end_i := weights - 4;
			for i in weights - 3 to weights - 1 loop
				for j in 0 to bands - 1 loop
					res(j, i) := 0;
				end loop;
			end loop;
		end if;
		
		for i in end_i downto 0 loop
			for j in 0 to bands - 1 loop
				res(j, i) := currweight;
			end loop;
			currweight := floor_div(currweight, 8);
		end loop;
		
		return res;
	end function;
	
	
	function init_weights_custom(
			bands: integer; weights: integer; scale_factor: integer;
			lambda: weight_init_vector_t)
			return weight_init_vector_t is
		variable res: weight_init_vector_t;
	begin
		for i in 0 to weights - 1 loop
			for j in 0 to bands - 1 loop
				if scale_factor = 0 then --extreme case where sc_factor = 0
					res(j, i) := lambda(j, i)*2**scale_factor - 1;
				else
					res(j, i) := lambda(j, i)*2**scale_factor + 2**(scale_factor - 1) - 1;
				end if;
			end loop;
		end loop;
		
		return res;
	end function;
	
	function init_accumulator(bands: integer;
			k_init: acc_init_vector_t;
			k_z: integer;
			mode: acc_initialization_mode) 
			return acc_init_vector_t is
	variable res: acc_init_vector_t;
	variable curr_k: integer;
	begin
		for i in 0 to bands - 1 loop
			if mode = ACCUMULATOR_DEFAULT then
				curr_k := k_z;
			else
				curr_k := k_init(i);
			end if;
			res(i) := (3*2**(curr_k + 6) - 49)*2**GAMMA_ZERO/2**7;
		end loop;
		
		return res;
	end function;
	
	function calculate_p_star(P: integer; PRED_MODE: prediction_mode) return integer is
	begin
		if PRED_MODE = FULL_PREDICTION then
			return P + 3;
		else
			return P;
		end if;
	end function;
	
	function calculate_reg_size(OMEGA, D, P: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer is
		variable kappa: integer := 1;
		variable result: integer;
	begin
		if PRED_MODE = FULL_PREDICTION THEN
			kappa := 19;
		end if;
		--the formula given by ccsds120.2-g-1 is ceil(log2((2**D - 1)*(8*P + kappa)+1))
		--bits(n) yields ceil(log2(n+1)), thus:
		result := OMEGA + 2 + bits((2**D - 1)*(8*P + kappa));
		if SPSV_MODE = SPSV_FAST then
			result := result - OMEGA - 1;
		end if;
		
		return result;
	
	end function;
	
	function calculate_pred_diff_len(OMEGA, P, D: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer is
		variable result: integer;
	begin
		if PRED_MODE = FULL_PREDICTION then
			result := OMEGA + 3 + bits((4*P + 9)*(2**D - 1));
		else
			result := OMEGA + 5 + bits(P*(2**D - 1));
		end if;
		if SPSV_MODE = SPSV_FAST then
			result := result - OMEGA - 1;
		end if;
		
		return result;
	end function;
	
	function calculate_pred_diff_max(OMEGA, P, D: integer; PRED_MODE: prediction_mode; SPSV_MODE: spsv_calculation) return integer is
		variable result: integer;
	begin
		if PRED_MODE = FULL_PREDICTION then
			result := (4*P + 9)*2**(OMEGA + 2)*(2**D - 1);
		else
			result := (4*P)*2**(OMEGA + 2)*(2**D - 1);
		end if;
		if SPSV_MODE = SPSV_FAST then
			result := result/(2**(OMEGA+1));
		end if;
		
		return result;
	
	end function;
	
end ccsds_constants;
