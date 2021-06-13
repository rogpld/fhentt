-------------------------------------------------------------------------------
-- Title      : Implementation of generic butterfly unit
-- Project    : Number Theoretic Transform
-------------------------------------------------------------------------------
-- File       : butterfly.vhd
-- Author     : Rogério Paludo  <rogerio.paludo@inesc-id.pt>
-- Company    : INESC-ID: Instituto de Engenharia de Sistemas e Computadores,
--              Investigação e Desenvolvimento
-- Created    : 2021-01-20
-- Last update: 2021-06-13
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: This file implements the butterfly unit using the scheme
-- presented by David Harvey in his paper "Faster arithmetic for
-- number-theoretic transforms", it replaces DSP multipliers by cnt shifts
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

entity butterfly_gen_cnt is
  generic (betawidth : positive := 30;   -- beta width (extended)
           modwidth  : positive := 28;   -- modulus width
           p         : std_logic_vector(modwidth-1 downto 0);
           -- shifts for the modulus
           s1        : integer  := 0;
           s2        : integer  := -13;
           s3        : integer  := -16;
           s4        : integer  := 28;
           -- shifts for J
           f1        : integer  := 0;
           f2        : integer  := -13;
           f3        : integer  := -16;
           f4        : integer  := -26;
           f5        : integer  := 28);  --
  -- ports
  port(
    -- variables inputs
    X, Y       : in  std_logic_vector(betawidth-1 downto 0);
    -- beta * w mod p
    W          : in  std_logic_vector(modwidth-1 downto 0);
    -- the results
    Xout, Yout : out std_logic_vector(betawidth-1 downto 0);
    clk, rst   : in  std_logic);
end entity butterfly_gen_cnt;
-------------------------------------------------------------------------------
architecture structural of butterfly_gen_cnt is
  constant target           : targetType                            := fpga;
  signal Xl, Yl             : std_logic_vector(betawidth-1 downto 0);
  signal Xreg, Yreg         : std_logic_vector(betawidth-1 downto 0);
  signal Wreg               : std_logic_vector(modwidth-1 downto 0);
  signal preg               : std_logic_vector(modwidth-1 downto 0) := p;
  signal T                  : std_logic_vector(betawidth-1 downto 0);
  signal Wext               : std_logic_vector(betawidth-1 downto 0);
  signal R                  : std_logic_vector(2*betawidth-1 downto 0);
  signal R0, R1             : std_logic_vector(betawidth-1 downto 0);
  signal R0reg              : std_logic_vector(betawidth-1 downto 0);
  signal R1reg              : std_logic_vector(betawidth-1 downto 0);
  signal Q                  : std_logic_vector(betawidth-1 downto 0);
  signal Quns               : unsigned(betawidth-1 downto 0);
  signal Quns_reg           : unsigned(betawidth-1 downto 0);
  signal H                  : std_logic_vector(betawidth-1 downto 0);
  signal Hreg               : unsigned(betawidth-1 downto 0);
  signal Huns               : unsigned(2*betawidth-1 downto 0);
  signal pext               : std_logic_vector(betawidth-1 downto 0);
begin

  register_X : entity work.ff
    generic map (
      width => betawidth)
    port map (
      d   => X,
      q   => Xreg,
      clk => clk,
      rst => rst);

  register_Y : entity work.ff
    generic map (
      width => betawidth)
    port map (
      d   => Y,
      q   => Yreg,
      clk => clk,
      rst => rst);

  register_W : entity work.ff
    generic map (
      width => modwidth)
    port map (
      d   => W,
      q   => Wreg,
      clk => clk,
      rst => rst);

  -- register_p : entity work.ff
  --   generic map (
  --     width => modwidth)
  --   port map (
  --     d   => p,
  --     q   => preg,
  --     clk => clk,
  --     rst => rst);

  -- extends p with additional bits
  pext <= (betawidth-modwidth-1 downto 0 => '0') & preg;

  X_plus_Y_minus_2p : entity work.addm2p_gen
    generic map (
      width  => betawidth,
      target => target)
    port map (
      A   => Xreg,
      B   => Yreg,
      p   => pext,
      Add => Xl);

  X_minus_Y_plus_2p : entity work.subp2p_gen
    generic map (
      width  => betawidth,
      target => target)
    port map (
      A   => Xreg,
      B   => Yreg,
      p   => pext,
      Sub => T);

  -- extend W, it is represented mod p
  Wext <= (0 to 1 => '0') & Wreg;

  W_times_T : entity work.komult
    generic map (
      width  => betawidth,
      target => target)
    port map (
      A    => Wext,
      B    => T,
      clk  => clk,
      rst  => rst,
      Prod => R);

  R0 <= R(R0'range);
  R1 <= R(R'length-1 downto R1'length);

  --------------------------------------------------------------------------------
  -- we need to shift register R1 with 4 delays
  -- this compensates the delays of the multipliers
  shift_register_R1 : entity work.sr
    generic map (
      width => R1reg'length,
      shift => 3)
    port map (
      d   => R1,
      q   => R1reg,
      clk => clk,
      rst => rst);
  --------------------------------------------------------------------------------
  -- Does not WORK! to spare some flip flops I'm using a simple register bank,
  -- it will keep stable as long as the input is stable, stability has to be
  -- handled at top level
  --------------------------------------------------------------------------------
  -- register_R1 : entity work.ff
  --   generic map (
  --     width => R1reg'length)
  --   port map (
  --     d   => R1,
  --     q   => R1reg,
  --     clk => clk,
  --     rst => rst);
  --------------------------------------------------------------------------------
  register_R0 : entity work.ff
    generic map (
      width => R0reg'length)
    port map (
      d   => R0,
      q   => R0reg,
      clk => clk,
      rst => rst);

  R0_times_J : entity work.J_mult_mod_beta
    generic map (
      width  => betawidth,
      target => target,
      s1     => f1,
      s2     => f2,
      s3     => f3,
      s4     => f4,
      s5     => f5)
    port map (
      X    => unsigned(R0reg(betawidth-1 downto 0)),
      rst  => rst,
      clk  => clk,
      Prod => Quns);

  Q <= std_logic_vector(Quns);

  -- output assignment
  -- register the output Y
  register_Quns : entity work.ff_unsigned
    generic map (
      width => Quns'length)
    port map (
      d   => Quns,
      q   => Quns_reg,
      clk => clk,
      rst => rst);

  Q_mult_p_1 : entity work.Q_mult_p
    generic map (
      width  => betawidth,
      s1     => s1,
      s2     => s2,
      s3     => s3,
      s4     => s4,
      target => target)
    port map (
      X    => Quns_reg,
      rst  => rst,
      clk  => clk,
      Prod => Huns);

  -- output assignment
  -- register the output Y
  register_H : entity work.ff_unsigned
    generic map (
      width => betawidth)
    port map (
      d   => Huns(Huns'high downto betawidth),
      q   => Hreg,
      clk => clk,
      rst => rst);

  Yl <= std_logic_vector(unsigned(R1reg) + twoc(Hreg(betawidth-1 downto 0)) + unsigned(preg));

  -- output assignment
  -- register the output Y
  register_Y_out : entity work.ff
    generic map (
      width => Yout'length)
    port map (
      d   => Yl,
      q   => Yout,
      clk => clk,
      rst => rst);

  register_X_out : entity work.sr
    generic map (
      width => Xout'length,
      shift => 6)
    port map (
      d   => Xl,
      q   => Xout,
      clk => clk,
      rst => rst);

end structural;
-------------------------------------------------------------------------------
