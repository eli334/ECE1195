----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2026 10:57:46 AM
-- Design Name: 
-- Module Name: ALU_Logical - rtl
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

entity ALU_Logical is
    Port ( A : in STD_LOGIC_VECTOR (31 downto 0);
           B : in STD_LOGIC_VECTOR (31 downto 0);
           Op : in STD_LOGIC_VECTOR (1 downto 0);
           R : out STD_LOGIC_VECTOR (31 downto 0));
end ALU_Logical;

architecture rtl of ALU_Logical is
signal logicAND, logicOR, logicXOR, logicNOR : STD_LOGIC_VECTOR(31 downto 0);
begin
        logicAND <= A and B;
        logicOR <= A or B;
        logicXOR <= A xor B;
        logicNOR <= A nor B; -- could be "not logicOR", but I like NOR more
    
    with Op select
        R <= 
        logicAND when "00",
        logicOR when "01",
        logicXOR when "10",
        logicNOR when others;
end rtl;
