library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity frontend is
	port(
		in_clk     : in std_logic;
		in_rst     : in std_logic;

		in_data    : in frontend_in_data_t;
		in_control : in frontend_in_control_t
	);
end entity frontend;

architecture RTL of frontend is
	signal flush : std_logic;
	signal stall : std_logic;
	
	signal if_in_data    : if_in_data_t;
	signal if_in_control : if_in_control_t;
	signal if_out_data   : if_out_data_t;

begin
	flush <= in_control.jump;
	--TODO: connect real stall signal from the fifo
	stall <= in_control.test_stall;
	
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
