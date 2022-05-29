library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blink is
  port (
    CLK_IN  : in std_logic;
    led     : out std_logic
  );
end blink;

architecture blink_impl of blink is
  constant counter_max  : natural := 6250000;
  signal counter        : natural range 0 to counter_max;
  signal toggle         : std_logic := '0';
begin

  proc: process (CLK_IN) is
  begin
    if rising_edge(CLK_IN) then
      if counter = counter_max - 1 then
        toggle <= not toggle;
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
    end if;
  end process proc;

  led <= toggle;
end blink_impl;
