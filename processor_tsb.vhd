library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
	
	signal temp : std_logic_vector(31 downto 0);
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
		variable a, b : word_t;
	begin
		a := X"FFFFFFFF";
		b := X"00000004";
		temp  <= std_logic_vector(shift_right(unsigned(a), To_integer(Unsigned(b))));
		wait for TRESET + TCLK*20 + 1 ns;
		
		wait until rising_edge(clock);
		
		wait for TCLK*16 + 1 ns;
		
		wait until rising_edge(clock);
		wait for TCLK*8;
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
			     out_control_data_mem => p_out_control_data_mem);	
	
	data_mem_inst : entity work.data_mem
		port map(in_clk      => clock,
			     in_rst      => reset,
			     in_control  => dm_in_control,
			     in_address  => dm_in_address,
			     in_data     => dm_in_data,
			     out_data    => dm_out_data,
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
