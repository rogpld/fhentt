-------------------------------------------------------------------------------
-- Title      : Simple D flip-flop
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : ff.vhd
-- Author     : Rogério Paludo  <rogerio.paludo@inesc-id.pt>
-- Company    : INESC-ID: Instituto de Engenharia de Sistemas e Computadores,
--              Investigação e Desenvolvimento
-- Created    : 2021-01-20
-- Last update: 2021-06-13
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2021 Rogério Paludo and Leonel Sousa
-- <firstname.lastname@inesc-id.pt>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-01-20  1.0      paludo  Created
-------------------------------------------------------------------------------
library ieee;
use work.ntt_utils.all;
use work.ntt_lib.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity ff_signed is
  generic (width : integer := 8);
  port (d        :     signed(width-1 downto 0);
        q        : out signed(width-1 downto 0);
        clk, rst :     std_logic);
end ff_signed;
-------------------------------------------------------------------------------
architecture behavior of ff_signed is
begin
  -- sync reset
  process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q <= (others => '0');
      else
        q <= d;
      end if;
    end if;
  end process;
end behavior;
-------------------------------------------------------------------------------
