----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:50:45 04/23/2016 
-- Design Name: 
-- Module Name:    shift_reg - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shift_reg is
	generic(
		DATA_WIDTH: integer := 16;
		DATA_LENGTH: integer := 1000
	);
	port(
		clk, enable: in std_logic;
		data_in: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		data_out: out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end shift_reg;

architecture Behavioral of shift_reg is
	type reg_mem is array(0 to DATA_LENGTH - 1) of
		std_logic_vector(DATA_WIDTH - 1 downto 0);
	
	signal contents: reg_mem := (others => (others => '0')); 
	
begin

	data_out <= contents(0);

	update_regs: process(clk, data_in, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			for i in 0 to DATA_LENGTH - 2 loop
				contents(i) <= contents(i + 1);
			end loop;
			contents(DATA_LENGTH - 1) <= data_in;
		end if;
	end process;


end Behavioral;

