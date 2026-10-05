LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY shift_tb IS
END shift_tb;

ARCHITECTURE tb OF shift_tb IS

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

    -- shared control signals
    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';
    signal LOAD     : std_logic := '0';
    signal ENABLE   : std_logic := '0';
    signal SIN      : std_logic := '0';

    -- 64-bit multiplicand shift register
    signal P_IN_L   : std_logic_vector(63 downto 0) := (others => '0');
    signal P_OUT_L  : std_logic_vector(63 downto 0);
    signal Q_L      : std_logic;

    -- 32-bit multiplier shift register
    signal P_IN_R   : std_logic_vector(31 downto 0) := (others => '0');
    signal P_OUT_R  : std_logic_vector(31 downto 0);
    signal Q_R      : std_logic;
    
    signal sim_done : boolean := false;
BEGIN

    UUT_L : entity work.ee_shift_register
        generic map (
            REG_WIDTH  => 64,
            left_shift => true
        )
        port map (
            LOAD   => LOAD,
            ENABLE => ENABLE,
            CLK    => CLK,
            SIN    => SIN,
            P_IN   => P_IN_L,
            RST    => RST,
            Q      => Q_L,
            P_OUT  => P_OUT_L
        );

    UUT_R : entity work.ee_shift_register
        generic map (
            REG_WIDTH  => 32,
            left_shift => false
        )
        port map (
            LOAD   => LOAD,
            ENABLE => ENABLE,
            CLK    => CLK,
            SIN    => SIN,
            P_IN   => P_IN_R,
            RST    => RST,
            Q      => Q_R,
            P_OUT  => P_OUT_R
        );

    -- Clock: runs forever
    clock_process : process
    begin
        while not sim_done loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    testing : process
    begin
        -- Initial reset
        RST <= '1';
        wait for 2 * CLK_PERIOD;
        wait until falling_edge(CLK);
        RST <= '0';
        LOAD <= '1';
        
        P_IN_L <= x"FFFFAAAA22228888";
        P_IN_R <= x"BBBBDDDD";
        wait until falling_edge(CLK);
        LOAD <= '0'; -- value is loaded
        
        ENABLE <= '1';
        wait for 8*CLK_PERIOD; -- 8 shifts; should be:
        assert P_OUT_L = x"FFAAAA2222888800"
            report "UUT_L  failed; did not shift by 8 bits correctly in 8 cycles" severity error;
        assert Q_L = '1'
            report "UUT_L  asserts incorrect bit on the MSB" severity error;
        
        assert P_OUT_R = x"00BBBBDD"
            report "UUT_R failed; did not shift by 8 bits correctly in 8 cycles" severity error;
        assert Q_R = '1'
            report "UUT_R asserts incorrect bit on the LSB" severity error;
        
        ENABLE <= '0';
        wait for 6*CLK_PERIOD;
        assert P_OUT_L = x"FFAAAA2222888800"
            report "UUT_L hold failed; did not hold value" severity error;
        assert P_OUT_R = x"00BBBBDD"
            report "UUT_R hold failed; did not hold value" severity error;
        
        
        ENABLE <= '1';
        SIN <= '1';
        wait for 8*CLK_PERIOD; -- fill 8 bits with SIN
        assert P_OUT_L = x"AAAA2222888800FF"
            report "UUT_L did not read SIN correctly" severity error;
        assert P_OUT_R = x"FF00BBBB"
            report "UUT_R did not read SIN correctly" severity error;
        
        ENABLE <= '0';
        SIN <= '0';
        RST <= '1';
        wait for CLK_PERIOD/4;
        assert P_OUT_L = x"0000000000000000"
            report "UUT_L did not async reset correctly" severity error;
        assert P_OUT_R = x"00000000"
            report "UUT_R did not async reset correctly" severity error;
        
        wait until falling_edge(CLK); -- sync back up to clock
        
        wait for CLK_PERIOD;
        RST <= '0';
        
        wait for 2*CLK_PERIOD; -- nothing should happen here
        
        P_IN_L <= x"0123456789ABCDEF";
        P_IN_R <= x"DEADBEEF";
        
        ENABLE <= '1';
        LOAD <= '1';
        
        wait for CLK_PERIOD;
        assert P_OUT_L = P_IN_L 
            report "UUT_L LOAD did not take priority" severity error;
        assert P_OUT_R = P_IN_R 
            report "UUT_R LOAD did not take priority" severity error;
        
        wait for CLK_PERIOD;
        
        
        report "Simulation completed " severity note;
        sim_done <= true;
        wait;
    end process;

END tb;