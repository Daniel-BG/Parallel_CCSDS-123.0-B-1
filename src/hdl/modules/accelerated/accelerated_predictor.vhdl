----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:41:23 04/22/2016 
-- Design Name: 
-- Module Name:    accelerated_predictor - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.ccsds_types.all;
use work.ccsds_constants.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity accelerated_predictor is
	generic(
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		C: integer := 4
	);
	port (
		clk, enable: in std_logic;
		t_curr: in unsigned(T_WIDTH - 1 downto 0);
		z_curr_in: in unsigned(Z_WIDTH - 1 downto 0);
		x_low, y_low, t_low, z_low, x_high: in boolean;
		sample_current: in std_logic_vector(C*D - 1 downto 0);
		mapped_prediction_residual: out std_logic_vector(C*D - 1 downto 0)
	);
end accelerated_predictor;

architecture Behavioral of accelerated_predictor is
	--types
	type vv_diff_vector is array(0 to C - 1) of std_logic_vector(P_STAR * (D + 3) - 1 downto 0);
	type vv_weight_vector is array(0 to C - 1) of std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
	type vv_sample is array(0 to C - 1) of unsigned(D - 1 downto 0);
	type vv_local_sum is array(0 to C - 1) of unsigned(D + 1 downto 0);
	type vv_mpr is array(0 to C - 1) of unsigned(D - 1 downto 0);
	type vv_pcld is array(0 to C - 1) of signed(PRED_DIFF_LEN - 1 downto 0);
	type vv_scaled_err is array(0 to C - 1) of signed(D + 1 downto 0);
	type vv_diff is array(0 to C - 1) of signed(D + 2 downto 0);
	type vv_z is array(0 to C - 1) of unsigned(Z_WIDTH - 1 downto 0);
	
	--pipelining signals
	signal diff_vector_filtered_pipe: vv_diff_vector;
	signal sample_current_pipe: vv_sample;
	signal sample_previous_band_pipe: unsigned(D - 1 downto 0);
	
	signal t_low_pipe, z_low_pipe: boolean;
	signal local_sum_pipe: vv_local_sum;
	signal z_curr_pipe, z_curr: vv_z;
	signal t_curr_pipe: unsigned(T_WIDTH - 1 downto 0);
	signal enable_pipe: std_logic;

	
	signal mpr: vv_mpr;
	signal diff_vector, diff_vector_filtered: vv_diff_vector;
	signal sample_previous_band: unsigned(D - 1 downto 0);
	signal sample_west, sample_northwest, sample_north, sample_northeast: vv_sample;
	signal sample_west_stdlv, sample_northwest_stdlv, sample_north_stdlv, sample_northeast_stdlv: 
		std_logic_vector(C*D - 1 downto 0);
	signal local_sum: vv_local_sum;

	signal diff_central, diff_west, diff_north, diff_northwest: vv_diff;
	signal diff_central_stdlv: std_logic_vector(C*(D + 3) - 1 downto 0);
	signal diff_central_stdlv_prev: std_logic_vector(P*(D + 3) - 1 downto 0);
	
	signal weight_vector_current, weight_vector_next, weight_vector_filtered: vv_weight_vector;
	signal weight_vector_current_stdlv, weight_vector_next_stdlv: 
		std_logic_vector(C * P_STAR * (OMEGA + 3) - 1 downto 0);
		
	signal scaled_err: vv_scaled_err;
	
	signal pcld: vv_pcld;
	
begin

	--pipelining
	pipeline: if PIPELINE_PREDICTOR generate
		pipe: process(clk)
		begin
			if rising_edge(clk) then
				sample_previous_band_pipe <= sample_previous_band;
				t_low_pipe <= t_low;
				z_low_pipe <= z_low;
				t_curr_pipe <= t_curr;
				enable_pipe <= enable;
			end if;
		end process;
	end generate;
	
	not_pipeline: if not PIPELINE_PREDICTOR generate
		sample_previous_band_pipe <= sample_previous_band;
		t_low_pipe <= t_low;
		z_low_pipe <= z_low;
		t_curr_pipe <= t_curr;
		enable_pipe <= enable;
	end generate;

	--PRIVATE PARALLEL PART
	parallelize: for i in 0 to C - 1 generate
		--stdlv translations 
		diff_central_stdlv((i + 1)*(D + 3) - 1 downto i*(D + 3)) <= std_logic_vector(diff_central(i));
		sample_west(i) <= unsigned(sample_west_stdlv((i + 1)*D - 1 downto i*D));
		sample_north(i) <= unsigned(sample_north_stdlv((i + 1)*D - 1 downto i*D));
		sample_northwest(i) <= unsigned(sample_northwest_stdlv((i + 1)*D - 1 downto i*D));
		sample_northeast(i) <= unsigned(sample_northeast_stdlv((i + 1)*D - 1 downto i*D));
		weight_vector_next_stdlv((i + 1)*P_STAR*(OMEGA + 3) - 1 downto i*P_STAR*(OMEGA + 3))
			<= weight_vector_next(i);
		weight_vector_current(i)
			<= weight_vector_current_stdlv((i + 1)*P_STAR*(OMEGA + 3) - 1 downto i*P_STAR*(OMEGA + 3));
			
		z_0: if i = 0 generate
			z_curr(0) <= z_curr_in;
		end generate;
		z_i: if i /= 0 generate
			z_curr(i) <= z_curr_in + i;
		end generate;
 	
	
		pipeline_parallel: if PIPELINE_PREDICTOR generate
			pipe: process(clk)
			begin
				if rising_edge(clk) then
					diff_vector_filtered_pipe(i) <= diff_vector_filtered(i);
					sample_current_pipe(i) <= unsigned(sample_current((i + 1)*D - 1 downto i*D));
					local_sum_pipe(i) <= local_sum(i);
					z_curr_pipe(i) <= z_curr(i);
				end if;
			end process;
		end generate;
		
		not_pipeline_parallel: if not PIPELINE_PREDICTOR generate
			diff_vector_filtered_pipe(i) <= diff_vector_filtered(i);
			sample_current_pipe(i) <= unsigned(sample_current((i + 1)*D - 1 downto i*D));
			local_sum_pipe(i) <= local_sum(i);
			z_curr_pipe(i) <= z_curr(i);
		end generate;
		
		mapped_prediction_residual((i + 1)*D - 1 downto i*D) <= std_logic_vector(mpr(i));
		
		--vectorial product unit
		central_local_diff_pred: entity work.central_local_difference_predictor
			generic map(P_STAR, PRED_DIFF_LEN, D, OMEGA, SPSV_MODE)
			port map(diff_vector_filtered_pipe(i), weight_vector_filtered(i), pcld(i));
			
		--prediction residual mapper
		gen_pred_res_mapper_0: if i = 0 generate
			pred_res_mapper: entity work.prediction_residual_mapper
				generic map(R, PRED_DIFF_LEN, OMEGA, D, P, SPSV_MODE)
				port map(sample_current_pipe(0), sample_previous_band_pipe, pcld(i), t_low_pipe, local_sum_pipe(i), z_low_pipe, mpr(i), scaled_err(i));
		end generate;
		gen_pred_res_mapper_i: if i /= 0 generate
			pred_res_mapper: entity work.prediction_residual_mapper
				generic map(R, PRED_DIFF_LEN, OMEGA, D, P, SPSV_MODE)
				port map(sample_current_pipe(i), sample_current_pipe(i - 1), pcld(i), t_low_pipe, local_sum_pipe(i), false, mpr(i), scaled_err(i));
		end generate;
		
		--weight updater
		w_update: entity work.weight_update
			generic map(V_MIN, V_MAX, T_INC, T_WIDTH, X_MAX, D, OMEGA, RHO_WIDTH, P_STAR, R_WEIGHT)
			port map(t_curr_pipe, diff_vector_filtered_pipe(i), scaled_err(i), weight_vector_filtered(i), weight_vector_next(i));
		
		--difference generator
		diff_gen_cen: entity work.difference_generator_central
			generic map	(D)
			port map(unsigned(sample_current((i + 1)*D - 1 downto i*D)), local_sum(i), diff_central(i));
			
		diff_gen_0: if PRED_MODE = FULL_PREDICTION generate
			diff_gen_dir: entity work.difference_generator_directional
				generic map(D)
				port map(sample_west(i), sample_north(i), sample_northwest(i), local_sum(i), y_low, x_low, 
							diff_north(i), diff_west(i), diff_northwest(i));
							
			diff_vector(i)(P_STAR*(D + 3) - 1 downto (P_STAR - 1)*(D + 3)) 
				<= std_logic_vector(diff_north(i));
			diff_vector(i)((P_STAR - 1)*(D + 3) - 1 downto (P_STAR - 2)*(D + 3)) 
				<= std_logic_vector(diff_west(i));
			diff_vector(i)((P_STAR - 2)*(D + 3) - 1 downto (P_STAR - 3)*(D + 3)) 
				<= std_logic_vector(diff_northwest(i));
		end generate;
		
		--local sum generation
		sum_gen_0: if SUM_MODE = NEIGHBOR_ORIENTED generate
			local_sum_gen: entity work.local_sum_generator_neighbor
				generic map(D)
				port map(sample_west(i), sample_northwest(i), sample_north(i), sample_northeast(i),
							y_low, x_low, x_high, local_sum(i));
		end generate;
		sum_gen_1: if SUM_MODE = COLUMN_ORIENTED generate
			local_sum_gen: entity work.local_sum_generator_column
				generic map(D)
				port map(sample_west(i), sample_north(i), y_low, local_sum(i));
		end generate;
		
		
		--making the difference vectors
		gen_diff_vectors: for j in 0 to P - 1 generate
			--differences taken from parallel compressors
			parallel_diffs: if j < i generate
				diff_vector(i)((P - j)*(D + 3) - 1 downto (P - 1 - j)*(D + 3)) 
					<= std_logic_vector(diff_central(i - 1 - j));
			end generate;
			--differences taken from memory
			memory_diffs: if j >= i generate
				diff_vector(i)((P - j)*(D + 3) - 1 downto (P - 1 - j)*(D + 3)) 
					<= diff_central_stdlv_prev((P - (j - i))*(D + 3) - 1 downto ((P - 1 - (j - i))*(D + 3)));
			end generate;
		end generate;
		
		--auxiliar functionality	
		diff_filter: entity work.difference_filter_previous_bands 
			generic map(Z_WIDTH, D, P_STAR, P)
			port map(z_curr(i), diff_vector(i), diff_vector_filtered(i));

		w_filter: entity work.weight_filter_previous_bands
			generic map(Z_WIDTH, OMEGA, P_STAR, P)
			port map(z_curr_pipe(i), weight_vector_current(i), weight_vector_filtered(i));
		
	end generate;
	
	
	--PARALLEL STORAGE
	
	gen_diff_storage: if P > 0 generate
		diff_storage: entity work.accelerated_difference_storage
			generic map(D, P, C)
			port map(clk, enable, diff_central_stdlv, diff_central_stdlv_prev);
	end generate;
	
	sample_strg_neigh: entity work.accelerated_sample_storage
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Z_MAX, D, C)
		port map(clk, enable, sample_current, sample_west_stdlv, sample_northwest_stdlv, sample_north_stdlv, sample_northeast_stdlv);

	sample_strg_prev_band: entity work.sample_storage_previous_band
		generic map(D)
		port map(clk, enable, t_low, unsigned(sample_current(C*D - 1 downto (C - 1)*D)), sample_previous_band);

	weight_storage: entity work.accelerated_weight_storage
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, P_STAR, OMEGA, C)
		port map(clk, enable_pipe, t_low_pipe, z_curr_pipe(0), weight_vector_next_stdlv, weight_vector_current_stdlv);


			
end Behavioral;

