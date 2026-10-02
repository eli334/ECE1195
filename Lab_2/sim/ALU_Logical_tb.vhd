----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 03:43:34 AM
-- Design Name: 
-- Module Name: ALU_Logical_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU_Logical_tb is
--  Port ( );
end ALU_Logical_tb;

architecture sim of ALU_Logical_tb is
    signal A, B, R : STD_LOGIC_VECTOR(31 downto 0);
    signal Op : STD_LOGIC_VECTOR(1 downto 0);
begin
    UUT :  entity work.ALU_Logical(rtl)
        port map(
            A => A,
            B => B, 
            Op => Op,
            R => R
         );
    process
        variable pass_count, fail_count : integer := 0;
        procedure test(op_code : integer;
                       a_val, b_val, expected_val : std_logic_vector(31 downto 0)
                  ) is variable expected : std_logic_vector(31 downto 0);
        begin
            A  <= a_val;
            B  <= b_val;
            Op <= std_logic_vector(to_unsigned(op_code, 2));
            
            wait for 1 ns;
            
            -- op codes:
            -- 00 - AND
            -- 01 - OR
            -- 10 - XOR
            -- 11 - NOR
            
        case op_code is
            when 0 => expected := a_val and b_val;
            when 1 => expected := a_val or b_val;
            when 2 => expected := a_val xor b_val;
            when others => expected := a_val nor b_val;
        end case;
        
        if R = expected then
            pass_count := pass_count + 1;
        else
            fail_count := fail_count + 1;
            report "FAIL op=" & integer'image(op_code)
                 & " A=" & integer'image(to_integer(unsigned(a_val)))
                 & " B=" & integer'image(to_integer(unsigned(b_val)));
        end if;
        
        end procedure;
    begin
    
    -- all zeros
    test(0, x"00000000", x"00000000", x"00000000");
    test(1, x"00000000", x"00000000", x"00000000");
    test(2, x"00000000", x"00000000", x"00000000");
    test(3, x"00000000", x"00000000", x"FFFFFFFF");
    
    -- all ones
    test(0, x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF");
    test(1, x"FFFFFFFF", x"FFFFFFFF", x"FFFFFFFF");
    test(2, x"FFFFFFFF", x"FFFFFFFF", x"00000000");
    test(3, x"FFFFFFFF", x"FFFFFFFF", x"00000000");
    
    -- interleaved
    test(0, x"AAAAAAAA", x"55555555", x"00000000");
    test(1, x"AAAAAAAA", x"55555555", x"FFFFFFFF");
    test(2, x"AAAAAAAA", x"55555555", x"FFFFFFFF");
    test(3, x"AAAAAAAA", x"55555555", x"00000000");
    
    -- very interleaved
    test(0, x"F0F0F0F0", x"0F0F0F0F", x"00000000");
    test(1, x"F0F0F0F0", x"0F0F0F0F", x"FFFFFFFF");
    test(2, x"F0F0F0F0", x"0F0F0F0F", x"FFFFFFFF");
    test(3, x"F0F0F0F0", x"0F0F0F0F", x"00000000");

    -- a <op> 0
    test(0, x"12345678", x"00000000", x"00000000");
    test(1, x"12345678", x"00000000", x"12345678");
    test(2, x"12345678", x"00000000", x"12345678");
    test(3, x"12345678", x"00000000", x"EDCBA987");
    
    report integer'image(pass_count) & " passed, " -- should be all of them, w/ 0 failed
         & integer'image(fail_count) & " failed.";
    wait;
    
    
    end process;
end sim;
