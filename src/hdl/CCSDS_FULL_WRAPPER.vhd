----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:12:15 03/07/2017 
-- Design Name: 
-- Module Name:    CCSDS_FULL_WRAPPER - Behavioral 
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

entity CCSDS_FULL_WRAPPER is
	generic(
		KHZ_FREQUENCY: integer := 200000;
		BAUDS: integer := 9600;
		CCSDS_INPUT_BYTES: integer := 2;
		QUEUE_SIZE: integer := 32
	);
	port(
		clk_in, sw2, rx: in std_logic;
		tx: out std_logic;
		LEDs: out std_logic_vector(7 downto 0)
	);
end CCSDS_FULL_WRAPPER;

architecture Behavioral of CCSDS_FULL_WRAPPER is
	--CONSTANTS
		--constant CCSDS_DATA_WIDTH: integer := D+1+U_MAX_LOG+D_PLUS_ONE_LOG;
		
	--SHARED SIGNALS
		signal clk, rst: std_logic;
		
	--temp testing
		signal out_byte: std_logic_vector(7 downto 0);


	--COMPONENT SIGNALS
		--FIFO IN (AFTER UART)
		signal fifoin_wren, fifoin_readen, fifoin_empty, fifoin_full: std_logic;
		signal fifoin_in, fifoin_out: std_logic_vector(7 downto 0);
		--FIFO FOR PARALLEL DATA
		signal fifose_wren, fifose_readen, fifose_empty, fifose_full: std_logic;
		signal fifose_in, fifose_out: std_logic_vector(C*CCSDS_INPUT_BYTES*8-1 downto 0);
		--CCSDS ALGORITHM OUTPUTS
		signal ccsds_output_queue_full, ccsds_output_queue_wrenb: std_logic;
		signal ccsds_output_queue_in: std_logic_vector(CCSDS_DATA_WIDTH*C-1 downto 0);
			--FIFO FOR SERIALIZED OUTPUT: ONLY SYNTHESIZED FOR PARALLEL STUFF
			signal fifopa_wren, fifopa_readen, fifopa_empty, fifopa_full: std_logic;
			signal fifopa_in, fifopa_out: std_logic_vector(C*CCSDS_DATA_WIDTH-1 downto 0);
		--FIFO FOR CCSDS OUTPUT
		signal fifopc_wren, fifopc_readen, fifopc_empty, fifopc_full: std_logic;
		signal fifopc_in, fifopc_out: std_logic_vector(CCSDS_DATA_WIDTH-1 downto 0);
		--FIFO FOR BYTEIZER
		signal fifoby_wren, fifoby_readen, fifoby_empty, fifoby_full: std_logic;
		signal fifoby_in, fifoby_out: std_logic_vector(BUF_LEN + BUF_LEN_LOG - 4 downto 0);
		--FIFO FOR UART OUTPUT
		signal fifoout_wren, fifoout_readen, fifoout_empty, fifoout_full: std_logic;
		signal fifoout_in, fifoout_out: std_logic_vector(7 downto 0);

begin

	--shared things:
	    --virtex 4
		--rst <= '1' when sw2 = '0' else '0';
		--virtex 7
		rst <= '1' when sw2 = '1' else '0';
		
		--CLOCK_DIVIDER: entity work.clk_divider
		--	port map(clk_in, rst, clk);
		clk <= clk_in;
		
		--LEDs(9) <= '1';
		--LEDs(8) <= rst;
		LEDs(7) <= fifoin_empty;
		LEDs(6) <= fifose_empty;
		LEDs(5) <= fifopc_empty;
		LEDs(4) <= fifoout_empty;
		LEDs(3) <= fifoin_full;
		LEDs(2) <= fifose_full;
		LEDs(1) <= fifopc_full;
		LEDs(0) <= rst;
		
	
	--UART INPUT CONTROLLER
		INPUT_CONTROL: entity work.uart_rx_nandland
			generic map (
				g_CLKS_PER_BIT => (KHZ_FREQUENCY*1000)/BAUDS
			)
			port map (
				i_Clk => clk,
				i_RX_Serial => rx,
				o_RX_DV => fifoin_wren,
				o_RX_Byte => fifoin_in
			);
			
	--FIFO that gets inputs from the UART
		FIFO_IN: entity work.STD_FIFO
			generic map (
				DATA_WIDTH => 8, FIFO_DEPTH => QUEUE_SIZE
			)
			port map (
				clk => clk, rst => rst,
				WriteEn	=> fifoin_wren,
				datain	=> fifoin_in,
				ReadEn	=> fifoin_readen,
				dataout	=> fifoin_out,
				Empty		=> fifoin_empty,
				Full		=> fifoin_full
			);
			
	----FIFO_IN TO SE2PA TO FIFO_SE (all must be removed in case of D=8 bit)
		SE2PA_CONTROL: entity work.se2pa_controller
			generic map (
				 IN_WIDTH => 8, PARALLEL_SIZE => CCSDS_INPUT_BYTES*C
			)
			port map (
				clk => clk,	rst => rst,
				input_queue_empty => fifoin_empty,
				output_queue_full => fifose_full,
				input_queue_out => fifoin_out,
				input_queue_rdenb => fifoin_readen,
				output_queue_wrenb => fifose_wren,
				output_queue_in => fifose_in
			);
			
			
	--FIFO for the joined data
		FIFO_SE2PA: entity work.STD_FIFO
			generic map (
				DATA_WIDTH => C*CCSDS_INPUT_BYTES*8, FIFO_DEPTH => QUEUE_SIZE
			)
			port map (
				clk => clk, rst => rst,
				WriteEn	=> fifose_wren,
				datain	=> fifose_in,
				ReadEn	=> fifose_readen,
				dataout	=> fifose_out,
				Empty		=> fifose_empty,
				Full		=> fifose_full
			);
			
	--CCSDS CONTROLLER
		CCSDS_CONTROL: entity work.ccsds_controller
			port map (
				clk => clk, rst => rst,
				input_queue_empty => fifose_empty,
				output_queue_full => ccsds_output_queue_full,
				input_queue_out   => fifose_out,
				input_queue_rdenb => fifose_readen,
				output_queue_wrenb=> ccsds_output_queue_wrenb,
				output_queue_in   => ccsds_output_queue_in,
				ccsds_out_done    => open
			);
			
		gen_ccsds_connections_c1: if C = 1 generate
			ccsds_output_queue_full <= fifopc_full;
			fifopc_wren <= ccsds_output_queue_wrenb;
			fifopc_in <= ccsds_output_queue_in;
		end generate;
		
		gen_ccsds_connections_cx: if C /= 1 generate
			ccsds_output_queue_full <= fifopa_full;
			fifopa_wren <= ccsds_output_queue_wrenb;
			fifopa_in <= ccsds_output_queue_in;
		end generate;
	
	--HERE GOES THE PARALLEL STUFF
		gen_parallel_stuff: if C /= 1 generate
			FIFO_PA2SE: entity work.STD_FIFO
				generic map (
					DATA_WIDTH => C*CCSDS_DATA_WIDTH, FIFO_DEPTH => QUEUE_SIZE
				)
				port map (
					clk => clk, rst => rst,
					WriteEn	=> fifopa_wren,
					datain	=> fifopa_in,
					ReadEn	=> fifopa_readen,
					dataout	=> fifopa_out,
					Empty		=> fifopa_empty,
					Full		=> fifopa_full
				);
		
			PA2SE_CONTROL: entity work.pa2se_controller
				generic map (
					OUT_WIDTH => CCSDS_DATA_WIDTH,
					PARALLEL_SIZE => C
				)
				port map (
					clk => clk, rst => rst,
					input_queue_empty => fifopa_empty,
					output_queue_full => fifopc_full,
					input_queue_out   => fifopa_out,
					input_queue_rdenb => fifopa_readen,
					output_queue_wrenb=> fifopc_wren,
					output_queue_in   => fifopc_in
				);
			
		end generate;

			
	--FIFO prior to coding
		FIFO_PRECODE: entity work.STD_FIFO
			generic map (
				DATA_WIDTH => CCSDS_DATA_WIDTH, FIFO_DEPTH => QUEUE_SIZE
			)
			port map (
				clk => clk, rst => rst,
				WriteEn	=> fifopc_wren,
				datain	=> fifopc_in,
				ReadEn	=> fifopc_readen,
				dataout	=> fifopc_out,
				Empty		=> fifopc_empty,
				Full		=> fifopc_full
			);
			
	--FIFO_PA TO FIFO_OUT
--		CODING_CONTROL: entity work.coding_controller
--			generic map (
--				U_MAX => U_MAX, D => D,
--				U_MAX_LOG => U_MAX_LOG,
--				D_PLUS_ONE_LOG => D_PLUS_ONE_LOG
--			)
--			port map (
--				clk => clk, rst => rst,
--				input_queue_empty => fifopc_empty,
--				output_queue_full => fifoout_full,
--				input_zeros => fifopc_out(CCSDS_DATA_WIDTH-1 downto D+D_PLUS_ONE_LOG+1),
--				input_codelength => fifopc_out(D+D_PLUS_ONE_LOG downto D+1),
--				input_code => fifopc_out(D downto 0),
--				input_queue_rdenb => fifopc_readen,
--				output_queue_wrenb => fifoout_wren,
--				output_byte => fifoout_in
--			);

		CODING_BYTEIZER_CONTROLLER: entity work.coding_to_fixed_length_controller
			generic map (
				D => D, U_MAX_LOG => U_MAX_LOG,
				D_PLUS_ONE_LOG => D_PLUS_ONE_LOG,
				BUF_LEN => BUF_LEN,
				BUF_LEN_LOG => BUF_LEN_LOG
			)
			port map (
				clk => clk, rst => rst,
				input_queue_empty => fifopc_empty,
				output_queue_full => fifoby_full,
				input_zeros => fifopc_out(CCSDS_DATA_WIDTH-1 downto D+D_PLUS_ONE_LOG+1),
				input_codelength => fifopc_out(D+D_PLUS_ONE_LOG downto D+1),
				input_code => fifopc_out(D downto 0),
				input_queue_rdenb => fifopc_readen,
				output_queue_wrenb => fifoby_wren,
				output_buffer => fifoby_in(BUF_LEN + BUF_LEN_LOG - 4 downto BUF_LEN_LOG - 3),
				output_buff_len => fifoby_in(BUF_LEN_LOG - 4 downto 0)
			);


		FIFO_BYTEIZER: entity work.STD_FIFO
			generic map (
				DATA_WIDTH => BUF_LEN + BUF_LEN_LOG - 3, FIFO_DEPTH => QUEUE_SIZE
			)
			port map (
				clk => clk, rst => rst,
				WriteEn	=> fifoby_wren,
				datain	=> fifoby_in,
				ReadEn	=> fifoby_readen,
				dataout	=> fifoby_out,
				Empty		=> fifoby_empty,
				Full		=> fifoby_full
			);
				
		BYTEIZER: entity work.byte_output_controller
			generic map (
				BUF_LEN => BUF_LEN,
				BUF_LEN_LOG => BUF_LEN_LOG
			)
			port map (
				clk => clk, rst => rst,
				input_queue_empty => fifoby_empty,
				output_queue_full => fifoout_full,
				input_buffer => fifoby_out(BUF_LEN + BUF_LEN_LOG - 4 downto BUF_LEN_LOG - 3),
				input_buff_len => fifoby_out(BUF_LEN_LOG - 4 downto 0),
				input_queue_rdenb => fifoby_readen,
				output_queue_wrenb => fifoout_wren,
				output_byte => fifoout_in
			);

			
	--FIFO for storing the data that has to be sent back to the UART after coding it
	--(done below)
		FIFO_OUT: entity work.STD_FIFO
			generic map (
				DATA_WIDTH => 8, FIFO_DEPTH => QUEUE_SIZE
			)
			port map (
				clk => clk, rst => rst,
				WriteEn	=> fifoout_wren,
				datain	=> fifoout_in,
				ReadEn	=> fifoout_readen,
				dataout	=> fifoout_out,
				Empty		=> fifoout_empty,
				Full		=> fifoout_full
			);
						
						


	--WRITE FROM FIFO OUT TO UART
		OUTPUT_CONTROL: entity work.output_controller
			generic map (
				g_CLKS_PER_BIT => (KHZ_FREQUENCY*1000)/BAUDS
			)
			port map (
				clk => clk, rst => rst,
				input_queue_empty => fifoout_empty,-- fifoby_empty, --
				input_queue_out => fifoout_out,--fifoby_out(58 downto 51), --
				input_queue_rdenb => fifoout_readen, --fifoby_readen, --
				output_tx => tx
			);

		
		

end Behavioral;

