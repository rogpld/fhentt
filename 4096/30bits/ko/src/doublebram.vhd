-------------------------------------------------------------------------------
-- Title      : Double port BRAM
-- Project    :
-------------------------------------------------------------------------------
-- File       : doublebram.vhd
-- Author     : Rogério Paludo  <paludo@Workspace>
-- Company    :
-- Created    : 2021-02-05
-- Last update: 2021-02-23
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This is true double port, with separate read and write
-- addresses. Note this uses two BRAMS because it needs two separate read
-- addresses.
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-02-05  1.0      paludo  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ntt_utils.all;
use work.ntt_lib.all;

entity doublebram is
  generic (dwidth : integer := 8;
           depth  : integer := 128);
  port (clk    : in  std_logic;
        -- port A
        dataa  : in  std_logic_vector(dwidth-1 downto 0);
        waddra : in  std_logic_vector(clogb2(depth)-1 downto 0);
        raddra : in  std_logic_vector(clogb2(depth)-1 downto 0);
        wea    : in  std_logic;
        -- port B
        datab  : in  std_logic_vector(dwidth-1 downto 0);
        waddrb : in  std_logic_vector(clogb2(depth)-1 downto 0);
        raddrb : in  std_logic_vector(clogb2(depth)-1 downto 0);
        web    : in  std_logic;
        -- outputs
        douta  : out std_logic_vector(dwidth-1 downto 0);
        doutb  : out std_logic_vector(dwidth-1 downto 0));
  attribute RAM_STYLE               : string;
  attribute RAM_STYLE of doublebram : entity is "block";
end entity;

architecture behavior of doublebram is
  -- -- Build a 2-D array type for the RAM
  -- subtype word_t is std_logic_vector(dwidth-1 downto 0);
  -- type memory_t is array(depth-1 downto 0) of word_t;
  -- -- Declare the RAM signal.
  -- shared variable ram : memory_t := (others => (others => '0'));

begin
  -- process(clk)
  -- begin
  --   if(rising_edge(clk)) then
  --     if(wea = '1') then
  --       ram(to_integer(unsigned(waddra))) := dataa;
  --     end if;
  --   end if;
  -- end process;

  -- process(clk)
  -- begin
  --   if(rising_edge(clk)) then
  --     if(web = '1') then
  --       ram(to_integer(unsigned(waddrb))) := datab;
  --     end if;
  --   end if;
  -- end process;

  -- process(clk)
  -- begin
  --   if(rising_edge(clk)) then
  --   douta <= ram(to_integer(unsigned(raddra)));
  --   end if;
  -- end process;

  -- process(clk)
  -- begin
  --   if(rising_edge(clk)) then
  --   doutb <= ram(to_integer(unsigned(raddrb)));
  --   end if;
  -- end process;

  bram_a : entity work.bram
    generic map (
      dwidth => dwidth,
      depth  => depth)
    port map (
      data  => dataa,
      waddr => waddra,
      raddr => raddra,
      we    => wea,
      clk   => clk,
      q     => douta);

  bram_b : entity work.bram
    generic map (
      dwidth => dwidth,
      depth  => depth)
    port map (
      data  => datab,
      waddr => waddrb,
      raddr => raddrb,
      we    => web,
      clk   => clk,
      q     => doutb);

end behavior;
