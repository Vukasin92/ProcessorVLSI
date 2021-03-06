library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.processor_pkg.all;

entity fifo_stage is
	generic (
		BUFFER_SIZE : natural := 3
	);
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in fifo_in_data_t;
		in_control : in fifo_in_control_t;
		
		out_control : out fifo_out_control_t;
		out_data : out fifo_out_data_t
	);
end entity fifo_stage;

architecture RTL of fifo_stage is
	type fifo_array_t is array (0 to 2**BUFFER_SIZE-1) of instruction_t;
	type register_t is record
		fifo_array : fifo_array_t;
		w_ptr : std_logic_vector(BUFFER_SIZE-1 downto 0);
		r_ptr : std_logic_vector(BUFFER_SIZE-1 downto 0);
		count : natural range 0 to 2**BUFFER_SIZE;
	end record register_t;
	
	signal register_reg : register_t;
	signal register_next : register_t;
	
	function init return register_t is
		variable ret : register_t;
	begin
		for i in ret.fifo_array'range loop
			ret.fifo_array(i).valid := '0';
			ret.fifo_array(i).word := (others => '0');
			ret.fifo_array(i).pc := (others => '0');
		end loop;
		ret.count := 0;
		ret.w_ptr := (others => '0');
		ret.r_ptr := (others => '0');
		return ret;
	end function init;
	
	signal output_data : fifo_out_data_t;
	signal output_control : fifo_out_control_t;
begin
	clk:process (in_clk, in_rst) is
	begin
		if (in_rst = '1') then
			register_reg <= init;
		elsif (rising_edge(in_clk)) then
			register_reg <= register_next;
		end if;
	end process clk;
	
	comb:process (register_reg, in_data, in_control, output_control, output_data) is
		variable cnt : natural range 0 to 2**BUFFER_SIZE;
		variable to_add : natural;
	begin
		register_next <= register_reg;
		out_data <= output_data;
		out_control <= output_control;
		output_control.stall <= '0';
		cnt := register_reg.count;
		to_add := 0;
		
		
		
		--read and flush logic
		if (in_control.flush = '1') then
			for i in register_next.fifo_array'range loop
				register_next.fifo_array(i).valid <= '0';
			end loop;
			register_next.r_ptr <= (others => '0');
			register_next.w_ptr <= (others => '0');
			cnt := 0;
		elsif (in_control.taken2 = '1') then
			register_next.r_ptr <= unsigned_add(register_reg.r_ptr, 2);
			for i in output_data.instuctions'range loop
				register_next.fifo_array(To_integer(Unsigned(unsigned_add(register_reg.r_ptr, i)))).valid <= '0';
			end loop;
			cnt := cnt - 2;
		elsif (in_control.taken1 = '1') then
			register_next.r_ptr <= unsigned_add(register_reg.r_ptr, 1);
			register_next.fifo_array(To_integer(Unsigned(register_reg.r_ptr))).valid <= '0';
			cnt := cnt - 1;
		end if;
		
		--write logic
		if (in_control.flush /= '1') then
			if (cnt >= 2**BUFFER_SIZE-1) then
				output_control.stall <= '1';
			else 
				for i in in_data.instructions'range loop
					register_next.fifo_array(To_integer(Unsigned(unsigned_add(register_reg.w_ptr,i)))) <= in_data.instructions(i);
					if (in_data.instructions(i).valid = '1') then
						cnt := cnt + 1;
						to_add := to_add + 1;
					end if;
					register_next.w_ptr <= unsigned_add(register_reg.w_ptr, to_add);
				end loop;	
			end if;
		end if;
		
		--output logic
		for i in out_data.instuctions'range loop
			output_data.instuctions(i) <= register_reg.fifo_array(To_integer(Unsigned(unsigned_add(register_reg.r_ptr,i))));
		end loop;
		register_next.count <= cnt;
	end process comb;
end architecture RTL;
