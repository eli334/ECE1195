LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_shift_register IS
    generic (
		REG_WIDTH : integer := 32
	);
    PORT( 
      CLK 	: IN     std_logic;
      D_IN	: IN     std_logic;
      P_IN  : IN     std_logic_vector(REG_WIDTH-1 downto 0); -- parallel in
	  EN  	: IN     std_logic;
      RST 	: IN     std_logic;
      Q   	: OUT    std_logic
   );

-- Declarations

END ee_shift_register ;