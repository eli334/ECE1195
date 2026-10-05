LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY register_tb IS
END register_tb;

ARCHITECTURE tb OF register_tb IS

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

    -- shared control signals
    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';
    signal LOAD     : std_logic := '0';

    -- 64-bit register
    signal P_IN_64   : std_logic_vector(63 downto 0) := (others => '0');
    signal P_OUT_64  : std_logic_vector(63 downto 0);

    signal sim_done : boolean := false;
BEGIN

    UUT_L : entity work.ee_register
        generic map (
            REG_WIDTH  => 64
        )
        port map (
            LOAD   => LOAD,
            CLK    => CLK,
            P_IN   => P_IN_64,
            RST    => RST,
            P_OUT  => P_OUT_64
        );

    clock_gen : process
    begin
        while not sim_done loop
            CLK <= '0';
            wait for CLK_PERIOD/2;
            CLK <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    testing : process
    begin
        -- async reset
        RST <= '1';
        wait for CLK_PERIOD;
        wait until falling_edge(CLK); -- reset to start
        
        P_IN_64 <= x"0F0F0F0F0F0F0F0F";
        LOAD <= '1';

        RST <= '0';
        wait for CLK_PERIOD;
        assert P_OUT_64 = x"0F0F0F0F0F0F0F0F"
            report "UUT_64 did not load correctly" severity error;
        LOAD <= '0';
        P_IN_64 <= x"0000000110000000"; -- all 0s would be confusing with reset

        wait for 2*CLK_PERIOD;
        assert P_OUT_64 = x"0F0F0F0F0F0F0F0F"
            report "UUT_64 changed when LOAD was 0" severity error;

        
        wait for CLK_PERIOD/8; -- stagger for async reset
        
        RST <= '1';
        wait for CLK_PERIOD/4; -- async reset should happen immediately
        assert P_OUT_64 = x"0000000000000000"
            report "UUT_64 did not async reset correctly" severity error;

        wait until falling_edge(CLK); -- sync back up to clock
        RST <= '0';

        wait for CLK_PERIOD;
        LOAD <= '1';
        P_IN_64 <= x"ABABABABABABABAB";
        wait for CLK_PERIOD;
        assert P_OUT_64 = x"ABABABABABABABAB"
            report "UUT_64 did not load correctly after async reset 1" severity error;
        
        P_IN_64 <= x"ABCDABCDABCDABCD";
        wait for CLK_PERIOD;
        assert P_OUT_64 = x"ABCDABCDABCDABCD"
            report "UUT_64 did not load correctly after async reset 2" severity error;


        P_IN_64 <= x"ABCDEF0123456789";
        wait for CLK_PERIOD;
        assert P_OUT_64 = x"ABCDEF0123456789"
            report "UUT_64 did not load correctly after async reset 3" severity error;

        LOAD <= '0';

        report "Simulation completed" severity note;
        sim_done <= true;
        wait;
    end process;
end tb;