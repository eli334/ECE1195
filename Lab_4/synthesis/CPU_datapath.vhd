--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-- entity mips_32bit_fsm is
--     port(
--         clk         : in  STD_LOGIC;
--         reset       : in  STD_LOGIC;
--         Op          : in  STD_LOGIC_VECTOR(5 downto 0);
--         Funct       : in  STD_LOGIC_VECTOR(5 downto 0); -- SPECIAL/SPECIAL2 ops

--         PCWriteCond : out STD_LOGIC;
--         PCWrite     : out STD_LOGIC;
--         IorD        : out STD_LOGIC;
--         MemRead     : out STD_LOGIC;
--         MemWrite    : out STD_LOGIC;
--         MemtoReg    : out STD_LOGIC;
--         IRWrite     : out STD_LOGIC;
--         PCSource    : out STD_LOGIC_VECTOR(1 downto 0);
--         ALUOp       : out STD_LOGIC_VECTOR(3 downto 0);
--         ALUSrcA     : out STD_LOGIC;
--         ALUSrcB     : out STD_LOGIC_VECTOR(1 downto 0);
--         RegWrite    : out STD_LOGIC;
--         RegDst      : out STD_LOGIC;
--         ExtOp       : out STD_LOGIC
--     );
-- end entity;

entity CPU_datapath IS
    port( 
        RST           : in STD_LOGIC;
        CLK           : in STD_LOGIC;
        memIn   : in STD_LOGIC_VECTOR(31 downto 0);
        dataAddr : out STD_LOGIC_VECTOR(31 downto 0);
        memOut  : out STD_LOGIC_VECTOR(31 downto 0);
        -- MemWrite   : out STD_LOGIC; -- out from FSM only

        OP          : out STD_LOGIC_VECTOR(5 downto 0);
        Funct       : out STD_LOGIC_VECTOR(5 downto 0); -- SPECIAL/SPECIAL2 ops

        PCWriteCond : in STD_LOGIC;
        PCWrite     : in STD_LOGIC;
        IorD        : in STD_LOGIC;
        MemRead     : in STD_LOGIC;
        MemWrite    : in STD_LOGIC;
        MemtoReg    : in STD_LOGIC;
        IRWrite     : in STD_LOGIC;
        PCSource    : in STD_LOGIC_VECTOR(1 downto 0);
        ALUOp       : in STD_LOGIC_VECTOR(3 downto 0);
        ALUSrcA     : in STD_LOGIC;
        ALUSrcB     : in STD_LOGIC_VECTOR(1 downto 0);
        RegWrite    : in STD_LOGIC;
        RegDst      : in STD_LOGIC;
        ExtOp       : in STD_LOGIC
        
    );
end CPU_datapath;

architecture datapath of CPU_datapath is
    -- ways to split IR for instructions

    signal IR_OUT  : STD_LOGIC_VECTOR(31 downto 0);
    signal IR_OP   : STD_LOGIC_VECTOR(5 downto 0); -- 31 downto 26
    
    signal IR_RS   : STD_LOGIC_VECTOR(4 downto 0); -- 25 downto 21
    signal IR_RT   : STD_LOGIC_VECTOR(4 downto 0); -- 20 downto 16
    signal IR_RD   : STD_LOGIC_VECTOR(4 downto 0); -- 15 downto 11

    
    signal IR_IMDT : STD_LOGIC_VECTOR(15 downto 0); -- 15 downto 0
    signal IR_SHAMT: STD_LOGIC_VECTOR(4 downto 0);  -- 10 downto 6

    signal IR_SPECIAL : STD_LOGIC_VECTOR(5 downto 0); -- 5 downto 0

    -- memory register
    signal MEM_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);

    -- ALU signals
    signal ALU_RESULT : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_A      : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_B      : STD_LOGIC_VECTOR(31 downto 0);
    
    signal ALU_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);


begin
    IR_OP      <= IR_OUT(31 downto 26);
    IR_RS      <= IR_OUT(25 downto 21);
    IR_RT      <= IR_OUT(20 downto 16);
    IR_RD      <= IR_OUT(15 downto 11);
    IR_IMDT    <= IR_OUT(15 downto 0);
    IR_SHAMT   <= IR_OUT(10 downto 6);
    
    IR_SPECIAL <= IR_OUT(5 downto 0); -- OP for SPECIAL/SPECIAL2 instructions
    Funct <= IR_SPECIAL; -- straight into FSM


    pc_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD => open,
            CLK => CLK,
            P_IN => open,
            RST => open,
            P_OUT => open
    );

    instr_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD => IRWrite,
            CLK => CLK,
            P_IN => memIn,
            RST => RST,
            P_OUT => IR_OUT
    );
    
    mem_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => '1',
            CLK   => CLK,
            P_IN  => memIn,
            RST   => RST,
            P_OUT => MEM_REG_OUT
    );

    ALU_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => open,
            CLK   => open,
            P_IN  => ALU_RESULT,
            RST   => RST,
            P_OUT => ALU_REG_OUT
    );

    A_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => open,
            CLK   => open,
            P_IN  => open,
            RST   => open,
            P_OUT => open
    );

    B_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => open,
            CLK   => open,
            P_IN  => open,
            RST   => open,
            P_OUT => open
    );

    ee_ALU_inst: entity work.ee_ALU
     port map(
        A => open,
        B => open,
        SHAMT => open,
        ALUOp => open,
        R => open,
        Overflow => open,
        Zero => open
    );

    sign_extender : entity work.ee_sign_extender(rtl)
        port map(
            data_in  => open,
            ExtOp    => open,
            data_out => open
    );

    shifter_PC   : entity work.ee_shifter(rtl)
        generic map (
            IN_WIDTH  => 32,
            OUT_WIDTH => 32,
            SHAMT     => 2
        )
        port map(
            data_in   => open,
            data_out  => open
    );

    shifter_J    : entity work.ee_shifter(rtl)
        generic map (
            IN_WIDTH  => 26,
            OUT_WIDTH => 28,
            SHAMT     => 2
        )
        port map(
            data_in   => open,
            data_out  => open
    );

    regfile      : entity work.ee_regfile_behav(behavioral)
        port map(
            read1       => open,
            data1       => open,
            read2       => open,
            data2       => open,
            writeSelect => open,
            dataIn      => open,
            regWrite    => open,
            RST         => open,
            CLK         => open
    );

    -- above is everything in the png
    
    multiplier  : entity work.ee_mult_top(structural)
        port map(
            A   => open,
            B   => open,
            CLK => open,
            RST => open,
            R   => open,
            done=> open
        );

    HI_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => open,
            CLK   => open,
            P_IN  => open,
            RST   => open,
            P_OUT => open
    );

    LO_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => open,
            CLK   => open,
            P_IN  => open,
            RST   => open,
            P_OUT => open
    );



    

end datapath;