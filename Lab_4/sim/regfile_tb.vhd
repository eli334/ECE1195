library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity regfile_tb is
end regfile_tb;

architecture tb of regfile_tb is
    signal simDone : BOOLEAN := false;
    constant CLK_PERIOD : TIME := 1 us;
    signal readLine1, readLine2 : STD_LOGIC_VECTOR(4 downto 0);
    signal dataLine1, dataLine2 : STD_LOGIC_VECTOR(31 downto 0);
    signal writeSelect : STD_LOGIC_VECTOR(4 downto 0);
    signal dataLineWrite : STD_LOGIC_VECTOR(31 downto 0);
    signal regWrite, RST, CLK : STD_LOGIC;
begin
    UUT : entity work.ee_regfile_behav
    port map(
        read1    => readLine1,
        data1    => dataLine1,
        read2    => readLine2,
        data2    => dataLine2,
        dataWSel => writeSelect,    -- write address select 
        dataWIn  => dataLineWrite,  -- data to be written
        regWrite => regWrite,       -- toggles writing on and off
        RST      => RST,      
        CLK      => CLK
    );

    clock_gen : process
        begin
        while not simDone loop
            CLK <= '0';
            wait for CLK_PERIOD/2;
            CLK <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    UUT_test : process
        begin
        dataLine1 <= x"1234ABCD";

        simDone <= true;
        wait;
    end process;
end tb;