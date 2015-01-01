library ieee;
use ieee.std_logic_1164.all;

use work.processor_pkg.all;

entity reg_file is
	generic (
		PARALEL_READS : integer := PARALEL_READS_FROM_REG_FILE;
		PARALEL_WRITES : integer := PARALEL_WRITES_TO_REG_FILE
	);
	port (
		in_clk : in std_logic;
		in_rst : in std_logic;
		
		in_data : in reg_file_in_data_t;
		in_control : in reg_file_in_control_t;
		
		out_data : out reg_array_t
	);
end entity reg_file;

architecture RTL of reg_file is
	
begin

end architecture RTL;
