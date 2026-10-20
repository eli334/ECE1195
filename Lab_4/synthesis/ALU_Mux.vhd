----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2026 10:57:46 AM
-- Design Name: 
-- Module Name: ALU_Mux - rtl
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

entity ALU_Mux is
    Port ( A : in STD_LOGIC_VECTOR(31 downto 0);
           B : in STD_LOGIC_VECTOR(31 downto 0);
           C : in STD_LOGIC_VECTOR(31 downto 0);
           D : in STD_LOGIC_VECTOR(31 downto 0);
           ALUOp : in STD_LOGIC_VECTOR (1 downto 0);
           R : out STD_LOGIC_VECTOR (31 downto 0));
end ALU_Mux;

architecture rtl of ALU_Mux is
begin
with ALUOp select
        R <= 
        A when "00",
        B when "01",
        C when "10",
        D when others;


end rtl;
