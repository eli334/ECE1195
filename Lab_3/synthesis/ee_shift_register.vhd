LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ee_shift_register IS
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

-- Declarations

END ee_shift_register;

architecture struct of ee_shift_register is
    signal shift_reg : STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0);
begin
    process(CLK, RST)
    begin
        if(RST = '1') then
            shift_reg <= (others => '0'); -- reset first because it's async
        elsif(rising_edge(CLK)) then
            if(load = '1') then
                shift_reg <= P_IN;      -- load parallel in
            elsif(ENABLE = '1') then
                if(left_shift) then
                    shift_reg <= shift_reg(REG_WIDTH-2 downto 0) & SIN; -- append SIN to right, shifting everything left      
                else
                    shift_reg <= SIN & shift_reg(REG_WIDTH-1 downto 1); -- append SIN to left, shifting everything right
                end if;
            end if;
        end if;
    end process;
    
    P_OUT   <= shift_reg;
    with left_shift select
    Q <=    shift_reg(0) when false,			-- right shift should be rightmost bit
            shift_reg(REG_WIDTH-1) when true;	-- left shift should be leftmost bit
end struct;