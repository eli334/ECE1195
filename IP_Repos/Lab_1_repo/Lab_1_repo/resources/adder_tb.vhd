library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder_tb is
end entity;

architecture sim of adder_tb is
	component adder is
		generic (
			WIDTH : positive := 8
		);
		port (
			A     : in  std_logic_vector(WIDTH-1 downto 0);
			B     : in  std_logic_vector(WIDTH-1 downto 0);
			S     : out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;

	constant WIDTH : positive := 4;
	signal A       : std_logic_vector(WIDTH-1 downto 0);
	signal B       : std_logic_vector(WIDTH-1 downto 0);
	signal S       : std_logic_vector(WIDTH-1 downto 0);
begin

	DUT: adder
		generic map (
			WIDTH => WIDTH
		)
		port map (
			A     => A,
			B     => B,
			S     => S
		);

	process
	begin
		for i in 0 to 2**WIDTH-1 loop
			for j in 0 to 2**WIDTH-1 loop
				A <= std_logic_vector(to_unsigned(i, WIDTH));
				B <= std_logic_vector(to_unsigned(j, WIDTH));
				wait for 10 ns;
			end loop;
		end loop;
		wait;
	end process;

end architecture;
