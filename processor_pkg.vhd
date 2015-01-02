library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_pkg is
	constant ISSUE_WIDTH : integer := 2;
	constant REG_NUMBER_EXP : integer := 5;
	constant FUNCTIONAL_UNITS : integer := 4;
	constant PARALEL_READS_FROM_REG_FILE : integer := 2;
	constant PARALEL_WRITES_TO_REG_FILE : integer  := 2;

	subtype address_t is std_logic_vector(31 downto 0);

	subtype word_t is std_logic_vector(31 downto 0);
	
	subtype reg_addr_t is std_logic_vector(REG_NUMBER_EXP-1 downto 0);
	
	type reg_addr_array_t is array (0 to PARALEL_READS_FROM_REG_FILE*ISSUE_WIDTH-1) of reg_addr_t; --addresses for reading
	type reg_write_addr_array_t is array(0 to PARALEL_WRITES_TO_REG_FILE-1) of reg_addr_t;
	type reg_write_array_t is array(0 to PARALEL_WRITES_TO_REG_FILE-1) of word_t;
	
	type reg_array_t is array (0 to PARALEL_READS_FROM_REG_FILE*ISSUE_WIDTH-1) of word_t;
	
	subtype operand_t is word_t;
	
	type operand_bundle_t is record
		reg_a : operand_t;
		reg_b : operand_t;
		imm : operand_t;
	end record operand_bundle_t;
	
	type operand_bundle_array_t is array(0 to ISSUE_WIDTH-1) of operand_bundle_t;
	--IF
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
	--ID
	type id_in_data_t is record
		instructions : undecoded_instruction_array_t;
	end record id_in_data_t;

	subtype if_out_data_t is id_in_data_t;

	type id_in_control_t is record
		stall : std_logic;
		flush : std_logic;
	end record id_in_control_t;

	type mnemonic_t is (ANDD, SUB, ADD, ADC, SBC, CMP, SSUB, SADD, SADC, SSBC, MOV, NOTT, SL, SR, ASR, SMOV, LOAD, STORE,
		BEQ, BGT, BHI, BAL, BLAL, STOP, ERROR);
	type kind_t is (DPR, DPI, BBL, S);
	type instruction_t is record
		pc    : address_t;
		word  : word_t;
		op    : mnemonic_t;
		valid : std_logic;
		reg_src1 : reg_addr_t;
		reg_src2 : reg_addr_t;
		kind : kind_t;
	end record instruction_t;

	type instruction_array_t is array (0 to ISSUE_WIDTH - 1) of instruction_t;
	
	--FIFO
	subtype taken_array_t is std_logic_vector(0 to ISSUE_WIDTH-1);
	
	type fifo_in_control_t is record
		flush : std_logic;
		taken1 : std_logic;
		taken2 : std_logic;
	end record fifo_in_control_t;
	
	type fifo_out_control_t is record
		stall : std_logic;
	end record fifo_out_control_t;
	
	type frontend_out_data_t is record
		instuctions : instruction_array_t;
	end record frontend_out_data_t;
	
	subtype fifo_out_data_t is frontend_out_data_t;

	type fifo_in_data_t is record
		instructions : instruction_array_t;
	end record fifo_in_data_t;

	subtype id_out_data_t is fifo_in_data_t;

	type frontend_in_data_t is record
		jump_pc : address_t;
	end record frontend_in_data_t;

	type frontend_in_control_t is record
		jump       : std_logic;
		taken1 : std_logic;
		taken2 : std_logic;
	end record frontend_in_control_t;

	type ins_memory_address_t is array (0 to ISSUE_WIDTH - 1) of address_t;
	
	subtype address_array_t is ins_memory_address_t;
	
	type ins_memory_data_t is array (0 to ISSUE_WIDTH - 1) of word_t;
	
	subtype word_array_t is ins_memory_data_t;
	
	
	--BACKEND
	
	type backend_in_data_t is record
		instructions : instruction_array_t;
	end record backend_in_data_t;
	
	type backend_in_control_t is record
		commit : std_logic_vector(FUNCTIONAL_UNITS-1 downto 0);
		taken1 : std_logic;
		taken2 : std_logic;
	end record backend_in_control_t;

	type fu_status_t is record
		busy : std_logic;
		--TODO : add status signals for LD/ST unit
	end record;
	
	subtype ls_unit_status_t is fu_status_t;

	type fu_status_array_t is array(0 to FUNCTIONAL_UNITS-1) of fu_status_t;

	type backend_out_control_t is record
		status : fu_status_array_t;
		jump : std_logic;
	end record backend_out_control_t;
	
	type backend_out_data_t is record
		jump_pc : address_t;
	end record backend_out_data_t;

	--of
	
	type of_in_data_t is record
		instructions : instruction_array_t;
	end record of_in_data_t;
	
	type of_in_control_t is record
		flush : std_logic;
		taken1 : std_logic;
		taken2 : std_logic;
	end record of_in_control_t;
	
	subtype operand is word_t;
	
	type of_out_data_t is record
		operands : operand_bundle_array_t;
		instructions : instruction_array_t;
	end record of_out_data_t;
	
	type of_out_control_t is record
		enable : std_logic_vector(FUNCTIONAL_UNITS-1 downto 0);
	end record of_out_control_t;
	
	--reg file
	type reg_file_in_control_t is record
		wr : std_logic_vector(0 to PARALEL_WRITES_TO_REG_FILE-1);
	end record reg_file_in_control_t;
	
	type reg_file_in_data_t is record
		read_addresses : reg_addr_array_t;
		write_addresses : reg_write_addr_array_t;
		data : reg_write_array_t;
	end record reg_file_in_data_t;
	--data mem
	subtype data_mem_address_t is address_t;
	subtype data_mem_data_t is word_t;
	
	type data_mem_out_control_t is record
		fc : std_logic;
	end record data_mem_out_control_t;
	
	type data_mem_in_control_t is record
		rd : std_logic;
		wr : std_logic;
	end record data_mem_in_control_t;
	
	subtype backend_in_control_data_mem_t is data_mem_out_control_t;
	subtype backend_out_control_data_mem_t is data_mem_in_control_t;
	subtype processor_in_control_data_mem is backend_in_control_data_mem_t;
	subtype processor_out_control_data_mem is backend_out_control_data_mem_t;
	-----------------------------------------
	function unsigned_add(data : std_logic_vector; increment : natural) return std_logic_vector;

	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t;
		
	function sign_extend(data : std_logic_vector; length : natural) return std_logic_vector;
end package processor_pkg;

package body processor_pkg is
	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t is
		variable ret : instruction_t;
	begin
		ret.pc    := inst.pc;
		ret.valid := inst.valid;
		ret.word  := word;
		--TODO : decode reg numbers and kinds
		case word(31 downto 27) is
			when "00000" =>
				ret.op := ANDD;
			when "00001" => 
				ret.op := SUB;
			when "00010" => 
				ret.op := ADD;
			when "00011" => 
				ret.op := ADC;
			when "00100" => 
				ret.op := SBC;
			when "00101" => 
				ret.op := CMP;
			when "00110" => 
				ret.op := SSUB;
			when "00111" => 
				ret.op := SADD;
			when "01000" => 
				ret.op := SADC;
			when "01001" =>
				ret.op := SSBC;
			when "01010" =>
				ret.op := MOV;
			when "01011" => 
				ret.op := NOTT;
			when "01100" =>
				ret.op := SL;
			when "01101" => 
				ret.op := SR;
			when "01110" => 
				ret.op := ASR;
			when "01111" => 
				ret.op := MOV;
			when "10000" => 
				ret.op := SMOV;
			when "10100" =>
				ret.op := LOAD;
			when "10101" => 
				ret.op := STORE;
			when "11000" => 
				ret.op := BEQ;
			when "11001" => 
				ret.op := BGT;
			when "11010" => 
				ret.op := BHI;
			when "11011" => 
				ret.op := BAL;
			when "11100" => 
				ret.op := BLAL;
			when "11111" => 
				ret.op := STOP;
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
	
	function sign_extend(data : std_logic_vector; length : natural) return std_logic_vector is
		variable ret : std_logic_vector(length-1 downto 0);
	begin
		ret := std_logic_vector(resize(signed(data), length));
		return ret;
	end function sign_extend;
end package body processor_pkg;
