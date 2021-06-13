-------------------------------------------------------------------------------
-- Title      : Computes P = X * Y, it uses Karatsuba-Ofman pipelined
--              multiplier
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : komult.vhd
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
entity komult is
  generic (width  : positive   := 30;                          -- word width
           target : targetType := fpga);                       --
  port (A, B     : in  std_logic_vector(width-1 downto 0);     -- operands
        clk, rst : in  std_logic;
        Prod     : out std_logic_vector(2*width-1 downto 0));  -- add
end komult;
-------------------------------------------------------------------------------
architecture structural of komult is
  -- type that holds the 16 bits chunks, for example, 33 bits requires 3 chunks
  constant nrchunks : integer := integer(ceil(real(width)/16.0));
  constant word     : integer := 16;
  type chunks_unsigned is array (0 to nrchunks-1) of unsigned(word-1 downto 0);
  type chunks_signed_ext is array (0 to nrchunks-1) of signed(word downto 0);
  type chunks_unsigned_ext is array (0 to nrchunks-1) of signed(word downto 0);
  type chunks_slv is array (0 to nrchunks-1) of std_logic_vector(word-1 downto 0);

  -- type to hold the partial results of the multiplications
  -- there are 9 results from 3 chunks
  type partial_results is array (0 to nrchunks**2 + 3) of
    unsigned(nrchunks * 32 - 1 downto 0);
  type partial_results_slv is array (0 to nrchunks**2 + 3) of
    std_logic_vector(nrchunks * 32 - 1 downto 0);

  -- signed chunks
  signal chunks_l         : chunks_unsigned;
  signal chunks_h         : chunks_unsigned;
  signal chunks_l_ext     : chunks_unsigned_ext;
  signal chunks_h_ext     : chunks_unsigned_ext;
  signal Da, Db           : unsigned(word downto 0);
  signal Da_sign, Db_sign : signed(word downto 0);


  -- std_logic_vector chunks
  signal chunks_l_slv : chunks_slv;
  signal chunks_h_slv : chunks_slv;
  --
  signal pres         : partial_results     := (others => (others => '0'));
  signal pres_slv     : partial_results_slv := (others => (others => '0'));
  signal pres1        : signed(34-1 downto 0);
  signal pres1_2c     : unsigned(34-1 downto 0);
  signal pres0        : unsigned(2*width-1 downto 0);
  signal S, C         : std_logic_vector(2*word downto 0);
  signal S1, C1       : std_logic_vector(2*width-1 downto 0);
  signal S2, C2       : std_logic_vector(2*width-1 downto 0);
  signal A_uns, B_uns : unsigned(width-1 downto 0);
  signal sel          : std_logic_vector(1 downto 0);
  signal prod_uns     : unsigned(2*width-1 downto 0);

  signal DA_msb_delayed_0, DB_msb_delayed_0 : std_logic;
  signal DA_msb_delayed_1, DB_msb_delayed_1 : std_logic;

begin

  -- delay da, db msb sign for the sign extension required after the CSA
  process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        DA_msb_delayed_0 <= '0';
        DB_msb_delayed_0 <= '0';
        DA_msb_delayed_1 <= '0';
        DB_msb_delayed_1 <= '0';
      else
        DA_msb_delayed_0 <= DA_sign(DA_sign'high);
        DB_msb_delayed_0 <= DB_sign(DB_sign'high);
        DA_msb_delayed_1 <= DA_msb_delayed_0;
        DB_msb_delayed_1 <= DB_msb_delayed_0;
      end if;
    end if;
  end process;

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

        A_uns <= unsigned(A(width-1 downto 0));
        B_uns <= unsigned(B(width-1 downto 0));

        -- get the chunks first
        chunks_l_slv(0) <= A(word-1 downto 0);
        chunks_l_slv(1) <= B(word-1 downto 0);
        chunks_h_slv(0) <= ((word - A(A'length-1 downto word)'length)-1 downto 0 => '0') & A(A'length-1 downto word);
        chunks_h_slv(1) <= ((word - B(B'length-1 downto word)'length)-1 downto 0 => '0') & B(B'length-1 downto word);

        -- get signed types for subtractions
        chunks_l(0) <= unsigned(chunks_l_slv(0));
        chunks_l(1) <= unsigned(chunks_l_slv(1));
        chunks_h(0) <= unsigned(chunks_h_slv(0));
        chunks_h(1) <= unsigned(chunks_h_slv(1));

        chunks_l_ext(0) <= signed('0' & chunks_l_slv(0));
        chunks_l_ext(1) <= signed('0' & chunks_l_slv(1));
        chunks_h_ext(0) <= signed('0' & chunks_h_slv(0));
        chunks_h_ext(1) <= signed('0' & chunks_h_slv(1));

        DA_sign <= chunks_h_ext(0) - chunks_l_ext(0);
        DB_sign <= chunks_h_ext(1) - chunks_l_ext(1);

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

        -- Karatsuba-Ofman middle product, (A1-A0) * (B1-B0)
        dsp_signed_mult_2 : entity work.dsp_signed_mult
          generic map (
            width => word+1)
          port map (
            A    => DA_sign,
            B    => DB_sign,
            clk  => clk,
            rst  => rst,
            Prod => pres1);

        -- get two complement of result for subtraction
        pres(1) <= (pres(1)'length - pres1'length - 1 downto 0 => '0') & unsigned(not pres1 + 1);

        dsp_unsigned_mult_3 : entity work.dsp_unsigned_mult
          generic map (
            width => word)
          port map (
            A    => chunks_h(0),
            B    => chunks_h(1),
            clk  => clk,
            rst  => rst,
            Prod => pres(2)(2*word - 1 downto 0));

        --------------------------------------------------
        -- CSA
        -- --------------------------------------------------
        csa_1 : entity work.csa
          generic map (
            width => 2*word+1)
          port map (
            A  => std_logic_vector(pres(0)(2*word downto 0)),
            B  => std_logic_vector(pres(1)(2*word downto 0)),
            CI => std_logic_vector(pres(2)(2*word downto 0)),
            S  => S,
            CO => C);

        shift_cond1 : if S'length + word >= S1'length generate
          S1 <= S(S1'length-word-1 downto 0) & (0 to word-1 => '0') when S(S'high) = '1'
                else S(S1'length-word-1 downto 0) & (0 to word-1 => '0');

          C1 <= C(C1'length-word-1 downto 0) & (0 to word-1 => '0');
        end generate;

        sel <= S(S'high) & pres(1)(33);

        shift_cond2 : if S'length + word < S1'length generate

          -- this is required to sign extend the result
          with sel select
            S1 <= (S1'length-(S'length+word) - 1 downto 0 => '0') & S & (0 to word-1 => '0') when "00",
            (S1'length-(S'length+word) - 1 downto 0       => '0') & S & (0 to word-1 => '0') when "01",
            (S1'length-(S'length+word) - 1 downto 0       => '0') & S & (0 to word-1 => '0') when "10",
            (S1'length-(S'length+word) - 1 downto 0       => '1') & S & (0 to word-1 => '0') when "11",
            (S1'length-(S'length+word) - 1 downto 0       => '1') & S & (0 to word-1 => '0') when others;

          C1 <= (C1'length-(C'length+word) - 1 downto 0 => '0') & C & (0 to word-1 => '0');
        end generate;

        pres(3) <= (pres(2)(2*word-1 downto 0) & pres(0)(2*word-1 downto 0));

        csa_2 : entity work.csa
          generic map (
            width => 2*width)
          port map (
            A  => S1,
            B  => C1,
            CI => std_logic_vector(pres(3)(2*width - 1 downto 0)),
            S  => S2,
            CO => C2);
        pres(4) <= (pres(4)'length - 2 * width - 1 downto 0 => '0') & (unsigned(S2) + unsigned(C2));
        --------------------------------------------------

      end generate;

      three_chunk : if nrchunks = 3 generate
      -- not implemented yet
      end generate;
    end generate fpga_target;

  end block combinational;

  Prod <= std_logic_vector(pres(4)(2*width-1 downto 0)) when (nrchunks > 1) else std_logic_vector(pres0);

  -- synthesis translate_off
  -- prod_uns <= pres(4)(2*width-1 downto 0) when (nrchunks > 1) else pres0;
  -- assert prod_uns = A_uns * B_uns report "Failure at the Multiplier (check overflow)!" severity warning;
  -- synthesis translate_on

end structural;
-------------------------------------------------------------------------------
