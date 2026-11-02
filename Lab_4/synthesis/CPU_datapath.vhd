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
        MemtoReg    : in STD_LOGIC_VECTOR(2 downto 0);
        IRWrite     : in STD_LOGIC;
        PCSource    : in STD_LOGIC_VECTOR(1 downto 0);
        ALUOp       : in STD_LOGIC_VECTOR(3 downto 0);
        ALUSrcA     : in STD_LOGIC_VECTOR(1 downto 0);
        ALUSrcB     : in STD_LOGIC_VECTOR(1 downto 0);
        SHAMTSrc    : in STD_LOGIC;
        RegWrite    : in STD_LOGIC;
        RegDst      : in STD_LOGIC;
        ExtOp       : in STD_LOGIC;

        MultDisable  : in STD_LOGIC;
        HILOEnable   : in STD_LOGIC;
        MultFinished : out STD_LOGIC
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

    signal IR_J       : STD_LOGIC_VECTOR(25 downto 0);
    
    -- regfile
    signal REGF_DATA_OUT_1 : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_DATA_OUT_2 : STD_LOGIC_VECTOR(31 downto 0);
    signal REGF_WRITE_ADDR : STD_LOGIC_VECTOR(4 downto 0);
    signal REGF_DATA_IN    : STD_LOGIC_VECTOR(31 downto 0);

    -- memory register
    signal MEM_ADDR_IN : STD_LOGIC_VECTOR(31 downto 0);
    signal MEM_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);
    
    -- A register
    signal A_REG_OUT   : STD_LOGIC_VECTOR(31 downto 0);
    
    -- B register
    signal B_REG_OUT   : STD_LOGIC_VECTOR(31 downto 0);
    
    -- ALUOut register
    signal ALU_REG_OUT : STD_LOGIC_VECTOR(31 downto 0);
    
    -- HI register
    signal HI_REG_IN   : STD_LOGIC_VECTOR(31 downto 0);
    signal HI_REG_OUT  : STD_LOGIC_VECTOR(31 downto 0);
    -- LO register
    signal LO_REG_IN   : STD_LOGIC_VECTOR(31 downto 0);
    signal LO_REG_OUT  : STD_LOGIC_VECTOR(31 downto 0);

    -- PC signals ((PCWriteCond AND ALU_ZERO) OR PCWrite)
    signal PC_LOAD    : STD_LOGIC;
    signal PC_VALUE_IN : STD_LOGIC_VECTOR(31 downto 0); -- PC mux from (0) ALU, (1) ALUOut, (2) J<<2
    signal PC_VALUE_OUT: STD_LOGIC_VECTOR(31 downto 0);

    --- ALU signals
    signal ALU_A        : STD_LOGIC_VECTOR(31 downto 0);
    signal ALU_B        : STD_LOGIC_VECTOR(31 downto 0);
    -- shamt (IR_SHAMT)
    -- ALUOp (from FSM)
    signal ALU_RESULT   : STD_LOGIC_VECTOR(31 downto 0);
    -- signal ALU_OF       : STD_LOGIC; -- unused
    signal ALU_ZERO     : STD_LOGIC;
    signal ALU_SHAMT    : STD_LOGIC_VECTOR(4 downto 0);
    
    -- LUI
    signal LUI_OUT      : STD_LOGIC_VECTOR(31 downto 0);
    
    -- CLO
    signal CLO_OUT      : STD_LOGIC_VECTOR(31 downto 0);

    --- multiplier signals
    signal MULT_RESULT : STD_LOGIC_VECTOR(63 downto 0);
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
    
begin
    --- memory logic

    IR_IN      <= memIn;
    memOut     <= B_REG_OUT;

    IR_OP      <= IR_OUT(31 downto 26);
    Op         <= IR_OP; -- straight into FSM
    
    IR_RS      <= IR_OUT(25 downto 21);
    IR_RT      <= IR_OUT(20 downto 16);
    IR_RD      <= IR_OUT(15 downto 11);
    IR_IMDT    <= IR_OUT(15 downto 0);
    IR_SHAMT   <= IR_OUT(10 downto 6);
    
    IR_SPECIAL <= IR_OUT(5 downto 0); -- OP for SPECIAL/SPECIAL2 instructions
    Funct <= IR_SPECIAL; -- straight into FSM

    IR_J <= IR_OUT(25 downto 0);

    PC_LOAD <= (PCWriteCond and not ALU_ZERO) or PCWrite;

    HI_REG_IN <= MULT_RESULT(63 downto 32);
    LO_REG_IN <= MULT_RESULT(31 downto 0);

    --- mux logic
    -- regfile Write Data
    with MemToReg select
        REGFILE_WD_MUX_OUT <=   ALU_REG_OUT when "000",
                                MEM_REG_OUT when "001",
                                LUI_OUT     when "010", -- LUI
                                CLO_OUT     when "011", -- CLO
                                HI_REG_OUT  when "100",
                                LO_REG_OUT  when "101",
                                ALU_REG_OUT when others;

    -- regfile Write Register 
    REGFILE_WR_MUX_OUT <=  IR_RD when RegDst = '1' else IR_RT;

    -- A mux
    with ALUSrcA select
        ALU_A <=    PC_VALUE_OUT when "00",
                    A_REG_OUT    when "01",
                    B_REG_OUT    when "10",
                    A_REG_OUT    when others;


                        -- ALU_A <= A_REG_OUT when ALUSrcA = '1' else PC_VALUE_OUT; 
    
    -- B mux
    with ALUSrcB select
        ALU_B <=            B_REG_OUT     when "00",
                            x"00000004"   when "01",
                            SGN_EXT_OUT   when "10",
                            IMDT_SLL_OUT  when "11",
                            B_REG_OUT     when others;

    -- PC mux
    with PCSource select
        PC_VALUE_IN <=  ALU_RESULT  when "00",
                        ALU_REG_OUT when "01",
                        PC_VALUE_OUT(31 downto 28) & PC_SLL_OUT when "10",
                        A_REG_OUT   when "11",
                        ALU_RESULT  when others;

    -- memAddr mux
    dataAddr <= ALU_REG_OUT when IorD = '1' else PC_VALUE_OUT; 

    -- SHAMT mux
    ALU_SHAMT <= IR_SHAMT when SHAMTSrc = '0' else A_REG_OUT(4 downto 0);

    pc_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => PC_LOAD,
            CLK   => CLK,
            P_IN  => PC_VALUE_IN,
            RST   => RST,
            P_OUT => PC_VALUE_OUT
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
            P_OUT => A_REG_OUT
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
            P_OUT => B_REG_OUT
    );

    ee_ALU_inst: entity work.ee_ALU
     port map(
        A        => ALU_A,
        B        => ALU_B,
        SHAMT    => IR_SHAMT,
        ALUOp    => ALUOp,
        R        => ALU_RESULT,
        Overflow => open,
        Zero     => ALU_ZERO
    );

    sign_extender : entity work.ee_sign_extender(rtl)
        port map(
            data_in  => IR_IMDT,
            ExtOp    => ExtOp, -- for ORI
            data_out => SGN_EXT_OUT
    );

    shifter_IMDT   : entity work.ee_shifter(rtl)
        generic map (
            IN_WIDTH  => 32,
            OUT_WIDTH => 32,
            SHAMT     => 2
        )
        port map(
            data_in   => SGN_EXT_OUT,
            data_out  => IMDT_SLL_OUT
    );

    shifter_J    : entity work.ee_shifter(rtl)
        generic map (
            IN_WIDTH  => 26,
            OUT_WIDTH => 28,
            SHAMT     => 2
        )
        port map(
            data_in   => IR_J,
            data_out  => PC_SLL_OUT
    );

    regfile      : entity work.ee_regfile_behav(behavioral)
        port map(
            read1       => IR_RS,
            data1       => REGF_DATA_OUT_1,
            read2       => IR_RT,
            data2       => REGF_DATA_OUT_2,
            writeSelect => REGFILE_WR_MUX_OUT,
            dataIn      => REGFILE_WD_MUX_OUT,
            regWrite    => RegWrite,
            RST         => RST,
            CLK         => CLK
    );

    -- above is everything in the png
    
    

    -- multiplier
    multiplier  : entity work.ee_mult_top(structural)
        port map(
            A    => A_REG_OUT,
            B    => B_REG_OUT,
            CLK  => CLK,
            RST  => MultDisable,
            R    => MULT_RESULT,
            done => MultFinished
        );
    


    HI_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => HILOEnable,
            CLK   => CLK,
            P_IN  => HI_REG_IN,
            RST   => RST,
            P_OUT => LO_REG_OUT
    );

    LO_reg    : entity work.ee_register(struct)
        generic map (
            REG_WIDTH => 32
        )
        port map(
            LOAD  => HILOEnable,
            CLK   => CLK,
            P_IN  => LO_REG_IN,
            RST   => RST,
            P_OUT => LO_REG_OUT
    );

    -- LUI 16-bit shifter
    LUI_shifter : entity work.ee_shifter(rtl)
            generic map (
                IN_WIDTH => 16,
                OUT_WIDTH => 32,
                SHAMT => 16
            ) port map (
                data_in => IR_IMDT,
                data_out => LUI_OUT
            );
    
    -- CLO
    CLO     : entity work.ee_CLO(rtl)
            port map(
                data_in => A_REG_OUT,
                returned_ones => CLO_OUT
            );

end datapath;