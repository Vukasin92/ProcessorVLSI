library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity branch_unit is
	port (
		in_clk : std_logic;
		in_rst : std_logic;
		
		in_data : in branch_in_data_t;
		in_control : in branch_in_control_t;
		
		out_data : out branch_out_data_t;
		out_control : out branch_out_control_t
	);
end entity branch_unit;

architecture RTL of branch_unit is
	type register_t is record
		instructionSelect : std_logic;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : branch_out_data_t;
	signal output_control : branch_out_control_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		ret.instructionSelect := '0';
		return ret;
	end function init;
	
	function condition(data : branch_in_data_t; sel : integer) return std_logic is
		variable ret : std_logic;
	begin
		ret := '0';
		case data.instructions(sel).op is
			when BEQ =>
				if (getZ(data.csr) = '1') then
					ret := '1';
				end if;
			when BGT => 
				if (((getN(data.csr) xor getV(data.csr)) or getZ(data.csr)) = '0') then
					ret := '1';
				end if;
			when BHI => 
				if ((getC(data.csr) or getZ(data.csr)) = '0') then
					ret := '1';
				end if;
			when BAL | BLAL =>
				ret := '1';
			when others => 
				report "Wrong instruction executed in branch unit." severity error;
		end case;
			
		return ret;
	end function condition;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (in_data, in_control, output_data, output_control, register_reg) is
		variable instructionIndex : integer;
		variable pc : word_t;
	begin
		out_data <= output_data;
		out_control <= output_control;
		register_next <= register_reg;
		
		output_data.reg_dst <= "11111";
		
		if (register_reg.instructionSelect = '0') then
			instructionIndex := 0;
		else
			instructionIndex := 1;
		end if;
		pc := unsigned_add(in_data.instructions(instructionIndex).pc,1);
		output_data.jump_pc <= std_logic_vector(signed(pc)+signed(in_data.operands(instructionIndex))); --TODO : consider if needed to add 2 more
		output_control.jump <= '0';
		output_control.busy <= '0';
		output_control.wr <= '0';
		output_data.write_address <= (others => '1');
		output_data.write_data <= pc;
		if (in_control.enable = '1') then
			register_next.instructionSelect <= in_control.selectInstruction; --instruction select is late 1 clock, because it is selected in stage before bu
			if (condition(in_data, instructionIndex) = '1') then
				output_control.jump <= '1';
				output_control.busy <= '1';
				if (in_data.instructions(instructionIndex).op = BLAL and in_control.commit = '1') then
					output_control.wr <= '1';
				end if;
			end if;
		end if;
	end process comb;
end architecture RTL;
