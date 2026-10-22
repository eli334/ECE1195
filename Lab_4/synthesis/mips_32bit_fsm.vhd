-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity mips_32bit_fsm is
    port(
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        Op          : in  STD_LOGIC_VECTOR(5 downto 0);
        Funct       : in  STD_LOGIC_VECTOR(5 downto 0); -- SPECIAL/SPECIAL2 ops

        PCWriteCond : out STD_LOGIC;
        PCWrite     : out STD_LOGIC;
        IorD        : out STD_LOGIC;
        MemRead     : out STD_LOGIC;
        MemWrite    : out STD_LOGIC;
        MemtoReg    : out STD_LOGIC;
        IRWrite     : out STD_LOGIC;
        PCSource    : out STD_LOGIC_VECTOR(1 downto 0);
        ALUOp       : out STD_LOGIC_VECTOR(1 downto 0);
        ALUSrcB     : out STD_LOGIC_VECTOR(1 downto 0);
        ALUSrcA     : out STD_LOGIC;
        RegWrite    : out STD_LOGIC;
        RegDst      : out STD_LOGIC;
        ExtOp       : out STD_LOGIC
    );
end entity;

architecture rtl of mips_32bit_fsm is

    -- Build an enumerated type for the state machine
    type state_type is (FETCH, DECODE, EXECUTE, MEM, WRITEBACK);
    type instruction is (I_ADDI, I_ADDU, I_AND, I_BNE, I_CLO, 
                          I_J, I_JR, I_LH, I_LUI, I_LW, 
                          I_MFHI, I_MFLO, I_MULTU, I_ORI, I_SLL, 
                          I_SLLV, I_SLTI, I_SRA, I_SUB, I_SW,
                          I_NOP, I_SLT);

    -- Register to hold the current state
    signal state   : state_type;
    signal instr   : instruction;

begin
    -- Logic to advance to the next state
    process (clk, reset)
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
        if reset = '1' then
            state <= FETCH;
            instr <= I_NOP;
        elsif (rising_edge(clk)) then
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
                        when OP_LUI  => instr <= I_LUI;
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
                                    report "SPECIAL function not implemented." severity warning;
                                    state <= FETCH;
                            end case;
                                
                        when SPECIAL2 =>
                            case Funct is
                                when SP2_CLO 
                                    => instr <= I_CLO;
                                when others => 
                                    report "SPECIAL2 function not implemented." severity warning;
                                    state <= FETCH; 
                            end case;
                        when others => 
                            report "Instruction not implemented." severity warning; 
                        end case;
                        state <= FETCH; -- not implemented yet
                when EXECUTE => 
                    state <= MEM;
                    case instr is
                        when I_LW | I_LH | I_SW => state <= MEM;
                        when I_ADDI | I_ORI | I_SLTI => 
                when MEM
                    => state <= WRITEBACK;
            end case;
        end if;
    end process;
    
    -- Output depends solely on the current state
    process (state, instr)
        -- ALU constants
    constant ALU_LGIC: STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant ALU_AND : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant ALU_OR  : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant ALU_XOR : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant ALU_NOR : STD_LOGIC_VECTOR(1 downto 0) := "11";

    constant ALU_ARTH: STD_LOGIC_VECTOR(1 downto 0) := "01";
    
    constant ALU_CMP : STD_LOGIC_VECTOR(1 downto 0) := "10";
    -- needs ARITH unit for subtraction; not sure how that's gonna work yet

    constant ALU_SHFT: STD_LOGIC_VECTOR(1 downto 0) := "11";
    constant SHFT_SLL: STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant SHFT_SLA: STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant SHFT_SRL: STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant SHFT_SRA: STD_LOGIC_VECTOR(1 downto 0) := "11";
    begin
        PCWriteCond <= '0';
        PCWrite     <= '0';
        IorD        <= '0';
        MemRead     <= '0';
        MemWrite    <= '0';
        MemtoReg    <= '0';
        IRWrite     <= '0';
        PCSource    <= "00";
        ALUOp       <= ALU_ADD;
        ALUSrcB     <= "00";
        ALUSrcA     <= '0';
        ExtOp       <= '0';
        RegWrite    <= '0';
        RegDst      <= '0';
        case state is
            when FETCH =>
                IorD     <= '0';
                MemRead  <= '1';
                IRWrite  <= '1';
                ALUSrcA  <= '0';
                ALUSrcB  <= "01"; -- 4 for PC + 4
                ALUOp    <= "01"; -- + for PC + 4
                PCSource <= "00";
                PCWrite  <= '1';
            when EXECUTE =>
                case instr is =>
                    -- Immediate
                    when I_ADDI
                        =>
            when ADDI_EX => 
                ALUOp <= "01";
            when ORI_EX => 
                ALUOp <= "00";
            when SLTI_EX =>
                ALUOp <= "11";
            when others =>
                report "Opcode not implemented yet." severity note;
        end case;
    end process;
    
end rtl;
