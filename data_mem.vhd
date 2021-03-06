library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.processor_pkg.all;



entity data_mem is
	generic(
		ADDRESS_SIZE : integer := 12;
		LOAD_FILE_NAME : string  := DATA_INIT_FILE
	);
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_control : in data_mem_in_control_t;
		in_address : in address_t;
		in_data : in word_t;
		
		out_data : out word_t;
		out_test : out out_test_t;
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
	
	impure function init return register_t is
		variable ret : register_t;
		file load_file : text open read_mode is LOAD_FILE_NAME;
		variable rdline : line;
		variable address : word_t;
		variable data : word_t;
	begin
		for i in ret.mem_data'range loop
			ret.mem_data(i) := (others => '0');
		end loop;
		ret.output_word := (others => '0');
		ret.count := 0;
		
		while not endfile(load_file) loop
			readline(load_file, rdline);
			hread(rdline, address);
			read(rdline, data);
			ret.mem_data(To_integer(Unsigned(address))) := data;
		end loop;
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
		for i in out_test'range loop
			out_test(i) <= register_reg.mem_data(i);
		end loop;
		output_control.fc <= '0';
		output_data <= register_reg.output_word;
		
		if (in_control.rd = '1') then
			register_next.count <= register_reg.count + 1;
			if (register_reg.count = 2) then
				register_next.output_word <= register_reg.mem_data(To_integer(Unsigned(in_address)));
			end if;
		elsif (in_control.wr = '1') then
			register_next.count <= register_reg.count + 1;
			if (register_reg.count = 2) then
				register_next.mem_data(To_integer(Unsigned(in_address))) <= in_data;
			end if;
		end if;
		
		if (register_reg.count = 3) then
			register_next.count <= 0;
			output_control.fc <= '1';
		else
			output_control.fc <= '0';
		end if;
	end process;
	

	
end architecture RTL;
