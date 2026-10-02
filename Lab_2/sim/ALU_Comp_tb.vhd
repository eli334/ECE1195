----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 03:43:34 AM
-- Design Name: 
-- Module Name: ALU_Comp_tb - Behavioral
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

entity ALU_Comp_tb is
--  Port ( );
end ALU_Comp_tb;

architecture sim of ALU_Comp_tb is
    signal A_31, B_31, S_31, CO : STD_LOGIC;
    signal ALUOp : STD_LOGIC_VECTOR(1 downto 0);
    signal R    : STD_LOGIC_VECTOR(31 downto 0);
begin
    UUT :  entity work.ALU_Comp(rtl)
        port map(
            A_31 => A_31,
            B_31 => B_31, 
            S_31 => S_31,
            CO => CO,
            ALUOp => ALUOp,
            R => R
         );
         
    
    process
        variable pass_count, fail_count : integer := 0;
        
        procedure test(op_code : integer;
                       A, B : unsigned(31 downto 0)
                  ) is 
                  variable expected : std_logic_vector(31 downto 0);
                  variable sub_result_signed : signed(31 downto 0);
                  variable CO_result : std_logic;
        begin
            -- set UUT's values
            ALUOp <= std_logic_vector(to_unsigned(op_code, 2)); -- op_code: integer, that I cast to a vector
            A_31 <= A(31);
            B_31 <= B(31);
            
            sub_result_signed := signed(A) - signed(B);
            S_31 <= sub_result_signed(31);            
            if A < B then
                CO <= '0';
            else
                CO <= '1';
            end if;
            
            
         
            wait for 10 ns;
            
            -- op codes:
            -- 00 - ignored
            -- 01 - ignored
            -- 10 - SLT - signed A < signed B
            -- 11 - SLTU - A < B
            
        case op_code is 
            when 2 => 
                if (signed(A) < signed(B)) then
                    expected := x"00000001";
                else
                    expected := x"00000000";
                end if;
            when others => 
                if (A < B) then
                    expected := x"00000001";
                else
                    expected := x"00000000";
                end if;
        end case;
        
        if R = expected then
            pass_count := pass_count + 1;
        else
            fail_count := fail_count + 1;
            report "FAIL op=" & integer'image(op_code)
                 & " A=" & integer'image(to_integer(unsigned(A)))
                 & " B=" & integer'image(to_integer(unsigned(B)))
                 & " Expected=" & integer'image(to_integer(unsigned(expected)))
                 & " Got=" & integer'image(to_integer(unsigned(R)))
                 severity error; 
        end if;
        
        end procedure;
        
    begin
        wait for 10 ns;
        -- signed tests
        test(2, unsigned(to_signed(-1, 32)), unsigned(to_signed(1, 32)));       -- -1 < +1 
        test(2, x"80000000", x"7FFFFFFF");                                      -- border between 31st bit flip
        test(2, x"FFFFFFFF", x"00000000");                                      -- -1 < 0
        test(2, unsigned(to_signed(-5, 32)), unsigned(to_signed(-6, 32)));      -- -5 < -6
        test(2, x"F0000000", x"F0000000");                                      -- equality check for random negative number with all 4 MSB bits set high
        
        
        
        -- unsigned tests
        test(3, x"7FFFFFFF", x"80000000");  -- just spamming max and min values, but these should all work obviously    
        test(3, x"FFFFFFFF", x"00000000");  -- the way I wrote the code means it's calculated at runtime w/ a different 
        test(3, x"00000000", x"FFFFFFFF");  -- method, so it passing means both unique methods agree                    
        test(3, x"FFFFFFFF", x"FFFFFFFF");
        test(3, x"00000000", x"00000000");  
                                            
                                            
        
        
        -- dual tests
        test(2, to_unsigned(5, 32), to_unsigned(10, 32));   -- +5 < +10
        test(3, to_unsigned(5, 32), to_unsigned(10, 32));   --  5 < 10
        
        test(2, to_unsigned(100, 32), to_unsigned(10, 32));   -- +100 < +10 is false
        test(3, to_unsigned(100, 32), to_unsigned(10, 32));   -- 100 < 10
        
        -- honestly I prefer C so most of the testing happens there
        
        
        report "Simulation Complete. Passes: " & integer'image(pass_count) 
           & " Errors: " & integer'image(fail_count);
           
        wait;
    end process;
end sim;