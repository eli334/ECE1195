----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/09/2026 09:38:08 PM
-- Design Name: 
-- Module Name: ee_adder_generic_32 - Structural
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

entity ee_adder_generic_32 is
    generic (
           N        : INTEGER:=32
    );
    port ( 
           numA, numB   : IN STD_LOGIC_VECTOR(N-1 downto 0);
           sub          : IN STD_LOGIC; -- no carry in; sub replaces Cin
           numSum       : OUT STD_LOGIC_VECTOR(N-1 downto 0);
           Carry_out    : OUT STD_LOGIC
         );  
end ee_adder_generic_32;

architecture Structural of ee_adder_generic_32 is
    component ee_adder_full_adder
        port (  A       : IN STD_LOGIC;
                B       : IN STD_LOGIC;
                Cin     : IN STD_LOGIC;
                sum     : OUT STD_LOGIC;
                Cout    : OUT STD_LOGIC
             );
    end component;
    signal carry : STD_LOGIC_VECTOR(N downto 0); -- one bit longer for final Cout
    signal onesComplement : STD_LOGIC_VECTOR(N-1 downto 0);
begin
    carry(0) <= sub;
    
    onesComplement <= numB xor (numB'range => sub);
    
    gen_adders : for i in 0 to N-1 generate
        U   : ee_adder_full_adder port map(
                A => numA(i),
                B => onesComplement(i),
                Cin => carry(i),
                sum => numSum(i),
                Cout => carry(i + 1)
              );
    end generate;
    Carry_out <= carry(N);
end Structural;
