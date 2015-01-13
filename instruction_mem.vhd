library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.processor_pkg.all;

entity instruction_mem is
	generic(
		ADDRESS_SIZE : integer := 8;
		LOAD_FILE_NAME : string  := INSTRUCTIONS_FILE
	);
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_addresses : in ins_memory_address_t;
		out_words   : out ins_memory_data_t
	);
end entity instruction_mem;

architecture RTL of instruction_mem is
	type mem_data_array_t is array (0 to 2**ADDRESS_SIZE-1) of word_t;
	
	type register_t is record
		mem_data : mem_data_array_t;
		output_words : word_array_t;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	impure function init return register_t is
		variable ret : register_t;
		file load_file : text open read_mode is LOAD_FILE_NAME;
		variable rdline : line;
		variable address : word_t;
		variable data : word_t;
		
		--variable wrline : line;
		--file out_file : text open write_mode is "ReadMirror.txt";
	begin
		for i in ret.mem_data'range loop
			ret.mem_data(i) := (others => '0');
		end loop;
		for i in ret.output_words'range loop
			ret.output_words(i) := (others => '0');
		end loop;
		--read initial content from file
		readline(load_file, rdline);
		while not endfile(load_file) loop
			readline(load_file, rdline);
			hread(rdline, address);
			read(rdline, data);
			--hwrite(wrline, address);
			--hwrite(wrline, data);
			--writeline(out_file, wrline);
			ret.mem_data(To_integer(Unsigned(address))) := data;
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
	
	comb:process (register_reg, in_addresses)
	begin
		register_next <= register_reg;
		out_words <= register_reg.output_words;
		
		for i in in_addresses'range loop
			register_next.output_words(i) <= register_reg.mem_data(To_integer(Unsigned(in_addresses(i))));
		end loop;
	end process comb;

end architecture RTL;
