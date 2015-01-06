library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity backend is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in backend_in_data_t; -- from processor, internal
		in_control : in backend_in_control_t; -- from processor, internal
		in_data_mem : in word_t;
		in_control_mem : in backend_in_control_data_mem_t;
		
		out_data_mem : out backend_out_data_data_mem_t;
		out_control_mem : out backend_out_control_data_mem_t;
		out_control : out backend_out_control_t;
		out_data : out backend_out_data_t
	);
end entity backend;

architecture RTL of backend is	
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
	
	signal lsu_in_data : ls_unit_in_data_t;
	signal lsu_in_control : ls_unit_in_control_t;
	signal lsu_in_control_mem : ls_unit_in_control_mem_t;
	signal lsu_in_data_mem : word_t;
	
	signal lsu_out_data : ls_unit_out_data_t;
	signal lsu_out_control : ls_unit_out_control_t;
	signal lsu_out_data_mem : ls_unit_out_data_mem_t;
	signal lsu_out_control_mem : ls_unit_out_control_mem_t;
begin
	lsu_in_data_mem <= in_data_mem;
	lsu_in_control_mem <= in_control_mem;
	out_data_mem.addr <= lsu_out_data_mem.addr;
	out_data_mem.data <= lsu_out_data_mem.data;
	out_control_mem <= lsu_out_control_mem;
	
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
	of_in_data.new_csr(ALU1) <= alu_out_data1.new_csr;
	of_in_control.csr_wr(ALU1) <= alu_out_control1.wr_csr;
	alu_in_data1.csr <= of_out_data.csr;
	
	alu_in_data2.instruction <= of_out_data.instructions(ALU2);
	alu_in_data2.operands <= of_out_data.operands(ALU2);
	alu_in_control2.enable <= of_out_control.enable(ALU2);
	alu_in_control2.commit <= in_control.commit(ALU2);
	of_in_data.new_csr(ALU2) <= alu_out_data2.new_csr;
	of_in_control.csr_wr(ALU2) <= alu_out_control2.wr_csr;
	alu_in_data2.csr <= of_out_data.csr;


	rf_in_data.write_addresses(ALU1) <= alu_out_data1.write_address;
	rf_in_data.data(ALU1) <= alu_out_data1.alu_out;
	rf_in_control.wr(ALU1) <= alu_out_control1.wr;
	rf_in_data.write_addresses(ALU2) <= alu_out_data2.write_address;
	rf_in_data.data(ALU2) <= alu_out_data2.alu_out;
	rf_in_control.wr(ALU2) <= alu_out_control2.wr;
	rf_in_data.write_addresses(BRANCH) <= bu_out_data.write_address;
	rf_in_data.data(BRANCH) <= bu_out_data.write_data;
	rf_in_control.wr(BRANCH) <= bu_out_control.wr;
	rf_in_data.write_addresses(LS) <= lsu_out_data.reg_number;
	rf_in_data.data(LS) <= lsu_out_data.reg_value;
	rf_in_control.wr(LS) <= lsu_out_control.wr;
	
	bu_in_data.instructions <= of_out_data.instructions;
	bu_in_data.operands(0) <= of_out_data.operands(0).imm;
	bu_in_data.operands(1) <= of_out_data.operands(1).imm;
	bu_in_data.csr <= of_out_data.csr;
	bu_in_control.enable <= of_out_control.enable(BRANCH);
	bu_in_control.commit <= in_control.commit(BRANCH);
	bu_in_control.selectInstruction <= in_control.selectInstruction; --TODO : connect from control unit
	jump_pc <= bu_out_data.jump_pc;
	jump <= bu_out_control.jump;
	
	out_control.alu_statuses(ALU1).busy <= alu_out_control1.busy;
	out_control.alu_statuses(ALU2).busy <= alu_out_control2.busy;
	out_control.bu_status.busy <= bu_out_control.busy;
	
	ls_unit_inst : entity work.ls_unit
		port map(in_clk          => clock,
			     in_rst          => reset,
			     in_control      => lsu_in_control,
			     in_data         => lsu_in_data,
			     in_data_mem     => lsu_in_data_mem,
			     in_control_mem  => lsu_in_control_mem,
			     out_control     => lsu_out_control,
			     out_data        => lsu_out_data,
			     out_data_mem    => lsu_out_data_mem,
			     out_control_mem => lsu_out_control_mem);
			     
	lsu_in_control.commit <= in_control.commit(LS);
	lsu_in_control.enable <= of_out_control.enable(LS);
	--lsu_in_control.selectInstruction <= in_control.selectInstruction(LS-2);
	lsu_in_data.instruction <= of_out_data.ls_instruction;
	lsu_in_data.operand <= of_out_data.ls_operand;
	out_control.lsu_status.is_load <= lsu_out_control.is_load;
	out_control.lsu_status.busy <= lsu_out_control.busy;
	
	out_control.alu_statuses(ALU1).reg_dst <= alu_out_data1.reg_dst;
	out_control.alu_statuses(ALU2).reg_dst <= alu_out_data2.reg_dst;
	out_control.lsu_status.reg_dst <= lsu_out_data.reg_number;
	out_control.bu_status.reg_dst <= bu_out_data.reg_dst;
	
	out_control.alu_statuses(ALU1).rob_number <= alu_in_data1.instruction.rob_number;
	out_control.alu_statuses(ALU2).rob_number <= alu_in_data2.instruction.rob_number;
	--out_control.lsu_status.rob_number <= lsu_in_data.instructions(to_integer(unsigned(lsu_in_control.selectInstruction))).rob_number;
	process (bu_in_control.selectInstruction, bu_in_data) is
	begin
		if (bu_in_control.selectInstruction = '1') then
			out_control.bu_status.rob_number <= bu_in_data.instructions(1).rob_number;
		else
			out_control.bu_status.rob_number <= bu_in_data.instructions(1).rob_number;
		end if;
	end process;
end architecture RTL;
