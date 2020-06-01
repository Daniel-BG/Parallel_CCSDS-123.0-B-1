library IEEE;
use work.ccsds_types.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


entity difference_generator_directional is
	generic
	(
		--sample bit depth
		D: integer := 16
	);
	port
	(
		--neighboring sample values
		sample_west, sample_north, sample_northwest: in unsigned(D - 1 downto 0);
		--local sum calculated using column or neighbor oriented sums
		local_sum: in unsigned(D + 1 downto 0);
		--are we on y = 0 or x = 0?
		y_low, x_low: in boolean;
		diff_north, diff_west, diff_northwest: out signed(D + 2 downto 0)
	);
end difference_generator_directional;


architecture Behavioral of difference_generator_directional is
	--temp variables to make easier code
	signal local_diff_zero, local_diff_north, local_diff_west, local_diff_northwest: signed(D + 2 downto 0);
begin
	
	--generate local differences
	----------------------------

	local_diff_zero <= to_signed(0, local_diff_zero'length);
	local_diff_north <= signed("0" & sample_north & "00") - signed("0" & local_sum);
	local_diff_west <= signed("0" & sample_west & "00") - signed("0" & local_sum);
	local_diff_northwest <= signed("0" & sample_northwest & "00") - signed("0" & local_sum);

	
	--output differences depending on (x,y) position
	diff_north <= 
		local_diff_zero when y_low else 
		local_diff_north;
	diff_west <= 
		local_diff_zero when y_low else
		local_diff_north when x_low else
		local_diff_west;
	diff_northwest  <=
		local_diff_zero when y_low else
		local_diff_north when x_low else
		local_diff_northwest;
			
			
end Behavioral;