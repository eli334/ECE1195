library ieee;
use ieee.std_logic_1164.all;

entity ee_mult_fsm is

	port
	(
		RST          : in	std_logic;
        CLK          : in	std_logic;
        Q            : in	std_logic;
        C_max        : in	std_logic;
		load_product : out	std_logic;
        multD_enable : out	std_logic;
        multR_enable : out	std_logic;
        counter_enable  : out	std_logic;
		done         : out	std_logic
	);
	
end entity;

architecture rtl of ee_mult_fsm is

	-- Build an enumerated type for the state machine
	type state_type is (go, finished);
	
	-- Register to hold the current state
	signal state : state_type;
begin
	process (RST, CLK)
	begin
		if RST = '1' then
			state <= go;
		elsif (rising_edge(CLK)) then
			case state is
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
    process (state, Q)
	begin
		case state is
			when go =>
                load_product <= Q;
                multD_enable <= '1';
                multR_enable <= '1';
                counter_enable <= '1';
                done <= '0';
            when finished =>
				load_product <= '0';
                multD_enable <= '0';
                multR_enable <= '0';
                counter_enable <= '0';
                done <= '1';
		end case;
	end process;
end architecture;