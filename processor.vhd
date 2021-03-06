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
		
		--rtl_synthesis off
		out_stop : out std_logic;
		--rtl_synthesis on
		
		out_data_ins_mem : out address_array_t;
		out_data_data_mem : out processor_out_data_data_mem;
		out_control_data_mem : out processor_out_control_data_mem
	);
end entity processor;
--TODO: connect control unit (make the instructions go from frontend to backend through the control unit!!!
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
	
	signal cu_in_data : cu_in_data_t;
	signal cu_in_control : cu_in_control_t;
	signal cu_out_data : instruction_array_t;
	signal cu_out_control : cu_out_control_t;
	
	signal cu_out_stop : std_logic;
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
	
	control_unit_inst : entity work.control_unit
		port map(in_clk      => clock,
			     in_rst      => reset,
			     in_data     => cu_in_data,
			     in_control  => cu_in_control,
			     out_data    => cu_out_data,
			     out_stop    => cu_out_stop,
			     out_control => cu_out_control);
	
	be_in_control <= cu_out_control;
	fe_in_control.taken1 <= cu_out_control.taken1;
	fe_in_control.taken2 <= cu_out_control.taken2;
	cu_in_control <= be_out_control;
	cu_in_data.instructions <= fe_out_data.instuctions;
	be_in_data.instructions <= cu_out_data;
	
	--rtl_synthesis off
		out_stop  <= cu_out_stop;
	--rtl_synthesis on
end architecture RTL;
