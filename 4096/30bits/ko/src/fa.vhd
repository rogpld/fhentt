-------------------------------------------------------------------------------
-- Title       : Full-adder
-- Project     : VHDL Library of Arithmetic Units
-------------------------------------------------------------------------------
-- File        : FullAdder.vhd
-- Author      : Reto Zimmermann  <zimmi@iis.ee.ethz.ch>
-- Company     : Integrated Systems Laboratory, ETH Zurich
-- Date        : 1997/11/04
-------------------------------------------------------------------------------
-- Copyright (c) 1998 Integrated Systems Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Description :
-- Should force the compiler to use a full-adder cell instead of simple logic
-- gates. Otherwise, a full-adder cell of the target library has to be
-- instantiated at this point (see second architecture).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity FullAdder is
  port (A, B, CI : in  std_logic;                         -- operands
        S, CO    : out std_logic);                        -- sum and carry out
end FullAdder;
-------------------------------------------------------------------------------
architecture behavior of FullAdder is
  signal Auns, Buns, CIuns, Suns : unsigned(1 downto 0);  -- unsigned temp
begin
  -- type conversion: std_logic -> 2-bit unsigned
  Auns  <= '0' & A;
  Buns  <= '0' & B;
  CIuns <= '0' & CI;
  -- should force the compiler to use a full-adder cell
  Suns  <= Auns + Buns + CIuns;
  -- type conversion: 2-bit unsigned -> std_logic
  S     <= Suns(0);
  CO    <= Suns(1);
end behavior;
