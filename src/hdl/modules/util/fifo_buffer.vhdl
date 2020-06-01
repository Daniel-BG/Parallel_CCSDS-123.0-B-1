----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:21:02 04/23/2016 
-- Design Name: 
-- Module Name:    fifo - Behavioral 
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
use work.ccsds_functions.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_buffer is
	generic(
		DATA_WIDTH: integer  := 8;
		BUFFER_LENGTH: integer := 1000
	);
	port(
		clk, enable: in std_logic;
		data_in: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		data_out: out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
end fifo_buffer;

architecture Behavioral of fifo_buffer is
	--use a BUFFER_LENGTH - 2 sized array because RAM will
	--hold last value on its output, so for example for a
	--3 cell buffer we only need 2 ram cells.
	type contents_storage is array(0 to BUFFER_LENGTH - 2) of
		std_logic_vector(DATA_WIDTH - 1 downto 0);
	
	signal contents: contents_storage := (others => (others => '0'));
	
	signal index: unsigned(bits(BUFFER_LENGTH - 2) - 1 downto 0) := (others => '0');
begin
	

	update_fifo: process(clk, data_in, index, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			--read and write data
			data_out <= contents(to_integer(index));
			contents(to_integer(index)) <= data_in;
			
			if index = BUFFER_LENGTH - 2 then
				index <= (others => '0');
			else
				index <= index + 1;
			end if;
		end if;
	end process;


end Behavioral;

