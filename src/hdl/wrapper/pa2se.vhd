----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:47 02/14/2017 
-- Design Name: 
-- Module Name:    pa2se - Behavioral 
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

entity pa2se is
	generic(
		OUT_WIDTH: integer := 8;
		PARALLEL_SIZE: integer := 4
	);
	port(
		clk, rst, enb: in std_logic;
		data_in: in std_logic_vector(OUT_WIDTH*PARALLEL_SIZE-1 downto 0);
		data_out: out std_logic_vector(OUT_WIDTH-1 downto 0);
		almost_done, done: out std_logic
	);
end pa2se;

architecture Behavioral of pa2se is
	signal counter: natural range 0 to PARALLEL_SIZE-1;
	type serialized_input_t is array(0 to PARALLEL_SIZE-1) 
		of std_logic_vector(OUT_WIDTH-1 downto 0);
	signal serialized_input: serialized_input_t;
begin

	gen_serialized_input: for i in 0 to PARALLEL_SIZE-1 generate
		serialized_input(i) <= data_in((i+1)*OUT_WIDTH-1 downto (i)*OUT_WIDTH);
	end generate;

    almost_done <= '1' when counter = PARALLEL_SIZE - 1 else '0';
	done <= '1' when counter = 0 else '0';
	
	send_data: process(clk, rst, enb, data_in)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				counter <= 0;
				data_out <= (others => '0'); 
			elsif enb = '1' then
				data_out <= serialized_input(counter);
				if counter = PARALLEL_SIZE-1 then
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

