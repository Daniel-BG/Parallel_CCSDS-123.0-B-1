----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:10:52 04/23/2016 
-- Design Name: 
-- Module Name:    difference_storage - Behavioral 
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
use work.ccsds_types.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity difference_storage is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		Y_MAX: integer := 200;
		D: integer := 16; 
		P: integer := 3;
		ENCODING: encoding_order := BAND_SEQUENTIAL
	);
	port(
		clk, enable: in std_logic;
		--difference that should be stored, pertaining to band z, sample t
		diff: in signed(D + 2 downto 0);
		--previous differences ranging from (z - P*, t) to (z - 1, P)
		out_diff: out std_logic_vector(P*(D + 3) - 1 downto 0)
	);
end difference_storage;

architecture Behavioral of difference_storage is

begin
	diff_bil: if ENCODING = BAND_INTERLEAVED_LINE generate
		diff_strg_bil: entity work.difference_storage_interleaved_line
			generic map(LINEAR_STORAGE_AS_SHIFT_REG, X_MAX, D, P)
			port map(clk, enable, diff, out_diff);
	end generate;

	diff_bip: if ENCODING = BAND_INTERLEAVED_PIXEL generate
		diff_strg_bip: entity work.difference_storage_interleaved_pixel
			generic map(D, P)
			port map(clk, enable, diff, out_diff);
	end generate;
	
	diff_seq: if ENCODING = BAND_SEQUENTIAL generate
		diff_strg_seq: entity work.difference_storage_sequential
			generic map(QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Y_MAX, D, P)
			port map(clk, enable, diff, out_diff);
	end generate;

end Behavioral;

