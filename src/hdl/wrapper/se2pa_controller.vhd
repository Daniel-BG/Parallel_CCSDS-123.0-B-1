----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:43:47 03/09/2017 
-- Design Name: 
-- Module Name:    se2pa_controller - Behavioral 
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

entity se2pa_controller is
	generic	(
		IN_WIDTH: integer := 8;
		PARALLEL_SIZE: integer := 2
	);
	port (
		clk, rst: in std_logic;
		input_queue_empty, output_queue_full: in std_logic;
		input_queue_out: in std_logic_vector(IN_WIDTH-1 downto 0);
		input_queue_rdenb, output_queue_wrenb: out std_logic;
		output_queue_in: out std_logic_vector(IN_WIDTH*PARALLEL_SIZE-1 downto 0)
	);
end se2pa_controller;

architecture Behavioral of se2pa_controller is
	--SERIAL TO PARALLEL SIGNALS
	type INPUT_CNTL_SM_TYPE is (SLEEP, WAITING, STREAMING);
	signal se2pa_conv_state_ns, se2pa_conv_state_cs: INPUT_CNTL_SM_TYPE;
	
	--SERIAL TO PARALLEL CODER
	signal se2pa_enb, se2pa_done: std_logic;
begin


	--CONVERTER to join multiple inputs into 1 (UART inputs 8 bits, might need more)	
	SERIAL_TO_PARALLEL: entity work.se2pa
		generic map (
			IN_WIDTH => IN_WIDTH, PARALLEL_SIZE => PARALLEL_SIZE
		)
		port map (
			clk => clk, rst => rst,
			enb => se2pa_enb,
			data_in => input_queue_out,
			data_out => output_queue_in,
			done => se2pa_done
		);

	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				se2pa_conv_state_cs <= SLEEP;
			else
				se2pa_conv_state_cs <= se2pa_conv_state_ns;
			end if;
		end if;
	end process;
		
		
			
    SE2PA_CNTL_COMB: process(se2pa_conv_state_cs, input_queue_empty, se2pa_done, output_queue_full) is
    begin
    
        -- set defaults
        input_queue_rdenb <= '0';
        se2pa_conv_state_ns  <= se2pa_conv_state_cs;
        se2pa_enb <= '0';
        output_queue_wrenb <= '0';
        
    
        case se2pa_conv_state_cs is
            --waiting for new data. this is separate from "waiting"
            --since the serial to parallel converter has "done" high
            --at this stage. This makes it so it is mandatory to 
            --parallelize the algorithm
            when SLEEP =>
                if input_queue_empty = '0' then
                    input_queue_rdenb <= '1';
                    se2pa_conv_state_ns  <= STREAMING;
                end if;
            --waiting for new data
            when WAITING =>
                --if the parallel buffer is filled, save it to the parallel
                --fifo and go to sleep
                if se2pa_done = '1' then
                    if output_queue_full = '0' then
                        output_queue_wrenb <= '1';
                        se2pa_conv_state_ns <= SLEEP;
                    end if;
                --if it is not full, then request a new value from the input queue
                else
                    if input_queue_empty = '0' then
                        input_queue_rdenb <= '1';
                        se2pa_conv_state_ns  <= STREAMING;
                    end if;
                end if;
            --save the value from the input queue to the serial to parallel converter,
            --then go to wait for the next value
            when STREAMING => 
                se2pa_enb <= '1';
                se2pa_conv_state_ns <= WAITING;
        end case;
    end process;
		
--	SE2PA_CNTL_COMB: process(se2pa_conv_state_cs, input_queue_empty, se2pa_done, output_queue_full) is
--    begin

--        -- set defaults
--        input_queue_rdenb <= '0';
--        se2pa_conv_state_ns  <= se2pa_conv_state_cs;
--        se2pa_enb <= '0';
--        output_queue_wrenb <= '0';
        

--        case se2pa_conv_state_cs is
--            --waiting for new data. this is separate from "waiting"
--            --since the serial to parallel converter has "done" high
--            --at this stage. This makes it so it is mandatory to 
--            --parallelize the algorithm
--            when SLEEP =>
--                if input_queue_empty = '0' then
--                    input_queue_rdenb <= '1';
--                    se2pa_conv_state_ns  <= STREAMING;
--                end if;
--            --waiting for new data
--            when WAITING =>
--                --if the parallel buffer is filled, save it to the parallel
--                --fifo and go to sleep
--                if se2pa_done = '1' then
--                    if output_queue_full = '0' then
--                        output_queue_wrenb <= '1';
--                        se2pa_conv_state_ns <= SLEEP;
--                    end if;
--                --if it is not full, then request a new value from the input queue
--                else
--                    if input_queue_empty = '0' then
--                        input_queue_rdenb <= '1';
--                        se2pa_conv_state_ns  <= STREAMING;
--                    end if;
--                end if;
--            --save the value from the input queue to the serial to parallel converter,
--            --then either immediately read the next value or wait if it is not present
--            when STREAMING =>
--                if se2pa_done = '1' then
--                    if output_queue_full = '0' then
--                        output_queue_wrenb <= '1';
--                        --does not need flush, save the data
--                        se2pa_enb <= '1';
--                        if input_queue_empty = '0' then
--                            input_queue_rdenb <= '1';
--                            se2pa_conv_state_ns <= STREAMING;
--                        else
--                            se2pa_conv_state_ns <= WAITING;
--                        end if;
--                    end if;
--                else
--                    --does not need flush, save the data
--                    se2pa_enb <= '1';
--                    if input_queue_empty = '0' then
--                        input_queue_rdenb <= '1';
--                        se2pa_conv_state_ns <= STREAMING;
--                    else
--                        se2pa_conv_state_ns <= WAITING;
--                    end if;
--                end if;
--        end case;
--    end process;

end Behavioral;

