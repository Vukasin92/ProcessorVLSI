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
	
	signal fe_in_data : frontend_in_data_t;
	signal fe_in_control : frontend_in_control_t;
	signal fe_in_mem : word_array_t;
	signal fe_out_mem : address_array_t;
	signal fe_out_data : frontend_out_data_t;
	
	signal be_in_data : backend_in_data_t;
	signal be_in_control : backend_in_control_t;
	signal be_in_data_mem : word_t;
	signal be_in_control_mem : backend_in_control_data_mem_t;
	
	signal be_out_control : backend_out_control_t;
	signal be_out_data : backend_out_data_t;
	
	signal mem_in_addresses : address_array_t;
	signal mem_out_words   : word_array_t;
	
	signal taken1, taken2 : std_logic;
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
	begin
		taken1 <= '0';
		taken2 <= '0';
		wait for TRESET + TCLK*20 + 1 ns;
		taken2 <= '1';
		wait for 6*TCLK;
		taken2 <= '0';
		taken1 <= '0';
		wait for 2*TCLK;
		taken1 <= '1';
		wait for TCLK;
		wait until rising_edge(clock);
		taken1 <= '0';
		wait for TCLK*4;
		wait;
	end process input;
		

	instruction_mem_inst : entity work.instruction_mem
		port map(
			in_clk => clock,
			in_rst => reset,
			in_addresses  => mem_in_addresses,
			out_words  => mem_out_words
		);

	frontend_inst : entity work.frontend
		port map(
			in_clk     => clock,
			in_rst     => reset,
			in_data    => fe_in_data,
			in_control => fe_in_control,
			in_mem => fe_in_mem,
			out_mem => fe_out_mem,
			out_data => fe_out_data
		);
		
	backend_inst : entity work.backend
		port map(in_clk          => clock,
			     in_rst          => reset,
			     in_data         => be_in_data,
			     in_control      => be_in_control,
			     in_data_mem     => be_in_data_mem,
			     in_control_mem  => be_in_control_mem,
			     out_data_mem    => open,
			     out_control_mem => open,
			     out_data		 => be_out_data,
			     out_control     => be_out_control);
			     
	be_in_data.instructions <= fe_out_data.instuctions;
	fe_in_control.jump <= be_out_control.jump;
	fe_in_data.jump_pc <= be_out_data.jump_pc;
	
	
	fe_in_mem <= mem_out_words;
	be_in_data_mem <= (others => '0');
	be_in_control_mem <= (others => '0');
	mem_in_addresses <= fe_out_mem;

	fe_in_control.taken1 <= taken1;
	fe_in_control.taken2 <= taken2;
	be_in_control.taken1 <= taken1;
	be_in_control.taken2 <= taken2;
	be_in_control.commit <= (others => '0');
end architecture RTL;
