----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:16:45 03/09/2017 
-- Design Name: 
-- Module Name:    output_controller - Behavioral 
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

entity output_controller is
	generic (
		g_CLKS_PER_BIT: integer := 87
	);
	port (
		clk, rst: in std_logic;
		input_queue_empty: in std_logic;
		input_queue_out: in std_logic_vector(7 downto 0);
		input_queue_rdenb: out std_logic;
		output_tx: out std_logic
	);
end output_controller;

architecture Behavioral of output_controller is
	--OUTPUT PROCESS SIGNALS
	type OUTPUT_CNTL_SM_TYPE is (IDLE, OUT_READY, UART_SENDING);
	signal state_send_back_ns, state_send_back_cs: OUTPUT_CNTL_SM_TYPE;
	--UART
	signal uart_send: std_logic;
	signal uart_txbusy, uart_done: std_logic;
begin

	--UART TRANSMITTER MODULE
	UART_TX: entity work.uart_tx_nandland
		generic map (
			g_CLKS_PER_BIT => g_CLKS_PER_BIT
		)
		port map (
			i_Clk => clk,
			i_TX_DV => uart_send,
			i_TX_Byte => input_queue_out,
			o_TX_Active => uart_txbusy,
			o_TX_Serial => output_tx,
			o_TX_Done => uart_done
		);

	--update process
	update: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_send_back_cs <= IDLE;
			else
				state_send_back_cs <= state_send_back_ns;
			end if;
		end if;
	end process;

	process_send_back: process(state_send_back_cs, input_queue_empty, uart_txbusy, uart_done)
	begin
	
		input_queue_rdenb <= '0';
		state_send_back_ns <= state_send_back_cs;
		uart_send <= '0';
	
		case state_send_back_cs is
			--idle state: waiting for data to be available
			when IDLE =>
				if input_queue_empty = '0' then
					input_queue_rdenb <= '1';
					state_send_back_ns <= OUT_READY;
				end if;
			--data has been read. waiting for UART to be ready
			when OUT_READY =>
				if uart_txbusy = '0' then
					uart_send <= '1';
					state_send_back_ns <= UART_SENDING;
				end if;
			--data is being sent. waiting for UART to be free
			when UART_SENDING =>
				if uart_done = '1' then
					state_send_back_ns <= IDLE;
				end if;			
		end case;
	
	end process process_send_back;


end Behavioral;

