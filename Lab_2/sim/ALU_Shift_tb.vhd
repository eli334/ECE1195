----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 03:43:34 AM
-- Design Name: 
-- Module Name: ALU_Shift_tb - Behavioral
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

entity ALU_Shift_tb is
--  Port ( );
end ALU_Shift_tb;

architecture sim of ALU_Shift_tb is
    signal A, R : STD_LOGIC_VECTOR(31 downto 0);
    signal SHAMT : STD_LOGIC_VECTOR(4 downto 0);
    signal ALUOp : STD_LOGIC_VECTOR(1 downto 0);
begin
    UUT : entity work.ALU_Shift(rtl) -- Unit Under Test
        port map (
            A  => A,
            SHAMT => SHAMT,
            ALUOp => ALUOp,
            R  => R
        );
        process
            variable pass_count, fail_count : integer := 0;
        
            procedure test(op_code : integer;
                           a_val : unsigned(31 downto 0);
                           shiftAmt : natural
                      ) is 
                      variable expected : std_logic_vector(31 downto 0);
            begin
            -- set UUT's values
            A <= std_logic_vector(a_val);
            SHAMT <= std_logic_vector(to_unsigned(shiftAmt, 5));
            ALUOp <= std_logic_vector(to_unsigned(op_code, 2));
            
            wait for 10 ns; -- R is set after this
            
            -- 00: SLL
            -- 01: SLA
            -- 10: SRL
            -- 11: SRA - fill w/ sign bit
            
            
            
            case op_code is
                when 0 | 1 => expected := std_logic_vector(shift_left(a_val, shiftAmt));
                when 2 => expected := std_logic_vector(shift_right(a_val, shiftAmt));
                when others => expected := std_logic_vector(shift_right(signed(a_val), shiftAmt));
            end case;
            
            if R = expected then
                pass_count := pass_count + 1;
            else
                fail_count := fail_count + 1;
                report "FAIL op=" & integer'image(op_code)
                     & " A=" & integer'image(to_integer(unsigned(A)))
                     & " SHAMT=" & natural'image(shiftAmt)
                     & " Expected=" & integer'image(to_integer(unsigned(expected)))
                     & " Got=" & integer'image(to_integer(unsigned(R)))
                     severity error; 
            end if;
            
                        
            end procedure;
            begin
            
            eeLoop : for i in 31 downto 0 loop
                test(0, X"FEDCBA98", i); -- doing table
                test(2, X"FEDCBA98", i);
                test(3, X"FEDCBA98", i);
            end loop eeLoop;
            
            report integer'image(pass_count) & " passed, " -- should be all of them, w/ 0 failed
                 & integer'image(fail_count) & " failed.";
    wait;
            
    end process;
end sim;
