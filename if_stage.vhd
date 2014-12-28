library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity if_stage is
	port(
		in_clk     : in  std_logic;
		in_rst     : in  std_logic;

		in_data    : in  if_in_data_t;
		in_control : in  if_in_control_t;

		out_data   : out if_out_data_t
	);
end entity if_stage;

architecture RTL of if_stage is
	type register_t is record
		pc : address_t;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : if_out_data_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		ret.pc := (others => '0');
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
	
	out_data <= output_data;
	
	comb:process (register_reg, in_data, in_control) is
	begin
		register_next <= register_reg;
		
		for i in output_data.instructions'range loop
			output_data.instructions(i).pc <= 
				unsigned_add(register_reg.pc, i);
			output_data.instructions(i).valid <= '1';
		end loop;
		register_next.pc <= unsigned_add(register_reg.pc, ISSUE_WIDTH);
		
		if (in_control.jump = '1') then
			register_next.pc <= in_data.jump_pc;
			for i in output_data.instructions'range loop
				output_data.instructions(i).valid <= '0';
			end loop;
		elsif (in_control.stall = '1') then
			register_next <= register_reg;
		end if;
	end process comb;
				
end architecture RTL;
