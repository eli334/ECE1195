library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity ee_mult_top is
    generic (
        MULT_WIDTH     : integer := 32 -- 32-bit multiplier gives 64-bit product
    );
    port(
        A            : in	std_logic_vector(MULT_WIDTH - 1 downto 0);
        B            : in	std_logic_vector(MULT_WIDTH - 1 downto 0);
        clk          : in	std_logic;
        rst          : in	std_logic;
        R            : out	std_logic_vector((2 * MULT_WIDTH - 1) downto 0);
        done         : out	std_logic
    );
end entity;

architecture structural of ee_mult_top is
    -- Signals to connect the submodules        
    signal Q               : std_logic;
    signal C_max           : std_logic;
    signal load_product    : std_logic;
    signal multD_enable    : std_logic;
    signal multR_enable    : std_logic;
    signal first_iter      : std_logic;
    
    signal counter_enable  : std_logic;

    -- signal multiplier      : std_logic_vector(MULT_WIDTH - 1 downto 0); -- not read from
    signal B_shift         : std_logic_vector(MULT_WIDTH-1 downto 0);
    signal A_ext, A_shift, adder_mux, multiplicand, adder_out, product_out:
                             std_logic_vector((2 * MULT_WIDTH - 1) downto 0);
begin
    ee_mult_counter : entity work.ee_counter
        generic map(
            COUNTER_WIDTH => integer(ceil(log2(real(MULT_WIDTH))))
        )
        port map(
            CLK          => clk,
            RST          => rst,
            ENABLE       => counter_enable,
            C_max        => C_max,
            COUNT        => open
        );
    ee_multiplicand_shift_reg : entity work.ee_shift_register
        generic map(
            REG_WIDTH  => 2 * MULT_WIDTH,
            left_shift => true
        )
        port map(
            LOAD   => first_iter,
            ENABLE => multD_enable,
            CLK    => clk,
            SIN    => '0',
            P_IN   => A_shift,
            RST    => '0',
            Q      => open,
            P_OUT  => multiplicand
        );
    ee_multiplier_shift_reg : entity work.ee_shift_register
        generic map(
            REG_WIDTH  => MULT_WIDTH,
            left_shift => false
        )
        port map(
            LOAD   => first_iter,
            ENABLE => multR_enable,
            CLK    => clk,
            SIN    => '0',
            P_IN   => B_shift,
            RST    => '0',
            Q      => Q,
            P_OUT  => open
        );
    
    ee_product_reg : entity work.ee_register
        generic map(
            REG_WIDTH  => 2 * MULT_WIDTH
        )
        port map(
            LOAD   => load_product,
            CLK    => clk,
            P_IN   => adder_out,
            RST    => rst,
            P_OUT  => product_out
        );
    ee_adder : entity work.ee_adder_generic_32
    generic map(
        N => 2 * MULT_WIDTH
    )
    port map(
        numA      => product_out,
        numB      => adder_mux,
        sub       => '0',
        Carry_out => open,
        numSum    => adder_out
    );
    ee_mult_fsm : entity work.ee_mult_fsm
        port map(
            RST          => rst,
            CLK          => clk,
            Q            => Q,
            B0           => B(0),
            C_max        => C_max,
            first_iter   => first_iter,
            load_product => load_product,
            multD_enable => multD_enable,
            multR_enable => multR_enable,
            counter_enable  => counter_enable,
            done         => done
    );

    adder_mux <= A_ext when first_iter = '1' else multiplicand;
    A_ext <= ((MULT_WIDTH-1 downto 0 => '0') & A);
    A_shift <= A_ext(2*MULT_WIDTH-2 downto 0) & '0';
    B_shift <= '0' & B(MULT_WIDTH-1 downto 1);
    R <= product_out;
end architecture;