library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.processor_pkg.all;

entity processor_tsb is
	generic(
		TCLK   : time := 5 ns;
		TRESET : time := 20 ns
	);
end entity processor_tsb;

architecture RTL of processor_tsb is
	signal clock, reset : std_logic;
	
	signal mem_in_addresses : address_array_t;
	signal mem_out_words   : word_array_t;
	
	signal dm_in_address : address_t;
	signal dm_in_data : word_t;
	signal dm_in_control : data_mem_in_control_t;
	signal dm_out_data : word_t;
	signal dm_out_control : data_mem_out_control_t;
	
	signal p_in_data_ins_mem : word_array_t;
	signal p_in_data_data_mem : word_t;
	signal p_in_control_data_mem : processor_in_control_data_mem;
	signal p_out_data_ins_mem : address_array_t;
	signal p_out_data_data_mem : processor_out_data_data_mem;
	signal p_out_control_data_mem : processor_out_control_data_mem;
	
	signal p_out_stop : std_logic;
	signal dm_out_test : out_test_t;
begin
	system_clock : process is
		variable clk : std_logic;
	begin
		clk   := '1';
		reset <= '1';
		wait for TRESET;
		reset <= '0';
		while true loop
			clock <= clk;
			clk   := not clk;
			wait for TCLK;
		end loop;
	end process system_clock;

	input:process is
		type mem_data_array_t is array (0 to 2**DATA_ADDRESS_SIZE-1) of word_t;
		variable mem : mem_data_array_t;
		
		file load_file1 : text open read_mode is DATA_INIT_FILE;
		file load_file2 : text open read_mode is DATA_FINAL_FILE;
		variable rdline : line;
		variable address : word_t;
		variable data : word_t;
		
		variable wrline : line;
		file out_file : text open write_mode is "outMem.txt";
		
		variable correct : boolean;
	begin
		wait until p_out_stop = '1';
		--compare output of data cache with expected
		correct := true;
		for i in mem'range loop
			mem(i) := (others => '0');
		end loop;
		--calculate expected values
		readline(load_file1, rdline);
		while not endfile(load_file1) loop
			readline(load_file1, rdline);
			hread(rdline, address);
			read(rdline, data);
			mem(To_integer(Unsigned(address))) := data;
		end loop;
		
		while not endfile(load_file2) loop
			readline(load_file2, rdline);
			hread(rdline, address);
			read(rdline, data);
			mem(To_integer(Unsigned(address))) := data;
			
			hwrite(wrline, address);
			writeline(out_file, wrline);
			write(wrline, dm_out_test(To_integer(Unsigned(address))));
			writeline(out_file, wrline);
			write(wrline, data);
			writeline(out_file, wrline);
		end loop;
		--compare with actual simulation values
		for i in mem'range loop
			if (compare(mem(i), dm_out_test(i)) /= 0) then
				correct := false;
				exit;
			end if;
		end loop;
		if (correct = true) then
			report "Test OK" severity note;
		else
			report "TEST NOK" severity error;
		end if;
		
		wait;
	end process input;
	
	processor_inst : entity work.processor
		port map(in_clk               => clock,
			     in_rst               => reset,
			     in_data_ins_mem      => p_in_data_ins_mem,
			     in_data_data_mem     => p_in_data_data_mem,
			     in_control_data_mem  => p_in_control_data_mem,
			     out_data_ins_mem     => p_out_data_ins_mem,
			     out_data_data_mem    => p_out_data_data_mem,
			     out_stop 			  => p_out_stop,
			     out_control_data_mem => p_out_control_data_mem);	
	
	data_mem_inst : entity work.data_mem
		port map(in_clk      => clock,
			     in_rst      => reset,
			     in_control  => dm_in_control,
			     in_address  => dm_in_address,
			     in_data     => dm_in_data,
			     out_data    => dm_out_data,
			     out_test    => dm_out_test,
			     out_control => dm_out_control);
			     
	dm_in_control <= p_out_control_data_mem;
	dm_in_data <= p_out_data_data_mem.data;
	dm_in_address <= p_out_data_data_mem.addr;
	p_in_control_data_mem <= dm_out_control;
	p_in_data_data_mem <= dm_out_data;
	
	instruction_mem_inst : entity work.instruction_mem
		port map(
			in_clk => clock,
			in_rst => reset,
			in_addresses  => mem_in_addresses,
			out_words  => mem_out_words
		);
	
	mem_in_addresses <= p_out_data_ins_mem;
	p_in_data_ins_mem <= mem_out_words;
end architecture RTL;
