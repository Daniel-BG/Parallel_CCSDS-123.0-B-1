----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:19:33 11/29/2016 
-- Design Name: 
-- Module Name:    accelerated_coordinate_generator - Behavioral 
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
use work.ccsds_types.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity accelerated_coordinate_generator is
	generic (
		X_WIDTH: integer := 4;
		X_MAX: integer := 16;
		Y_WIDTH: integer := 4;
		Y_MAX: integer := 16;
		Z_WIDTH: integer := 4;
		Z_MAX: integer := 10;
		T_WIDTH: integer := 8;
		C: integer := 4
	);
	port (
		clk, rst, enable: in std_logic;
		--output values. they come out delayed with respect to the internal counter to allow
		--for outputting at the same time the current and next coordinate values,
		--in hopes that this allows for segmentation in further modules thus reducing clock
		--cycle
		x_out: out unsigned(X_WIDTH - 1 downto 0);
		y_out: out unsigned(Y_WIDTH - 1 downto 0);
		z_out: out unsigned(Z_WIDTH - 1 downto 0);
		t_out: out unsigned(T_WIDTH - 1 downto 0);
		done: out boolean
	);
end accelerated_coordinate_generator;

architecture Behavioral of accelerated_coordinate_generator is
	signal x: unsigned(X_WIDTH - 1 downto 0) := (others => '0');
	signal y: unsigned(Y_WIDTH - 1 downto 0) := (others => '0');
	signal z: unsigned(Z_WIDTH - 1 downto 0) := (others => '0');
	signal local_done: boolean := false;
begin
	x_out <= x;
	y_out <= y;
	z_out <= z;
	--t is just a function of current y and x. if X_MAX is power of two, t calculation becomes trivial
	t_out <= resize(resize(y, t_out'length) * to_unsigned(X_MAX, t_out'length), t_out'length) + resize(x, t_out'length);
	done <= local_done;

	update_values: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				x <= (others => '0');
				y <= (others => '0');
				z <= (others => '0');
				local_done <= false;
			elsif enable = '1' and local_done = false then
				--if x has not yet reached max value, increment, otherwise
				--carry 1 to y
				if z /= to_unsigned(Z_MAX - C, z'length) then
					z <= z + C;
				else
					z <= (others => '0');
					--same with y
					if x /= to_unsigned(X_MAX - 1, x'length) then
						x <= x + 1;
					else
						x <= (others => '0');
						--same with z, detect overflow if over range
						if y /= to_unsigned(Y_MAX - 1, y'length) then
							y <= y + 1;
						else
							local_done <= true;
						end if;
					end if;
				end if;
			end if;
		end if;	
	end process;



end Behavioral;
	