library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity reg_file is
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in reg_file_in_data_t;
		in_control : in reg_file_in_control_t;
		
		out_data : out reg_array_t
	);
end entity reg_file;

architecture RTL of reg_file is
	type regs_t is array (0 to 2**REG_NUMBER_EXP - 1) of word_t;
	type register_t is record
		registers : regs_t;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		for i in ret.registers'range loop
			ret.registers(i) := unsigned_add(Std_logic_vector(To_unsigned(i, 32)),1);-- for test : (others => '0');
		end loop;
		return ret;
	end function init;
	
	signal output_data : reg_array_t;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (in_data, in_control, register_reg, output_data) is
	begin
		out_data <= output_data;
		register_next <= register_reg;
		
		for i in 0 to PARALEL_READS_FROM_REG_FILE*ISSUE_WIDTH-1 loop
			output_data(i) <= register_reg.registers(To_integer(Unsigned(in_data.read_addresses(i))));
		end loop;
		
		for i in 0 to PARALEL_WRITES_TO_REG_FILE-1 loop
			if (in_control.wr(i)='1') then
				register_next.registers(To_integer(Unsigned(in_data.write_addresses(i)))) <= in_data.data(i);
				
				for j in 0 to PARALEL_READS_FROM_REG_FILE*ISSUE_WIDTH-1 loop
					if (in_data.read_addresses(j) = in_data.write_addresses(i)) then
						output_data(j) <= in_data.data(i); --bypass write value to read port
					end if;
				end loop;
			end if;
		end loop;
	end process comb;
end architecture RTL;
