library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ntt_utils.all;
use work.ntt_lib.all;

entity bram is
  generic (dwidth : integer := 8;
           depth  : integer := 128);
  port (data    : in  std_logic_vector(dwidth-1 downto 0);
        waddr   : in  std_logic_vector(clogb2(depth)-1 downto 0);
        raddr   : in  std_logic_vector(clogb2(depth)-1 downto 0);
        we, clk : in  std_logic;
        q       : out std_logic_vector(dwidth-1 downto 0));
  attribute RAM_STYLE         : string;
  attribute RAM_STYLE of bram : entity is "block";
end entity;

architecture behavior of bram is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector(dwidth-1 downto 0);
  type memory_t is array(0 to depth-1) of word_t;
  -- Declare the RAM signal.
  signal ram : memory_t := (others => (others => '0'));

begin
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we = '1') then
        ram(to_integer(unsigned(waddr))) <= data;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if(rising_edge(clk)) then
    q <= ram(to_integer(unsigned(raddr)));
    end if;
  end process;

end behavior;

-------------------------------------------------------------------------------
-- this is not supported because it needs separate ports for read and write
-------------------------------------------------------------------------------
--
-- Dual-Port Block RAM with Two Write Ports
-- Correct Modelization with a Shared Variable
--
-- Download: ftp://ftp.xilinx.com/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/rams_16b.vhd
--
-------------------------------------------------------------------------------
-- library IEEE;
-- use IEEE.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use work.ntt_utils.all;
-- use work.ntt_lib.all;

-- entity bram is
--   generic (
--     width : integer := 8;               -- data width
--     depth : integer := 128);            -- how many data words
--   port(clk    : in  std_logic;
--        wea    : in  std_logic;
--        web    : in  std_logic;
--        addra  : in  std_logic_vector(clogb2(depth)-1 downto 0);
--        addrb  : in  std_logic_vector(clogb2(depth)-1 downto 0);
--        raddra : in  std_logic_vector(clogb2(depth)-1 downto 0);
--        raddrb : in  std_logic_vector(clogb2(depth)-1 downto 0);
--        dia    : in  std_logic_vector(width-1 downto 0);
--        dib    : in  std_logic_vector(width-1 downto 0);
--        doa    : out std_logic_vector(width-1 downto 0);
--        dob    : out std_logic_vector(width-1 downto 0));
-- end bram;
-- -------------------------------------------------------------------------------
-- architecture syn of bram is
--   type ram_type is array (depth-1 downto 0) of std_logic_vector(width-1 downto 0);
--   shared variable RAM : ram_type;
-- begin
--   process (clk)
--   begin
--     if rising_edge(clk) then
--       DOA <= RAM(to_integer(unsigned(rADDRA)));
--       if WEA = '1' then
--         RAM(to_integer(unsigned(ADDRA))) := DIA;
--       end if;
--     end if;
--   end process;
--   process (clk)
--   begin
--     if rising_edge(clk) then
--       DOB <= RAM(to_integer(unsigned(rADDRB)));
--       if WEB = '1' then
--         RAM(to_integer(unsigned(ADDRB))) := DIB;
--       end if;
--     end if;
--   end process;
-- end syn;
