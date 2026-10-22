----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2026 02:54:53 AM
-- Design Name: 
-- Module Name: ee_ALU - Combinational
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

entity ee_ALU is
    Port ( A : in STD_LOGIC_VECTOR (31 downto 0);
           B : in STD_LOGIC_VECTOR (31 downto 0);
           SHAMT : in STD_LOGIC_VECTOR (4 downto 0);
           ALUOp : in STD_LOGIC_VECTOR (3 downto 0);
           R : out STD_LOGIC_VECTOR (31 downto 0);
           Overflow : out STD_LOGIC;
           Zero : out STD_LOGIC);
end ee_ALU;

architecture Combinational of ee_ALU is
    signal logicalOut, arithOut, compOut, shiftOut : STD_LOGIC_VECTOR(31 downto 0);
    signal funcSelect, opSelect : STD_LOGIC_VECTOR(1 downto 0);
    signal arithCO : STD_LOGIC;
begin
    funcSelect <= ALUOp(3 downto 2);
    opSelect <= ALUOp(1 downto 0);

    logical : entity work.ALU_Logical(rtl)
        port map ( 
            A   =>  A,
            B   =>  B,
            Op  =>  opSelect,
            R   =>  logicalOut -- 0
        );
    Arith_Unit : entity work.Arith_Unit(struct)
    generic map (
        n => 32
    )
    port map (
        A => A,
        B => B,
        C_Op => opSelect,
        CO => arithCO,
        OFL => Overflow,
        S => arithOut, -- 1
        Z => Zero
    );
    comp : entity work.ALU_Comp(rtl)
    port map (
        A_31 => A(31),
        B_31 => B(31),
        S_31 => arithOut(31),
        CO => arithCO,
        ALUOp => opSelect,
        R => compOut -- 2
    );
    shift : entity work.ALU_Shift(rtl)
    port map (
        A => A,
        SHAMT => SHAMT,
        ALUOp => opSelect,
        R => shiftOut -- 3
    );
    mux : entity work.ALU_Mux(rtl)
    port map(
        A => logicalOut, -- 0
        B => arithOut,   -- 1
        C => compOut,    -- 2
        D => shiftOut,   -- 3
        ALUOp => funcSelect,
        R => R
    );
end Combinational;
