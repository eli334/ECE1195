LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_shifter IS
    generic (
        IN_WIDTH  : INTEGER := 32;
        OUT_WIDTH : INTEGER := 32;
        SHAMT     : INTEGER := 2
    );
    port ( 
        data_in     : in STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0);
        data_out    : out STD_LOGIC_VECTOR(OUT_WIDTH-1 downto 0)
    );
end ee_shifter;

architecture rtl of ee_shifter is
    constant keep : integer := OUT_WIDTH - SHAMT;
begin
    data_out <= data_in(keep-1 downto 0) & (shamt-1 downto 0 => '0');
end architecture;