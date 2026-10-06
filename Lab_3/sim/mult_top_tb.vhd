library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity mult_top_tb is
end mult_top_tb;

architecture tb of mult_top_tb is
    constant MULT_WIDTH     : integer := 32;
    
    signal A            : std_logic_vector(MULT_WIDTH - 1 downto 0) := (others => '0');
    signal B            : std_logic_vector(MULT_WIDTH - 1 downto 0) := (others => '0');
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal R            : std_logic_vector((2 * MULT_WIDTH - 1) downto 0);
    signal done         : std_logic;

    signal A_4          : std_logic_vector(3 downto 0);
    signal B_4          : std_logic_vector(3 downto 0);
    signal R_4          : std_logic_vector(7 downto 0);
    signal done_4       : std_logic;

    signal sim_done     : boolean := false;
    constant CLK_PERIOD : time := 20 ns;

begin
    DUT_4 : entity work.ee_mult_top
        generic map (
            MULT_WIDTH => 4
        )
        port map (
            A     => A_4,
            B     => B_4,
            clk   => clk,
            rst   => rst,
            R     => R_4,
            done  => done_4
        );

    DUT_32 : entity work.ee_mult_top
        generic map (
            MULT_WIDTH => 32
        )
        port map (
            A     => A,
            B     => B,
            clk   => clk,
            rst   => rst,
            R     => R,
            done  => done
        );
    
    clock_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    test_process : process
    begin
        rst <= '1';
        A_4 <= "1011"; -- 11
        B_4 <= "1101"; -- 13
        wait for CLK_PERIOD;

        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for CLK_PERIOD / 8;
        -- partial product 1 is 00001011
        assert R_4 = "00001011" report "4-bit multiplication failed at partial product 1" severity error;
        assert done_4 = '0' report "4-bit multiplication asserts done too early" severity error;
        wait for CLK_PERIOD;
        

        -- partial product 2 is 00001011
        assert R_4 = "00001011" report "4-bit multiplication failed at partial product 2" severity error;
        assert done_4 = '0' report "4-bit multiplication asserts done too early" severity error;
        wait for CLK_PERIOD;
        

        -- partial product 3 is 00110111
        assert R_4 = "00110111" report "4-bit multiplication failed at partial product 3" severity error;
        assert done_4 = '0' report "4-bit multiplication asserts done too early" severity error;
        
        wait for CLK_PERIOD;
        assert R_4 = "10001111" report "4-bit multiplication failed at final result" severity error;
        assert done_4 = '1' report "4-bit multiplication failed to assert done" severity error;
        
        wait for 2 * CLK_PERIOD;
        assert R_4 = "10001111" report "4-bit multiplication failed to hold final result" severity error;
        assert done_4 = '1' report "4-bit multiplication failed to hold done" severity error;
        
        

        -- 32 bit tests
        rst <= '1';
        A <= x"12341234";
        B <= x"43214321";
        wait for CLK_PERIOD;
        
        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for 30 * CLK_PERIOD;
        wait for CLK_PERIOD / 8;
        assert done = '0' report "32-bit multiplication asserts done too early" severity error;
        wait for CLK_PERIOD; -- just after the next clock period, check the result
        assert done = '1' report "32-bit multiplication failed to assert done in time" severity error;
        assert R = x"04C5FE3FEE2DF4B4" report "32-bit multiplication failed" severity error;

        wait for CLK_PERIOD;
        
        -- test 2
        rst <= '1';
        A <= x"FFFFFFFF";
        B <= x"FFFFFFFF";
        wait for CLK_PERIOD;
        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for 31 * CLK_PERIOD + CLK_PERIOD / 8; -- just after the next clock period, check the result
        assert done = '1' report "32-bit multiplication failed to assert done in time" severity error;
        assert R = x"FFFFFFFE00000001" report "32-bit multiplication of F's failed" severity error;

        wait for CLK_PERIOD;
        
        -- test 3
        rst <= '1';
        A <= x"00000000";
        B <= x"FFFFFFFF"; -- 0 * N = 0
        wait for CLK_PERIOD;
        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for 31 * CLK_PERIOD + CLK_PERIOD / 8; -- just after the next clock period, check the result
        assert R = x"0000000000000000" report "32-bit multiplication by 0 failed" severity error;

        wait for CLK_PERIOD;
        
        -- test 4
        rst <= '1';
        A <= x"12345678";
        B <= x"87654321";
        wait for CLK_PERIOD;
        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for 16 * CLK_PERIOD;
        A <= x"00000000"; -- change A in the middle of multiplication, should not affect result
        B <= x"00000000"; -- same for B
        wait for 15 * CLK_PERIOD + CLK_PERIOD / 8; -- just after the next clock period, check the result
        assert R = x"09A0CD0570B88D78" report "32-bit multiplication failed to hold result after changing inputs" 
            severity error;
        
        wait for CLK_PERIOD;
        
        -- test 5; interrupted by RST test
        rst <= '1';
        A <= x"2468ACE0";
        B <= x"13579BDF";
        wait for CLK_PERIOD;
        wait until falling_edge(clk);
        rst <= '0';
        
        wait until rising_edge(clk);
        wait for 24 * CLK_PERIOD;
        -- interruption by new values
        
        rst <= '1';
        A <= x"11112222";
        B <= x"22224444";
        wait for CLK_PERIOD;
        wait until falling_edge(clk);
        rst <= '0';

        wait until rising_edge(clk);
        wait for 31*CLK_PERIOD + CLK_PERIOD / 8;
        assert R = x"02468f5c22221908" report "calculation that interrupted RST did not give correct R" 
            severity error;
        

        report "Simulation finished" severity note;
        sim_done <= true;
        wait;
    end process;
    
end tb;