----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:41:23 04/22/2016 
-- Design Name: 
-- Module Name:    predictor - Behavioral 
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

entity predictor is
	generic(
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false
	);
	port (
		clk, rst, enable: in std_logic;
		t_curr: in unsigned(T_WIDTH - 1 downto 0);
		z_curr: in unsigned(Z_WIDTH - 1 downto 0);
		x_low, y_low, t_low, z_low, x_high: in boolean;
		sample_current: in unsigned(D - 1 downto 0);
		mapped_prediction_residual: out unsigned(D - 1 downto 0)
	);
end predictor;

architecture Behavioral of predictor is
	--pipelining signals
	signal diff_vector_filtered_pipe: std_logic_vector(P_STAR * (D + 3) - 1 downto 0);
	signal sample_current_pipe, sample_previous_band_pipe: unsigned(D - 1 downto 0);
	signal t_low_pipe, z_low_pipe, x_high_pipe: boolean;
	signal local_sum_pipe: unsigned(D + 1 downto 0);
	signal z_curr_pipe: unsigned(Z_WIDTH - 1 downto 0);
	signal t_curr_pipe: unsigned(T_WIDTH - 1 downto 0);
	signal enable_pipe: std_logic;

	
	signal mpr: unsigned(D - 1 downto 0);
	signal diff_vector, diff_vector_filtered: std_logic_vector(P_STAR * (D + 3) - 1 downto 0);
	signal sample_previous_band, 
		sample_west, sample_northwest, sample_north, sample_northeast: unsigned(D - 1 downto 0);
	signal local_sum: unsigned(D + 1 downto 0);

	signal diff_central, diff_west, diff_north, diff_northwest: signed(D + 2 downto 0);
	
	signal weight_vector_current, weight_vector_next, weight_vector_filtered:
		std_logic_vector(P_STAR * (OMEGA + 3) - 1 downto 0);
		
	signal scaled_err: signed(D + 1 downto 0);
	
	signal pcld: signed(PRED_DIFF_LEN - 1 downto 0);
	
begin

	pipeline: if PIPELINE_PREDICTOR generate
		pipe: process(clk)
		begin
			if rising_edge(clk) then
				diff_vector_filtered_pipe <= diff_vector_filtered;
				sample_current_pipe <= sample_current;
				sample_previous_band_pipe <= sample_previous_band;
				t_low_pipe <= t_low;
				z_low_pipe <= z_low;
				x_high_pipe <= x_high;
				local_sum_pipe <= local_sum;
				z_curr_pipe <= z_curr;
				t_curr_pipe <= t_curr;
				enable_pipe <= enable;
			end if;
		end process;
	end generate;
	
	not_pipeline: if not PIPELINE_PREDICTOR generate
		diff_vector_filtered_pipe <= diff_vector_filtered;
		sample_current_pipe <= sample_current;
		sample_previous_band_pipe <= sample_previous_band;
		t_low_pipe <= t_low;
		z_low_pipe <= z_low;
		x_high_pipe <= x_high;
		local_sum_pipe <= local_sum;
		z_curr_pipe <= z_curr;
		t_curr_pipe <= t_curr;
		enable_pipe <= enable;
	end generate;


	mapped_prediction_residual <= mpr;

	--vectorial product unit
	central_local_diff_pred: entity work.central_local_difference_predictor
		generic map(P_STAR, PRED_DIFF_LEN, D, OMEGA, SPSV_MODE)
		port map(diff_vector_filtered_pipe, weight_vector_filtered, pcld);
		
	--prediction residual mapper
	pred_res_mapper:	entity work.prediction_residual_mapper
		generic map(R, PRED_DIFF_LEN, OMEGA, D, P, SPSV_MODE)
		port map(sample_current_pipe, sample_previous_band_pipe, pcld, t_low_pipe, local_sum_pipe, z_low_pipe, mpr, scaled_err);
		
	--weight updater
	w_update: entity work.weight_update
		generic map(V_MIN, V_MAX, T_INC, T_WIDTH, X_MAX, D, OMEGA, RHO_WIDTH, P_STAR, R_WEIGHT)
		port map(t_curr_pipe, diff_vector_filtered_pipe, scaled_err, weight_vector_filtered, weight_vector_next);
		
	
	--difference generator (s in FULL PREDICTION)
	diff_gen_cen: entity work.difference_generator_central
		generic map	(D)
		port map(sample_current, local_sum, diff_central);

	diff_gen_0: if PRED_MODE = FULL_PREDICTION generate
		diff_gen_dir: entity work.difference_generator_directional
			generic map(D)
			port map(sample_west, sample_north, sample_northwest, local_sum, y_low, x_low, 
						diff_north, diff_west, diff_northwest);
		diff_vector(P_STAR*(D + 3) - 1 downto (P_STAR - 1)*(D + 3)) 
			<= std_logic_vector(diff_north);
		diff_vector((P_STAR - 1)*(D + 3) - 1 downto (P_STAR - 2)*(D + 3)) 
			<= std_logic_vector(diff_west);
		diff_vector((P_STAR - 2)*(D + 3) - 1 downto (P_STAR - 3)*(D + 3)) 
			<= std_logic_vector(diff_northwest);
	end generate;
		
	--local sum generation
	sum_gen_0: if SUM_MODE = NEIGHBOR_ORIENTED generate
		local_sum_gen: entity work.local_sum_generator_neighbor
			generic map(D)
			port map(sample_west, sample_northwest, sample_north, sample_northeast,
						y_low, x_low, x_high, local_sum);
	end generate;
	
	sum_gen_1: if SUM_MODE = COLUMN_ORIENTED generate
		local_sum_gen: entity work.local_sum_generator_column
			generic map(D)
			port map(sample_west, sample_north, y_low, local_sum);
	end generate;
	
	
	--storages
	--no need to check PRED_MODE = FULL_PREDICTION since P*(D + 3) - 1 downto 0 gives
	--us the desired result. If it is full_pred, the first differences will be
	--N, NW, W, if not, they are empty
	gen_storage: if P > 0 generate
		diff_storage: entity work.difference_storage
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Y_MAX, D, P, ENCODING)
			port map(clk, enable, diff_central, diff_vector(P*(D + 3) - 1 downto 0));
	end generate;
	
	sample_strg_neigh: entity work.sample_storage_neighbor
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Z_MAX, D, ENCODING)
		port map(clk, enable, sample_current, sample_west, sample_northwest, sample_north, sample_northeast);
	
	sample_strg_prev_band: entity work.sample_storage_previous_band
		generic map(D)
		port map(clk, enable, t_low, sample_current, sample_previous_band);
	
	weight_storage: entity work.weight_storage
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_WIDTH, Z_MAX, P_STAR, OMEGA, ENCODING)--, WEIGHT_INIT)
		port map(z_curr_pipe, rst, clk, enable_pipe, t_low_pipe, x_high_pipe, weight_vector_next, weight_vector_current);
		
	
	
	--auxiliar functionality	
	diff_filter: entity work.difference_filter_previous_bands 
		generic map(Z_WIDTH, D, P_STAR, P)
		port map(z_curr, diff_vector, diff_vector_filtered);
		
	w_filter: entity work.weight_filter_previous_bands
		generic map(Z_WIDTH, OMEGA, P_STAR, P)
		port map(z_curr_pipe, weight_vector_current, weight_vector_filtered);

			
end Behavioral;

