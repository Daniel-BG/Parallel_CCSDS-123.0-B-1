----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:37:13 04/06/2017 
-- Design Name: 
-- Module Name:    byte_output_controller - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity byte_output_controller is
	generic (
		BUF_LEN: integer := 56; --7 + U_MAX + D + 1;
		BUF_LEN_LOG: integer := 6
	);
	port (
		clk, rst: in std_logic;
		input_queue_empty, output_queue_full: in std_logic;
		input_buffer: in std_logic_vector(BUF_LEN - 1 downto 0);
		input_buff_len: in std_logic_vector(BUF_LEN_LOG - 4 downto 0);
		input_queue_rdenb, output_queue_wrenb: out std_logic;
		output_byte: out std_logic_vector(7 downto 0)
	);
end byte_output_controller;

architecture Behavioral of byte_output_controller is
    type BOC_TYPE is (IDLE, OUTPUTTING);
    signal outputting_state_ns, outputting_state_cs: BOC_TYPE;

	--outputter signals
	signal output_bytes_cs, output_bytes_ns : std_logic_vector(BUF_LEN_LOG - 4 downto 0);
	
	--helper signals
	signal input_buffer_shifted: std_logic_vector(BUF_LEN - 1 downto 0);
	
begin

	input_buffer_shifted <= std_logic_vector(shift_left(unsigned(input_buffer), to_integer(unsigned(output_bytes_cs & "000"))));
	output_byte <= input_buffer_shifted(BUF_LEN - 1 downto BUF_LEN - 8);

	--update process
	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				outputting_state_cs <= IDLE;
				output_bytes_cs <= (others => '0');
			else
				outputting_state_cs <= outputting_state_ns;
				output_bytes_cs <= output_bytes_ns;
			end if;
		end if;
	end process;	


	process_outputting_cmb: process (output_bytes_cs, outputting_state_cs, input_queue_empty, output_queue_full, input_buff_len)
	
	begin
		--next state defaults
		output_bytes_ns <= output_bytes_cs;
		outputting_state_ns <= outputting_state_cs;
		--variable defualts
		output_queue_wrenb <= '0';
		input_queue_rdenb <= '0';
		
		
		
		case outputting_state_cs is
			when IDLE =>
				if input_queue_empty = '0' then
					input_queue_rdenb <= '1';
					outputting_state_ns <= OUTPUTTING;
					output_bytes_ns <= (others => '0');
				end if;
				
			when OUTPUTTING =>
				if output_queue_full = '0' then
					output_queue_wrenb <= '1';
					--if we are done in this cycle (After sending the current byte)
					if unsigned(output_bytes_cs) = unsigned(input_buff_len) - to_unsigned(1, input_buff_len'length) then
						if input_queue_empty = '0' then
							input_queue_rdenb <= '1';
							outputting_state_ns <= OUTPUTTING;
							output_bytes_ns <= (others => '0');
						else
							outputting_state_ns <= IDLE;
						end if;
					
					else --case we are not done yet
						output_bytes_ns <= std_logic_vector(unsigned(output_bytes_cs) + to_unsigned(1, output_bytes_cs'length));
						outputting_state_ns <= OUTPUTTING;
					end if;
				end if;
		
		end case;
	
	end process;


end Behavioral;

