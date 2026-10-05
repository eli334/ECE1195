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
        while true loop
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
        P_IN_R <= x"BBBBCCCC";
        wait until falling_edge(CLK);
        LOAD <= '0'; -- value is loaded
        
        ENABLE <= '1';
        wait for 8*CLK_PERIOD; -- 8 shifts; should be:
        assert P_OUT_L = x"FFAAAA2222888800"
            report "left shift failed; did not shift by 8 bits correctly in 8 cycles" severity error;
        assert P_OUT_R = x"00BBBBCC"
            report "right shift failed; did not shift by 8 bits correctly in 8 cycles" severity error;

        report "Simulation finished" severity note;
        wait;   -- stop this process forever
    end process;

END tb;