-------------------------------------------------------------------------------
-- Title      : Computes P = X * Y, regular integer multiplier
-- Project    :
-------------------------------------------------------------------------------
-- File       : addm2p.vhd
-- Author     : Rogério Paludo  <paludo@Workspace>
-- Company    :
-- Created    : 2021-01-20
-- Last update: 2021-01-24
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2021
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
entity mult_mod2n is
  generic (width  : positive   := 30;                        -- word width
           target : targetType := fpga);                     --
  port (A, B     : in  std_logic_vector(width-1 downto 0);   -- operands
        clk, rst : in  std_logic;
        Prod     : out std_logic_vector(width-1 downto 0));  -- add
end mult_mod2n;
-------------------------------------------------------------------------------
architecture structural of mult_mod2n is
  -- type that holds the 16 bits chunks, for example, 33 bits requires 3 chunks
  constant nrchunks : integer := integer(ceil(real(width)/16.0));
  type chunks is array (0 to nrchunks-1) of unsigned(15 downto 0);

  -- type to hold the partial results of the multiplications
  -- there are 9 results from 3 chunks
  type partial_results is array (0 to nrchunks**2) of
    std_logic_vector(nrchunks * 32 - 1 downto 0);

  signal chunks_l       : chunks;
  signal chunks_h       : chunks;
  signal pres, pres_reg : partial_results;

  signal S, C             : std_logic_vector(width-1 downto 0);
  signal At, Bt           : std_logic_vector(16-1 downto 0);
  signal prodt, prodt_reg : std_logic_vector(2*width-1 downto 0);

  -- synthesis attributes
  attribute USE_DSP : string;
  attribute USE_DSP of pres: signal is "YES";
begin
  -- purpose: this generates DSP multipliers in
  -- chunks of 16 bits
  combinational : block is
  begin  -- block combinational part
    -- default multiplier using DSP blocks of the FPGA
    fpga_target : if target = fpga generate
      -- simple 16 bit multiplier using DSP blocks
      one_chunk : if nrchunks = 1 generate
        prodt <= std_logic_vector(unsigned(A) * unsigned(B));
      end generate;
      -- this is a two chunk multiplier, i.e.,
      -- 32 bits using 16 bits DSP multipliers
      -- note that the output has 64 bits
      two_chunk : if nrchunks = 2 generate
        -- get the chunks first
        chunks_l(0) <= unsigned(A(15 downto 0));
        chunks_l(1) <= unsigned(B(15 downto 0));
        At          <= ((16 - A(A'length-1 downto 16)'length)-1 downto 0 => '0') & A(A'length-1 downto 16);
        Bt          <= ((16 - B(B'length-1 downto 16)'length)-1 downto 0 => '0') & B(B'length-1 downto 16);
        chunks_h(0) <= unsigned(At);
        chunks_h(1) <= unsigned(Bt);
        -- multipliers
        -- check the diagram on the Koren book pg. 149, since this is modular
        -- the high part of the product does not have to be computed
        -- we spare a DSP block
        pres(0)     <= (32-1 downto 0                                    => '0') & std_logic_vector(chunks_l(0) * chunks_l(1));  -- position 0
        pres(1)     <= (16-1 downto 0                                    => '0') & std_logic_vector(chunks_l(0) * chunks_h(1)) & (16-1 downto 0 => '0');  -- position 32
        pres(2)     <= (16-1 downto 0                                    => '0') & std_logic_vector(chunks_l(1) * chunks_h(0)) & (16-1 downto 0 => '0');  -- position 32
        -- csa tree, only one CSA is needed
        -- this can be simplified even further to reduce the cost
        csa_1 : entity work.csa
          generic map (
            width => width)
          port map (
            A  => pres_reg(0)(width-1 downto 0),
            B  => pres_reg(1)(width-1 downto 0),
            CI => pres_reg(2)(width-1 downto 0),
            S  => S,
            CO => C);
      end generate;

      three_chunk : if nrchunks = 3 generate
        -- not implemented yet
      end generate;

    end generate fpga_target;
  -- asic_target : if target /= fgpa generate
  -- TODO: implement the asic architecture
  -- end generate asic_target;
  end block combinational;

  -- register the output of the DSP blocks
  process(clk, rst)
  begin
    if rst = '1' then
      pres_reg  <= (others => (others => '0'));
      prodt_reg <= (others => '0');
    elsif rising_edge(clk) then
      pres_reg  <= pres;
      prodt_reg <= prodt;
    end if;
  end process;

  -- register the output of the multiplier/result
  process(clk, rst)
  begin
    if rst = '1' then
      Prod <= (others => '0');
    elsif rising_edge(clk) then
      Prod <= std_logic_vector(unsigned(S) + unsigned(C)) when (nrchunks > 1)
            else std_logic_vector(prodt_reg(Prod'range));
    end if;
  end process;

end structural;
-------------------------------------------------------------------------------
