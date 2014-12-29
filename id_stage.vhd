library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity id_stage is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in id_in_data_t;
		in_control : in id_in_control_t;
		in_mem : in word_array_t;
		
		out_data : out id_out_data_t;
		out_mem : out address_array_t
	);
end entity id_stage;

architecture RTL of id_stage is
	type register_t is record
		instructions : undecoded_instruction_array_t;
		late_instructions : word_array_t;
		late_stall : std_logic;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : id_out_data_t;
	signal output_mem : address_array_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		for i in ret.instructions'range loop
			ret.instructions(i).valid := '0';
			ret.instructions(i).pc := (others => '0');
			ret.late_stall := '0';
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
	
	out_data <= output_data;
	out_mem <= output_mem;
	
	comb:process (register_reg, in_data, in_control, in_mem) is
		variable decode_words : word_array_t;
	begin
		register_next <= register_reg;
		
		register_next.instructions <= in_data.instructions;
		for i in output_mem'range loop
			output_mem(i) <= in_data.instructions(i).pc;
		end loop;
		
		if (register_reg.late_stall = '1') then
			decode_words := register_reg.late_instructions;
		else
			decode_words := in_mem;
		end if;
		for i in output_data.instructions'range loop
			output_data.instructions(i) <= 
				decode(register_reg.instructions(i), decode_words(i));
		end loop;
		
		if (in_control.flush = '1') then
			for i in output_data.instructions'range loop
				output_data.instructions(i).valid <= '0';
			end loop;
		else
			if (in_control.stall = '1' )then
				register_next <= register_reg;
			end if;
			register_next.late_stall <= in_control.stall;
			register_next.late_instructions <= in_mem;
				
			if (register_reg.late_stall = '1') then
				register_next.late_instructions <= 
					register_reg.late_instructions;
			end if;
		end if;
	end process comb;
		
		
		
end architecture RTL;
