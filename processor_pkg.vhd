library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_pkg is
	constant ISSUE_WIDTH : integer := 2;

	subtype address_t is std_logic_vector(31 downto 0);

	type address_array_t is array (0 to ISSUE_WIDTH - 1) of address_t;

	subtype word_t is std_logic_vector(31 downto 0);

	type word_array_t is array (0 to ISSUE_WIDTH - 1) of word_t;

	type if_in_data_t is record
		jump_pc : address_t;
	end record if_in_data_t;

	type if_in_control_t is record
		jump  : std_logic;
		stall : std_logic;
	end record if_in_control_t;

	type undecoded_instruction_t is record
		pc    : address_t;
		valid : std_logic;
	end record undecoded_instruction_t;

	type undecoded_instruction_array_t is array (0 to ISSUE_WIDTH - 1) of undecoded_instruction_t;

	type id_in_data_t is record
		instructions : undecoded_instruction_array_t;
	end record id_in_data_t;

	type id_in_control_t is record
		stall : std_logic;
		flush : std_logic;
	end record id_in_control_t;

	type mnemonic_t is (ADD, ERROR);
	type instruction_t is record
		pc    : address_t;
		word  : word_t;
		op    : mnemonic_t;
		valid : std_logic;
	end record instruction_t;

	type instruction_array_t is array (0 to ISSUE_WIDTH - 1) of instruction_t;

	type fifo_in_data_t is record
		instructions : instruction_array_t;
	end record fifo_in_data_t;

	subtype id_out_data_t is fifo_in_data_t;

	subtype if_out_data_t is id_in_data_t;

	type frontend_in_data_t is record
		jump_pc : address_t;
	end record frontend_in_data_t;

	type frontend_in_control_t is record
		jump       : std_logic;
		test_stall : std_logic;
	end record frontend_in_control_t;

	function unsigned_add(data : std_logic_vector; increment : natural) return std_logic_vector;

	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t;
end package processor_pkg;

package body processor_pkg is
	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t is
		variable ret : instruction_t;
	begin
		ret.pc    := inst.pc;
		ret.valid := inst.valid;
		ret.word  := word;
		case word(31 downto 27) is
			when "00000" =>
				ret.op := ADD;
			when others =>
				ret.op := ERROR;
		end case;
		return ret;
	end function decode;

	function unsigned_add(data : std_logic_vector; increment : natural) return std_logic_vector is
		variable ret : std_logic_vector(data'range);
	begin
		if (is_X(data)) then
			ret := data;
		else
			ret := std_logic_vector(unsigned(data) + to_unsigned(increment, data'length));
		end if;
		return ret;
	end function unsigned_add;
end package body processor_pkg;
