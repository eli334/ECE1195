LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity ee_CLO IS
    port( 
      data_in       : in STD_LOGIC_VECTOR(31 downto 0);
      returned_ones : out STD_LOGIC_VECTOR(31 downto 0)
   );
end entity ee_CLO;

architecture rtl of ee_CLO is

begin
    process(data_in)
    variable numOnes : INTEGER range 0 to 32;
    begin
        numOnes := 0;
        countOnes : for i in 31 downto 0 loop
            if data_in(i) = '1' then
                numOnes := numOnes + 1;
            else
                exit;
            end if;
        end loop countOnes;

        returned_ones <= std_logic_vector(TO_UNSIGNED(numOnes, 32));
    end process;
    

end architecture;

