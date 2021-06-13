-------------------------------------------------------------------------------
-- Title       : Full-adder
-- Project     : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File        : fa.vhd
-- Author      : Rogério Paludo  <rogerio.paludo@inesc-id.pt>
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
entity FullAdder is
  port (A, B, CI : in  std_logic;                         -- operands
        S, CO    : out std_logic);                        -- sum and carry out
end FullAdder;
-------------------------------------------------------------------------------
architecture behavior of FullAdder is
  signal Auns, Buns, CIuns, Suns : unsigned(1 downto 0);  -- unsigned temp
begin

  Auns  <= '0' & A;
  Buns  <= '0' & B;
  CIuns <= '0' & CI;

  Suns  <= Auns + Buns + CIuns;

  S     <= Suns(0);
  CO    <= Suns(1);
end behavior;
