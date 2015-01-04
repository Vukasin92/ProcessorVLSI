library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity data_mem is
	generic(
		ADDRESS_SIZE : integer := 8
	);
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_control : in data_mem_in_control_t;
		in_address : in address_t;
		in_data : in word_t;
		
		out_data : out word_t;
		out_control : out data_mem_out_control_t
	);
end entity data_mem;

architecture RTL of data_mem is
	type mem_data_array_t is array (0 to 2**ADDRESS_SIZE-1) of word_t;
	
	type register_t is record
		mem_data : mem_data_array_t;
		output_word : word_t;
		count : integer;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		for i in ret.mem_data'range loop
			ret.mem_data(i) := (others => '0');
		end loop;
		ret.output_word := (others => '0');
		return ret;
	end function init;
	
	signal output_data : word_t;
	signal output_control : data_mem_out_control_t;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (register_reg, in_control, in_address, in_data, output_control, output_data) is
	begin
		register_next <= register_reg;
		out_data <= output_data;
		out_control<= output_control;
		
		output_control.fc <= '0';
		
		if (register_reg.count = 3) then
			register_next.count <= 0;
			out_control.fc <= '1';
		else
			out_control.fc <= '0';
		end if;
		output_data <= register_reg.mem_data(To_integer(Unsigned(in_address)));
		
		if (in_control.rd = '1') then
			register_next.count <= register_reg.count + 1;
		elsif (in_control.wr = '1') then
			register_next.count <= register_reg.count + 1;
			if (register_reg.count = 2) then
				register_next.mem_data(To_integer(Unsigned(in_address))) <= in_data;
			end if;
		end if;
	end process;
	

	
end architecture RTL;
