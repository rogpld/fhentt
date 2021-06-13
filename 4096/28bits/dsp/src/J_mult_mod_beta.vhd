-------------------------------------------------------------------------------
-- Title      : Multiplies R0 by J, to be used in the Montgomery Butterfly
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : J_mult_mod_beta.vhd
-- Author     : Rogério Paludo  <rogerio.paludo@inesc-id.pt>
-- Company    : INESC-ID: Instituto de Engenharia de Sistemas e Computadores,
--              Investigação e Desenvolvimento
-- Created    : 2021-01-31
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
-- 2021-01-31  1.0      paludo  Created
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use work.ntt_utils.all;
use work.ntt_lib.all;
--------------------------------------------------------------------------------
entity J_mult_mod_beta is
  generic (width              : integer    := 30;
           s1, s2, s3, s4, s5 : integer;
           target             : targetType := fpga);
  port (X        : in  unsigned(width-1 downto 0);
        rst, clk : in  std_logic;
        Prod     : out unsigned(width-1 downto 0));
end J_mult_mod_beta;
--------------------------------------------------------------------------------
architecture behavior of J_mult_mod_beta is

  constant ss1 : integer := abs(s1);
  constant ss2 : integer := abs(s2);
  constant ss3 : integer := abs(s3);
  constant ss4 : integer := abs(s4);
  constant ss5 : integer := abs(s5);

  signal X2c                     : unsigned(width-1 downto 0)         := (others => '0');
  signal Zs1, Zs2, Zs3, Zs4, Zs5 : unsigned(width-1 downto 0)         := (others => '0');
  signal Prod_slv, S, S11, C11   : std_logic_vector(width-1 downto 0) := (others => '0');
  signal C                       : std_logic_vector(width downto 0)   := (others => '0');
  signal S22, C22, S33, C33      : std_logic_vector(width-1 downto 0) := (others => '0');

begin
  X2c <= twoc(X);
  --------------------------------------------------------------------------------
  -- this works because the shifts are fixed and known before synthesis for each
  -- modulus
  --------------------------------------------------------------------------------
  -- because the additive inverse the 2c is the inverse here
  -- when the shift is positive we subtract, otherwise we add
  shift_1_neg : if s1 < 0 generate
    Zs1 <= X2c;
  end generate shift_1_neg;

  shift_1_pos : if s1 >= 0 generate
    Zs1 <= X;
  end generate shift_1_pos;

  shift_2_neg : if s2 < 0 generate
    Zs2 <= shift_left(X, ss2);
  end generate shift_2_neg;

  shift_2_pos : if s2 >= 0 generate
    Zs2 <= shift_left(X2c, ss2);
  end generate shift_2_pos;

  shift_3_neg : if s3 < 0 generate
    Zs3 <= shift_left(X, ss3);
  end generate shift_3_neg;

  shift_3_pos : if s3 >= 0 generate
    Zs3 <= shift_left(X2c, ss3);
  end generate shift_3_pos;

  shift_4_neg : if s4 < 0 generate
    Zs4 <= shift_left(X, ss4);
  end generate shift_4_neg;

  shift_4_pos : if s4 >= 0 generate
    Zs4 <= shift_left(X2c, ss4);
  end generate shift_4_pos;

  five_shifts : if s5 /= 0 generate
    shift_5_neg : if s5 < 0 generate
      Zs5 <= shift_left(X, ss5);
    end generate shift_5_neg;

    shift_5_pos : if s5 >= 0 generate
      Zs5 <= shift_left(X2c, ss5);
    end generate shift_5_pos;
  end generate five_shifts;
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- first csa, since s3 > s2 > s1, this is of size width-s2
  --------------------------------------------------------------------------------
  S(ss2-1 downto 0) <= std_logic_vector(Zs1(ss2-1 downto 0));
  C(ss2-1 downto 0) <= (others => '0');

  csa_loop_generate_ha : for i in ss2 to ss3-1 generate
    csa_of_HA_1 : entity work.HalfAdder
      port map (
        A  => std_logic(Zs1(i)),
        B  => std_logic(Zs2(i)),
        S  => S(i),
        CO => C(i+1));
  end generate;

  csa_loop_generate_fa : for i in ss3 to width-1 generate
    csa_1 : entity work.FullAdder
      port map (
        A  => std_logic(Zs1(i)),
        B  => std_logic(Zs2(i)),
        CI => std_logic(Zs3(i)),
        S  => S(i),
        CO => C(i+1));
  end generate;

  --------------------------------------------------------------------------------
  -- second csa, since s4 > s3 > s2 > s1 in absolute value
  --------------------------------------------------------------------------------
  s4_diff_zero : if s4 /= 0 generate
    S11(ss4-1 downto 0) <= S(ss4-1 downto 0);
    C11(ss4-1 downto 0) <= C(ss4-1 downto 0);
    csa_2 : entity work.csa
    generic map (
      width => width-ss4)
    port map (
      A  => S(width-1 downto ss4),
      B  => C(width-1 downto ss4),
      CI => std_logic_vector(Zs4(width-1 downto ss4)),
      S  => S11(width-1 downto ss4),
      CO => C11(width-1 downto ss4));
  end generate s4_diff_zero;

  s4_equal_zero : if s4 = 0 generate
      S11 <= S;
      C11 <= C(width-1 downto 0);
  end generate s4_equal_zero;
  --------------------------------------------------------------------------------
  -- third csa, if s5 != 0
  --------------------------------------------------------------------------------
  third_csa : if s5 /= 0 generate
    S22(ss5-1 downto 0) <= S11(ss5-1 downto 0);
    C22(ss5-1 downto 0) <= C11(ss5-1 downto 0);
    third_csa_2 : entity work.csa
      generic map (
        width => width-ss5)
      port map (
        A  => S11(width-1 downto ss5),
        B  => C11(width-1 downto ss5),
        CI => std_logic_vector(Zs5(width-1 downto ss5)),
        S  => S22(width-1 downto ss5),
        CO => C22(width-1 downto ss5));
  end generate third_csa;

  final_addition_three_csa : if s5 /= 0 generate
    modadd_three_csa : entity work.modadd
      generic map (
        width  => width-ss2,
        target => target)
      port map (
        A   => S22(width-1 downto ss2),
        B   => C22(width-1 downto ss2),
        Add => Prod_slv(width-1 downto ss2));
  end generate final_addition_three_csa;

  final_addition_two_csa : if s5 = 0 or s4 = 0 generate
    modadd_two_csa : entity work.modadd
      generic map (
        width  => width-ss2,
        target => target)
      port map (
        A   => S11(width-1 downto ss2),
        B   => C11(width-1 downto ss2),
        Add => Prod_slv(width-1 downto ss2));
  end generate final_addition_two_csa;

  Prod <= unsigned(Prod_slv(width-1 downto ss2)) & unsigned(S(ss2-1 downto 0));

end behavior;
--------------------------------------------------------------------------------
