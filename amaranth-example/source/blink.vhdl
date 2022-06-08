library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_blink is
  port (
    clock : in std_logic;
    led   : out std_logic
  );
end led_blink;

architecture led_blink_impl of led_blink is
  constant counter_max  : natural := 6250000;
  signal counter        : natural range 0 to counter_max;
  signal toggle         : std_logic := '0';
begin

  proc: process (clock) is
  begin
    if rising_edge(clock) then
      if counter = counter_max - 1 then
        toggle <= not toggle;
        counter <= 0;
      else
        counter <= counter + 1;
      end if;
    end if;
  end process proc;

  led <= toggle;
end led_blink_impl;
