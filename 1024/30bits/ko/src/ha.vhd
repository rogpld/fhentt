-------------------------------------------------------------------------------
-- Title       : Half-Adder
-- Project     : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File        : ha.vhd
-- Author      : Rogério Paludo <rogerio.paludo@inesc-id.pt>
-- Company     :
-- Date        : 2021
-------------------------------------------------------------------------------
-- Copyright (c) 2021 Rogério Paludo and Leonel Sousa
-- <firstname.lastname@inesc-id.pt>
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
  Auns <= '0' & A;
  Buns <= '0' & B;
  Suns <= Auns + Buns;
  S    <= Suns(0);
  CO   <= Suns(1);
end behavior;
