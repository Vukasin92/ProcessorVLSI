library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_pkg is
	constant ISSUE_WIDTH : integer := 2;
	constant REG_NUMBER_EXP : integer := 5;
	constant FUNCTIONAL_UNITS : integer := 4;
	constant PARALEL_READS_FROM_REG_FILE : integer := 3;
	constant PARALEL_WRITES_TO_REG_FILE : integer  := 4;

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
		reg_c : operand_t;
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

	type mnemonic_t is (ANDD, SUB, ADD, ADC, SBC, CMP, SSUB, SADD, SADC, SSBC, MOV, NOTT, SL, SR, ASR, MOVI, SMOV, LOAD, STORE,
		BEQ, BGT, BHI, BAL, BLAL, STOP, ERROR);
	type kind_t is (DPR, DPI, BBL, S);
	type instruction_t is record
		pc    : address_t;
		word  : word_t;
		op    : mnemonic_t;
		valid : std_logic;
		reg_src1 : reg_addr_t;
		reg_src2 : reg_addr_t;
		reg_dst : reg_addr_t;
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
	
	--FUs
	
	--branch unit
	
	type branch_in_control_t is record
		commit : std_logic;
		enable : std_logic;
		selectInstruction : std_logic;
	end record branch_in_control_t;
	
	type branch_in_data_t is record
		instructions : instruction_array_t;
		operands : word_array_t; --only imm operands will be connected
		csr : word_t;
	end record branch_in_data_t;
	
	type branch_out_control_t is record
		busy : std_logic;
		jump : std_logic;
		wr : std_logic;
	end record branch_out_control_t;
	
	type branch_out_data_t is record
		--TODO : add rob number maybe? So control units knows which branch instruction has made jump
		jump_pc : address_t;
		write_address : reg_addr_t; -- always 31 - link register
		write_data : word_t;
	end record branch_out_data_t;
		
	--alu
	
	type alu_out_control_t is record
		busy : std_logic;
		wr : std_logic;
		wr_csr : std_logic;
	end record alu_out_control_t;
	
	type alu_in_control_t is record
		commit : std_logic;
		enable : std_logic;
	end record alu_in_control_t;
	
	type alu_out_data_t is record
		write_address : reg_addr_t;
		alu_out : word_t;
		new_csr : word_t;
	end record alu_out_data_t;
	
	type alu_in_data_t is record
		instruction : instruction_t;
		operands : operand_bundle_t;
		csr : word_t;	
	end record alu_in_data_t;
	
	--backend
	
	type backend_in_data_t is record
		instructions : instruction_array_t;
	end record backend_in_data_t;
	
	type backend_in_control_t is record
		commit : std_logic_vector(FUNCTIONAL_UNITS-1 downto 0);
		taken1 : std_logic;
		taken2 : std_logic;
		selectInstruction : std_logic_vector(1 downto 0);
	end record backend_in_control_t;

	type alu_status_t is record
		busy : std_logic;
	end record;

	type alu_status_array_t is array(0 to 1) of alu_status_t;

	type lsu_status_t is record
		busy : std_logic;
		is_load : std_logic;
	end record lsu_status_t;
	
	type bu_status_t is record
		busy : std_logic;
	end record bu_status_t;

	type backend_out_control_t is record
		alu_statuses : alu_status_array_t; --TODO : see what status signal FUs need to send (when writing Ctrl unit) - see all references
		lsu_status : lsu_status_t;
		bu_status : bu_status_t;
		jump : std_logic;
	end record backend_out_control_t;
	
	type backend_out_data_t is record
		jump_pc : address_t;
	end record backend_out_data_t;

	--of
	
	type of_in_data_t is record
		instructions : instruction_array_t;
		new_csr : word_array_t;
	end record of_in_data_t;
	
	type of_in_control_t is record
		flush : std_logic;
		taken1 : std_logic;
		taken2 : std_logic;
		csr_wr : std_logic_vector(1 downto 0);
	end record of_in_control_t;
	
	subtype operand is word_t;
	
	type of_out_data_t is record
		operands : operand_bundle_array_t;
		instructions : instruction_array_t;
		csr : word_t;
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
	
	type data_mem_out_control_t is record
		fc : std_logic;
	end record data_mem_out_control_t;
	
	type data_mem_in_control_t is record
		rd : std_logic;
		wr : std_logic;
	end record data_mem_in_control_t;
	
	type backend_out_data_data_mem_t is record
		addr : address_t;
		data : word_t;
	end record backend_out_data_data_mem_t;
	
	subtype backend_in_control_data_mem_t is data_mem_out_control_t;
	subtype backend_out_control_data_mem_t is data_mem_in_control_t;
	subtype processor_in_control_data_mem is backend_in_control_data_mem_t;
	subtype processor_out_control_data_mem is backend_out_control_data_mem_t;
	subtype processor_out_data_data_mem is backend_out_data_data_mem_t;
	
	--ls unit
	
	subtype ls_unit_in_control_mem_t is backend_in_control_data_mem_t;
	subtype ls_unit_out_control_mem_t is backend_out_control_data_mem_t;
	type ls_unit_out_data_mem_t is record
		addr : address_t;
		data : word_t;
	end record ls_unit_out_data_mem_t;
	
	type ls_unit_in_control_t is record
		enable : std_logic;
		commit : std_logic;
		selectInstruction : std_logic;
	end record ls_unit_in_control_t;
	
	type ls_unit_out_control_t is record
		busy : std_logic;
		wr : std_logic;
		is_load : std_logic;
	end record ls_unit_out_control_t;
	
	type ls_unit_in_data_t is record
		operands : operand_bundle_array_t;
		instructions : instruction_array_t;
	end record ls_unit_in_data_t;
	
	type ls_unit_out_data_t is record
		reg_number : reg_addr_t;
		reg_value : word_t;
	end record ls_unit_out_data_t;
	-----------------------------------------
	function unsigned_add(data : std_logic_vector; increment : natural) return std_logic_vector;

	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t;
		
	function sign_extend(data : std_logic_vector; length : natural) return std_logic_vector;
		
	function setN(csr : word_t) return word_t;
	function setZ(csr : word_t) return word_t;
	function setC(csr : word_t) return word_t;
	function setV(csr : word_t) return word_t;
		
	function resetN(csr : word_t) return word_t;
	function resetZ(csr : word_t) return word_t;
	function resetC(csr : word_t) return word_t;
	function resetV(csr : word_t) return word_t;
	
	function getN(csr : word_t) return std_logic;
	function getZ(csr : word_t) return std_logic;
	function getC(csr : word_t) return std_logic;
	function getV(csr : word_t) return std_logic;
		
	function unsigned_sub(data : std_logic_vector; decrement : natural) return std_logic_vector;
end package processor_pkg;

package body processor_pkg is
	function decode(inst : undecoded_instruction_t; word : word_t) return instruction_t is
		variable ret : instruction_t;
	begin
		--TODO : add spot for reorder buffer index number to fill when instruction is taken from fifo
		ret.pc    := inst.pc;
		ret.valid := inst.valid;
		ret.word  := word;
		case word(31 downto 27) is
			when "00000" =>
				ret.op := ANDD;
				ret.kind := DPR;
			when "00001" => 
				ret.op := SUB;
				ret.kind := DPR;
			when "00010" => 
				ret.op := ADD;
				ret.kind := DPR;
			when "00011" => 
				ret.op := ADC;
				ret.kind := DPR;
			when "00100" => 
				ret.op := SBC;
				ret.kind := DPR;
			when "00101" => 
				ret.op := CMP;
				ret.kind := DPR;
			when "00110" => 
				ret.op := SSUB;
				ret.kind := DPR;
			when "00111" => 
				ret.op := SADD;
				ret.kind := DPR;
			when "01000" => 
				ret.op := SADC;
				ret.kind := DPR;
			when "01001" =>
				ret.op := SSBC;
				ret.kind := DPR;
			when "01010" =>
				ret.op := MOV;
				ret.kind := DPR;
			when "01011" => 
				ret.op := NOTT;
				ret.kind := DPR;
			when "01100" =>
				ret.op := SL;
				ret.kind := DPR;
			when "01101" => 
				ret.op := SR;
				ret.kind := DPR;
			when "01110" => 
				ret.op := ASR;
				ret.kind := DPR;
			when "01111" => 
				ret.op := MOVI;
				ret.kind := DPI;
			when "10000" => 
				ret.op := SMOV;
				ret.kind := DPI;
			when "10100" =>
				ret.op := LOAD;
				ret.kind := DPR;
			when "10101" => 
				ret.op := STORE;
				ret.kind := DPR;
			when "11000" => 
				ret.op := BEQ;
				ret.kind := BBL;
			when "11001" => 
				ret.op := BGT;
				ret.kind := BBL;
			when "11010" => 
				ret.op := BHI;
				ret.kind := BBL;
			when "11011" => 
				ret.op := BAL;
				ret.kind := BBL;
			when "11100" => 
				ret.op := BLAL;
				ret.kind := BBL;
			when "11111" => 
				ret.op := STOP;
				ret.kind := S;
			when others =>
				ret.op := ERROR;
		end case;
		ret.reg_src1 := word(26 downto 22);
		ret.reg_src2 := word(16 downto 12);
		ret.reg_dst := word(21 downto 17);
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
	
	function unsigned_sub(data : std_logic_vector; decrement : natural) return std_logic_vector is
		variable ret : std_logic_vector(data'range);
	begin
		if (is_X(data)) then
			ret := data;
		else
			ret := std_logic_vector(unsigned(data) - to_unsigned(decrement, data'length));
		end if;
		return ret;
	end function unsigned_sub;
	
	function sign_extend(data : std_logic_vector; length : natural) return std_logic_vector is
		variable ret : std_logic_vector(length-1 downto 0);
	begin
		ret := std_logic_vector(resize(signed(data), length));
		return ret;
	end function sign_extend;
	
	function setN(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(31) := '1';
		return ret;
	end function setN;
	function setZ(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(30) := '1';
		return ret;
	end function setZ;
	function setC(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(29) := '1';
		return ret;
	end function setC;
	function setV(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(28) := '1';
		return ret;
	end function setV;
	
	function getN(csr : word_t) return std_logic is
	begin
		return csr(31);
	end function getN;
	function getZ(csr : word_t) return std_logic is
	begin
		return csr(30);
	end function getZ;
	function getC(csr : word_t) return std_logic is
	begin
		return csr(29);
	end function getC;
	function getV(csr : word_t) return std_logic is
	begin
		return csr(28);
	end function getV;
	
	function resetN(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(31) := '0';
		return ret;
	end function resetN;
	function resetZ(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(30) := '0';
		return ret;
	end function resetZ;
	function resetC(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(29) := '0';
		return ret;
	end function resetC;
	function resetV(csr : word_t) return word_t is
		variable ret : word_t;
	begin
		ret := csr;
		ret(28) := '0';
		return ret;
	end function resetV;
end package body processor_pkg;
