----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2026 10:57:46 AM
-- Design Name: 
-- Module Name: ALU_Shift - rtl
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

entity ALU_Shift is
    generic (
        width : INTEGER := 32 -- unused; lS and rS both assume 32 bits- might want to make it 64 with a default "0" input for the future
    );
    Port ( A :      in STD_LOGIC_VECTOR (width-1 downto 0);
           SHAMT :  in STD_LOGIC_VECTOR (4 downto 0);
           ALUOp :  in STD_LOGIC_VECTOR (1 downto 0);
           R :      out STD_LOGIC_VECTOR (width-1 downto 0));
end ALU_Shift;

architecture rtl of ALU_Shift is
    -- approach: 5 shifters: 1, 2, 4, 8, 16 gives all 32 SHAMTs (from lecture)
    -- looks at SHAMT(i) for whether it shifts
    type stage_arr is array (0 to 4) of STD_LOGIC_VECTOR(width-1 downto 0);
    signal leftStage : stage_arr;
    signal rightStage : stage_arr;
    signal Fill : STD_LOGIC_VECTOR(width-1 downto 0);
begin
    leftStage(0) <= A(30 downto 0) & '0'                               when SHAMT(0) = '1' else A;
    leftStage(1) <= (leftStage(0)(29 downto 0) & "00")                 when SHAMT(1) = '1' else leftStage(0);
    leftStage(2) <= (leftStage(1)(27 downto 0) & "0000")               when SHAMT(2) = '1' else leftStage(1);
    leftStage(3) <= (leftStage(2)(23 downto 0) & "00000000")           when SHAMT(3) = '1' else leftStage(2);
    leftStage(4) <= (leftStage(3)(15 downto 0) & "0000000000000000")   when SHAMT(4) = '1' else leftStage(3);
    
    Fill <= (others => ALUOp(0) and A(31));
    rightStage(0) <= (Fill(0) & A(31 downto 1))                         when SHAMT(0) = '1' else A;
    rightStage(1) <= (Fill(1 downto 0) & rightStage(0)(31 downto 2))    when SHAMT(1) = '1' else rightStage(0);
    rightStage(2) <= (Fill(3 downto 0) & rightStage(1)(31 downto 4))    when SHAMT(2) = '1' else rightStage(1);
    rightStage(3) <= (Fill(7 downto 0) & rightStage(2)(31 downto 8))    when SHAMT(3) = '1' else rightStage(2);
    rightStage(4) <= (Fill(15 downto 0) & rightStage(3)(31 downto 16))  when SHAMT(4) = '1' else rightStage(3);
    
    with ALUOp(1) select
        R <= leftStage(4) when '0',
            rightStage(4) when others;
end rtl;
