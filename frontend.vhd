library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity frontend is
	port(
		in_clk     : in std_logic;
		in_rst     : in std_logic;

		in_data    : in frontend_in_data_t;
		in_control : in frontend_in_control_t;
		in_mem     : in  memory_data_t;

		out_mem    : out memory_address_t;
		out_data : out frontend_out_data_t
	);
end entity frontend;

architecture RTL of frontend is
	signal flush : std_logic;
	signal stall : std_logic;
	
	signal if_in_data    : if_in_data_t;
	signal if_in_control : if_in_control_t;
	signal if_out_data   : if_out_data_t;

	signal id_in_data    : id_in_data_t;
	signal id_in_control : id_in_control_t;
	signal id_in_mem     : memory_data_t;
	signal id_out_data   : id_out_data_t;
	signal id_out_mem    : memory_address_t;
	
	signal fifo_in_data : fifo_in_data_t;
	signal fifo_out_data : fifo_out_data_t;
	signal fifo_in_control : fifo_in_control_t;
	signal fifo_out_control : fifo_out_control_t;
begin
	flush <= in_control.jump;
	stall <= fifo_out_control.stall;
	
	fifo_stage_inst : entity work.fifo_stage
		port map(in_clk      => in_clk,
			     in_rst      => in_rst,
			     in_data     => fifo_in_data,
			     in_control  => fifo_in_control,
			     out_control => fifo_out_control,
			     out_data    => fifo_out_data);
			     
	fifo_in_data <= id_out_data;
	fifo_in_control.flush <= flush;
	fifo_in_control.taken1 <= in_control.taken1;
	fifo_in_control.taken2 <= in_control.taken2;
	
	out_data <= fifo_out_data;
	
	id_in_data          <= if_out_data;
	id_in_control.flush <= flush;
	id_in_control.stall <= stall;
	id_in_mem           <= in_mem;
	out_mem             <= id_out_mem;
	id_stage_inst : entity work.id_stage
		port map(
			in_clk     => in_clk,
			in_rst     => in_rst,
			in_data    => id_in_data,
			in_control => id_in_control,
			in_mem     => id_in_mem,
			out_data   => id_out_data,
			out_mem    => id_out_mem
		);
	
	if_in_data.jump_pc <= in_data.jump_pc;
	if_in_control.jump <= in_control.jump;
	if_in_control.stall <= stall;
	if_stage_inst : entity work.if_stage
		port map(in_clk     => in_clk,
			     in_rst     => in_rst,
			     in_data    => if_in_data,
			     in_control => if_in_control,
			     out_data   => if_out_data);
end architecture RTL;
