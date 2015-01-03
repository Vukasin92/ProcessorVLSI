library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity frontend_tsb is
	generic(
		TCLK   : time := 5 ns;
		TRESET : time := 20 ns
	);
end entity frontend_tsb;

architecture RTL of frontend_tsb is
	signal clock : std_logic;
	signal reset : std_logic;

	signal frontend_in_data    : frontend_in_data_t;
	signal frontend_in_control : frontend_in_control_t;
	
	signal mem_in_addresses : address_array_t;
	signal mem_out_words   : word_array_t;
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
		frontend_in_data.jump_pc <= (others => '0');
		frontend_in_control.jump <= '0';
		frontend_in_control.taken1 <= '0';
		frontend_in_control.taken2 <= '0';
		wait for TRESET + TCLK*12 + 1 ns;
		--frontend_in_control.taken2 <= '1';
		--wait until rising_edge(clock);
		--wait for 2*TCLK;
		--frontend_in_control.taken2 <= '0';
		frontend_in_control.taken1 <= '1';
		wait until rising_edge(clock);
		wait for 2*TCLK;
		frontend_in_control.taken1 <= '0';
		
		wait for TCLK*4;
		frontend_in_control.jump <= '1';
		wait until rising_edge(clock);
		frontend_in_control.jump <= '0';
		
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
			in_data    => frontend_in_data,
			in_control => frontend_in_control,
			in_mem => mem_out_words,
			out_mem => mem_in_addresses
		);

end architecture RTL;
