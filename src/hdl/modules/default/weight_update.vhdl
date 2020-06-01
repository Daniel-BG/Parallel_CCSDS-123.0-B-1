library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;

use work.ccsds_constants.all;
		--V_MIN: integer := -3;
		--V_MAX: integer := 3;
		--T_INC: integer := 6;
		--T_WIDTH: integer := 8;
		--X_MAX: integer := 10;
		--D: integer := 16;
		--OMEGA: integer := 10;
		--RHO_WIDTH: integer := 6;
		--P_STAR: integer := 6;
		--R_WEIGHT: integer := 20

entity weight_update is
	generic (
		V_MIN: integer := V_MIN;
		V_MAX: integer := V_MAX;
		T_INC: integer := T_INC;
		T_WIDTH: integer := T_WIDTH;
		X_MAX: integer := X_MAX;
		D: integer := D;
		OMEGA: integer := OMEGA;
		RHO_WIDTH: integer := RHO_WIDTH;
		P_STAR: integer := P_STAR;
		R_WEIGHT: integer := R_WEIGHT
	);
	port (
		t: in unsigned(T_WIDTH - 1 downto 0);
		U_port: in std_logic_vector(P_STAR*(D + 3) - 1 downto 0);
		e: in signed(D + 1 downto 0);
		w_in_port: in std_logic_vector(P_STAR*(OMEGA + 3) - 1 downto 0);
		w_out_port: out std_logic_vector(P_STAR*(OMEGA + 3) - 1 downto 0)
	);
end weight_update;

architecture Behavioral of weight_update is
	
	signal rho, rho_clipped: signed(RHO_WIDTH - 1 downto 0);
	--length set to t_width + 1 otherwise it might not fit if T_MAX ~ 2**T_WIDTH - 1
	signal t_scaled: signed(T_WIDTH downto 0);
	
	
	type weight_vector_t is array(0 to P_STAR - 1) of signed((OMEGA + 3) - 1 downto 0); 
	type diff_vector_t is array(0 to P_STAR - 1) of signed((D + 3) - 1 downto 0); 
	--bigger size for intermediate calculations
	type weight_middle is array(0 to P_STAR - 1) of signed(R_WEIGHT - 1 downto 0); 
	
	signal w_in, w_out: weight_vector_t;
	signal weight_unclipped, diff_shifted, diff_signed: weight_middle;
	signal U: diff_vector_t;
begin

	assign_arrays:
		for i in 0 to P_STAR - 1 generate
			w_in(i) <= signed(w_in_port((OMEGA + 3)*(i + 1) - 1 downto (OMEGA + 3)*i));
			w_out_port((OMEGA + 3)*(i + 1) - 1 downto (OMEGA + 3)*i) <= std_logic_vector(w_out(i));
			U(i) <= signed(U_port((D + 3)*(i + 1) - 1 downto (D + 3)*i));
		end generate;
	
	t_scaled <= to_signed(V_MIN, t_scaled'length) + 
		shift_right(signed("0" & t) - to_signed(X_MAX, t_scaled'length), T_INC);
		
	rho_update: process (t_scaled)
	begin
		if to_integer(t_scaled) < V_MIN then
			rho_clipped <= to_signed(V_MIN, rho_clipped'length);
		elsif to_integer(t_scaled) > V_MAX then
			rho_clipped <= to_signed(V_MAX, rho_clipped'length);
		else
			rho_clipped <= resize(t_scaled, rho_clipped'length);
		end if;
	end process;
	
	rho <= rho_clipped + to_signed(D - OMEGA, rho'length);
	


	weight_updating:
		for i in 0 to P_STAR - 1 generate
			diff_signed(i) <=
				resize(U(i), R_WEIGHT)
					when to_integer(e) >= 0 else
				resize(-U(i), R_WEIGHT);
		
			diff_shifted(i) <= 
				shift_right(diff_signed(i), to_integer(rho))
					when rho >= 0 else
				shift_left(diff_signed(i), to_integer(-rho));
		
			weight_unclipped(i) <= resize(w_in(i), R_WEIGHT) + shift_right(1 + diff_shifted(i), 1);

				
			-- -2**(OMEGA + 2) = WMIN
			-- 2**(OMEGA + 2) - 1 = WMAX
			w_out(i) <= to_signed(-(2**(OMEGA + 2)), w_out(i)'length) 
				when to_integer(weight_unclipped(i)) < -(2**(OMEGA + 2))
				else to_signed(2**(OMEGA + 2) - 1, w_out(i)'length) 
				when to_integer(weight_unclipped(i)) > 2**(OMEGA + 2) - 1
				else resize(weight_unclipped(i), w_out(i)'length);
		end generate;
	
end Behavioral;