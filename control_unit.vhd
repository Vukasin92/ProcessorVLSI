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
	
	type registers_commit_t is array(0 to 31) of std_logic_vector(3 downto 0);
	
	type rob_t is array (0 to ROB_SIZE-1) of rob_elem_t;
	
	type register_t is record
		rob : rob_t;
		curr : std_logic_vector(3 downto 0);
		commit : std_logic_vector(3 downto 0);
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
		
		output_control.commit <= register_reg.commit;
		ins0 := in_data.instructions(0);
		ins1 := in_data.instructions(1);
		t1 := '0';
		t2 := '0';
		
		--taken1 signal generation
		if (ins0.valid = '1') then
			t1 := '1';
			cmp1 := compare(ins0.reg_src1, in_data.load_reg_number);
			cmp2 := compare(ins0.reg_src2, in_data.load_reg_number);
			if (in_control.lsu_status.busy = '1' and in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0))) then
				t1 := '0';
			end if;
			if (in_control.lsu_status.busy = '1' and (ins0.op = LOAD or ins0.op = STORE)) then
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
			cmp1 := compare(ins1.reg_src1, in_data.load_reg_number);
			cmp2 := compare(ins1.reg_src2, in_data.load_reg_number);
			if (in_control.lsu_status.busy = '1' and in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0))) then
				t2 := '0';
			end if;
			
			cmp1 := compare(ins1.reg_src1, ins0.reg_dst);
			cmp2 := compare(ins1.reg_src2, ins0.reg_dst);
			if ((cmp1 = 0) or (cmp2 = 0)) then
				t2 := '0';
			end if;
			
			if (ins1.op = STORE and ins0.kind = BBL) then
				t2 := t2 and '0';
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
			
			if (t2 = '1') then
				if ((ins1.kind = DPR or ins1.kind = DPI) and ins1.op /= STORE) then
					register_next.registers_commit(to_integer(unsigned(ins1.reg_dst))) <= unsigned_add(register_reg.curr,1);
				end if;
				if (ins1.op = BLAL) then
					register_next.registers_commit(31) <= unsigned_add(register_reg.curr,1);
				end if;
				ins1.rob_number := unsigned_add(register_reg.curr,1);
				register_next.curr <= unsigned_add(register_reg.curr, 2);
				register_next.rob(To_integer(Unsigned(register_reg.curr))+1).valid <= '1'; 
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
						else
							output_control.selectInstruction <= '1';
						end if;
					when others => 
						null;
				end case;
			end if;
		end loop;
		
		for i in output_control.commit'range loop
			if (i<2) then
				if (register_reg.rob(to_integer(unsigned(in_control.alu_statuses(i).rob_number))).valid = '0' or in_control.jump = '1') then
					c(i) := '0';
				else
					c(i) := '1';
				end if;
				cmp1 := compare(register_reg.registers_commit(to_integer(unsigned(in_control.alu_statuses(i).reg_dst))), in_control.alu_statuses(i).rob_number);
				if (cmp1 /= 0) then
					c(i) := '0';
				end if;
			end if;
			if (i = 2) then
				if (register_reg.rob(to_integer(unsigned(in_control.lsu_status.rob_number))).valid = '1') then
					c(i) := '1';
				else
					c(i) := '0';
				end if;
				cmp1 := compare(register_reg.registers_commit(to_integer(unsigned(in_control.lsu_status.reg_dst))), in_control.lsu_status.rob_number);
				if (cmp1 /= 0 and in_control.lsu_status.is_load = '1') then
					c(i) := '0';
				end if;
			end if;
			if (i = 3) then
				if (register_reg.rob(to_integer(unsigned(in_control.bu_status.rob_number))).valid = '1') then
					c(i) := '1';
				else
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
			while rn /= curr loop
				rn := (rn+1) mod ROB_SIZE;
				register_next.rob(rn).valid <= '0';
			end loop;
		end if;
		
		output_control.taken1 <= t1;
		output_control.taken2 <= t2;
		output_data(0) <= ins0;
		output_data(1) <= ins1;
	end process comb;
end architecture RTL;
