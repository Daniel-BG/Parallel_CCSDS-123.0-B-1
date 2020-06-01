library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity coordinate_generator_counter is
	--increment first on I, then J when I wraps around, then K when J wraps around
	generic (
		I_WIDTH: integer := 4;
		I_MAX: integer := 16;
		J_WIDTH: integer := 4;
		J_MAX: integer := 16;
		K_WIDTH: integer := 4;
		K_MAX: integer := 10
	);
	port (
		--counter controls
		clk, rst, enable: in std_logic;
		--coordinate outputs
		i_out: out unsigned(I_WIDTH - 1 downto 0);
		j_out: out unsigned(J_WIDTH - 1 downto 0);
		k_out: out unsigned(K_WIDTH - 1 downto 0);
		--output if done counting. Counter is stopped as long as
		--done = true. Reset with rst if necessary
		done: out boolean
	);
end coordinate_generator_counter;

architecture Behavioral of coordinate_generator_counter is
	signal i: unsigned(I_WIDTH - 1 downto 0) := (others => '0');
	signal j: unsigned(J_WIDTH - 1 downto 0) := (others => '0');
	signal k: unsigned(K_WIDTH - 1 downto 0) := (others => '0');
	signal local_done: boolean := false;
begin
	i_out <= i;
	j_out <= j;
	k_out <= k;
	done <= local_done;

	update_values: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				i <= (others => '0');
				j <= (others => '0');
				k <= (others => '0');
				local_done <= false;
			elsif enable = '1' and local_done = false then
				--if x has not yet reached max value, increment, otherwise
				--carry 1 to y
				if i /= to_unsigned(I_MAX - 1, i'length) then
					i <= i + 1;
				else
					i <= (others => '0');
					--same with y
					if j /= to_unsigned(J_MAX - 1, j'length) then
						j <= j + 1;
					else
						j <= (others => '0');
						--same with z, detect overflow if over range
						if k /= to_unsigned(K_MAX - 1, k'length) then
							k <= k + 1;
						else
							local_done <= true;
						end if;
					end if;
				end if;
			end if;
		end if;	
	end process;


end Behavioral;
	