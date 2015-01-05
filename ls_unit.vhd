library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity ls_unit is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_control : in ls_unit_in_control_t;
		in_data : in ls_unit_in_data_t;
		in_data_mem : in word_t;
		in_control_mem : in ls_unit_in_control_mem_t;
		
		out_control : out ls_unit_out_control_t;
		out_data : out ls_unit_out_data_t;
		out_data_mem : out ls_unit_out_data_mem_t;
		out_control_mem : out ls_unit_out_control_mem_t
	);
end entity ls_unit;

architecture RTL of ls_unit is
	type register_t is record
		input_control : ls_unit_in_control_t;
		output_control_mem : ls_unit_out_control_mem_t;
		input_data : ls_unit_in_data_t;
		output_data_mem : ls_unit_out_data_mem_t;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : ls_unit_out_data_t;
	signal output_data_mem : ls_unit_out_data_mem_t;
	signal output_control : ls_unit_out_control_t;
	signal output_control_mem : ls_unit_out_control_mem_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		ret.input_control.enable := '0';
		ret.input_control.commit := '0';
		ret.input_control.selectInstruction := '0';
		ret.output_control_mem.rd := '0';
		ret.output_control_mem.wr := '0';
		ret.output_data_mem.addr := (others => '0');
		ret.output_data_mem.data := (others => '0');
		for i in ret.input_data.instructions'range loop
			ret.input_data.instructions(i).word := (others => '0');--IS_LOAD!
		end loop;
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
	
	comb:process (in_control, in_data, in_data_mem, in_control_mem, register_reg, output_control, output_control_mem, output_data, output_data_mem) is
		variable instructionIndex : integer;
	begin
		out_data <= output_data;
		out_control <= output_control;
		out_data_mem <= output_data_mem;
		out_control_mem <= output_control_mem;
		register_next <= register_reg;
		
		
		output_control.is_load <= '0';
		output_control.busy <= '0';
		output_control.wr <= '0';
		
		
		if (register_reg.input_control.selectInstruction = '0') then
			instructionIndex := 0;
		else
			instructionIndex := 1;
		end if;
		
		output_data.reg_number <= register_reg.input_data.instructions(instructionIndex).reg_dst;
		output_data.reg_value <= (others => '0');
		
		output_data_mem <= register_reg.output_data_mem;
		output_control_mem <= register_reg.output_control_mem;
		
		if (in_control.enable = '1' or register_reg.input_control.enable = '1') then
			output_control.busy <= '1';
			if (register_reg.input_data.instructions(instructionIndex).op = LOAD) then
				output_control.is_load <= '1'; --TODO: when checking on hazzard check if busy, if is_load, and reg_number!
			end if;
		end if;
		
		if (in_control_mem.fc = '1') then
			output_control.busy <= '0';
			register_next.input_control.enable <= '0';
			register_next.input_control.commit <= '0';
			if (register_reg.input_control.commit = '1') then
				if (register_reg.input_data.instructions(instructionIndex).op = LOAD) then
					output_control.wr <= '1';
					output_data.reg_value <= in_data_mem;
					register_next.output_control_mem.rd <= '0';
				elsif (register_reg.input_data.instructions(instructionIndex).op = STORE) then
					register_next.output_control_mem.wr <= '0';
				else
					report "Wrong instruction in LOAD/STORE Unit about to commit." severity error;
				end if;
			end if;
		end if;
		
		if (in_control.enable = '1') then
			register_next.input_control <= in_control;
			register_next.input_data <= in_data;
			register_next.output_data_mem.addr <= in_data.operands(instructionIndex).reg_a;
			register_next.output_data_mem.data <= in_data.operands(instructionIndex).reg_c;
			output_data.reg_number <= in_data.instructions(instructionIndex).reg_dst;
			
			if (in_data.instructions(instructionIndex).op = LOAD) then
				register_next.output_control_mem.rd <= '1';
				output_control.is_load <= '1';
			elsif (in_data.instructions(instructionIndex).op = STORE) then
				register_next.output_control_mem.wr <= '1';
				output_control.is_load <= '0';
			else
				report "Wrong instruction in LOAD/STORE Unit." severity error;
			end if;
		end if;
	end process comb;
end architecture RTL;
