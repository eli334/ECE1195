library ieee;
use ieee.std_logic_1164.all;

entity ee_mult_fsm is
    port
    (
        RST             : in    std_logic;
        CLK             : in    std_logic;
        Q               : in    std_logic;  
        B0              : in    std_logic;
		C_max           : in    std_logic;
        first_iter      : out   std_logic; 
        load_product    : out   std_logic;
        multD_enable    : out   std_logic;
        multR_enable    : out   std_logic;
        counter_enable  : out   std_logic;
        done            : out   std_logic
    );
end entity;

architecture rtl of ee_mult_fsm is
    type state_type is (first, go, finished);
    signal state : state_type;
begin
    process (RST, CLK)
    begin
        if RST = '1' then
            state <= first;
        elsif rising_edge(CLK) then
            case state is
                when first =>
                    state <= go;
                when go =>
                    if C_max = '1' then
                        state <= finished;
                    else
                        state <= go;
                    end if;
                when finished =>
                    state <= finished;
            end case;
        end if;
    end process;

    -- Mealy output logic
    process (state, Q, B0)
    begin
        first_iter     <= '0';
        load_product   <= '0';
        multD_enable   <= '0';
        multR_enable   <= '0';
        counter_enable <= '0';
        done           <= '0';

        case state is
            when first =>
                first_iter     <= '1';
                load_product   <= B0;
                counter_enable <= '1';
            when go =>
                load_product   <= Q;
                multD_enable   <= '1';
                multR_enable   <= '1';
                counter_enable <= '1';
            when finished =>
                done           <= '1';
        end case;
    end process;
end architecture;