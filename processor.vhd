library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity processor is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data_ins_mem : in word_array_t;
		in_data_data_mem : in word_t;
		in_control_data_mem : in processor_in_control_data_mem;
		
		out_data_ins_mem : out address_array_t;
		out_data_data_mem : out processor_out_data_data_mem;
		out_control_data_mem : out processor_out_control_data_mem
	);
end entity processor;

architecture RTL of processor is
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
	signal be_out_data_mem : backend_out_data_data_mem_t;
	signal be_out_control_mem : backend_out_control_data_mem_t;
	signal be_out_control : backend_out_control_t;
	signal be_out_data : backend_out_data_t;
begin
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
	
	clock <= in_clk;
	reset <= in_rst;
	fe_in_mem <= in_data_ins_mem;
	out_data_ins_mem <= fe_out_mem;
	be_in_data_mem <= in_data_data_mem;
	be_in_control_mem <= in_control_data_mem;
	out_data_ins_mem <= fe_out_mem;
	out_data_data_mem <= be_out_data_mem;
	out_control_data_mem <= be_out_control_mem;
	--TODO : instantiate control unit and connect, change next lines
	fe_in_control.taken1 <= '0';
	fe_in_control.taken2 <= '0';
	be_in_control.taken1 <= '0';
	be_in_control.taken2 <= '0';
	be_in_control.commit <= (others => '0');
end architecture RTL;
