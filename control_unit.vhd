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
		jump : std_logic;
		valid : std_logic;
	end record rob_elem_t;
	
	type rob_t is array (0 to ROB_SIZE-1) of rob_elem_t;
	
	type register_t is record
		rob : rob_t;
		curr : std_logic_vector(rob_t'length-1 downto 0);
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
			ret.rob(i).valid := '0';
			ret.rob(i).jump := '0';
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
	begin
		register_next <= register_reg;
		out_data <= output_data;
		out_control <= output_control;
		
		ins0 := in_data.instructions(0);
		ins1 := in_data.instructions(1);
		t1 := '0';
		t2 := '0';
		
		--taken1 signal generation
		if (ins0.valid = '1') then
			t1 := '1';
			cmp1 := compare(ins0.reg_src1, in_data.load_reg_number);
			cmp2 := compare(ins0.reg_src2, in_data.load_reg_number);
			if (in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0))) then
				t1 := '0';
			end if;
		end if;
		
		--taken2 signal generation;
		if (ins1.valid = '1' and t1 = '1') then
			t2 := '1';
			cmp1 := compare(ins1.reg_src1, in_data.load_reg_number);
			cmp2 := compare(ins1.reg_src2, in_data.load_reg_number);
			if (in_control.lsu_status.is_load = '1' and ((cmp1 = 0) or (cmp2 = 0))) then
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
		end if;
		
		--selectInstruction generation
		output_control.selectInstruction <= "00";
		for i in in_data.instructions'range loop
		case in_data.instructions(i).op is
			when LOAD | STORE =>
				if (i = 0) then
					output_control.selectInstruction(LS-2) <= '0';
				else
					output_control.selectInstruction(LS-2) <= '1';
				end if;
			when BEQ | BHI | BLAL | BAL| BGT => 
				if (i = 0) then
					output_control.selectInstruction(BRANCH-2) <= '0';
				else
					output_control.selectInstruction(BRANCH-2) <= '1';
				end if;
			when others => 
				null;
			end case;
		end loop;
	
		--TODO: commit signal generation (hazzards 1, 4, 6)
		
		output_control.taken1 <= t1;
		output_control.taken2 <= t2;
	end process comb;
end architecture RTL;
