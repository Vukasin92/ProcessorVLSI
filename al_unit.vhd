library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity al_unit is
	port (
		in_data : in alu_in_data_t;
		in_control : in alu_in_control_t;
		
		out_data : out alu_out_data_t;
		out_control : out alu_out_control_t
	);
end entity al_unit;

architecture RTL of al_unit is
	type alu_out_t is record
			output : word_t;
			csr : word_t;
			wr : std_logic;
			wr_csr : std_logic;
		end record alu_out_t;
	
	signal output_data : alu_out_data_t;
	signal output_control : alu_out_control_t;
	function func(data : alu_in_data_t) return alu_out_t is
		variable ret : alu_out_t;
		variable a, b : word_t;
		variable temp : std_logic;
		variable temp_out : std_logic_vector(32 downto 0);
	begin
		--TODO : implement all alu functions
		a := data.operands.reg_a;
		
		case data.instruction.kind is
		when DPR => 
			b := data.operands.reg_b;
		when DPI =>
			b := data.operands.imm;
		when others => 
			report "Wrong addressing mode in ALU." severity error;
		end case;
		ret.csr := data.csr;
		ret.wr := '1';
		ret.wr_csr := '0';
		case data.instruction.op is
			when ANDD => 
				ret.output := a AND b;
			when ADD | SADD=>
				ret.wr_csr := '1';
				temp_out := std_logic_vector(('0' & unsigned(a))+('0' & unsigned(b)));
				ret.output := temp_out(31 downto 0);
			when SUB | SSUB => 
				ret.wr_csr := '1';
				temp_out :=std_logic_vector(('1' & unsigned(a))-('0' & unsigned(b)));
				ret.output := temp_out(31 downto 0);
			when ADC | SADC =>
				ret.wr_csr := '1';
				temp_out := std_logic_vector(('0' & unsigned(a))+('0' & unsigned(b)));
				if (getC(ret.csr) = '1') then
					temp_out := unsigned_add(temp_out,1);
				end if;
				ret.output := temp_out(31 downto 0);
			when SBC | SSBC=> 
				ret.wr_csr := '1';
				temp_out :=std_logic_vector(('1' & unsigned(a))-('0' & unsigned(b)));
				if (getC(ret.csr) = '1') then
					temp_out := unsigned_sub(temp_out,1);
				end if;
				ret.output := temp_out(31 downto 0);
			when CMP => 
				ret.wr_csr := '1';
				ret.wr := '0';
				temp_out :=std_logic_vector(('1' & unsigned(a))-('0' & unsigned(b)));
				ret.output := temp_out(31 downto 0);
			when MOV | MOVI | SMOV => 
				ret.output := b;
			when NOTT =>
				--for i in b'range loop 
					--ret.output(i) := not b(i);
				--end loop;
				ret.output := not b;
			when SL =>
				ret.output := std_logic_vector(shift_left(unsigned(a), To_integer(Unsigned(b))));
			when SR => 
				ret.output := std_logic_vector(shift_right(unsigned(a), To_integer(Unsigned(b))));
			when ASR => 
				ret.output := std_logic_vector(shift_right(signed(a), To_integer(Unsigned(b))));
			when others => 
				null;
		end case;
		
		--csr calculation
		temp := '0';
		for i in ret.output'range loop
			temp  := temp or ret.output(i);
		end loop;
		if (temp = '0') then
			ret.csr := setZ(ret.csr);
		else
			ret.csr := resetZ(ret.csr);
		end if;
		
		case data.instruction.op is
			when ADD | ADC | SADC | SADD => 
				if (temp_out(32) = '1') then
					ret.csr := setC(ret.csr);
				else
					ret.csr := resetC(ret.csr);
				end if;
				
				if ((signed(a)>0 and signed(b)>0 and signed(ret.output)<0) or
					(signed(a)<0 and signed(b)<0 and signed(ret.output)>0)) then
					ret.csr := setV(ret.csr);
				else
					ret.csr := resetV(ret.csr);
				end if;
			when SUB | SBC | SSUB | SSBC | CMP => 
				if (temp_out(32) = '0') then
					ret.csr := setC(ret.csr);
				else
					ret.csr := resetC(ret.csr);
				end if;
				if ((signed(a)>0 and signed(b)<0 and signed(ret.output)<0) or
					(signed(a)<0 and signed(b)>0 and signed(ret.output)>0)) then
					ret.csr := setV(ret.csr);
				else
					ret.csr := resetV(ret.csr);
				end if;
			when others =>
				null;
		end case;
		
		case data.instruction.op is
			when ADD | SUB | SBC | ADC => 
				ret.csr := resetN(ret.csr);
				ret.csr := resetV(ret.csr);
			when SADD | SSUB | SSBC | SADC | CMP =>
				if (ret.output(31) = '1') then --check for N bit
					ret.csr := setN(ret.csr);
				else
					ret.csr := resetN(ret.csr);
				end if;
			when others => 
				null;
			end case;
		return ret;
	end function func;
begin
	comb:process (in_data, in_control, output_data, output_control) is
		
		variable alu_out : alu_out_t; 
	begin
		out_data <= output_data;
		out_control <= output_control;
		
		output_data.reg_dst <= in_data.instruction.reg_dst;
		
		output_data.write_address <= in_data.instruction.reg_dst;
		output_control.wr <= '0';
		output_control.wr_csr <= '0';
		output_control.busy <= '0';
		output_data.new_csr <= in_data.csr;
		output_data.alu_out <= (others => '0');
		if (in_control.enable = '1' and in_control.commit = '1') then
			alu_out := func(in_data);
			output_data.alu_out <= alu_out.output;
			output_control.wr <= alu_out.wr;
			output_control.wr_csr <= alu_out.wr_csr;
			output_control.busy <= '1';
			output_data.new_csr <= alu_out.csr;
		end if;
	end process comb;
end architecture RTL;
