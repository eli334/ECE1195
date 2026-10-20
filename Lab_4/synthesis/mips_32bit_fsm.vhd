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
        RegDst      : out STD_LOGIC
    );
end entity;

architecture rtl of mips_32bit_fsm is

    -- Build an enumerated type for the state machine
    type state_type is (FETCH, DECODE, ADDI_EX, ORI_EX, SLTI_EX, I_WB);
    
    -- Register to hold the current state
    signal state   : state_type;

begin
    -- Logic to advance to the next state
    process (clk, reset)
    constant OP_ADDI : STD_LOGIC_VECTOR(5 downto 0) := "001000";
    constant OP_ORI  : STD_LOGIC_VECTOR(5 downto 0) := "001101";
    constant OP_SLTI : STD_LOGIC_VECTOR(5 downto 0) := "001010";
    begin
        if reset = '1' then
            state <= FETCH;
        elsif (rising_edge(clk)) then
            case state is
                when DECODE =>
                    case Op is
                        when OP_ADDI => state <= ADDI_EX;
                        when OP_ORI  => state <= ORI_EX;
                        when OP_SLTI => state <= SLTI_EX;
                        when others => state <= FETCH;
                    end case;
                when ADDI_EX | ORI_EX | SLTI_EX 
                    => state <= I_WB;
                when I_WB
                    => state <= FETCH;
            end case;
        end if;
    end process;
    
    -- Output depends solely on the current state
    process (state)
    begin
        case state is
            when ADDI_EX 
            => ALUOp <= 
            when ORI_EX =>
            when SLTI_EX =>

        end case;
    end process;
    
end rtl;
