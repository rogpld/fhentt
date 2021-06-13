-------------------------------------------------------------------------------
-- Title      : Computes X' = X - Y + 2 * p
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : subp2p.vhd
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
-------------------------------------------------------------------------------
entity subp2p is
  generic (width   : positive   := 10;  -- word width
           target  : targetType := fpga;
           modulus : integer    := 241);  -- modulus to be added to X - Y
  port (A, B : in  std_logic_vector(width-1 downto 0);   -- operands
        Sub  : out std_logic_vector(width-1 downto 0));  -- sub
end subp2p;
-------------------------------------------------------------------------------
architecture structural of subp2p is
  signal Asig, Bsig : signed(width downto 0);            -- signed
  signal m          : signed(width downto 0);
  signal Subsig     : signed(width downto 0);
begin
  -- default ripple-carry suber as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> signed
    Asig <= signed('0' & A);
    Bsig <= signed('0' & B);
    m    <= to_signed(2 * modulus, m'length);
    Subsig <= Asig - Bsig + m;
    Sub  <= std_logic_vector(Subsig(Sub'range));
  end generate fpga_target;

-- asic_target : if target /= fgpa generate
-- TODO: implement the asic architecture
-- end generate asic_target;
end structural;
-------------------------------------------------------------------------------
