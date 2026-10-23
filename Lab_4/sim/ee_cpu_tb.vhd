library ieee;
use ieee.std_logic_1164.all;

entity ee_cpu_tb is
end ee_cpu_tb;

architecture tb of ee_cpu_tb is
    signal Clock, Reset, MemWrite : STD_LOGIC;
    signal MemoryDataIn, MemoryAddress, MemoryDataOut : STD_LOGIC_VECTOR(31 downto 0);
begin
    U_0 : entity work.CPU
        port map(
            Reset         => Reset,
            Clock         => Clock,
            MemoryDataIn  => MemoryDataIn,
            MemoryAddress => MemoryAddress,
            MemoryDataOut => MemoryDataOut,
            MemWrite      => MemWrite
        );
end tb;