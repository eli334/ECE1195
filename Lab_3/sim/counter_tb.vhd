LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity counter_tb is
end counter_tb;

architecture tb of counter_tb is
    component ee_counter is
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
    end component;
    
    constant CLK_PERIOD : time := 20 ns;

    constant COUNTER_WIDTH : integer := 5;
    signal CLK      : std_logic := '0';
    signal RST      : std_logic := '0';
    signal ENABLE   : std_logic := '0';
    signal C_max    : std_logic;
    signal COUNT    : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal sim_done : boolean := false;


begin
    DUT : ee_counter
        generic map ( COUNTER_WIDTH => COUNTER_WIDTH )
        port map (
            CLK     => CLK,
            RST     => RST,
            ENABLE  => ENABLE,
            C_max   => C_max,
            COUNT   => COUNT
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
            RST <= '1';
            ENABLE <= '0';
            wait until falling_edge(CLK); -- reset and sync
            
            RST <= '0';
            ENABLE <= '1';

            for i in 0 to 2**COUNTER_WIDTH-2 loop
                assert COUNT = std_logic_vector(to_unsigned(i, COUNTER_WIDTH)) 
                    report "COUNT did not increment correctly" severity error;
                assert C_max = '0' 
                    report "C_max is 1 when count is not maximum" severity error;
                wait until falling_edge(CLK);

            end loop;

            assert C_max = '1' 
                report "C_max is not 1 when count reaches maximum" severity error;
            
                wait for 2 * CLK_PERIOD; -- let it roll over
            
            assert COUNT = "00001" 
                report "COUNT did not roll over correctly" severity error;
            assert C_max = '0' 
                report "C_max is not 0 when count rolls over" severity error;

            ENABLE <= '0';
            wait for 2 * CLK_PERIOD;
            assert COUNT = "00001" 
                report "COUNT changed when ENABLE was 0" severity error;

            ENABLE <= '1';
            wait for 2 * CLK_PERIOD;

            assert COUNT = "00011" 
                report "COUNT did not increment correctly after ENABLE was re-enabled"
                severity error;

            RST <= '1';
            wait for CLK_PERIOD/8; -- async reset should happen immediately
            assert COUNT = "00000"
                report "COUNT did not async reset correctly" severity error;

            report "Testbench completed" severity note;
            sim_done <= true;
            wait;
        end process;
end architecture tb;


