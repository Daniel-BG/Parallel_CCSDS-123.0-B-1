----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:53:20 03/09/2017 
-- Design Name: 
-- Module Name:    ccsds_controller - Behavioral 
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
use work.ccsds_constants.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ccsds_controller is
	port (
		clk, rst: in std_logic;
		input_queue_empty, output_queue_full: in std_logic;
		input_queue_out: std_logic_vector(C*D-1 downto 0);
		input_queue_rdenb, output_queue_wrenb: out std_logic;
		output_queue_in: out std_logic_vector(C*CCSDS_DATA_WIDTH-1 downto 0);
		ccsds_out_done: out boolean
	);
end ccsds_controller;

architecture Behavioral of ccsds_controller is
	--CCSDS I/O PROCESSING SIGNALS
	type MIDDLE_CNTL_SM_TYPE is (IDLE, PROCESSING_DATA, SAVING_DATA);
	signal middle_cntl_ns, middle_cntl_cs: MIDDLE_CNTL_SM_TYPE;
	--COUNTER PROCESS SIGNALS
	signal processing, data_processed: std_logic;
	constant COUNTER_MAX: natural := 7;
	signal counter: natural range 0 to COUNTER_MAX;
	--CCSDS SIGNALS
	signal ccsds_enb: std_logic;
	signal ccsds_cw: unsigned(D downto 0);
	signal ccsds_cwl: unsigned(D_PLUS_ONE_LOG-1 downto 0);
	signal ccsds_z: unsigned(U_MAX_LOG-1 downto 0);
	
	signal ccsds_p_cw: std_logic_vector(C*(D+1)-1 downto 0);
	signal ccsds_p_cwl: std_logic_vector(C*D_PLUS_ONE_LOG-1 downto 0);
	signal ccsds_p_z: std_logic_vector(C*U_MAX_LOG-1 downto 0);
	
begin
	
	gen_c1: if C = 1 generate
	
		output_queue_in(D downto 0) <= std_logic_vector(ccsds_cw);
		output_queue_in(D+D_PLUS_ONE_LOG downto D+1) <= std_logic_vector(ccsds_cwl);
		output_queue_in(CCSDS_DATA_WIDTH-1 downto D+D_PLUS_ONE_LOG+1) <= std_logic_vector(ccsds_z);
		
		CCSDS_ALGORITHM: entity work.compressor
			port map (
				clk, rst, ccsds_enb,
				unsigned(input_queue_out),
				ccsds_cw,
				ccsds_z,
				ccsds_cwl,
				ccsds_out_done
			);
	end generate;
	
	gen_c2: if C /= 1 generate
		CCSDS_PARALLEL_ALGORITHM: entity work.accelerated_compressor
			port map (
				clk, rst, ccsds_enb,
				input_queue_out,
				ccsds_p_cw,
				ccsds_p_z,
				ccsds_p_cwl,
				ccsds_out_done
			);
			
		gen_output: for i in 0 to C - 1 generate
			output_queue_in((i*CCSDS_DATA_WIDTH)+D downto (i*CCSDS_DATA_WIDTH)) 
				<= ccsds_p_cw((i+1)*(D+1)-1 downto i*(D+1));
			output_queue_in((i*CCSDS_DATA_WIDTH)+D+D_PLUS_ONE_LOG downto (i*CCSDS_DATA_WIDTH)+D+1) 
				<= ccsds_p_cwl((i+1)*(D_PLUS_ONE_LOG)-1 downto i*(D_PLUS_ONE_LOG));
			output_queue_in((i*CCSDS_DATA_WIDTH)+CCSDS_DATA_WIDTH-1 downto (i*CCSDS_DATA_WIDTH)+D+D_PLUS_ONE_LOG+1) 
				<= ccsds_p_z((i+1)*(U_MAX_LOG)-1 downto i*(U_MAX_LOG));
		end generate;
	end generate;

	--update process
	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				middle_cntl_cs <= IDLE;
			else
				middle_cntl_cs <= middle_cntl_ns;
			end if;
		end if;
	end process;

	--counter process to control the number of cycles ccsds spends on calculations
	upd_counter: process(clk)
	begin
		if rising_edge(clk) then
			if processing = '0' then
				counter <= 0;
			elsif counter < COUNTER_MAX then
				counter <= counter + 1;
			end if;
		end if;
	end process;
	--flag to check whether the counter reached its limit
	data_processed <= '1' when counter = COUNTER_MAX else '0';


	MIDDLE_CNTL_COMB: process (middle_cntl_cs, input_queue_empty, data_processed, output_queue_full) is
	begin

		-- set defaults
		input_queue_rdenb		<= '0';
		middle_cntl_ns			<= middle_cntl_cs;
		processing				<= '0';
		ccsds_enb				<= '0';
		output_queue_wrenb	<= '0';


		case middle_cntl_cs is
			--waiting for data to be available
			when IDLE =>
				if input_queue_empty = '0' then
					input_queue_rdenb <= '1';
					middle_cntl_ns <= PROCESSING_DATA;
				end if;
			--processing the data
			when PROCESSING_DATA =>
				processing <= '1';
				-- if data has been processed and we have room on the output fifo
				if data_processed = '1' and output_queue_full = '0' then
					middle_cntl_ns  <= SAVING_DATA;
					output_queue_wrenb <= '1';
				end if;
			--extra state to make sure propagation through the circuit is correct
			when SAVING_DATA => 
				middle_cntl_ns  <= IDLE;
				ccsds_enb <= '1';
		end case;
	end process;


end Behavioral;

