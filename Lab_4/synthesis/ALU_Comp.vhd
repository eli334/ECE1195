----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2026 10:57:46 AM
-- Design Name: 
-- Module Name: ALU_Comp - rtl
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

entity ALU_Comp is
    Port ( A_31 :   in STD_LOGIC; -- 31st bit from A
           B_31 :   in STD_LOGIC; -- 31st bit from B
           S_31 :   in STD_LOGIC; -- 31st bit from arith unit result
           CO :     in STD_LOGIC; -- carryout from arith unit
           ALUOp :  in STD_LOGIC_VECTOR (1 downto 0);
           R :  out STD_LOGIC_VECTOR (31 downto 0)
    );
end ALU_Comp;

architecture rtl of ALU_Comp is
    signal intermedOpposite, intermedSame, intermedSigned, intermedUnsigned : STD_LOGIC;
begin
    ---- signed (SLT):
    --- opposite signs
    -- if A is positive and B is negative, then A > B
    -- (if A_31 is low and B_31 is high)
    -- if A is negative and B is positive, then A < B
    
    -- so, A < B when A is high and B is low
    intermedOpposite <= A_31 and not(B_31);     -- opposite signed A < B
    
    --- same signs
    -- if S_31 is negative (1), then A < B
    -- if S_31 is positive (0), then A > B
    
    -- so, A < B when S_31 is high
    intermedSame <= S_31;                       -- same signed A < B
    
    
    
    with (A_31 xor B_31) select -- 0 if same, 1 if opposite
        intermedSigned <= intermedSame      when '0',
                          intermedOpposite  when '1';
    
    ---- unsigned (SLTU):
    -- if CO is low, A < B
    -- if CO is high, A > B
    
    -- so, A < B when CO is low
    intermedUnsigned <= not(CO);                -- unsigned A < B
    
    
    with ALUOp(0) select
        R <=  (0 => intermedSigned,   others => '0')    when '0',
              (0 => intermedUnsigned, others => '0')  when others;

end rtl;
