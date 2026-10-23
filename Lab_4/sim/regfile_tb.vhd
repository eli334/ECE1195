library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity regfile_tb is
end regfile_tb;

architecture tb of regfile_tb is
    signal simDone : BOOLEAN := false;
    constant CLK_PERIOD : TIME := 1 us;
    signal read1, read2 : STD_LOGIC_VECTOR(4 downto 0);
    signal data1, data2 : STD_LOGIC_VECTOR(31 downto 0);
    signal writeSelect : STD_LOGIC_VECTOR(4 downto 0);
    signal dataIn : STD_LOGIC_VECTOR(31 downto 0);
    signal regWrite, RST, CLK : STD_LOGIC;

    
begin
    UUT : entity work.ee_regfile_behav
    port map(
        read1       => read1,
        data1       => data1,
        read2       => read2,
        data2       => data2,
        writeSelect => writeSelect,    -- write address select 
        dataIn      => dataIn,  -- data to be written
        regWrite    => regWrite,       -- toggles writing on and off
        RST         => RST,      
        CLK         => CLK
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
    variable byteVal : STD_LOGIC_VECTOR(7 downto 0);
        begin
        RST <= '0';
        regWrite <= '1';
        
        wait until falling_edge(clk);

        for i in 1 to 2**writeSelect'length-1 loop
            byteVal := std_logic_vector(to_unsigned(i + 1, 8));
            dataIn <= byteVal & byteVal & byteVal & byteVal;
            
            writeSelect <= std_logic_vector(to_unsigned(i, writeSelect'length));
            read1       <= std_logic_vector(to_unsigned(i, read1'length));
            wait for CLK_PERIOD;
            
            assert(data1 = byteVal & byteVal & byteVal & byteVal)
                report "Data was not written to register " & integer'image(i);
        end loop;
        
        for i in 2**writeSelect'length-1 downto 1 loop
            byteVal := std_logic_vector(to_unsigned(i + 1, 8));
            read2 <= std_logic_vector(to_unsigned(i, read2'length));

            wait for CLK_PERIOD/32;
            
            assert(data2 = byteVal & byteVal & byteVal & byteVal)
                report "Data was not read correctly by read2 in register " & integer'image(i);
        end loop;
        
        RST <= '1'; -- at falling edge already
        regWrite <= '0';
        wait for CLK_PERIOD / 8;
        RST <= '0';

         for i in 1 to 2**writeSelect'length-1 loop
            read1       <= std_logic_vector(to_unsigned(i, read1'length));
            wait for CLK_PERIOD/128; -- async and instant in sim
            
            assert(data1 = x"00000000")
                report "Data was not reset in register " & integer'image(i);
        end loop;
        
        wait until falling_edge(clk);

        regWrite    <= '1';
        writeSelect <= "00000";
        dataIn      <= x"1234ABCD";
        read1       <= "00000";
        wait for CLK_PERIOD;

        regWrite    <= '0';
        
        assert(data1 = x"00000000")
            report "$0 did not block write" severity error;
        
        wait until falling_edge(clk);
        

        report "Simulation finished.";
        simDone <= true;
        wait;
    end process;
end tb;