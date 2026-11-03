library ieee;
use ieee.std_logic_1164.all;

entity cpu_tb is
    port(
        reset : in STD_LOGIC;
        clock : in STD_LOGIC
    );
end cpu_tb;

architecture tb of cpu_tb is
    signal MemWrite : STD_LOGIC;
    signal mem_addr : STD_LOGIC_VECTOR(31 downto 0);
    signal cpu_to_mem, mem_to_cpu : STD_LOGIC_VECTOR(31 downto 0);
begin
    U_0 : entity work.CPU
        port map(
            Reset         => Reset,
            Clock         => clock,
            MemoryDataIn  => mem_to_cpu,
            MemoryAddress => mem_addr,
            MemoryDataOut => cpu_to_mem,
            MemWrite      => MemWrite
        );
    U_1 : entity work.CPU_memory
    generic map (
        ADDR_BITS => 12
    )
    port map( 
      Clk      => clock,
      MemWrite => MemWrite,
      addr     => mem_addr,
      dataIn   => cpu_to_mem,
      MemWait  => open,
      dataOut  => mem_to_cpu
   );
end tb;