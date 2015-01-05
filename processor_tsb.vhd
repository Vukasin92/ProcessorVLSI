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
	signal be_out_control_mem : backend_out_control_data_mem_t;
	signal be_out_data_mem : backend_out_data_data_mem_t;
	
	signal mem_in_addresses : address_array_t;
	signal mem_out_words   : word_array_t;
	
	signal taken1, taken2 : std_logic;
	
	signal dm_in_address : address_t;
	signal dm_in_data : word_t;
	signal dm_in_control : data_mem_in_control_t;
	signal dm_out_data : word_t;
	signal dm_out_control : data_mem_out_control_t;
	
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
		taken1 <= '0';
		taken2 <= '0';
		a := X"FFFFFFFF";
		b := X"00000004";
		temp  <= std_logic_vector(shift_right(unsigned(a), To_integer(Unsigned(b))));
		be_in_control.selectInstruction <= "00";
		wait for TRESET + TCLK*20 + 1 ns;
		taken1 <= '1';
		wait until rising_edge(clock);
		taken1 <= '0';
		wait for TCLK*16 + 1 ns;
		taken1 <= '1';
		wait until rising_edge(clock);
		taken1 <= '0';
		wait for TCLK*8;
--		taken2 <= '1';
--		wait for 6*TCLK;
--		taken2 <= '0';
--		taken1 <= '0';
--		wait for 2*TCLK;
--		taken1 <= '1';
--		wait for TCLK;
--		wait until rising_edge(clock);
--		taken1 <= '0';
--		wait for TCLK*4;
		wait;
	end process input;
		
	data_mem_inst : entity work.data_mem
		port map(in_clk      => clock,
			     in_rst      => reset,
			     in_control  => dm_in_control,
			     in_address  => dm_in_address,
			     in_data     => dm_in_data,
			     out_data    => dm_out_data,
			     out_control => dm_out_control);
			     
	dm_in_control <= be_out_control_mem;
	dm_in_data <= be_out_data_mem.data;
	dm_in_address <= be_out_data_mem.addr;
	be_in_control_mem <= dm_out_control;
	be_in_data_mem <= dm_out_data;
	
	instruction_mem_inst : entity work.instruction_mem
		port map(
			in_clk => clock,
			in_rst => reset,
			in_addresses  => mem_in_addresses,
			out_words  => mem_out_words
		);
	--TODO : Instantiate processor entity instead frontend+backend - after adding control unit (finishing)
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
			     out_data_mem    => be_out_data_mem,
			     out_control_mem => be_out_control_mem,
			     out_data		 => be_out_data,
			     out_control     => be_out_control);
			     
	be_in_data.instructions <= fe_out_data.instuctions;
	fe_in_control.jump <= be_out_control.jump;
	fe_in_data.jump_pc <= be_out_data.jump_pc;
	
	
	fe_in_mem <= mem_out_words;
	mem_in_addresses <= fe_out_mem;

	fe_in_control.taken1 <= taken1;
	fe_in_control.taken2 <= taken2;
	be_in_control.taken1 <= taken1;
	be_in_control.taken2 <= taken2;
	be_in_control.commit <= (others => '1');
end architecture RTL;
