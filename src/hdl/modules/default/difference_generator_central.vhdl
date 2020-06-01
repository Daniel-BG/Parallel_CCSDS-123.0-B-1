library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


entity difference_generator_central is
	generic
	(
		--sample bit depth
		D: integer := 16
	);
	port
	(
		--current sample values and sum
		sample_current: in unsigned(D - 1 downto 0);
		local_sum: in unsigned(D + 1 downto 0);
		diff_central: out signed(D + 2 downto 0)
	);
end difference_generator_central;


architecture Behavioral of difference_generator_central is

begin
	
	--output central difference (4*current_sample - local_sum)
	diff_central <= signed("0" & sample_current & "00") - signed("0" & local_sum);
			
end Behavioral;