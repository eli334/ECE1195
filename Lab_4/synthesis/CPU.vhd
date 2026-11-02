LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity CPU IS
   port( 
        Reset         : in STD_LOGIC;
        Clock         : in STD_LOGIC;
        MemoryDataIn  : in STD_LOGIC_VECTOR(31 downto 0);
        MemoryAddress : out STD_LOGIC_VECTOR(31 downto 0);
        MemoryDataOut : out STD_LOGIC_VECTOR(31 downto 0);
        MemWrite      : out STD_LOGIC
   );
end CPU;

architecture rtl of CPU is
    signal PCWriteCond, PCWrite, IorD, IRWrite : STD_LOGIC;
    signal RegWrite, RegDst, ExtOp, SHAMTSrc             : STD_LOGIC;
    signal MultDisable, MultFinished, HILOEnable         : STD_LOGIC;
    signal PCSource, ALUSrcA, ALUSrcB                    : STD_LOGIC_VECTOR(1 downto 0);
    signal MemtoReg                                      : STD_LOGIC_VECTOR(2 downto 0);
    signal ALUOp                                         : STD_LOGIC_VECTOR(3 downto 0);
    signal Op, Funct                                     : STD_LOGIC_VECTOR(5 downto 0);
begin
    datapath : entity work.CPU_datapath(datapath)
        port map(
            RST         => Reset,
            CLK         => Clock,
            memOut      => MemoryDataOut,
            dataAddr    => MemoryAddress,
            memIn       => MemoryDataIn,


            PCWriteCond => PCWriteCond,
            PCWrite     => PCWrite,
            IorD        => IorD,
            MemtoReg    => MemtoReg,
            IRWrite     => IRWrite,
            ALUSrcA     => ALUSrcA,
            ALUSrcB     => ALUSrcB,
            SHAMTSrc    => SHAMTSrc,
            RegWrite    => RegWrite,
            RegDst      => RegDst,
            ExtOp       => ExtOp,
            PCSource    => PCSource,
            ALUOp       => ALUOp,
            Op          => Op,
            Funct       => Funct,
            MultDisable => MultDisable,
            HILOEnable => HILOEnable,
            MultFinished => MultFinished

        );
    control : entity work.mips_32bit_fsm(rtl)
        port map(
            CLK         => Clock,
            RST         => Reset,

            PCWriteCond => PCWriteCond,
            PCWrite     => PCWrite,
            IorD        => IorD,
            MemRead     => open,
            MemWrite    => MemWrite,
            MemtoReg    => MemtoReg,
            IRWrite     => IRWrite,
            ALUSrcA     => ALUSrcA,
            ALUSrcB     => ALUSrcB,
            RegWrite    => RegWrite,
            RegDst      => RegDst,
            ExtOp       => ExtOp,
            PCSource    => PCSource,
            ALUOp       => ALUOp,
            Op          => Op,
            Funct       => Funct,
            MultDisable => MultDisable,
            HILOEnable => HILOEnable,
            MultFinished => MultFinished
        );
end architecture;