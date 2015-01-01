library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity backend is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in backend_in_data_t; -- from processor, internal
		in_control : in backend_in_control_t; -- from processor, internal
		in_data_mem : in word_t;
		in_control_mem : in backend_in_control_data_mem_t;
		
		out_data_mem : out address_t;
		out_control_mem : out backend_out_control_data_mem_t;
		out_control : out backend_out_control_t;
		out_data : out backend_out_data_t
	);
end entity backend;

architecture RTL of backend is
	signal clock, reset : std_logic;
	signal jump : std_logic;
	
	signal of_in_data : of_in_data_t;
	signal of_in_control : of_in_control_t;
	signal of_in_reg : reg_array_t;
	signal of_out_data : of_out_data_t;
	signal of_out_control : of_out_control_t;
	signal of_out_reg : reg_addr_array_t;
	
	signal rf_in_data : reg_file_in_data_t;
	signal rf_in_control : reg_file_in_control_t;
	signal rf_out_data : reg_array_t;
begin
	of_stage_inst : entity work.of_stage
		port map(in_clk      => clock,
			     in_rst      => reset,
			     in_data     => of_in_data,
			     in_control  => of_in_control,
			     in_reg      => of_in_reg,
			     out_data    => of_out_data,
			     out_control => of_out_control,
			     out_reg     => of_out_reg);
			     
	clock <= in_clk;
	reset <= in_rst;
	
	of_in_data.instructions <= in_data.instructions;
	of_in_control.flush <= jump; --TODO : connect to jump from branch unit
	--TODO : of_in_reg <= in_reg;
	reg_file_inst : entity work.reg_file
		port map(in_clk     => clock,
			     in_rst     => reset,
			     in_data    => rf_in_data,
			     in_control => rf_in_control,
			     out_data   => rf_out_data);
			     
	rf_in_data.read_addresses <= of_out_reg;
	-- TODO : connect write_addresses and wr signals to reg_file
	of_in_reg <= rf_out_data;
end architecture RTL;
