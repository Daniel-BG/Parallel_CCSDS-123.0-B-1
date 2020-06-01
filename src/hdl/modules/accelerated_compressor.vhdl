----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:41:23 04/22/2016 
-- Design Name: 
-- Module Name:    compressor - Behavioral 
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

entity accelerated_compressor is
	port (
		clk, rst, enable: in std_logic;
		sample_current: in std_logic_vector(C*D - 1 downto 0);
		codeword: out std_logic_vector(C*(D + 1) - 1 downto 0);
		preceding_zeros: out std_logic_vector(C*U_MAX_LOG - 1 downto 0);
		word_size: out std_logic_vector(C*D_PLUS_ONE_LOG - 1 downto 0);
		done: out boolean
	);
end accelerated_compressor;

architecture Behavioral of accelerated_compressor is
	
	signal t_curr, t_curr_pipe_1, t_curr_pipe_2: unsigned(T_WIDTH - 1 downto 0);
	signal z_curr, z_curr_pipe_1, z_curr_pipe_2: unsigned(Z_WIDTH - 1 downto 0);
	signal y_curr: unsigned(Y_WIDTH - 1 downto 0);
	signal x_curr: unsigned(X_WIDTH - 1 downto 0);
	
	signal t_low, y_low, x_low, x_high, z_low, t_low_pipe_1, t_low_pipe_2, x_high_pipe_1, x_high_pipe_2: boolean;
	
	signal mpr, mpr_pipe_2: std_logic_vector(C*D - 1 downto 0);


	signal enable_pipe_1, enable_pipe_2: std_logic;
	
	
begin

	--predictor
	-----------
	predictor: entity work.accelerated_predictor
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, QUADRIC_STORAGE_AS_SHIFT_REG, C)
		port map(clk, enable, t_curr, z_curr, x_low, y_low, t_low, z_low, x_high, sample_current, mpr);


	--encoder
	---------
	encoder:	entity work.accelerated_encoder
		generic map(LINEAR_STORAGE_AS_SHIFT_REG, Z_MAX, Z_WIDTH, GAMMA_ZERO, GAMMA_STAR, T_WIDTH, D, D_PLUS_ONE_LOG, K_Z, U_MAX, U_MAX_LOG, C)
		port map(t_curr_pipe_2, clk, enable_pipe_2, t_low_pipe_2, mpr_pipe_2, z_curr_pipe_2, codeword, preceding_zeros, word_size);

		
	--rest---
	---------
	pipeline_pred: if PIPELINE_PREDICTOR generate
		save_values: process(clk)
		begin
			if (rising_edge(clk)) then
				t_curr_pipe_1 <= t_curr;
				enable_pipe_1 <= enable;
				z_curr_pipe_1 <= z_curr;
				t_low_pipe_1 <= t_low;
				x_high_pipe_1 <= x_high;
			end if;
		end process;
	end generate;
	
	no_pipeline_pred: if not PIPELINE_PREDICTOR generate
			t_curr_pipe_1 <= t_curr;
			enable_pipe_1 <= enable;
			z_curr_pipe_1 <= z_curr;
			t_low_pipe_1 <= t_low;
			x_high_pipe_1 <= x_high;
	end generate;
		
	pipeline_enc: if PIPELINE_ENCODER generate
		save_values: process(clk)
		begin
			if (rising_edge(clk)) then
				t_curr_pipe_2 <= t_curr_pipe_1;
				enable_pipe_2 <= enable_pipe_1;
				mpr_pipe_2 <= mpr;
				z_curr_pipe_2 <= z_curr_pipe_1;
				t_low_pipe_2 <= t_low_pipe_1;
				x_high_pipe_2 <= x_high_pipe_1;
			end if;
		end process;
	end generate;
	
	no_pipeline_enc: if not PIPELINE_ENCODER generate
			t_curr_pipe_2 <= t_curr_pipe_1;
			enable_pipe_2 <= enable_pipe_1;
			mpr_pipe_2 <= mpr;
			z_curr_pipe_2 <= z_curr_pipe_1;
			t_low_pipe_2 <= t_low_pipe_1;
			x_high_pipe_2 <= x_high_pipe_1;
	end generate;

	
	--auxiliar functionality
	------------------------
	lim_gen: entity work.limit_generator
		generic map(X_MAX, X_WIDTH, Y_WIDTH, T_WIDTH, Z_WIDTH)
		port map(x_curr, y_curr, z_curr, t_curr, t_low, y_low, x_low, x_high, z_low);
--		
--	coord_gen: entity work.coordinate_generator 
--		generic map(X_WIDTH, X_MAX, Y_WIDTH, Y_MAX, Z_WIDTH, Z_MAX, T_WIDTH, ENCODING)
--		port map(clk, rst, enable, x_curr, y_curr, z_curr, t_curr, done);
		
	coord_gen: entity work.accelerated_coordinate_generator
		generic map(X_WIDTH, X_MAX, Y_WIDTH, Y_MAX, Z_WIDTH, Z_MAX, T_WIDTH, C)
		port map(clk, rst, enable, x_curr, y_curr, z_curr, t_curr, done);

			
end Behavioral;

