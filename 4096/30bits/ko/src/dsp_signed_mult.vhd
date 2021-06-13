-------------------------------------------------------------------------------
-- Title      : Computes signed multiplication with inputs and outputs
--              registered
-- Project    :
-------------------------------------------------------------------------------
-- File       : dsp_signed_mult.vhd
-- Author     : Rogério Paludo  <paludo@Workspace>
-- Company    :
-- Created    : 2021-01-20
-- Last update: 2021-02-07
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
entity dsp_signed_mult is
  generic (width : positive := 16);                  --
  port (A, B     : in  signed(width-1 downto 0);     -- operands
        clk, rst : in  std_logic;
        Prod     : out signed(2*width-1 downto 0));  -- add
  attribute USE_DSP                    : string;
  attribute USE_DSP of dsp_signed_mult : entity is "yes";
end dsp_signed_mult;
-------------------------------------------------------------------------------
architecture structural of dsp_signed_mult is
  signal A_reg, B_reg     : signed(width-1 downto 0);
  signal Prod_t, Prod_reg : signed(2*width-1 downto 0);
begin
  -- register inputs
  A_register: entity work.ff_signed
    generic map (
      width => width)
    port map (
      d   => A,
      q   => A_reg,
      clk => clk,
      rst => rst);

  B_register: entity work.ff_signed
    generic map (
      width => width)
    port map (
      d   => B,
      q   => B_reg,
      clk => clk,
      rst => rst);

  -- output assignment
  output_reg: entity work.ff_signed
    generic map (
      width => 2*width)
    port map (
      d   => Prod_t,
      q   => Prod_reg,
      clk => clk,
      rst => rst);

  Prod_t <= A_reg * B_reg;
  Prod   <= Prod_reg;

end architecture;

--------------------------------------------------------------------------------
-- using this causes many timing problems, I don't known why it is so slow
-- does not make much sense. Perhaps increasing the pipeline would help
-- or since this is a mcro the compiler does not merge well with the subsequent
-- arithmetic operations.
--------------------------------------------------------------------------------

-- -- MULT_MACRO    : In order to incorporate this function into the design,
-- --     VHDL      : the following instance declaration needs to be placed
-- --   instance    : in the architecture body of the design code.  The
-- --  declaration  : (MULT_MACRO_inst) and/or the port declarations
-- --     code      : after the "=>" assignment maybe changed to properly
-- --               : reference and connect this function to the design.
-- --               : All inputs and outputs must be connected.

-- --    Library    : In addition to adding the instance declaration, a use
-- --  declaration  : statement for the UNISIM.vcomponents library needs to be
-- --      for      : added before the entity declaration.  This library
-- --    Xilinx     : contains the component declarations for all Xilinx
-- --   primitives  : primitives and points to the models that will be used
-- --               : for simulation.

-- --  Copy the following four statements and paste them before the
-- --  Entity declaration, unless they already exist.


-- -- MULT_MACRO: Multiply Function implemented in a DSP48E
-- --             Virtex-7
-- -- Xilinx HDL Language Template, version 2018.1

-- library ieee;
-- use work.ntt_utils.all;
-- use work.ntt_lib.all;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use IEEE.math_real.all;

-- Library UNISIM;
-- use UNISIM.vcomponents.all;

-- Library UNIMACRO;
-- use UNIMACRO.vcomponents.all;
-- -------------------------------------------------------------------------------
-- entity dsp_signed_mult is
--   generic (width : positive := 16);     --
--   port (A, B     : in  signed(width-1 downto 0);     -- operands
--         clk, rst : in  std_logic;
--         Prod     : out signed(2*width-1 downto 0));  -- add
--   attribute USE_DSP                    : string;
--   attribute USE_DSP of dsp_signed_mult : entity is "yes";
-- end dsp_signed_mult;
-- -------------------------------------------------------------------------------
-- architecture structural of dsp_signed_mult is
--   signal A_slv, B_slv : std_logic_vector(width-1 downto 0);
--   signal Prod_slv     : std_logic_vector(2*width-1 downto 0);
-- begin
--   A_slv <= std_logic_vector(A);
--   B_slv <= std_logic_vector(B);
-- MULT_MACRO_inst : MULT_MACRO
--   generic map (
--     DEVICE  => "7SERIES",  -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
--     LATENCY => 2,                       -- Desired clock cycle latency, 0-4
--     WIDTH_A => width,                   -- Multiplier A-input bus width, 1-25
--     WIDTH_B => width)                   -- Multiplier B-input bus width, 1-18
--   port map (
--     P   => Prod_slv,  -- Multiplier ouput bus, width determined by WIDTH_P generic
--     A   => A_slv,  -- Multiplier input A bus, width determined by WIDTH_A generic
--     B   => B_slv,  -- Multiplier input B bus, width determined by WIDTH_B generic
--     CE  => '1',                         -- 1-bit active high input clock enable
--     CLK => clk,                         -- 1-bit positive edge clock input
--     RST => rst                          -- 1-bit input active high reset
--     );
--   Prod <= signed(Prod_slv);
-- end architecture;
--------------------------------------------------------------------------------
