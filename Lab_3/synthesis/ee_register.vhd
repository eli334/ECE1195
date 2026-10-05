LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_register IS
    generic (
        REG_WIDTH : integer := 32
        );
    PORT( 
      LOAD		: IN     std_logic;
      CLK		: IN     std_logic;
      P_IN		: IN     std_logic_vector(REG_WIDTH-1 downto 0); -- parallel in
      RST		: IN     std_logic;
      P_OUT		: OUT    std_logic_vector(REG_WIDTH-1 downto 0)  -- parallel out
   );
end entity ee_register;

architecture struct of ee_register is
    signal reg : STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0);
begin
    process(CLK, RST)
    begin
        if(RST = '1') then
            reg <= (others => '0'); -- reset first because it's async
        elsif(rising_edge(CLK)) then
            if(load = '1') then
                reg <= P_IN;      -- load parallel in
            end if;
        end if;
    end process;
    
    P_OUT   <= reg;
end struct;