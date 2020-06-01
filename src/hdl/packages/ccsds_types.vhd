library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


package ccsds_types is
	type local_sum_mode is (NEIGHBOR_ORIENTED, COLUMN_ORIENTED);
	type prediction_mode is (FULL_PREDICTION, REDUCED_PREDICTION);
	type encoding_order is (BAND_INTERLEAVED_PIXEL, BAND_INTERLEAVED_LINE, BAND_SEQUENTIAL);
	type weight_initialization_mode is (WEIGHT_CUSTOM, WEIGHT_DEFAULT);
	type acc_initialization_mode is (ACCUMULATOR_CUSTOM, ACCUMULATOR_DEFAULT);
	type spsv_calculation is (SPSV_FAST, SPSV_PRECISE);
	
	--type registros is array (0 to 31) of std_logic_vector(31 downto 0); -- tipo registros que es array de 32 posiciones tamaño palabr
	--constant f_nor : std_logic_vector (5 downto 0) := "100111";		-- NOR

end package;