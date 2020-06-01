----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:19:40 03/09/2017 
-- Design Name: 
-- Module Name:    pa2se_controller - Behavioral 
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

entity pa2se_controller is
	generic(
		OUT_WIDTH: integer := 8;
		PARALLEL_SIZE: integer := 4
	);
	port (
		clk, rst: in std_logic;
		input_queue_empty, output_queue_full: in std_logic;
		input_queue_out: in std_logic_vector(OUT_WIDTH*PARALLEL_SIZE-1 downto 0);
		input_queue_rdenb, output_queue_wrenb: out std_logic;
		output_queue_in: out std_logic_vector(OUT_WIDTH-1 downto 0)
	);
end pa2se_controller;

architecture Behavioral of pa2se_controller is
	type OUTPUT_CNTL_SM_TYPE is (SLEEP, READING, DATA_READ);
	signal output_cntl_cs, output_cntl_ns: OUTPUT_CNTL_SM_TYPE;
	--PARALLEL TO SERIAL DECODER
	signal pa2se_enb, pa2se_done, pa2se_almost_done: std_logic;
	
begin

	--update process
	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				output_cntl_cs <= SLEEP;
			else
				output_cntl_cs <= output_cntl_ns;
			end if;
		end if;
	end process;	

	PA2SE_CORE: entity work.pa2se
		generic map (
			OUT_WIDTH => OUT_WIDTH,
			PARALLEL_SIZE => PARALLEL_SIZE
		)
		port map (
			clk => clk, rst => rst, enb => pa2se_enb,
			data_in => input_queue_out,
			data_out => output_queue_in,
			almost_done => pa2se_almost_done,
			done => pa2se_done
		);

	OUTPUT_CNTL_COMB: process(output_cntl_cs, input_queue_empty, output_queue_full, pa2se_done) is
	begin
		
		-- set defaults
		pa2se_enb <= '0';
		input_queue_rdenb <= '0';
		output_cntl_ns  <= output_cntl_cs;
		output_queue_wrenb <= '0';
		
		
		case output_cntl_cs is
			--waiting for data to be available on the parallel fifo
			when SLEEP =>
				if input_queue_empty = '0' then
					input_queue_rdenb <= '1';
					output_cntl_ns  <= READING;
				end if;
			--reading stuff from the parallel stream
			when READING =>
				pa2se_enb <= '1';
				output_cntl_ns <= DATA_READ;
			--waiting for data writes to be acknowledged
			when DATA_READ =>
				if output_queue_full = '0' then
					output_queue_wrenb <= '1';
					if pa2se_done = '1' then
						--edge case to be faster. could simply always jump to sleep
						if input_queue_empty = '0' then
							input_queue_rdenb <= '1';
							output_cntl_ns  <= READING;
						else
							output_cntl_ns <= SLEEP;
						end if;
					--otherwise continue reading
					else
						output_cntl_ns <= READING;
					end if;
				end if;
		end case;

	end process;


end Behavioral;

