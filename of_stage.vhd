library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity of_stage is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in of_in_data_t;
		in_control : in of_in_control_t;
		in_reg : in reg_array_t;
		
		out_data : out of_out_data_t;
		out_control : out of_out_control_t;
		out_reg : out reg_addr_array_t
	);
end entity of_stage;

architecture RTL of of_stage is
	type register_t is record
		instructions : instruction_array_t;
		operands : operand_bundle_array_t;
		taken1 : std_logic;
		taken2 : std_logic;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	signal output_data : of_out_data_t;
	signal output_reg : reg_addr_array_t;
	signal output_control : of_out_control_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		for i in ret.instructions'range loop
			ret.instructions(i).valid := '0';
			ret.instructions(i).pc := (others => '0');
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
	
	comb:process (in_control, in_data, register_reg, in_reg, output_data, output_reg, output_control) is
		variable en : std_logic_vector(FUNCTIONAL_UNITS-1 downto 0);
	begin
		register_next <= register_reg;
		out_data <= output_data;
		out_control <= output_control;
		out_reg <= output_reg;
		en := (others => '0');
		
		for i in in_data.instructions'range loop
			output_reg(2*i) <= in_data.instructions(i).reg_src1;
			output_reg(2*i+1) <= in_data.instructions(i).reg_src2;
		end loop;
		
		for i in register_reg.operands'range loop
			register_next.operands(i).reg_a <= in_reg(2*i);
			register_next.operands(i).reg_b <= in_reg(2*i+1);
			if (in_data.instructions(i).kind=DPI) then
				register_next.operands(i).imm <= sign_extend(in_data.instructions(i).word(16 downto 0), 32);
			else
				register_next.operands(i).imm <= sign_extend(in_data.instructions(i).word(26 downto 0), 32);
			end if;
		end loop;
		
		for i in register_reg.instructions'range loop
			register_next.instructions(i) <= in_data.instructions(i);
			if ((register_reg.taken1='1' and i=0) or (register_reg.taken2='1')) then --if one instruction is to be executed, do this only for first one
				if (register_reg.instructions(i).valid='1') then
					case register_reg.instructions(i).op is
					when ANDD | SUB | ADD | ADC | SBC | CMP | SSUB | SADD | SADC | SSBC | MOV | NOTT | SL | SR | ASR | SMOV | MOVI =>
						if (i=0) then
							en(0) := '1';
						else
							en(1) := '1';
						end if;
					when LOAD | STORE => 
						en(2) := '1';
					when BEQ | BGT | BHI | BAL | BLAL =>
						en(3) := '1';
					when STOP =>
						null;--TODO
					when ERROR => 
						null;--TODO
					end case;
				end if;
			end if;
		end loop;
		
		if (in_control.flush = '1') then
			for i in register_reg.instructions'range loop
				register_next.instructions(i).valid <= '0';
			end loop;
		end if;
		
		register_next.taken1 <= in_control.taken1;
		register_next.taken2 <= in_control.taken2;
		output_control.enable <= en;
		output_data.instructions <= register_reg.instructions;
		output_data.operands <= register_reg.operands;	
	end process comb;
end architecture RTL;
