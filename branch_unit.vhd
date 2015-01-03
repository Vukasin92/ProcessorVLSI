library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity branch_unit is
	port (
		in_clk : std_logic;
		in_rst : std_logic;
		
		in_data : in branch_in_data_t;
		in_control : in branch_in_control_t;
		
		out_data : out branch_out_data_t;
		out_control : out branch_out_control_t
	);
end entity branch_unit;

architecture RTL of branch_unit is
	type register_t is record
		instructionSelect : std_logic;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : branch_out_data_t;
	signal output_control : branch_out_control_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		ret.instructionSelect := '0';
		return ret;
	end function init;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (in_data, in_control, output_data, output_control, register_reg) is
		variable instructionIndex : integer;
	begin
		out_data <= output_data;
		out_control <= output_control;
		register_next <= register_reg;
		
		register_next.instructionSelect <= in_control.selectInstruction;
		
		if (register_reg.instructionSelect = '0') then
			instructionIndex := 0;
		else
			instructionIndex := 1;
		end if;
		output_data.jump_pc <= std_logic_vector(signed(in_data.instructions(instructionIndex).pc)+signed(in_data.operands(instructionIndex))); --TODO : consider if needed to add 2 more
		output_control.jump <= '0';
		output_control.busy <= '0';
		if (in_control.enable = '1' and in_control.commit = '1') then
			output_control.jump <= '1';
			output_control.busy <= '1';
		end if;
	end process comb;
end architecture RTL;
