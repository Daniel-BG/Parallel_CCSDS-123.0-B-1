----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:20:41 04/23/2016 
-- Design Name: 
-- Module Name:    sample_storage_neighbor - Behavioral 
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
use work.ccsds_types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sample_storage_neighbor is
	generic (
		LINEAR_STORAGE_AS_SHIFT_REG: boolean := false;
		QUADRIC_STORAGE_AS_SHIFT_REG: boolean := false;
		X_MAX: integer := 200;
		Z_MAX: integer := 200;
		D: integer := 16;
		ENCODING: encoding_order := BAND_SEQUENTIAL
	);
	port(
		clk, enable: in std_logic;
		sample: in unsigned(D - 1 downto 0);
		sample_west, sample_northwest, sample_north, sample_northeast:
			out unsigned(D - 1 downto 0)
	);
end sample_storage_neighbor;

architecture Behavioral of sample_storage_neighbor is

begin
	
		gen_bsq: if ENCODING = BAND_SEQUENTIAL generate
			sample_strg_bsq: entity work.sample_storage_sequential_neighbor
				generic map(LINEAR_STORAGE_AS_SHIFT_REG, X_MAX, D)
				port map(clk, enable, sample, sample_west, sample_northwest, sample_north, sample_northeast);
		end generate;

		gen_bip: if ENCODING = BAND_INTERLEAVED_PIXEL generate
			sample_strg_bip: entity work.sample_storage_interleaved_pixel_neighbor
				generic map(LINEAR_STORAGE_AS_SHIFT_REG, QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Z_MAX, D)
				port map(clk, enable, sample, sample_west, sample_northwest, sample_north, sample_northeast);
		end generate;
		
		gen_bil: if ENCODING = BAND_INTERLEAVED_LINE generate
			sample_strg_bil: entity work.sample_storage_interleaved_line_neighbor
				generic map(QUADRIC_STORAGE_AS_SHIFT_REG, X_MAX, Z_MAX, D)
				port map(clk, enable, sample, sample_west, sample_northwest, sample_north, sample_northeast);
		end generate;

end Behavioral;

