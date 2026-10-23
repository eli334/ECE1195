LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;


ENTITY ee_regfile_behav IS
    -- GENERIC(
    --     REG_WIDTH : INTEGER := 32
    -- );
    PORT( 
        read1 : IN STD_LOGIC_VECTOR(4 downto 0);
        data1 : OUT STD_LOGIC_VECTOR(31 downto 0);
        read2 : IN STD_LOGIC_VECTOR(4 downto 0);
        data2 : OUT STD_LOGIC_VECTOR(31 downto 0);
        writeSelect : IN STD_LOGIC_VECTOR(4 downto 0); -- write address select 
        dataIn  : IN STD_LOGIC_VECTOR(31 downto 0); -- data to be written
        regWrite: IN STD_LOGIC; -- toggles writing on and off
        RST     : IN STD_LOGIC;
        CLK     : IN STD_LOGIC
        );
end ee_regfile_behav;


architecture behavioral of ee_regfile_behav is
    type reg_array is array (31 downto 0) of std_logic_vector(31 downto 0);
    signal regs : reg_array;
begin
    data1 <= regs(to_integer(unsigned(read1)));
    data2 <= regs(to_integer(unsigned(read2)));
    regs(0) <= (others => '0');

    process(CLK, RST)
    begin
        if(RST = '1') then
            for i in regs'range loop
                regs(i) <= (others => '0');
            end loop;
        elsif(rising_edge(CLK)) then
            if(regWrite = '1') then
                if(writeSelect = "00000") then
                    report("Attempted write to $0; blocked") severity warning;
                else
                    regs(to_integer(unsigned(writeSelect))) <= dataIn;
                end if;
            end if;
        end if;
    end process;
end architecture;

