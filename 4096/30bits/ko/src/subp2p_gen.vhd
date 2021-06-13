-------------------------------------------------------------------------------
-- Title      : Computes X' = X - Y + 2 * p
-- Project    :
-------------------------------------------------------------------------------
-- File       : subp2p_gen.vhd
-- Author     : Rogério Paludo  <paludo@Workspace>
-- Company    :
-- Created    : 2021-01-20
-- Last update: 2021-01-20
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Impl
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
entity subp2p_gen is
  generic (width  : positive   := 10;   -- word width
           target : targetType := fpga);
  port (A, B : in  std_logic_vector(width-1 downto 0);   -- operands
        p    : in  std_logic_vector(width-1 downto 0);
        Sub  : out std_logic_vector(width-1 downto 0));  -- add
end subp2p_gen;
-------------------------------------------------------------------------------
architecture structural of subp2p_gen is
  signal Asig, Bsig : signed(width downto 0);            -- signed
  signal m          : signed(width downto 0);
  signal Subsig     : signed(width downto 0);
begin
  -- default ripple-carry suber as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> signed
    Asig   <= signed('0' & A);
    Bsig   <= signed('0' & B);
    m      <= signed(p & '0');
    Subsig <= Asig - Bsig + m;
    Sub    <= std_logic_vector(Subsig(Sub'range));
  end generate fpga_target;

-- asic_target : if target /= fgpa generate
-- TODO: implement the asic architecture
-- end generate asic_target;
end structural;
-------------------------------------------------------------------------------
