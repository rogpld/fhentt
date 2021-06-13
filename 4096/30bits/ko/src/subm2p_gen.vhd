-------------------------------------------------------------------------------
-- Title      : Computes X' = X - p if X > p
-- Project    :
-------------------------------------------------------------------------------
-- File       : subm2p.vhd
-- Author     : Rogério Paludo  <paludo@Workspace>
-- Company    :
-- Created    : 2021-01-20
-- Last update: 2021-01-22
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
-------------------------------------------------------------------------------
entity subm2p_gen is
  generic (width  : positive   := 10;                     -- word width
           target : targetType := fpga;
           p      : std_logic_vector(pword-1 downto 0));  -- the two complement
                                                          -- of the modulus mod
                                                          -- 2**width
  port (A   : in  std_logic_vector(width-1 downto 0);     -- operands
        Sub : out std_logic_vector(width-1 downto 0));    -- sub
end subm2p_gen;
-------------------------------------------------------------------------------
architecture behavior of subm2p_gen is
  signal Auns   : unsigned(width-1 downto 0);               -- unsigned
  signal Subuns : unsigned(width-1 downto 0);               -- unsigned
  signal m, m2c : unsigned(width-1 downto 0);
  constant pcnt : unsigned(width-1 downto 0) := ((0 to width-pword-1 => '0') & unsigned(p));
begin
  -- default ripple-carry suber as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> unsigned
    Auns   <= unsigned(A);
    Subuns <= Auns - pcnt;
    Sub    <= std_logic_vector(Subuns) when Auns > pcnt else A;
  end generate fpga_target;

  -- asic_target : if target /= fgpa generate
  -- TODO: implement the asic architecture
  -- end generate asic_target;
end behavior;
-------------------------------------------------------------------------------
