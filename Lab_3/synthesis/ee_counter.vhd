LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_counter IS
    generic (
        COUNTER_WIDTH : integer := 5
        );
    PORT( 
      CLK		: IN     std_logic;
      RST		: IN     std_logic;
      ENABLE	: IN     std_logic;
      C_max     : OUT    std_logic;
      COUNT	: OUT    std_logic_vector(COUNTER_WIDTH-1 downto 0)  -- parallel out
   );
end entity ee_counter;

architecture struct of ee_counter is
    signal reg : STD_LOGIC_VECTOR(COUNTER_WIDTH-1 downto 0);
begin
    process(CLK, RST)
    begin
        if(RST = '1') then
            reg <= (others => '0'); -- reset first because it's async
        elsif(rising_edge(CLK)) then
            if(ENABLE = '1') then
                reg <= std_logic_vector(unsigned(reg) + 1);      -- increment counter
            end if;
        end if;
    end process;

    COUNT   <= reg;
    C_max   <= '1' when reg = (reg'range => '1') else '0';
end struct;