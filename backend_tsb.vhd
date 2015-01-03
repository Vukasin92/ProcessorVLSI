library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity backend_tsb is
	generic(
		TCLK   : time := 5 ns;
		TRESET : time := 20 ns
	);
end entity backend_tsb;

architecture RTL of backend_tsb is
	signal clock : std_logic;
	signal reset : std_logic;

	signal backend_in_data    : backend_in_data_t;
	signal backend_in_control : backend_in_control_t;
	
	signal backend_out_control : backend_out_control_t;
	signal backend_out_data : backend_out_data_t;
	
	signal backend_in_data_mem : word_t;
	signal backend_in_control_mem : backend_in_control_data_mem_t;
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
		--ins0: add imm and r2 and write to r3
		backend_in_data.instructions(0).valid <= '1';
		backend_in_data.instructions(0).kind <= DPI;
		backend_in_data.instructions(0).op <= ADD;
		backend_in_data.instructions(0).reg_src1 <= "00010";
		backend_in_data.instructions(0).reg_src2 <= "00001";
		backend_in_data.instructions(0).reg_dst <= "00011";
		backend_in_data.instructions(0).word <= X"00008005";
		backend_in_data.instructions(0).pc <= (others => '0');
		--ins1 sub r2 from r1 and write to r3
		backend_in_data.instructions(1).valid <= '1';
		backend_in_data.instructions(1).kind <= DPR;
		backend_in_data.instructions(1).op <= SUB;
		backend_in_data.instructions(1).reg_src1 <= "00010";
		backend_in_data.instructions(1).reg_src2 <= "00001";
		backend_in_data.instructions(1).reg_dst <= "00011";
		backend_in_data.instructions(1).word <= X"00000005";
		backend_in_data.instructions(1).pc <= (others => '0');

		backend_in_control.taken1 <= '0';
		backend_in_control.taken2 <= '0';
		wait for TRESET + TCLK*12 + 1 ns;
		
		backend_in_control.taken1 <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		backend_in_data.instructions(0).op <= MOV;
		backend_in_data.instructions(0).reg_src1 <= "01000";
		backend_in_data.instructions(0).kind <= DPR;
		
		backend_in_data.instructions(1).op <= CMP;
		backend_in_data.instructions(1).kind <= DPR;
		backend_in_data.instructions(1).word <= X"04000000";
		
		backend_in_control.taken2 <= '1';
		backend_in_control.taken1 <= '0';
		wait for TCLK;
		backend_in_data.instructions(0).op <= SBC;
		backend_in_data.instructions(0).reg_src1 <= "10000";
		backend_in_data.instructions(0).kind <= DPR;
		
		backend_in_data.instructions(1).op <= BLAL;
		backend_in_data.instructions(1).kind <= BBL;
		backend_in_data.instructions(1).word <= X"04000000";
		
		backend_in_control.taken2 <= '1';
		backend_in_control.taken1 <= '1';
		wait until rising_edge(clock);
		backend_in_control.taken2 <= '0';
		backend_in_control.taken1 <= '0';
		wait for TCLK*4;
		
		wait;
	end process input;
		

	backend_inst : entity work.backend
		port map(in_clk          => clock,
			     in_rst          => reset,
			     in_data         => backend_in_data,
			     in_control      => backend_in_control,
			     in_data_mem     => backend_in_data_mem,
			     in_control_mem  => backend_in_control_mem,
			     out_data_mem    => open,
			     out_control_mem => open,
			     out_control     => backend_out_control,
			     out_data        => backend_out_data);
end architecture RTL;
