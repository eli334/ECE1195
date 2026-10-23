--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity CPU_datapath IS
    port( 
        RST         : in STD_LOGIC;
        CLK         : in STD_LOGIC;
        memIn       : in STD_LOGIC_VECTOR(31 downto 0);
        dataAddr    : out STD_LOGIC_VECTOR(31 downto 0);
        memOut      : out STD_LOGIC_VECTOR(31 downto 0);
        -- MemWrite : out STD_LOGIC; -- out from FSM only

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
    
    --- registers
    
    -- IR (and ways IR is split for instructions)

    signal IR_IN   : STD_LOGIC_VECTOR(31 downto 0);
    signal IR_OUT  : STD_LOGIC_VECTOR(31 downto 0);
    signal IR_OP   : STD_LOGIC_VECTOR(5 downto 0); -- 31 downto 26
    
    signal IR_RS   : STD_LOGIC_VECTOR(4 downto 0); -- 25 downto 21
    signal IR_RT   : STD_LOGIC_VECTOR(4 downto 0); -- 20 downto 16
    signal IR_RD   : STD_LOGIC_VECTOR(4 downto 0); -- 15 downto 11
    
    signal IR_IMDT : STD_LOGIC_VECTOR(15 downto 0); -- 15 downto 0
    signal IR_SHAMT: STD_LOGIC_VECTOR(4 downto 0);  -- 10 downto 6

    signal IR_SPECIAL : STD_LOGIC_VECTOR(5 downto 0); -- 5 downto 0
    
    -- regfile
    signal REGF_ADDR_IN_1  : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_ADDR_IN_2  : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_DATA_OUT_1 : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_DATA_OUT_2 : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_WRITE_ADDR : STD_LOGIC_VECTOR(4 downto 0);
    signal REGF_DATA_IN    : STD_LOGIC_VECTOR(31 downto 0);

    -- memory register
    signal MEM_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);
    
    -- A register
    signal A_REG_OUT   : STD_LOGIC_VECTOR(31 downto 0);
    
    -- B register
    signal B_REG_OUT   : STD_LOGIC_VECTOR(31 downto 0);
    
    -- ALUOut register
    signal ALU_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);
    
    -- PC signals ((PCWriteCond AND ALU_ZERO) OR PCWrite)
    signal PCLoad    : STD_LOGIC;
    signal PCValueIn : STD_LOGIC_VECTOR(31 downto 0); -- PC mux from (0) ALU, (1) ALUOut, (2) J<<2
    signal PCValueOut: STD_LOGIC_VECTOR(31 downto 0);

    --- ALU signals
    signal ALU_RESULT   : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_A        : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_B        : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_ZERO     : STD_LOGIC;
    -- signal ALU_OVERFLOW : STD_LOGIC;

    --- sign extender signals
    signal SGN_EXT_OUT  : STD_LOGIC_VECTOR(31 downto 0);

    -- shifter signals
    signal IMDT_SLL_OUT   : STD_LOGIC_VECTOR(31 downto 0);
    signal PC_SLL_OUT     : STD_LOGIC_VECTOR(27 downto 0);

    
    --- MUX signals
    -- regfile Write Data
    signal REGFILE_WD_MUX_OUT : STD_LOGIC_VECTOR(31 downto 0);
    -- regfile Write Register
    signal REGFILE_WR_MUX_OUT : STD_LOGIC_VECTOR(4 downto 0);
    
    -- ALU A
    signal ALU_A_MUX_OUT      : STD_LOGIC_VECTOR(31 downto 0);
    -- ALU B
    signal ALU_B_MUX_OUT      : STD_LOGIC_VECTOR(31 downto 0);
    
begin
    memOut     <= IR_IN;

    IR_OP      <= IR_OUT(31 downto 26);
    Op         <= IR_OP; -- straight into FSM
    
    IR_RS      <= IR_OUT(25 downto 21);
    IR_RT      <= IR_OUT(20 downto 16);
    IR_RD      <= IR_OUT(15 downto 11);
    IR_IMDT    <= IR_OUT(15 downto 0);
    IR_SHAMT   <= IR_OUT(10 downto 6);
    
    IR_SPECIAL <= IR_OUT(5 downto 0); -- OP for SPECIAL/SPECIAL2 instructions
    Funct <= IR_SPECIAL; -- straight into FSM

    PCLoad <= (PCWriteCond and ALU_ZERO) or PCWrite;

    --- mux logic
    -- regfile Write Data
    REGFILE_WD_MUX_OUT <= MEM_REG_OUT when MemtoReg = '1' else ALU_REG_OUT;
    
    -- regfile Write Register 
    REGFILE_WR_MUX_OUT <=  IR_IMDT when RegDst = '1' else IR_RT;

    -- A mux
    ALU_A_MUX_OUT <= A_REG_OUT when ALUSrcA = '1' else PCValueOut; 
    with ALUSrcB select
    ALU_B_MUX_OUT <= B_REG_OUT             when "00",
                     x"00000004"           when "01",
                     EXT_IMM               when "10",
                     EXT_IMM_SHIFTED       when others;

    pc_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => PCLoad,
            CLK   => CLK,
            P_IN  => PCValueIn,
            RST   => RST,
            P_OUT => PCValueOut
    );

    instr_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => IRWrite,
            CLK   => CLK,
            P_IN  => IR_IN,
            RST   => RST,
            P_OUT => IR_OUT
    );
    
    mem_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => '1',
            CLK   => CLK,
            P_IN  => IR_IN,
            RST   => RST,
            P_OUT => MEM_REG_OUT
    );

    ALUOut_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => '1',
            CLK   => CLK,
            P_IN  => ALU_RESULT,
            RST   => RST,
            P_OUT => ALU_REG_OUT
    );

    A_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => '1',
            CLK   => CLK,
            P_IN  => REGF_DATA_OUT_1,
            RST   => RST,
            P_OUT => ALU_A
    );

    B_reg : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => '1',
            CLK   => CLK,
            P_IN  => REGF_DATA_OUT_2,
            RST   => RST,
            P_OUT => ALU_B
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
            data_in  => IR_IMDT,
            ExtOp    => ExtOp, -- for ORI
            data_out => IMDT_SLL_OUT
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
            read1       => REGF_ADDR_IN_1,
            data1       => REGF_DATA_OUT_1,
            read2       => REGF_ADDR_IN_2,
            data2       => REGF_DATA_OUT_2,
            writeSelect => REGF_WRITE_ADDR,
            dataIn      => REGF_DATA_IN,
            regWrite    => RegWrite,
            RST         => RST,
            CLK         => CLK
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