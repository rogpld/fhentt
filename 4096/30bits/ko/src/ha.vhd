-------------------------------------------------------------------------------
-- Title       : Half-Adder
-- Project     : VHDL Library of Arithmetic Units
-------------------------------------------------------------------------------
-- File        : HalfAdder.vhd
-- Author      : Reto Zimmermann  <zimmi@iis.ee.ethz.ch>
-- Company     : Integrated Systems Laboratory, ETH Zurich
-- Date        : 1997/11/04
-------------------------------------------------------------------------------
-- Copyright (c) 1998 Integrated Systems Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Description :
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity HalfAdder is
  port (A, B  : in  std_logic;                            -- operands
        S, CO : out std_logic);                           -- sum and carry out
end HalfAdder;
-------------------------------------------------------------------------------
architecture behavior of HalfAdder is
  signal Auns, Buns, CIuns, Suns : unsigned(1 downto 0);  -- unsigned temp
begin
  -- type conversion: std_logic -> 2-bit unsigned
  Auns <= '0' & A;
  Buns <= '0' & B;
  -- should force the compiler to use a full-adder cell
  Suns <= Auns + Buns;
  -- type conversion: 2-bit unsigned -> std_logic
  S    <= Suns(0);
  CO   <= Suns(1);
end behavior;
