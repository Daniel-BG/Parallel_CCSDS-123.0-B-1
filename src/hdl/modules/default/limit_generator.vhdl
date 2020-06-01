----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:18:06 04/22/2016 
-- Design Name: 
-- Module Name:    limit_generator - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity limit_generator is
	generic(
		X_MAX: integer := 200;
		X_WIDTH: integer := 8;
		Y_WIDTH: integer := 8;
		T_WIDTH: integer := 8;
		Z_WIDTH: integer := 8
	);
	port(
		x: in unsigned(X_WIDTH - 1 downto 0);
		y: in unsigned(Y_WIDTH - 1 downto 0);
		z: in unsigned(Z_WIDTH - 1 downto 0);
		t: in unsigned(T_WIDTH - 1 downto 0);
		t_low, y_low, x_low, x_high, z_low: out boolean
	);
end limit_generator;

architecture Behavioral of limit_generator is
begin
	z_low		<= true when z = 0 else false;
	t_low		<= true when t = 0 else false;
	y_low		<= true when y = 0 else false;
	x_low		<= true when x = 0 else false;
	x_high	<= true when x = X_MAX - 1  else false;
end Behavioral;

