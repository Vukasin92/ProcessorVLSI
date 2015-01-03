library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity al_unit is
	port (
		in_data : in alu_in_data_t;
		in_control : in alu_in_control_t;
		
		out_data : out alu_out_data_t;
		out_control : out alu_out_control_t
	);
end entity al_unit;

architecture RTL of al_unit is
	signal output_data : alu_out_data_t;
	signal output_control : alu_out_control_t;
	function func(data : alu_in_data_t) return word_t is
		variable ret : word_t;
		variable a, b : word_t;
	begin
		--TODO : implement all alu functions
		a := data.operands.reg_a;
		
		case data.instruction.kind is
		when DPR => 
			b := data.operands.reg_b;
		when DPI =>
			b := data.operands.imm;
		when others => 
			report "Wrong addressing mode in ALU." severity error;
		end case;
		
		case data.instruction.op is
			when ADD =>
				ret := std_logic_vector(unsigned(a)+unsigned(b));
			when SUB => 
				ret := std_logic_vector(unsigned(a)-unsigned(b));
			when others => 
				null;
		end case;
		return ret;
	end function func;
begin
	comb:process (in_data, in_control, output_data, output_control) is
	begin
		out_data <= output_data;
		out_control <= output_control;
		
		output_data.alu_out <= func(in_data);
		output_data.write_address <= in_data.instruction.reg_dst;
		output_control.wr <= '0';
		output_control.busy <= '0';
		if (in_control.enable = '1' and in_control.commit = '1') then
			output_control.wr <= '1';
			output_control.busy <= '1';
		end if;
	end process comb;
end architecture RTL;
