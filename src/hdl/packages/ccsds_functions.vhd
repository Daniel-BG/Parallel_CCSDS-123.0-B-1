--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

package ccsds_functions is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--
	function bits(number: integer) return integer;
	function signexp(number: integer) return integer;
	function minimum(a: integer; b: integer) return integer;
	function maximum(a: integer; b: integer) return integer;
	function clip (number: integer; lower: integer; upper: integer) return integer;
	function mod_r (number: integer; modulus: integer) return integer;
	function sign_plus (a: integer) return integer;
	function floor_div (dividend: integer; divisor: integer) return integer;
	procedure next_integer(variable seed1, seed2:inout positive; int_range:in integer; variable result:out integer);

end ccsds_functions;

package body ccsds_functions is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

	procedure next_integer(variable seed1, seed2:inout positive; int_range:in integer; variable result:out integer) is
		variable rand: real;								-- random real-number value in range 0 to 1.0  
	begin
		--generate random number (0.0-1.0)
		uniform(seed1, seed2, rand);  
		--if int_range is positive, return number from 0 to int_range - 1
		--if it is negative, return from int_range to -int_range - 1
		if int_range > 0 then
			result := integer(rand*real(int_range - 1));
		else
			result := integer(rand*real(-int_range*2 - 1)) + int_range;
		end if;
	end procedure next_integer;


	function sign_plus (a: integer) return integer is
	begin
		if a < 0 then
			return -1;
		else
			return 1;
		end if;
	end sign_plus;
	
	function floor_div (dividend: integer; divisor: integer) return integer is
	begin
		if dividend >= 0 then
			return dividend / divisor;
		else
			return -((- dividend + divisor - 1) / divisor);
		end if;
	end floor_div;
	
	function mod_r (number: integer; modulus: integer) return integer is
	begin
		return ((number + 2**(modulus - 1)) mod 2**modulus) - 2**(modulus - 1);
	end mod_r;
	
	function clip (number: integer; lower: integer; upper: integer) return integer is
	begin
		if number < lower then
			return lower;
		elsif number > upper then
			return upper;
		else
			return number;
		end if;
	end clip;
	
	function minimum(a: integer; b: integer) return integer is
	begin
		if a < b then
			return a;
		else
			return b;
		end if;
	end minimum;
	
	function maximum(a: integer; b: integer) return integer is
	begin
		if a > b then
			return a;
		else
			return b;
		end if;
	end maximum;
	
	function signexp(number: integer) return integer is
	begin
		if number mod 2 = 0 then
			return 1;
		else
			return -1;
		end if;
	end signexp;
	
	function bits(number: integer) return integer is
	begin
		return integer(ceil(log2(real(number + 1))));
	end bits;
---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end ccsds_functions;
