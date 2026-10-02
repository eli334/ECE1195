----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/09/2026 09:58:04 PM
-- Design Name: 
-- Module Name: ee_adder_full_adder - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ee_adder_full_adder is
    Port ( A : in STD_LOGIC;
           B : in STD_LOGIC;
           Cin : in STD_LOGIC;
           sum : out STD_LOGIC;
           Cout : out STD_LOGIC
         );
end ee_adder_full_adder;

architecture Combinational of ee_adder_full_adder is
signal sig1, sig2, sig3: STD_LOGIC;
begin
    sig1 <= A XOR B;
    sig2 <= A AND B;
    sig3 <= sig1 AND Cin;
    sum  <= sig1 XOR Cin;
    Cout <= sig2 OR sig3;
end Combinational;
