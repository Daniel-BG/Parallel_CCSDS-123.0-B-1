----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:00:41 03/09/2017 
-- Design Name: 
-- Module Name:    coding_to_fixed_length_controller - Behavioral 
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

entity coding_to_fixed_length_controller is
	generic (
		D: integer := 16;
		U_MAX_LOG: integer := 6;
		D_PLUS_ONE_LOG: integer := 5;
		BUF_LEN: integer := 56; --7 + U_MAX + D + 1;
		BUF_LEN_LOG: integer := 6
	);
	port (
		clk, rst: in std_logic;
		input_queue_empty, output_queue_full: in std_logic;
		input_zeros: in std_logic_vector(U_MAX_LOG-1 downto 0);
		input_codelength: in std_logic_vector(D_PLUS_ONE_LOG-1 downto 0);
		input_code: in std_logic_vector(D downto 0);
		input_queue_rdenb, output_queue_wrenb: out std_logic;
		output_buffer: out std_logic_vector(BUF_LEN - 1 downto 0);
		output_buff_len: out std_logic_vector(BUF_LEN_LOG - 4 downto 0)
	);
end coding_to_fixed_length_controller;


architecture Behavioral of coding_to_fixed_length_controller is
	type CTFL_TYPE is (IDLE, SAVING); --, ENDING);
	signal coding_state_cs, coding_state_ns: CTFL_TYPE;

	--coder signals
	signal input_buffer_cs, input_buffer_ns, input_buffer_proc : 
		std_logic_vector(BUF_LEN - 1 downto 0);
	signal bits_taken_cs, bits_taken_ns: std_logic_vector(2 downto 0);
	signal next_buffer_bytes: std_logic_vector(BUF_LEN_LOG - 4 downto 0);
	--these should be variables, but by making them signals they can be traced
	signal total_bits_used : std_logic_vector(BUF_LEN_LOG - 1 downto 0);
	signal code_mask_base, code_masked : std_logic_vector(D downto 0);
	--signal code_masked_preshift: std_logic_vector(BUF_LEN + D + 1 - 1 downto 0);
	signal code_final : std_logic_vector(BUF_LEN - 1 downto 0);
	
	
begin

	output_buff_len <= next_buffer_bytes;
	output_buffer <= input_buffer_proc;


	--update process
	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				input_buffer_cs <= (others => '0');
				bits_taken_cs <= (others => '0');
				coding_state_cs <= IDLE;
			else
				input_buffer_cs <= input_buffer_ns;
				bits_taken_cs <= bits_taken_ns;
				coding_state_cs <= coding_state_ns;
			end if;
		end if;
	end process;
	

	--generate next buffer
	code_mask_base <= (others => '1');
	code_masked <= std_logic_vector(shift_right(unsigned(code_mask_base), to_integer(D + 1 - unsigned(input_codelength)))) and input_code;
	total_bits_used <= std_logic_vector(
		resize(unsigned(bits_taken_cs), BUF_LEN_LOG) + 
		resize(unsigned(input_zeros), BUF_LEN_LOG) +
		resize(unsigned(input_codelength), BUF_LEN_LOG));
		
	
	--code_final <= std_logic_vector(shift_left(resize(unsigned(code_masked), BUF_LEN), BUF_LEN - to_integer(unsigned(total_bits_used))));	
	code_final <= std_logic_vector(shift_left(resize(unsigned(code_masked), BUF_LEN), to_integer(BUF_LEN - unsigned(total_bits_used))));
	--code_masked_preshift(BUF_LEN + D downto BUF_LEN) <= code_masked;
	--code_masked_preshift(BUF_LEN - 1 downto 0) <= (others => '0');
	--code_final <= std_logic_vector(resize(shift_right(unsigned(code_masked_preshift), to_integer(unsigned(total_bits_used))), BUF_LEN));
	
	--this goes on to the next step
	input_buffer_proc <= input_buffer_cs or code_final;
	next_buffer_bytes <= std_logic_vector(resize(shift_right(unsigned(total_bits_used), 3), next_buffer_bytes'length));



	--coding process
	process_coding_cmb: process(input_buffer_cs, bits_taken_cs, coding_state_cs, input_queue_empty, next_buffer_bytes, output_queue_full, input_buffer_proc, total_bits_used)
	begin 
	

		
		--load defaults
		input_buffer_ns <= input_buffer_cs;
		bits_taken_ns <= bits_taken_cs;
		coding_state_ns <= coding_state_cs;
		input_queue_rdenb <= '0';
		output_queue_wrenb <= '0';
			
		
		case coding_state_cs is
			--waiting for new data to be available
			when IDLE =>
				if input_queue_empty = '0' then
					coding_state_ns <= SAVING;
					input_queue_rdenb <= '1';
				end if;
			--calculate the shifts and stuff and enable the write flag for the 
			--next step
--			when SAVING =>
--				if unsigned(next_buffer_bytes) = 0 then
--					coding_state_ns <= ENDING;
--				else
--					if output_queue_full = '0' then
--						output_queue_wrenb <= '1';
--						coding_state_ns <= ENDING;
--					end if;
--				end if;
--			when ENDING =>
--				if unsigned(next_buffer_bytes) /= 0 then
--					input_buffer_ns <= std_logic_vector(shift_left(unsigned(input_buffer_proc), to_integer(unsigned(next_buffer_bytes & "000"))));
--				else
--					input_buffer_ns <= input_buffer_proc;
--				end if;
--				bits_taken_ns <= total_bits_used(2 downto 0);
--				coding_state_ns <= IDLE;
				
			when SAVING =>
				if output_queue_full = '0' or unsigned(next_buffer_bytes) = 0 then
					--200%improvements
					if input_queue_empty = '0' then
						coding_state_ns <= SAVING;
						input_queue_rdenb <= '1';
					else 
						coding_state_ns <= IDLE;
					end if;
					
					if unsigned(next_buffer_bytes) /= 0 then
						output_queue_wrenb <= '1';
						input_buffer_ns <= std_logic_vector(shift_left(unsigned(input_buffer_proc), to_integer(unsigned(next_buffer_bytes & "000"))));
					else
						input_buffer_ns <= input_buffer_proc;
					end if;
					bits_taken_ns <= total_bits_used(2 downto 0);
				end if;
		end case;
	end process;

end Behavioral;

