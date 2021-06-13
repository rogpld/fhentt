-------------------------------------------------------------------------------
-- Title      : Computes unsigned multiplication with inputs and outputs
--              registered
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : dsp_unsigned_mult.vhd
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
use IEEE.math_real.all;
-------------------------------------------------------------------------------
entity dsp_unsigned_mult is
  generic (width : positive := 16);                  --
  port (A, B     : in  unsigned(width-1 downto 0);     -- operands
        clk, rst : in  std_logic;
        Prod     : out unsigned(2*width-1 downto 0));  -- add
  attribute USE_DSP                    : string;
  attribute USE_DSP of dsp_unsigned_mult : entity is "yes";
end dsp_unsigned_mult;
-------------------------------------------------------------------------------
architecture structural of dsp_unsigned_mult is
  signal A_reg, B_reg     : unsigned(width-1 downto 0);
  signal Prod_t, Prod_reg : unsigned(2*width-1 downto 0);
begin
  -- register inputs
  A_register: entity work.ff_unsigned
    generic map (
      width => width)
    port map (
      d   => A,
      q   => A_reg,
      clk => clk,
      rst => rst);

  B_register: entity work.ff_unsigned
    generic map (
      width => width)
    port map (
      d   => B,
      q   => B_reg,
      clk => clk,
      rst => rst);

  -- output assignment
  output_reg: entity work.ff_unsigned
    generic map (
      width => 2*width)
    port map (
      d   => Prod_t,
      q   => Prod_reg,
      clk => clk,
      rst => rst);

  Prod_t <= A_reg * B_reg;
  Prod   <= Prod_reg;
end architecture;
