-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;

entity mips_32bit_fsm is
    port(
        CLK         : in  STD_LOGIC;
        RST       : in  STD_LOGIC;
        Op          : in  STD_LOGIC_VECTOR(5 downto 0);
        Funct       : in  STD_LOGIC_VECTOR(5 downto 0); -- SPECIAL/SPECIAL2 ops

        PCWriteCond : out STD_LOGIC;
        PCWrite     : out STD_LOGIC;
        IorD        : out STD_LOGIC;
        MemRead     : out STD_LOGIC;
        MemWrite    : out STD_LOGIC;
        MemtoReg    : out STD_LOGIC_VECTOR(2 downto 0);
        IRWrite     : out STD_LOGIC;
        PCSource    : out STD_LOGIC_VECTOR(1 downto 0);
        ALUOp       : out STD_LOGIC_VECTOR(3 downto 0);
        ALUSrcA     : out STD_LOGIC_VECTOR(1 downto 0);
        ALUSrcB     : out STD_LOGIC_VECTOR(1 downto 0);
        SHAMTSrc    : out STD_LOGIC;
        RegWrite    : out STD_LOGIC;
        RegDst      : out STD_LOGIC;
        ExtOp       : out STD_LOGIC;

        MultDisable  : out STD_LOGIC;
        HILOEnable   : out STD_LOGIC;
        MultFinished : in STD_LOGIC
    );
end entity;

architecture rtl of mips_32bit_fsm is

    -- Build an enumerated type for the state machine
    type state_type is (FETCH, DECODE, EXECUTE, MEM, WRITEBACK, WAIT_DONE, HILO_WB);
    type instruction is (
        I_NOP,
        I_ADDI, I_ORI,  I_SLTI, I_LUI,  -- ALU, immediate (RT)
        I_ADDU, I_AND,  I_SUB,  I_SLT,  -- ALU, registers (RD)
        I_SLL,  I_SRA,  I_SLLV,         -- shifts         (RD)
        I_LW,   I_SW,   I_LH,           -- memory
        I_BNE,  I_J,    I_JR,           -- branching/jumps
        I_MFHI, I_MFLO, I_MULTU,        -- multiply       (HI/LO regs)
        I_CLO                           -- SPECIAL2
        );

    -- subtype ALU_IMM is instruction range I_ADDI to I_LUI;
    -- subtype ALU_REG is instruction range I_ADDU to I_SLT;
    -- subtype SHIFT_OP   is instruction range I_SLL  to I_SLLV;
    -- subtype MEMORY_OP  is instruction range I_LW   to I_LH;
    -- subtype JUMP_OP    is instruction range I_BNE  to I_JR;

    -- Register to hold the current state
    signal state   : state_type;
    signal instr   : instruction;

begin
    -- Logic to advance to the next state
    process (CLK, RST)
    constant OP_ADDI : STD_LOGIC_VECTOR(5 downto 0) := "001000";
    constant OP_ORI  : STD_LOGIC_VECTOR(5 downto 0) := "001101";
    constant OP_SLTI : STD_LOGIC_VECTOR(5 downto 0) := "001010";
    constant OP_BNE  : STD_LOGIC_VECTOR(5 downto 0) := "000101";
    constant OP_J    : STD_LOGIC_VECTOR(5 downto 0) := "000010";
    constant OP_LH   : STD_LOGIC_VECTOR(5 downto 0) := "100001";
    constant OP_LUI  : STD_LOGIC_VECTOR(5 downto 0) := "001111";
    constant OP_LW   : STD_LOGIC_VECTOR(5 downto 0) := "100011";
    constant OP_SW   : STD_LOGIC_VECTOR(5 downto 0) := "101011";


    constant SPECIAL : STD_LOGIC_VECTOR(5 downto 0) := "000000";
    constant SP_ADDU : STD_LOGIC_VECTOR(5 downto 0) := "100001";
    constant SP_AND  : STD_LOGIC_VECTOR(5 downto 0) := "100100";
    constant SP_JR   : STD_LOGIC_VECTOR(5 downto 0) := "001000"; -- this is the same as OP_J
    constant SP_MFHI : STD_LOGIC_VECTOR(5 downto 0) := "010000";
    constant SP_MFLO : STD_LOGIC_VECTOR(5 downto 0) := "010010";
    constant SP_MULTU: STD_LOGIC_VECTOR(5 downto 0) := "011001";
    constant SP_SLL  : STD_LOGIC_VECTOR(5 downto 0) := "000000";
    constant SP_SLLV : STD_LOGIC_VECTOR(5 downto 0) := "000100";
    constant SP_SRA  : STD_LOGIC_VECTOR(5 downto 0) := "000011";
    constant SP_SUB  : STD_LOGIC_VECTOR(5 downto 0) := "100010";
    

    constant SPECIAL2: STD_LOGIC_VECTOR(5 downto 0) := "011100";
    constant SP2_CLO : STD_LOGIC_VECTOR(5 downto 0) := "100001";
    begin
        if RST = '1' then
            state <= FETCH;
            instr <= I_NOP;
        elsif (rising_edge(CLK)) then
            case state is
                when FETCH => 
                    state <= DECODE;
                when DECODE =>  
                    state <= EXECUTE;
                    case Op is
                        when OP_ADDI => instr <= I_ADDI;
                        when OP_ORI  => instr <= I_ORI;
                        when OP_SLTI => instr <= I_SLTI;
                        when OP_BNE  => instr <= I_BNE;
                        when OP_J    => instr <= I_J;
                        when OP_LH   => instr <= I_LH;
                        when OP_LUI  => instr <= I_LUI; state <= WRITEBACK;
                        when OP_LW   => instr <= I_LW;
                        when OP_SW   => instr <= I_SW;

                        when SPECIAL =>
                            case Funct is
                                when SP_ADDU => instr <= I_ADDU;
                                when SP_AND  => instr <= I_AND;
                                when SP_JR   => instr <= I_JR;
                                when SP_MFHI => instr <= I_MFHI;
                                when SP_MFLO => instr <= I_MFLO;
                                when SP_MULTU=> instr <= I_MULTU;
                                when SP_SLL  => instr <= I_SLL;
                                when SP_SLLV => instr <= I_SLLV;
                                when SP_SRA  => instr <= I_SRA;
                                when SP_SUB  => instr <= I_SUB;
                                when others => 
                                    report "SPECIAL function not implemented."
                                    severity warning;
                                    state <= FETCH;
                            end case;
                                
                        when SPECIAL2 =>
                            case Funct is
                                when SP2_CLO 
                                    => instr <= I_CLO;
                                when others => 
                                    report "SPECIAL2 function not implemented."
                                    severity warning;
                                    state <= FETCH; 
                            end case;
                        when others => 
                            report "Opcode not implemented: Op = " & integer'image(to_integer(unsigned(Op)))
                            & ", state = " & state_type'image(state)
                            severity warning;
                            state <= FETCH;
                    end case;
                when EXECUTE => 
                    state <= WRITEBACK;
                    case instr is
                        when I_LW   | I_SW  | I_LH  => state <= MEM;
                        when I_BNE  | I_J   | I_JR  => state <= FETCH;
                        when I_MULTU                => state <= WAIT_DONE;
                        when others => null;
                    end case;
                when MEM =>
                    case instr is
                        when I_SW => state <= FETCH;
                        when others => state <= WRITEBACK;
                    end case;
                when WRITEBACK => state <= FETCH;
                when WAIT_DONE => 
                    case MultFinished is
                        when '0' => state <= WAIT_DONE;
                        when '1' => state <= HILO_WB;
                        when others => state <= WAIT_DONE;
                    end case;
                when HILO_WB   => state <= FETCH;
                when others =>
                    report "State not recognized." severity warning;
                    state <= FETCH;
            end case;
        end if;
    end process;
    
    -- Output depends solely on the current state
    process (state, instr)
        -- ALU constants
    constant UNIT_LOGIC : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant UNIT_ARITH : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant UNIT_CMP   : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant UNIT_SHIFT : STD_LOGIC_VECTOR(1 downto 0) := "11";
    
    constant ALU_AND    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_LOGIC & "00";
    constant ALU_OR     : STD_LOGIC_VECTOR(3 downto 0) := UNIT_LOGIC & "01";
    -- constant ALU_XOR    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_LOGIC & "10";
    -- constant ALU_NOR    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_LOGIC & "11";
    
    constant ALU_ADD    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_ARITH & "00";
    constant ALU_ADDU   : STD_LOGIC_VECTOR(3 downto 0) := UNIT_ARITH & "01";
    constant ALU_SUB    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_ARITH & "10";
    -- constant ALU_SUBU   : STD_LOGIC_VECTOR(3 downto 0) := UNIT_ARITH & "11";
    
    constant ALU_SLT    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_CMP & "10";
    -- constant ALU_SLTU   : STD_LOGIC_VECTOR(3 downto 0) := UNIT_CMP & "11";
    
    constant ALU_SLL    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_SHIFT & "00";
    -- constant ALU_SRL    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_SHIFT & "10";
    constant ALU_SRA    : STD_LOGIC_VECTOR(3 downto 0) := UNIT_SHIFT & "11";

    -- constant ALU_SLTU   : STD_LOGIC_VECTOR(3 downto 0) := UNIT_CMU & "11";

    
    -- needs ARITH unit for subtraction; not sure how that's gonna work yet

    begin
        -- PC
        PCWrite     <= '0';
        PCWriteCond <= '0';  -- PC is precalculated for branches to save an instruction cycle
        PCSource    <= "00"; -- 00; PC+4, 01; ALUOut branch, 10: jump address 
        -- memory
        IorD        <= '0';  -- 0; PC, 1; ALUOut
        MemRead     <= '0';
        MemWrite    <= '0';
        MemtoReg    <= "000";
        -- registers
        IRWrite     <= '0'; -- '1' for fetch; latches instruction on CLK
        RegDst      <= '0'; -- 0; rt, 1; rd
        RegWrite    <= '0'; -- only for writeback
        -- ALU
        ALUOp       <= ALU_ADD; -- sane default
        ALUSrcA     <= "00";
        ALUSrcB     <= "00";
        ExtOp       <= '0'; -- for I-type sign extending; 0; sign-extend, 1; zero-extend (for ORI)
        SHAMTSrc    <= '0';

        -- multiplier
        HILOEnable <= '0';
        MultDisable <= '1';
        case state is
            when FETCH =>
                IorD     <= '0';
                MemRead  <= '1';
                IRWrite  <= '1';        -- fetching writes to instruction register
                ALUSrcA  <= "00";
                ALUSrcB  <= "01";       -- mux 1 is tied to x"00000004" for PC + 4
                ALUOp    <= ALU_ADD;    -- + for PC + 4; PC is incremented while instruction is being fetched
                PCSource <= "00";
                PCWrite  <= '1';
            when DECODE =>
                ALUSrcA <= "00";       -- PC (already incremented to PC + 4)
                ALUSrcB <= "11";      -- sign-extended immediate << 2
                ALUOp   <= ALU_ADD;   -- ALUOut = branch target for BNE's EXECUTE
            when EXECUTE =>
                case instr is
                    when I_ADDI  => -- Immediate first
                        ALUOp   <= ALU_ADD;
                        ALUSrcA <= "01"; -- rs is muxed to 1
                        ALUSrcB <= "10"; -- mux 2 is sign extended I, not SLL'd by 2
                        ExtOp   <= '0';
                    when I_ORI   =>
                        ALUOp   <= ALU_OR;
                        ALUSrcA <= "01"; -- rs is muxed to 1
                        ALUSrcB <= "10"; -- mux 2 is sign extended I, not SLL'd by 2
                        ExtOp   <= '1';
                    when I_SLTI  => 
                        ALUOp   <= ALU_SLT;
                        ALUSrcA <= "01"; -- rs is muxed to 1
                        ALUSrcB <= "10"; -- mux 2 is sign extended I, not SLL'd by 2
                        ExtOp   <= '0';
                    when I_LW    =>
                        ALUOp   <= ALU_ADD;
                        ALUSrcA <= "01";
                        ALUSrcB <= "10";
                        ExtOp   <= '0';
                    when I_LH    => null;
                    when I_SW    => 
                        ALUOp   <= ALU_ADD;
                        ALUSrcA <= "01";
                        ALUSrcB <= "10";
                        ExtOp   <= '0';
                    when I_BNE   => 
                        ALUOp   <= ALU_SUB;
                        ALUSrcA <= "01";
                        ALUSrcB <= "00";
                        PCSource <= "01";
                        PCWriteCond <= '1';

                    -- R-type
                    when I_ADDU  => 
                        ALUOp   <= ALU_ADDU;
                        AluSrcA <= "01";
                        AluSrcB <= "00"; -- from register B
                    when I_AND   => 
                        ALUOp   <= ALU_AND;
                        AluSrcA <= "01";
                        AluSrcB <= "00";
                    when I_SUB   => 
                        ALUOp <= ALU_SUB;
                        AluSrcA <= "01";
                        AluSrcB <= "00";
                    when I_SLL   => 
                        ALUOp   <= ALU_SLL;
                        AluSrcA <= "10"; -- reg B, for rt
                    when I_SLLV  => 
                        ALUOp       <= ALU_SLL;
                        ALUSrcA     <= "10";
                        SHAMTSrc    <= '1'; -- reads lowest 5 bits from register A
                    when I_SRA   => 
                        ALUOp   <= ALU_SRA;
                        ALUSrcA <= "10";
                    when I_JR    => 
                        PCSource <= "11";
                        PCWrite  <= '1';
                    when I_MULTU => 
                        MultDisable <= '0';
                    when I_MFHI  => 
                        MemToReg <= "100";
                        RegDst   <= '1';
                    when I_MFLO  =>
                        MemToReg <= "101";
                        RegDst   <= '1';
                        -- J-type (just JMP)
                    when I_J     => 
                        PCSource <= "10";
                        PCWrite  <= '1';
                    -- Other?
                    when I_CLO   => 
                        ALUSrcA <= "01"; -- rs is muxed to 1
                    -- when BLTZAL  =>
                    when others  => null;
                end case;
            when MEM =>
                case instr is
                    when I_SW =>
                        MemWrite <= '1';
                        IorD     <= '1';
                    when I_LW | I_LH =>
                        IorD     <= '1';
                    when others => null;
                end case;
            when WRITEBACK =>   
                RegWrite <= '1';
                case instr is
                    when I_ADDI | I_ORI | I_SLTI | I_LUI | I_LW | I_LH => RegDst <= '0';
                    when others                                        => RegDst <= '1';
                end case;
                case instr is
                    when I_LW | I_LH => MemToReg <= "001";
                    when I_LUI       => MemToReg <= "010";
                    when I_CLO       => MemtoReg <= "011";
                    when I_MFHI      => MemtoReg <= "100";
                    when I_MFLO      => MemtoReg <= "101";
                    when others      => MemToReg <= "000";
                end case;
            when WAIT_DONE =>
                MultDisable <= '0';
            when HILO_WB =>     
                MultDisable <= '0';
                HILOEnable <= '1';
            when others => 
                report "Output state not implemented yet." severity warning;
        end case;
    end process;
    
end rtl;
