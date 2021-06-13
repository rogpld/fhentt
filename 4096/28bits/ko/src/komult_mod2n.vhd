-------------------------------------------------------------------------------
-- Title      : Computes P = (X * Y) % 2^n, it uses Karatsuba-Ofman pipelined
--              multiplier
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : komult_mod2n.vhd
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
entity komult_mod2n is
  generic (width  : positive   := 30;                        -- word width
           target : targetType := fpga);                     --
  port (A, B     : in  std_logic_vector(width-1 downto 0);   -- operands
        clk, rst : in  std_logic;
        Prod     : out std_logic_vector(width-1 downto 0));  -- add
end komult_mod2n;
-------------------------------------------------------------------------------
architecture structural of komult_mod2n is
  -- type that holds the 16 bits chunks, for example, 33 bits requires 3 chunks
  constant nrchunks : integer := integer(ceil(real(width)/16.0));
  constant word     : integer := 16;
  type chunks_unsigned is array (0 to nrchunks-1) of unsigned(word-1 downto 0);

  -- type to hold the partial results of the multiplications
  -- there are 9 results from 3 chunks
  type partial_results is array (0 to nrchunks**2 + 4) of
    unsigned(nrchunks * 32 - 1 downto 0);

  -- unsigned chunks
  signal chunks_l : chunks_unsigned;
  signal chunks_h : chunks_unsigned;

  signal pres         : partial_results := (others => (others => '0'));
  signal pres0        : unsigned(2*width-1 downto 0) := (others => '0');
  signal S, C         : std_logic_vector(width-word-1 downto 0);
  signal A_uns, B_uns : unsigned(width-1 downto 0) := (others => '0');

begin
  -- purpose: this generates DSP multipliers in
  -- chunks of word bits
  combinational : block is
  begin
    -- default multiplier using DSP blocks of the FPGA
    fpga_target : if target = fpga generate
      -- simple word bit multiplier using DSP blocks
      one_chunk : if nrchunks = 1 generate
        A_uns <= unsigned(A(width-1 downto 0));
        B_uns <= unsigned(B(width-1 downto 0));
        simple_word_bit : entity work.dsp_unsigned_mult
          generic map (
            width => width)
          port map (
            A    => A_uns,
            B    => B_uns,
            clk  => clk,
            rst  => rst,
            Prod => pres0);
      end generate;
      -- this is a two chunk multiplier, i.e.,
      -- 32 bits using word bits DSP multipliers
      -- note that the output has 64 bits
      two_chunk : if nrchunks = 2 generate
        -- get the chunks first
        chunks_l(0) <= unsigned(A(word-1 downto 0));
        chunks_l(1) <= unsigned(B(word-1 downto 0));
        chunks_h(0) <= unsigned(std_logic_vector'(((word - A(A'length-1 downto word)'length)-1 downto 0 => '0') & A(A'length-1 downto word)));
        chunks_h(1) <= unsigned(std_logic_vector'(((word - B(B'length-1 downto word)'length)-1 downto 0 => '0') & B(B'length-1 downto word)));

        -- LSB product
        dsp_unsigned_mult_1 : entity work.dsp_unsigned_mult
          generic map (
            width => word)
          port map (
            A    => chunks_l(0),
            B    => chunks_l(1),
            clk  => clk,
            rst  => rst,
            Prod => pres(0)(2*word - 1 downto 0));

        dsp_signed_mult_2 : entity work.dsp_unsigned_mult
          generic map (
            width => width-word)
          port map (
            A    => chunks_h(0)(width-word-1 downto 0),
            B    => chunks_l(1)(width-word-1 downto 0),
            clk  => clk,
            rst  => rst,
            Prod => pres(1)(2*(width-word)-1 downto 0));

        dsp_signed_mult_3 : entity work.dsp_unsigned_mult
          generic map (
            width => width-word)
          port map (
            A    => chunks_h(1)(width-word-1 downto 0),
            B    => chunks_l(0)(width-word-1 downto 0),
            clk  => clk,
            rst  => rst,
            Prod => pres(2)(2*(width-word)-1 downto 0));

        pres(3) <= (pres(3)'length-width-1 downto 0 => '0') & pres(1)(width-word-1 downto 0) & (word-1 downto 0 => '0');
        pres(4) <= (pres(4)'length-width-1 downto 0 => '0') & pres(2)(width-word-1 downto 0) & (word-1 downto 0 => '0');

        ----------------------------------------------------
        -- FINAL sums
        ----------------------------------------------------
        csa_1 : entity work.csa
          generic map (
            width => width-word)
          port map (
            A  => std_logic_vector(pres(3)(width-1 downto word)),
            B  => std_logic_vector(pres(4)(width-1 downto word)),
            CI => std_logic_vector(pres(0)(width-1 downto word)),
            S  => S,
            CO => C);

        pres(5) <= (pres(5)'length-width-1 downto 0 => '0') & (unsigned(S) + unsigned(C)) & pres(0)(word-1 downto 0);

      end generate;

      three_chunk : if nrchunks = 3 generate
      -- not implemented yet
      end generate;
    end generate fpga_target;

  end block combinational;

  Prod <= std_logic_vector(pres(5)(width-1 downto 0)) when (nrchunks > 1) else std_logic_vector(pres0(width-1 downto 0));

end structural;
-------------------------------------------------------------------------------
