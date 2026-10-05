LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_register IS
    generic (
        REG_WIDTH : integer := 32;
        left_shift : boolean := true
        );
    PORT( 
      LOAD		: IN     std_logic;
      ENABLE	: IN     std_logic;
      CLK		: IN     std_logic;
      SIN		: IN     std_logic;                              -- serial in
      P_IN		: IN     std_logic_vector(REG_WIDTH-1 downto 0); -- parallel in
      RST		: IN     std_logic;
      Q			: OUT    std_logic;                              -- serial out
      P_OUT		: OUT    std_logic_vector(REG_WIDTH-1 downto 0)  -- parallel out
   );
end entity ee_register;

