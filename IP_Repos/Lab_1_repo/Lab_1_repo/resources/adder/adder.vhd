library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder is
	generic (
		WIDTH : positive := 8
	);
	port (
		A     : in  std_logic_vector(WIDTH-1 downto 0);
		B     : in  std_logic_vector(WIDTH-1 downto 0);
		S     : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture rtl of adder is
begin
	S <= std_logic_vector(unsigned(A) + unsigned(B));
end architecture;
-- new comment
