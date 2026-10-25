LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_sign_extender IS
    port ( 
        data_in     : in STD_LOGIC_VECTOR(15 downto 0);
        ExtOp       : in STD_LOGIC; -- '0' is sign-extend, '1' is zero-extend
        data_out    : out STD_LOGIC_VECTOR(31 downto 0)
    );
end ee_sign_extender;

architecture rtl of ee_sign_extender is
    signal sign_bit : STD_LOGIC;
begin
    --
    sign_bit <= data_in(15) and not(ExtOp);
    
    data_out <= (31 downto 16 => sign_bit) & data_in;
end architecture;