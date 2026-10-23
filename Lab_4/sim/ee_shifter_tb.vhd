library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ee_shifter_tb is
end ee_shifter_tb;

architecture tb of ee_shifter_tb is
    constant width0in  : integer := 26;
    constant width0out : integer := 28;
    constant width1in  : integer := 32;
    constant width1out : integer := 32;
    constant shiftamt  : integer :=  2;

    signal testSig0In  : STD_LOGIC_VECTOR(width0in-1 downto 0);
    signal testSig0Out : STD_LOGIC_VECTOR(width0out-1 downto 0);
    signal testSig1In  : STD_LOGIC_VECTOR(width1in-1 downto 0);
    signal testSig1Out : STD_LOGIC_VECTOR(width1out-1 downto 0);
begin
    UUT0 : entity work.ee_shifter(rtl)
        generic map(
            IN_WIDTH  => width0in,
            OUT_WIDTH => width0out,
            SHAMT     => shiftamt
        )
        port map(
            data_in => testSig0In,
            data_out => testSig0Out
        );

    UUT1 : entity work.ee_shifter(rtl)
    generic map(
            IN_WIDTH  => width1in,
            OUT_WIDTH => width1out,
            SHAMT     => shiftamt
        )
        port map(
            data_in => testSig1In,
            data_out => testSig1Out
        );
    
        process
        begin
        -- 26 -> 28: nothing is dropped, two zeros are appended
        testSig0In <= std_logic_vector(to_unsigned(1, 26));
        wait for 1 ns;
        assert testSig0Out = x"0000004" report "26->28: 1 should become 4" severity error;
 
        testSig0In <= (others => '1');
        wait for 1 ns;
        assert testSig0Out = x"FFFFFFC" report "26->28: all ones failed" severity error;
 
        testSig0In <= std_logic_vector(to_unsigned(2**25, 26));   -- top bit only
        wait for 1 ns;
        assert testSig0Out = x"8000000" report "26->28: top bit should land in bit 27" severity error;
 
        -- 32 -> 32: the top two bits are dropped
        testSig1In <= x"00000001";
        wait for 1 ns;
        assert testSig1Out = x"00000004" report "32->32: 1 should become 4" severity error;
 
        testSig1In <= x"FFFFFFFF";
        wait for 1 ns;
        assert testSig1Out = x"FFFFFFFC" report "32->32: all ones failed" severity error;
 
        testSig1In <= x"C0000001";                                 -- top two bits set
        wait for 1 ns;
        assert testSig1Out = x"00000004" report "32->32: top two bits should be dropped" severity error;
 
        report "Shifter tests finished.";
        wait;
        end process;
end tb;