-------------------------------------------------------------------------------
-- Title      : Multiplies Q by p, to be used in the Montgomery Butterfly
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : Q_mult.vhd
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
use work.ntt_utils.all;
use work.ntt_lib.all;
--------------------------------------------------------------------------------
entity Q_mult_p is
  generic (width          : integer    := 30;
           s1, s2, s3, s4 : integer;
           target         : targetType := fpga);
  port (X        : in  unsigned(width-1 downto 0);
        rst, clk : in  std_logic;
        Prod     : out unsigned(2*width-1 downto 0));
end Q_mult_p;
--------------------------------------------------------------------------------
architecture behavior of Q_mult_p is
  constant ss1                 : integer                              := abs(s1);
  constant ss2                 : integer                              := abs(s2);
  constant ss3                 : integer                              := abs(s3);
  constant ss4                 : integer                              := abs(s4);
  signal Xext                  : unsigned(width downto 0)             := (others => '0');
  signal X2c_sign              : unsigned(width downto 0)             := (others => '0');
  signal X2c                   : unsigned(width-1 downto 0)           := (others => '0');
  signal Zs1, Zs2, Zs3, Zs4    : unsigned(2*width-1 downto 0)         := (others => '0');
  signal Prod_slv, S, S11, C11 : std_logic_vector(2*width-1 downto 0) := (others => '0');
  signal C                     : std_logic_vector(2*width downto 0)   := (others => '0');
  signal sign                  : std_logic;
begin
  Xext     <= '0' & X;
  X2c_sign <= twoc(Xext);
  sign     <= X2c_sign(X2c_sign'high);
  X2c      <= X2c_sign(width-1 downto 0);

  -- condition to make it work: s1 < s2 < s3 < s4 < s5, s1 = 0
  -- for example, s1 = 0, s2 = 13, s2 = 16, s3 = 26, s4 = 28, (s5 = 30, which
  -- is not really used due to the modular reduction)

  --------------------------------------------------------------------------------
  -- this works because the shifts are fixed and known before synthesis for each
  -- modulus
  --------------------------------------------------------------------------------
  shift_1_neg : if s1 < 0 generate
    Zs1 <= (X2c'length-1 downto 0 => '0') & X2c;
  end generate shift_1_neg;

  shift_1_pos : if s1 >= 0 generate
    Zs1 <= (X'length-1 downto 0 => '0') & X;
  end generate shift_1_pos;

  shift_2_neg : if s2 < 0 generate
    Zs2 <= (Zs2'length-X2c'length-ss2-1 downto 0 => '1') & X2c & (ss2-1 downto 0 => '0') when sign = '1'
           else
           (Zs2'length-X2c'length-ss2-1 downto 0 => '0') & X2c & (ss2-1 downto 0 => '0');
  end generate shift_2_neg;

  shift_2_pos : if s2 >= 0 generate
    Zs2 <= (Zs2'length-X'length-ss2-1 downto 0 => '0') & X & (ss2-1 downto 0 => '0');
  end generate shift_2_pos;

  shift_3_neg : if s3 < 0 generate
    Zs3 <= (Zs3'length-X2c'length-ss3-1 downto 0 => '1') & X2c & (ss3-1 downto 0 => '0') when sign = '1'
           else
           (Zs3'length-X2c'length-ss3-1 downto 0 => '0') & X2c & (ss3-1 downto 0 => '0');
  end generate shift_3_neg;

  shift_3_pos : if s3 >= 0 generate
    Zs3 <= (Zs3'length-X'length-ss3-1 downto 0 => '0') & X & (ss3-1 downto 0 => '0');
  end generate shift_3_pos;

  shift_4_neg : if s4 < 0 generate
    Zs4 <= (Zs4'length-X2c'length-ss4-1 downto 0 => '1') & X2c & (ss4-1 downto 0 => '0') when sign = '1'
           else
           (Zs4'length-X2c'length-ss4-1 downto 0 => '0') & X2c & (ss4-1 downto 0 => '0');
  end generate shift_4_neg;

  shift_4_pos : if s4 >= 0 generate
    Zs4 <= (Zs4'length-X'length-ss4-1 downto 0 => '0') & X & (ss4-1 downto 0 => '0');
  end generate shift_4_pos;
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

  csa_loop_generate_fa : for i in ss3 to width+ss2-1 generate
    csa_1 : entity work.FullAdder
      port map (
        A  => std_logic(Zs1(i)),
        B  => std_logic(Zs2(i)),
        CI => std_logic(Zs3(i)),
        S  => S(i),
        CO => C(i+1));
  end generate;

  -- depends on the sign extension
  loop_ss2_ss3_generate_not : for i in width+ss2 to width+ss3-1 generate
    s2_neg_s3_neg_1 : if s2 < 0 generate
      S(i)   <= not Zs3(i) when sign = '1' else Zs3(i);
      C(i+1) <= Zs3(i)     when sign = '1' else '0';
    end generate s2_neg_s3_neg_1;
    s2_pos_s3_neg_1 : if s2 >= 0 generate
      S(i)   <= Zs3(i);
      C(i+1) <= '0';
    end generate s2_pos_s3_neg_1;
  end generate;

  sign_extension_generate : for i in width+ss3 to 2*width-1 generate
    s2_neg_s3_neg_2 : if s2 < 0 generate
      S(i)   <= '0' when sign = '1' else '0';
      C(i+1) <= '1' when sign = '1' else '0';
    end generate s2_neg_s3_neg_2;
    s2_pos_s3_neg_2 : if s2 >= 0 generate
      S(i)   <= '1' when sign = '1' else '0';
      C(i+1) <= '0';
    end generate s2_pos_s3_neg_2;
  end generate;
  --------------------------------------------------------------------------------
  -- second csa, since s4 > s3 > s2 > s1 in absolute value
  --------------------------------------------------------------------------------
  S11(ss4-1 downto 0) <= S(ss4-1 downto 0);
  C11(ss4-1 downto 0) <= C(ss4-1 downto 0);
  csa_2 : entity work.csa
    generic map (
      width => width)
    port map (
      A  => S(width+ss4-1 downto ss4),
      B  => C(width+ss4-1 downto ss4),
      CI => std_logic_vector(Zs4(width+ss4-1 downto ss4)),
      S  => S11(width+ss4-1 downto ss4),
      CO => C11(width+ss4-1 downto ss4));
  --------------------------------------------------------------------------------
  -- Final addition
  --------------------------------------------------------------------------------
  Prod_slv(ss2-1 downto 0)                       <= S(ss2-1 downto 0);
  Prod_slv(Prod_slv'high-2 downto ss2)           <= std_logic_vector(unsigned(S11(Prod_slv'high-2 downto ss2)) + unsigned(C11(Prod_slv'high-2 downto ss2)));
  Prod_slv(Prod_slv'high downto Prod_slv'high-1) <= (others => '0');
  Prod                                           <= unsigned(Prod_slv);
end behavior;
--------------------------------------------------------------------------------
