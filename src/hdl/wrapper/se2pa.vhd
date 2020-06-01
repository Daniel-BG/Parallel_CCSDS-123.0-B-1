----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:44:05 02/14/2017 
-- Design Name: 
-- Module Name:    se2pa - Behavioral 
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

entity se2pa is
	generic(
		IN_WIDTH: integer := 8;
		PARALLEL_SIZE: integer := 2
	);
	port(
		clk, rst, enb: in std_logic;
		data_in: in std_logic_vector(IN_WIDTH-1 downto 0);
		data_out: out std_logic_vector(IN_WIDTH*PARALLEL_SIZE-1 downto 0);
		done: out std_logic
	);
end se2pa;

architecture Behavioral of se2pa is
	signal counter: natural range 0 to PARALLEL_SIZE-1;
	
	type data_arr_t is array(0 to PARALLEL_SIZE - 1) of std_logic_vector(IN_WIDTH - 1 downto 0);
	signal data_arr: data_arr_t;
begin
	--done when the whole thing is read
	done <= '1' when counter = 0 else '0';
	
	--separate data_out into its components
	partition_data: for i in 0 to PARALLEL_SIZE - 1 generate
		data_out((i+1)*IN_WIDTH-1 downto (i)*IN_WIDTH) <= data_arr(i);
	end generate;

	--receive data and place immediately on the output
	--take care when saving the output because it changes
	--after done='1' as soon as enable is loaded
	receive_data: process(clk, rst, enb, data_in)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				counter <= 0;
				for i in 0 to PARALLEL_SIZE - 1 loop
					data_arr(i) <= (others => '0');
				end loop;
			elsif enb = '1' then
				data_arr(counter) <= data_in;
				if counter = PARALLEL_SIZE-1 then
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

