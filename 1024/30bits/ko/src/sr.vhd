-------------------------------------------------------------------------------
-- Title      : Simple Shift register parametric
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
-------------------------------------------------------------------------------
entity sr is
  generic (width : integer := 8;
           shift : integer := 4);
  port (d        : in  std_logic_vector(width-1 downto 0);
        q        : out std_logic_vector(width-1 downto 0);
        clk, rst : in  std_logic);
end sr;
-------------------------------------------------------------------------------
architecture behavior of sr is
  type shiftregister is array (0 to shift-1) of std_logic_vector(width-1 downto 0);
  signal sr : shiftregister;
begin

  shift_register_ff_0: entity work.ff
    generic map (
      width => width)
    port map (
      d   => d,
      q   => sr(0),
      clk => clk,
      rst => rst);

  shift_register_loop: for i in 1 to shift-1 generate
    shift_register_ff: entity work.ff
      generic map (
        width => width)
      port map (
        d   => sr(i-1),
        q   => sr(i),
        clk => clk,
        rst => rst);
  end generate shift_register_loop;
  q <= sr(shift-1);

end behavior;
-------------------------------------------------------------------------------
