library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity control_unit is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in cu_in_data_t;
		in_control : in cu_in_control_t;
		
		--rtl_synthesis off
		out_stop : out std_logic;
		--rtl_synthesis on
		
		out_data : out instruction_array_t;
		out_control : out cu_out_control_t
	);
end entity control_unit;
--TODO: commit signal generation, taken1 and taken2 signal generation, rob
architecture RTL of control_unit is
	type rob_elem_t is record
		valid : std_logic;
		instruction : instruction_t;
	end record rob_elem_t;
	
	type registers_commit_t is array(0 to 2**REG_NUMBER_EXP-1) of std_logic_vector(3 downto 0);
	
	type rob_t is array (0 to ROB_SIZE-1) of rob_elem_t;
	
	type register_t is record
		stop : std_logic;
		rob : rob_t;
		curr : std_logic_vector(3 downto 0);
		--commit : std_logic_vector(3 downto 0);
		registers_commit : registers_commit_t;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : instruction_array_t;
	signal output_control : cu_out_control_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		ret.curr := (others => '0');
		for i in ret.rob'range loop
			ret.rob(i).valid := '1';
		end loop;
		ret.stop := '0';
		for i in 0 to 2**REG_NUMBER_EXP-1 loop
		--ret.registers_commit(i) := (others => '0');
		end loop;
		return ret;
	end function init;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (register_reg, in_data, in_control, output_data, output_control) is
		variable ins0, ins1 : instruction_t;
		variable cmp1, cmp2 : integer;
		variable t1, t2 : std_logic;
		variable c : std_logic_vector(3 downto 0);
		variable curr : integer;
		variable rn : integer;
	begin
		register_next <= register_reg;
		out_data <= output_data;
		out_control <= output_control;
		
		output_control.alu1_csr_2_branch <= '0';
		--output_control.commit <= register_reg.commit;
		output_control.commit <= "0000";
		output_control.selectInstruction <= '0';
		ins0 := in_data.instructions(0);
		ins1 := in_data.instructions(1);
		t1 := '0';
		t2 := '0';
		c := "0000";
		
		--rtl_synthesis off
		out_stop <= register_reg.stop;
		--rtl_synthesis on
		
		--taken1 signal generation
		if (register_reg.stop = '0') then
			if (ins0.valid = '1') then
				t1 := '1';
				cmp1 := compare(ins0.reg_src1, in_control.lsu_status.reg_dst);
				cmp2 := compare(ins0.reg_src2, in_control.lsu_status.reg_dst);
				if (in_control.lsu_status.busy = '1' and in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0)) 
					and (compare(in_control.lsu_status.rob_number, register_reg.registers_commit(To_integer(Unsigned(in_control.lsu_status.reg_dst))))=0))
				 then
					t1 := '0';
				end if;
				if (in_control.lsu_status.busy = '1' and (ins0.op = LOAD or ins0.op = STORE)) then
					t1 := '0';
				end if;
				
				if (ins0.op = STOP) then
					if (in_control.lsu_status.busy = '0') then
						register_next.stop <= '1';
					end if;
					t1 := '0';
				end if;
				
				if (t1 = '1') then
					if ((ins0.kind = DPR or ins0.kind = DPI) and ins0.op /= STORE) then
						register_next.registers_commit(to_integer(unsigned(ins0.reg_dst))) <= register_reg.curr;
					end if;
					if (ins0.op = BLAL) then
						register_next.registers_commit(31) <= register_reg.curr;
					end if;
					ins0.rob_number := register_reg.curr;
					register_next.curr <= unsigned_add(register_reg.curr, 1);
					register_next.rob(To_integer(Unsigned(register_reg.curr))).valid <= '1'; 
				end if;
			end if;
			
			--taken2 signal generation;
			if (ins1.valid = '1' and t1 = '1') then
				t2 := '1';
				cmp1 := compare(ins1.reg_src1, in_control.lsu_status.reg_dst);
				cmp2 := compare(ins1.reg_src2, in_control.lsu_status.reg_dst);
				if (in_control.lsu_status.busy = '1' and in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0)) 
					and (compare(in_control.lsu_status.rob_number, register_reg.registers_commit(To_integer(Unsigned(in_control.lsu_status.reg_dst))))=0))
				 then
					t2 := '0';
				end if;
				
				cmp1 := compare(ins1.reg_src1, ins0.reg_dst);
				cmp2 := compare(ins1.reg_src2, ins0.reg_dst);
				if (((cmp1 = 0) or (cmp2 = 0)) and ins1.kind = DPR) then
					t2 := '0';
				end if;
				
				if (ins1.op = STORE and (ins0.kind = BBL or compare(ins0.reg_dst, ins1.reg_dst) = 0)) then --reg to store same as reg_dst of previous instr.
					t2 := '0';
				end if;
				
				if ((ins1.op = STORE or ins1.op = LOAD) and compare(ins0.reg_src1, ins1.reg_dst) = 0) then --addr of load or store to be calculated in previous instr.
					t2 := '0';
				end if;
				
				if (in_control.lsu_status.busy = '1' and (ins1.op = LOAD or ins1.op = STORE)) then
					t2 := '0';
				end if;
				if ((ins1.op = LOAD or ins1.op = STORE) and (ins0.op = LOAD or ins0.op = STORE)) then
					t2 := '0';
				end if;
				if (ins0.kind = BBL and ins1.kind = BBL) then
					t2 := '0';
				end if;
				
				if (ins1.op = STOP) then
					t2 := '0';
				end if;
				
				if (t2 = '1') then
					if ((ins1.kind = DPR or ins1.kind = DPI) and ins1.op /= STORE) then
						register_next.registers_commit(to_integer(unsigned(ins1.reg_dst))) <= unsigned_add(register_reg.curr,1);
					end if;
					if (ins1.op = BLAL) then
						register_next.registers_commit(31) <= unsigned_add(register_reg.curr,1);
					end if;
					ins1.rob_number := unsigned_add(register_reg.curr,1);
					register_next.curr <= unsigned_add(register_reg.curr, 2);
					register_next.rob(To_integer(Unsigned(unsigned_add(register_reg.curr,1)))).valid <= '1'; 
				end if;
			end if;
			
			--selectInstruction generation
			output_control.selectInstruction <= '0';--TODO: check this snippet
			for i in in_data.instructions'range loop
				if (in_data.instructions(i).valid = '1') then
					case in_data.instructions(i).op is
						when BEQ | BHI | BLAL | BAL| BGT => 
							if (i = 0) then
								output_control.selectInstruction <= '0';
							elsif (t2 = '1') then
								output_control.selectInstruction <= '1';
							end if;
						when others => 
							null;
					end case;
				end if;
			end loop;
			
			for i in output_control.commit'range loop
			if (i<2) then
					cmp2 := 1;
					c(i) := '1';
					rn := To_integer(Unsigned(in_control.bu_status.rob_number));--7
					curr := To_integer(Unsigned(register_reg.curr));--9
					cmp1 := To_integer(Unsigned(in_control.alu_statuses(i).rob_number));--8
						if (curr<=rn) then --TODO : recheck this conditions
							if (cmp1<=curr or cmp1>rn) then
								cmp2 := 0;
							end if;
						else
							if (cmp1>rn and cmp1<=curr) then --TODO: !!!! error
								cmp2 := 0;
							end if;
						end if;
					if (register_reg.rob(to_integer(unsigned(in_control.alu_statuses(i).rob_number))).valid = '0' or (in_control.jump = '1' and cmp2 = 0)) then
						c(i) := '0';
					end if;
					if (cmp2 /= 0 and i=0 and ins0.valid = '1') then
						output_control.alu1_csr_2_branch <= '1';
					end if;

					cmp1 := compare(register_reg.registers_commit(to_integer(unsigned(in_control.alu_statuses(i).reg_dst))), in_control.alu_statuses(i).rob_number);
					if (cmp1 /= 0) then
						c(i) := '0';
					end if;
				end if;
				if (i = 2) then
					c(i) := '1';
					if (register_reg.rob(to_integer(unsigned(in_control.lsu_status.rob_number))).valid = '0') then
						c(i) := '0';
					end if;
					cmp1 := compare(register_reg.registers_commit(to_integer(unsigned(in_control.lsu_status.reg_dst))), in_control.lsu_status.rob_number);
					if (cmp1 /= 0) then
						c(i) := '0';
					end if;
				end if;
				if (i = 3) then
					c(i) := '1';
					if (register_reg.rob(to_integer(unsigned(in_control.bu_status.rob_number))).valid = '0') then
						c(i) := '0';
					end if;
					cmp1 := compare(register_reg.registers_commit(to_integer(unsigned(in_control.bu_status.reg_dst))), in_control.bu_status.rob_number);
					if (cmp1 /= 0) then
						c(i) := '0';
					end if;
				end if;
			end loop;
			
			--TODO: hazzard 1
			
			for i in in_control.alu_statuses'range loop
				output_control.commit(i) <= c(i);
			end loop;
			output_control.commit(LS) <= c(LS);
			output_control.commit(BRANCH) <= c(BRANCH);
			
			if (in_control.jump = '1') then
				rn := To_integer(Unsigned(in_control.bu_status.rob_number));
				curr := To_integer(Unsigned(register_reg.curr));
				for i in 0 to ROB_SIZE-1 loop
					if (curr<=rn) then --TODO : recheck this conditions
						if (i<=curr or i>rn) then
							register_next.rob(i).valid <= '0';
						end if;
					else
						if (i>rn and i<=curr) then
							register_next.rob(i).valid <= '0';
						end if;
					end if;
				end loop;
			end if;
		end if;--stop bit condition
		
		output_control.taken1 <= t1;
		output_control.taken2 <= t2;
		output_data(0) <= ins0;
		output_data(1) <= ins1;
	end process comb;
end architecture RTL;
