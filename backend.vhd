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
	constant ALU1 : integer := 0;
	constant ALU2 : integer := 1;
	constant LS : integer := 2;
	constant BRANCH : integer := 3;
	
	signal clock, reset : std_logic;
	signal jump : std_logic;
	signal jump_pc : address_t;
	
	signal of_in_data : of_in_data_t;
	signal of_in_control : of_in_control_t;
	signal of_in_reg : reg_array_t;
	signal of_out_data : of_out_data_t;
	signal of_out_control : of_out_control_t;
	signal of_out_reg : reg_addr_array_t;
	
	signal rf_in_data : reg_file_in_data_t;
	signal rf_in_control : reg_file_in_control_t;
	signal rf_out_data : reg_array_t;
	
	signal alu_in_data1 : alu_in_data_t;
	signal alu_out_data1 : alu_out_data_t;
	signal alu_in_control1 : alu_in_control_t;
	signal alu_out_control1 : alu_out_control_t;
	
	signal alu_in_data2 : alu_in_data_t;
	signal alu_out_data2 : alu_out_data_t;
	signal alu_in_control2 : alu_in_control_t;
	signal alu_out_control2 : alu_out_control_t;
	
	signal bu_in_data : branch_in_data_t;
	signal bu_in_control : branch_in_control_t;
	signal bu_out_data : branch_out_data_t;
	signal bu_out_control : branch_out_control_t;
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
	
	out_data.jump_pc <= jump_pc;
	out_control.jump <= jump;
	
	of_in_data.instructions <= in_data.instructions;
	of_in_control.flush <= jump;
	of_in_control.taken1 <= in_control.taken1;
	of_in_control.taken2 <= in_control.taken2;
	reg_file_inst : entity work.reg_file
		port map(in_clk     => clock,
			     in_rst     => reset,
			     in_data    => rf_in_data,
			     in_control => rf_in_control,
			     out_data   => rf_out_data);
			     
	rf_in_data.read_addresses <= of_out_reg;
	of_in_reg <= rf_out_data;
	
	branch_unit_inst : entity work.branch_unit
		port map(in_clk 	 => clock,
				 in_rst 	 => reset,
				 in_data     => bu_in_data,
			     in_control  => bu_in_control,
			     out_data    => bu_out_data,
			     out_control => bu_out_control);
			     
	al_unit_inst1 : entity work.al_unit
		port map(in_data     => alu_in_data1,
			     in_control  => alu_in_control1,
			     out_data    => alu_out_data1,
			     out_control => alu_out_control1);
			     
	al_unit_inst2 : entity work.al_unit
		port map(in_data     => alu_in_data2,
			     in_control  => alu_in_control2,
			     out_data    => alu_out_data2,
			     out_control => alu_out_control2);
			     
	alu_in_data1.instruction <= of_out_data.instructions(ALU1);
	alu_in_data1.operands <= of_out_data.operands(ALU1);
	alu_in_control1.enable <= of_out_control.enable(ALU1);
	alu_in_control1.commit <= in_control.commit(ALU1);
	alu_in_data2.instruction <= of_out_data.instructions(ALU2);
	alu_in_data2.operands <= of_out_data.operands(ALU2);
	alu_in_control2.enable <= of_out_control.enable(ALU2);
	alu_in_control2.commit <= in_control.commit(ALU2);

	rf_in_data.write_addresses(ALU1) <= alu_out_data1.write_address;
	rf_in_data.data(ALU1) <= alu_out_data1.alu_out;
	rf_in_control.wr(ALU1) <= alu_out_control1.wr;
	rf_in_data.write_addresses(ALU2) <= alu_out_data2.write_address;
	rf_in_data.data(ALU2) <= alu_out_data2.alu_out;
	rf_in_control.wr(ALU2) <= alu_out_control2.wr;
	--TODO connect load output to rf_in_data.write_addresses(2), and wr signal
	
	bu_in_data.instructions <= of_out_data.instructions;
	bu_in_data.operands(0) <= of_out_data.operands(0).imm;
	bu_in_data.operands(1) <= of_out_data.operands(1).imm;
	bu_in_control.enable <= of_out_control.enable(BRANCH);
	bu_in_control.commit <= in_control.commit(BRANCH);
	bu_in_control.selectInstruction <= in_control.selectInstruction(BRANCH-2); --TODO : connect from control unit
	jump_pc <= bu_out_data.jump_pc;
	jump <= bu_out_control.jump;
end architecture RTL;
