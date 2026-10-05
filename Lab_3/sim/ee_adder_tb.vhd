library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity ee_adder_tb is
end ee_adder_tb;

architecture TB of ee_adder_tb is
    component ee_adder_generic_32 is
    generic (N : INTEGER := 32);
    port(
        numA, numB  : in std_logic_vector(N-1 downto 0);
        sub         : in std_logic;
        numSum      : out std_logic_vector(N-1 downto 0);
        Carry_out   : out std_logic
        );
    end component;
    
    constant WIDTH                : positive := 6;   -- small enough to test all 2^WIDTH inputs
    signal numA_small, numB_small : std_logic_vector(WIDTH-1 downto 0);
    signal sub_small              : std_logic;
    signal numSum_small           : std_logic_vector(WIDTH-1 downto 0);
    signal Carry_out_small        : std_logic;
    
    constant MAX_WIDTH            : positive := 64;
    signal numA_64, numB_64       : std_logic_vector(MAX_WIDTH-1 downto 0);
    signal sub_64                 : std_logic;
    signal numSum_64              : std_logic_vector(MAX_WIDTH-1 downto 0);
    signal Carry_out_64           : std_logic;
begin
    DUT6 : ee_adder_generic_32
        generic map ( N => WIDTH )
        port map (
            numA      => numA_small,
            numB      => numB_small,
            sub       => sub_small,
            numSum    => numSum_small,
            Carry_out => Carry_out_small
        );
        
    DUT64 : ee_adder_generic_32
        generic map ( N => MAX_WIDTH )
        port map (
            numA      => numA_64,
            numB      => numB_64,
            sub       => sub_64,
            numSum    => numSum_64,
            Carry_out => Carry_out_64
        );
        
        
        custom_width_test : process
          variable tempI, tempJ : unsigned(WIDTH-1 downto 0);
        begin
            -- addition
            sub_small <= '0';
            
            for i in 0 to 2**WIDTH - 1 loop
                tempI := to_unsigned(i, WIDTH);
                numA_small <= std_logic_vector(tempI);
                for j in 0 to 2**WIDTH - 1 loop
                
                    tempJ := to_unsigned(j, WIDTH);
                    numB_small <= std_logic_vector(tempJ);
                    
                    wait for 10 ns;
                    
                    assert(unsigned(numSum_small) = tempI + tempJ)
                      report "Addition failed"
                      severity failure;
                    
                    assert((Carry_out_small = '1') = (i + j > 2**WIDTH - 1))
                      report "Carry failed (add)"
                      severity failure;
                end loop;
            end loop;
            
            -- subtraction
            sub_small <= '1';
            
            for i in 0 to 2**WIDTH - 1 loop
                tempI := to_unsigned(i, WIDTH);
                numA_small <= std_logic_vector(tempI);
                
                for j in 0 to 2**WIDTH - 1 loop
                    tempJ := to_unsigned(j, WIDTH);
                    numB_small <= std_logic_vector(tempJ);
                    
                    wait for 10 ns;
                    
                    assert(unsigned(numSum_small) = tempI - tempJ) 
                      report "Subtraction failed"
                      severity failure;
                      
                    assert((Carry_out_small = '1') = (i >= j))
                      report "Carry failed (sub)" 
                      severity failure;
                end loop;    
            end loop;
            report "Sim finished.";
        wait;
    end process;
    
    corner_case_test : process
    begin

    sub_64 <= '0'; -- addition tests first
    
    
    numA_64 <= x"0000000000000001";
    numB_64 <= x"0000000000000000";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = "1") report "1+0 failed.";
    assert(Carry_out_64 = '0') report "1+0 returned incorrect carry bit."; 
    
    numA_64 <= x"FFFFFFFFFFFFFFFF";
    numB_64 <= x"0000000000000001";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = "0") report "0xFFFFFFFFFFFFFFFF + 1 did not overflow correctly";
    assert(Carry_out_64 = '1') report "Overflow returned incorrect carry bit."; 
    
    numA_64 <= x"7FFFFFFFFFFFFFFF";
    numB_64 <= x"0000000000000001";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"8000000000000000") report "0x7FFFFFFFFFFFFFFF + 1 did not work correctly.";
    assert(Carry_out_64 = '0') report "0x7FFFFFFFFFFFFFFF + 1 returned incorrect carry bit."; 
       
    
    sub_64 <= '1'; -- subtraction tests
    
    numA_64 <= x"000000000000000A";
    numB_64 <= x"0000000000000003";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"0000000000000007") report "0xA - 0x3 did not work correctly.";
    assert(Carry_out_64 = '1') report "0xA - 0x3 returned incorrect carry bit.";
    
    
    numA_64 <= x"0000000000000003";
    numB_64 <= x"000000000000000A";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"FFFFFFFFFFFFFFF9") report "0x3 - 0xA did not work correctly.";
    assert(Carry_out_64 = '0') report "0x3 - 0xA returned incorrect carry bit.";
    
    
    numA_64 <= x"0123456789ABCDEF";
    numB_64 <= x"0123456789ABCDEF";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = "0") report "random X - X did not work correctly.";
    assert(Carry_out_64 = '1') report "X - X returned incorrect carry bit.";
    
    numA_64 <= x"0123456789ABCDEF";
    numB_64 <= x"0000000000000000";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"0123456789ABCDEF") report "random X - 0 did not work correctly.";
    assert(Carry_out_64 = '1') report "X - 0 returned incorrect carry bit";
    
    sub_64 <= '0'; -- more addition tests
    
    numA_64 <= x"AAAAAAAAAAAAAAAA";
    numB_64 <= x"5555555555555555";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"FFFFFFFFFFFFFFFF") report "all As + 5s did not work correctly.";
    assert(Carry_out_64 = '0') report "As + 5s returned incorrect carry bit";
    
    numA_64 <= x"8000000000000000";
    numB_64 <= x"8000000000000000";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"0000000000000000") report "Only both MSBs adding did not work correctly.";
    assert(Carry_out_64 = '1') report "Adding MSBs returned incorrect carry bit";
    
    
    numA_64 <= x"0000000000000000";
    numB_64 <= x"0000000000000000";
    wait for 10 ns;
    
    assert(unsigned(numSum_64) = x"0000000000000000") report "0 + 0 did not return 0.";
    assert(Carry_out_64 = '0') report "0 + 0 gave wrong carry";
    
    
    report "Corner case test finished.";
    
    wait;
    end process;
end TB;  