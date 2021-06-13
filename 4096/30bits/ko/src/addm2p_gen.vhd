-------------------------------------------------------------------------------
-- Title      : Computes X' = X - Y + 2 * p for generic p
-- Project    :
-------------------------------------------------------------------------------
-- File       : addm2p.vhd
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
entity addm2p_gen is
  generic (width  : positive   := 10;                    -- word width
           target : targetType := fpga);                 -- the two complement
                                                         -- of the modulus mod
                                                         -- 2**width
  port (A, B : in  std_logic_vector(width-1 downto 0);   -- operands
        p    : in  std_logic_vector(width-1 downto 0);
        Add  : out std_logic_vector(width-1 downto 0));  -- add
end addm2p_gen;
-------------------------------------------------------------------------------
architecture behavior of addm2p_gen is
  signal Auns, Buns         : unsigned(width downto 0);  -- unsigned
  signal Adduns, Adduns_red : unsigned(width downto 0);  -- unsigned
  signal m, m2c             : unsigned(width downto 0);
begin
  -- default ripple-carry adder as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> unsigned
    Auns       <= unsigned('0' & A);
    Buns       <= unsigned('0' & B);
    m          <= unsigned(p & '0');
    m2c        <= '0' & (not(m(width-1 downto 0)) + 1);
    Adduns     <= (Auns + Buns);
    -- this corresponds to adding the two complement value of (-2p % 2**width)
    Adduns_red <= Auns + Buns + m2c;
    -- type conversion: unsigned -> std_logic_vector
    Add        <= std_logic_vector(Adduns_red(Add'range)) when Adduns_red(width) else std_logic_vector(Adduns(Add'range));
  end generate fpga_target;

  -- asic_target : if target /= fgpa generate
  -- TODO: implement the asic architecture
  -- end generate asic_target;
end behavior;
-------------------------------------------------------------------------------
