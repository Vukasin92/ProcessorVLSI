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
		enable : std_logic;
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
		ret.enable := '0';
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
	begin
		out_data <= output_data;
		out_control <= output_control;
		out_data_mem <= output_data_mem;
		out_control_mem <= output_control_mem;
		register_next <= register_reg;
		
		output_control_mem.rd <= '0';
		output_control_mem.wr <= '0';
		output_data_mem.addr <= (others => '0');
		output_data_mem.data <= (others => '0');
		
		output_control.is_load <= '0';
		output_control.busy <= '0';
		output_control.wr <= '0';
		
		output_data.reg_number <= in_data.instruction.reg_dst;
		output_data.reg_value <= (others => '0');
		
		if (in_control_mem.fc = '1') then
			output_control.busy <= '0';
			register_next.enable <= '0';
			if (in_control.commit = '1') then
				if (in_data.instruction.op = LOAD) then
					output_control.wr <= '1';
					output_data.reg_value <= in_data_mem;
					output_control_mem.rd <= '0';
				elsif (in_data.instruction.op = STORE) then
					output_control_mem.wr <= '0';
				else
					report "Wrong instruction in LOAD/STORE Unit about to commit." severity error;
				end if;
			end if;
		end if;
		
		if (in_control.enable = '1' or register_reg.enable = '1') then
			output_data_mem.addr <= in_data.operand.reg_a;
			output_data_mem.data <= in_data.operand.reg_c;
			output_data.reg_number <= in_data.instruction.reg_dst;
			
			if (in_data.instruction.op = LOAD) then
				output_control_mem.rd <= '1';
				output_control.is_load <= '1';
			elsif (in_data.instruction.op = STORE) then
				output_control_mem.wr <= '1';
				output_control.is_load <= '0';
			else
				report "Wrong instruction in LOAD/STORE Unit." severity error;
			end if;
			
			output_control.busy <= '1';
			if (in_data.instruction.op = LOAD) then
				output_control.is_load <= '1'; --TODO: when checking on hazzard check if busy, if is_load, and reg_number!
			end if;
		end if;
	end process comb;
end architecture RTL;
