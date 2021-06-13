
-------------------------------------------------------------------------------
-- Title      : Address Generator for addressing in the NTT
-- Project    : Number Theoretical Transform
-------------------------------------------------------------------------------
-- File       : AddresGenerator.vhd
-- Author     : Rogério Paludo  <rogerio.paludo@inesc-id.pt>
-- Company    : INESC-ID: Instituto de Engenharia de Sistemas e Computadores,
--              Investigação e Desenvolvimento
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
-- 2021-02-08  1.0      paludo  Created
-------------------------------------------------------------------------------
library ieee;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ntt_utils.all;
use work.ntt_lib.all;
use ieee.math_real.all;
-------------------------------------------------------------------------------
entity AddressGenerator is
  generic (local_levels    : integer := 3;
           local_PE        : integer := 1;
           local_NTTN      : integer := 8;
           local_nttword   : natural := 3;
           local_addr_bits : natural := addr_bits;
           local_mem_bits  : natural := clogb2(2 * local_PE)
           );
  port (clk, en, rst : in  std_logic;
        lvl          : in  unsigned(clogb2(local_levels)-1 downto 0);
        last_lvl_cnt : out unsigned(clogb2(8*local_PE) downto 0);
        mem_idx      : out array_of_slv_t(0 to 4*local_PE-1)(local_mem_bits-1 downto 0);
        addr_idx     : out array_of_slv_t(0 to 4*local_PE-1)(local_addr_bits-1 downto 0));
end AddressGenerator;
-------------------------------------------------------------------------------
architecture arch_mult_pe of AddressGenerator is

  constant mem_bits : integer := local_mem_bits;

  -- constant addr_bits : integer  := clogb2((local_NTTN/2)/local_PE);
  constant otp_bits : integer  := mem_bits * 4 * local_pe + local_addr_bits * 4 * local_pe;
  constant cnt_bits : integer  := clogb2((local_NTTN/4)/local_PE);
  constant lvl_bits : positive := clogb2(local_levels);
  constant inp_bits : integer  := lvl_bits + cnt_bits;

  signal inp        : std_logic_vector(inp_bits-1 downto 0)     := (others => '0');
  signal otp        : std_logic_vector(otp_bits-1 downto 0)     := (others => '0');
  signal cnt_sig    : unsigned(cnt_bits-1 downto 0);
  signal max_lvl    : unsigned(clogb2(local_levels)-1 downto 0) := (others => '1');
  signal max_lvl_p1 : unsigned(clogb2(local_levels)-1 downto 0) := (others => '1');

component AddressGenerator_32_pe1 is
    port (
      inp5  : in  std_ulogic;
      inp4  : in  std_ulogic;
      inp3  : in  std_ulogic;
      inp2  : in  std_ulogic;
      inp1  : in  std_ulogic;
      inp0  : in  std_ulogic;
      otp15 : out std_ulogic;
      otp14 : out std_ulogic;
      otp13 : out std_ulogic;
      otp12 : out std_ulogic;
      otp11 : out std_ulogic;
      otp10 : out std_ulogic;
      otp9  : out std_ulogic;
      otp8  : out std_ulogic;
      otp7  : out std_ulogic;
      otp6  : out std_ulogic;
      otp5  : out std_ulogic;
      otp4  : out std_ulogic;
      otp3  : out std_ulogic;
      otp2  : out std_ulogic;
      otp1  : out std_ulogic;
      otp0  : out std_ulogic);
  end component;

  component AddressGenerator_512_pe1 is
    port (
      inp10 : in  std_ulogic;
      inp9  : in  std_ulogic;
      inp8  : in  std_ulogic;
      inp7  : in  std_ulogic;
      inp6  : in  std_ulogic;
      inp5  : in  std_ulogic;
      inp4  : in  std_ulogic;
      inp3  : in  std_ulogic;
      inp2  : in  std_ulogic;
      inp1  : in  std_ulogic;
      inp0  : in  std_ulogic;
      otp31 : out std_ulogic;
      otp30 : out std_ulogic;
      otp29 : out std_ulogic;
      otp28 : out std_ulogic;
      otp27 : out std_ulogic;
      otp26 : out std_ulogic;
      otp25 : out std_ulogic;
      otp24 : out std_ulogic;
      otp23 : out std_ulogic;
      otp22 : out std_ulogic;
      otp21 : out std_ulogic;
      otp20 : out std_ulogic;
      otp19 : out std_ulogic;
      otp18 : out std_ulogic;
      otp17 : out std_ulogic;
      otp16 : out std_ulogic;
      otp15 : out std_ulogic;
      otp14 : out std_ulogic;
      otp13 : out std_ulogic;
      otp12 : out std_ulogic;
      otp11 : out std_ulogic;
      otp10 : out std_ulogic;
      otp9  : out std_ulogic;
      otp8  : out std_ulogic;
      otp7  : out std_ulogic;
      otp6  : out std_ulogic;
      otp5  : out std_ulogic;
      otp4  : out std_ulogic;
      otp3  : out std_ulogic;
      otp2  : out std_ulogic;
      otp1  : out std_ulogic;
      otp0  : out std_ulogic);
  end component;

 component AddressGenerator_1024_pe1 is
    port (
      inp11 : in  std_ulogic;
      inp10 : in  std_ulogic;
      inp9  : in  std_ulogic;
      inp8  : in  std_ulogic;
      inp7  : in  std_ulogic;
      inp6  : in  std_ulogic;
      inp5  : in  std_ulogic;
      inp4  : in  std_ulogic;
      inp3  : in  std_ulogic;
      inp2  : in  std_ulogic;
      inp1  : in  std_ulogic;
      inp0  : in  std_ulogic;
      otp35 : out std_ulogic;
      otp34 : out std_ulogic;
      otp33 : out std_ulogic;
      otp32 : out std_ulogic;
      otp31 : out std_ulogic;
      otp30 : out std_ulogic;
      otp29 : out std_ulogic;
      otp28 : out std_ulogic;
      otp27 : out std_ulogic;
      otp26 : out std_ulogic;
      otp25 : out std_ulogic;
      otp24 : out std_ulogic;
      otp23 : out std_ulogic;
      otp22 : out std_ulogic;
      otp21 : out std_ulogic;
      otp20 : out std_ulogic;
      otp19 : out std_ulogic;
      otp18 : out std_ulogic;
      otp17 : out std_ulogic;
      otp16 : out std_ulogic;
      otp15 : out std_ulogic;
      otp14 : out std_ulogic;
      otp13 : out std_ulogic;
      otp12 : out std_ulogic;
      otp11 : out std_ulogic;
      otp10 : out std_ulogic;
      otp9  : out std_ulogic;
      otp8  : out std_ulogic;
      otp7  : out std_ulogic;
      otp6  : out std_ulogic;
      otp5  : out std_ulogic;
      otp4  : out std_ulogic;
      otp3  : out std_ulogic;
      otp2  : out std_ulogic;
      otp1  : out std_ulogic;
      otp0  : out std_ulogic);
  end component;


component AddressGenerator_2048_pe1 is
    port (
      inp12 : in  std_ulogic;
      inp11 : in  std_ulogic;
      inp10 : in  std_ulogic;
      inp9  : in  std_ulogic;
      inp8  : in  std_ulogic;
      inp7  : in  std_ulogic;
      inp6  : in  std_ulogic;
      inp5  : in  std_ulogic;
      inp4  : in  std_ulogic;
      inp3  : in  std_ulogic;
      inp2  : in  std_ulogic;
      inp1  : in  std_ulogic;
      inp0  : in  std_ulogic;
      otp39 : out std_ulogic;
      otp38 : out std_ulogic;
      otp37 : out std_ulogic;
      otp36 : out std_ulogic;
      otp35 : out std_ulogic;
      otp34 : out std_ulogic;
      otp33 : out std_ulogic;
      otp32 : out std_ulogic;
      otp31 : out std_ulogic;
      otp30 : out std_ulogic;
      otp29 : out std_ulogic;
      otp28 : out std_ulogic;
      otp27 : out std_ulogic;
      otp26 : out std_ulogic;
      otp25 : out std_ulogic;
      otp24 : out std_ulogic;
      otp23 : out std_ulogic;
      otp22 : out std_ulogic;
      otp21 : out std_ulogic;
      otp20 : out std_ulogic;
      otp19 : out std_ulogic;
      otp18 : out std_ulogic;
      otp17 : out std_ulogic;
      otp16 : out std_ulogic;
      otp15 : out std_ulogic;
      otp14 : out std_ulogic;
      otp13 : out std_ulogic;
      otp12 : out std_ulogic;
      otp11 : out std_ulogic;
      otp10 : out std_ulogic;
      otp9  : out std_ulogic;
      otp8  : out std_ulogic;
      otp7  : out std_ulogic;
      otp6  : out std_ulogic;
      otp5  : out std_ulogic;
      otp4  : out std_ulogic;
      otp3  : out std_ulogic;
      otp2  : out std_ulogic;
      otp1  : out std_ulogic;
      otp0  : out std_ulogic);
  end component;


component AddressGenerator_4096_pe1 is
    port (
      inp13 : in  std_ulogic;
      inp12 : in  std_ulogic;
      inp11 : in  std_ulogic;
      inp10 : in  std_ulogic;
      inp9  : in  std_ulogic;
      inp8  : in  std_ulogic;
      inp7  : in  std_ulogic;
      inp6  : in  std_ulogic;
      inp5  : in  std_ulogic;
      inp4  : in  std_ulogic;
      inp3  : in  std_ulogic;
      inp2  : in  std_ulogic;
      inp1  : in  std_ulogic;
      inp0  : in  std_ulogic;
      otp43 : out std_ulogic;
      otp42 : out std_ulogic;
      otp41 : out std_ulogic;
      otp40 : out std_ulogic;
      otp39 : out std_ulogic;
      otp38 : out std_ulogic;
      otp37 : out std_ulogic;
      otp36 : out std_ulogic;
      otp35 : out std_ulogic;
      otp34 : out std_ulogic;
      otp33 : out std_ulogic;
      otp32 : out std_ulogic;
      otp31 : out std_ulogic;
      otp30 : out std_ulogic;
      otp29 : out std_ulogic;
      otp28 : out std_ulogic;
      otp27 : out std_ulogic;
      otp26 : out std_ulogic;
      otp25 : out std_ulogic;
      otp24 : out std_ulogic;
      otp23 : out std_ulogic;
      otp22 : out std_ulogic;
      otp21 : out std_ulogic;
      otp20 : out std_ulogic;
      otp19 : out std_ulogic;
      otp18 : out std_ulogic;
      otp17 : out std_ulogic;
      otp16 : out std_ulogic;
      otp15 : out std_ulogic;
      otp14 : out std_ulogic;
      otp13 : out std_ulogic;
      otp12 : out std_ulogic;
      otp11 : out std_ulogic;
      otp10 : out std_ulogic;
      otp9  : out std_ulogic;
      otp8  : out std_ulogic;
      otp7  : out std_ulogic;
      otp6  : out std_ulogic;
      otp5  : out std_ulogic;
      otp4  : out std_ulogic;
      otp3  : out std_ulogic;
      otp2  : out std_ulogic;
      otp1  : out std_ulogic;
      otp0  : out std_ulogic);
  end component;

begin

  max_lvl    <= to_unsigned(local_levels-1, max_lvl'length);
  max_lvl_p1 <= to_unsigned(local_levels, max_lvl'length);

  addresses : process(clk)
    variable cnt                    : unsigned(cnt_bits-1 downto 0);
    variable cnt_final_stage        : unsigned(clogb2(2*local_PE) downto 0);
    variable cnt_final_stage_offset : unsigned(clogb2(8*local_PE) downto 0);
    variable temp                   : unsigned(cnt'length+cnt_final_stage_offset'length-1 downto 0);
  begin  -- process addresses
    if rising_edge(clk) then
      if rst = '1' then
        cnt                    := (others => '0');
        cnt_final_stage        := (others => '0');
        cnt_final_stage_offset := (others => '0');
        cnt_sig                <= (others => '0');
        last_lvl_cnt           <= (others => '0');
      else

        if en = '1' then

          if lvl < max_lvl_p1 then
            -- regular modular counter to output the addresses
            if cnt < local_NTTN/(4 * local_PE) then
              cnt := cnt + 1;
            else
              cnt := (others => '0');
            end if;
            last_lvl_cnt <= (others => '0');
            cnt_sig      <= cnt;
          else
            -- final stage, frequency divider proportial to the number
            -- of processing elements to output serially the data
            if cnt_final_stage > local_PE-1 then
              if cnt < local_NTTN/(8 * local_PE)-1 then
                cnt := cnt + 1;
              else
                cnt                    := to_unsigned(0, cnt'length);
                cnt_final_stage_offset := cnt_final_stage_offset + 1;
              end if;
              cnt_final_stage := (others => '0');
            else
              cnt_final_stage := cnt_final_stage + 1;
            end if;
            last_lvl_cnt <= cnt_final_stage_offset;
            cnt_sig      <= cnt;
          end if;
        end if;
      end if;
    end if;
  end process addresses;

  inp <= std_logic_vector(lvl) & std_logic_vector(cnt_sig);
  -- inp(1) <= std_logic_vector(lvl) & std_logic_vector(cnt_sig);

  -----------------------------------------------------------------------------
  -- note the processing elements in these are twice as the specified number
  -- because of even/odd elements
  -----------------------------------------------------------------------------

 ag_32_1 : if NTTN = 32 and pe = 1 generate

    AG_32_pe1_1 : AddressGenerator_32_pe1
      port map (
        inp5  => inp(5),
        inp4  => inp(4),
        inp3  => inp(3),
        inp2  => inp(2),
        inp1  => inp(1),
        inp0  => inp(0),
        otp15 => otp(15),
        otp14 => otp(14),
        otp13 => otp(13),
        otp12 => otp(12),
        otp11 => otp(11),
        otp10 => otp(10),
        otp9  => otp(9),
        otp8  => otp(8),
        otp7  => otp(7),
        otp6  => otp(6),
        otp5  => otp(5),
        otp4  => otp(4),
        otp3  => otp(3),
        otp2  => otp(2),
        otp1  => otp(1),
        otp0  => otp(0));

  end generate;

  ag_512_1 : if NTTN = 512 and pe = 1 generate

    AG_512_pe1_1 : AddressGenerator_512_pe1
      port map (
        inp10 => inp(10),
        inp9  => inp(9),
        inp8  => inp(8),
        inp7  => inp(7),
        inp6  => inp(6),
        inp5  => inp(5),
        inp4  => inp(4),
        inp3  => inp(3),
        inp2  => inp(2),
        inp1  => inp(1),
        inp0  => inp(0),
        otp31 => otp(31),
        otp30 => otp(30),
        otp29 => otp(29),
        otp28 => otp(28),
        otp27 => otp(27),
        otp26 => otp(26),
        otp25 => otp(25),
        otp24 => otp(24),
        otp23 => otp(23),
        otp22 => otp(22),
        otp21 => otp(21),
        otp20 => otp(20),
        otp19 => otp(19),
        otp18 => otp(18),
        otp17 => otp(17),
        otp16 => otp(16),
        otp15 => otp(15),
        otp14 => otp(14),
        otp13 => otp(13),
        otp12 => otp(12),
        otp11 => otp(11),
        otp10 => otp(10),
        otp9  => otp(9),
        otp8  => otp(8),
        otp7  => otp(7),
        otp6  => otp(6),
        otp5  => otp(5),
        otp4  => otp(4),
        otp3  => otp(3),
        otp2  => otp(2),
        otp1  => otp(1),
        otp0  => otp(0));

  end generate;

  ag_1024_1 : if NTTN = 1024 and pe = 1 generate

    AG_1024_pe1_1 : AddressGenerator_1024_pe1
      port map (
        inp11 => inp(11),
        inp10 => inp(10),
        inp9  => inp(9),
        inp8  => inp(8),
        inp7  => inp(7),
        inp6  => inp(6),
        inp5  => inp(5),
        inp4  => inp(4),
        inp3  => inp(3),
        inp2  => inp(2),
        inp1  => inp(1),
        inp0  => inp(0),
        otp35 => otp(35),
        otp34 => otp(34),
        otp33 => otp(33),
        otp32 => otp(32),
        otp31 => otp(31),
        otp30 => otp(30),
        otp29 => otp(29),
        otp28 => otp(28),
        otp27 => otp(27),
        otp26 => otp(26),
        otp25 => otp(25),
        otp24 => otp(24),
        otp23 => otp(23),
        otp22 => otp(22),
        otp21 => otp(21),
        otp20 => otp(20),
        otp19 => otp(19),
        otp18 => otp(18),
        otp17 => otp(17),
        otp16 => otp(16),
        otp15 => otp(15),
        otp14 => otp(14),
        otp13 => otp(13),
        otp12 => otp(12),
        otp11 => otp(11),
        otp10 => otp(10),
        otp9  => otp(9),
        otp8  => otp(8),
        otp7  => otp(7),
        otp6  => otp(6),
        otp5  => otp(5),
        otp4  => otp(4),
        otp3  => otp(3),
        otp2  => otp(2),
        otp1  => otp(1),
        otp0  => otp(0));

  end generate;


 ag_2048_1 : if NTTN = 2048 and pe = 1 generate

    AG_2048_pe1_1 : AddressGenerator_2048_pe1
      port map (
        inp12 => inp(12),
        inp11 => inp(11),
        inp10 => inp(10),
        inp9  => inp(9),
        inp8  => inp(8),
        inp7  => inp(7),
        inp6  => inp(6),
        inp5  => inp(5),
        inp4  => inp(4),
        inp3  => inp(3),
        inp2  => inp(2),
        inp1  => inp(1),
        inp0  => inp(0),
        otp39 => otp(39),
        otp38 => otp(38),
        otp37 => otp(37),
        otp36 => otp(36),
        otp35 => otp(35),
        otp34 => otp(34),
        otp33 => otp(33),
        otp32 => otp(32),
        otp31 => otp(31),
        otp30 => otp(30),
        otp29 => otp(29),
        otp28 => otp(28),
        otp27 => otp(27),
        otp26 => otp(26),
        otp25 => otp(25),
        otp24 => otp(24),
        otp23 => otp(23),
        otp22 => otp(22),
        otp21 => otp(21),
        otp20 => otp(20),
        otp19 => otp(19),
        otp18 => otp(18),
        otp17 => otp(17),
        otp16 => otp(16),
        otp15 => otp(15),
        otp14 => otp(14),
        otp13 => otp(13),
        otp12 => otp(12),
        otp11 => otp(11),
        otp10 => otp(10),
        otp9  => otp(9),
        otp8  => otp(8),
        otp7  => otp(7),
        otp6  => otp(6),
        otp5  => otp(5),
        otp4  => otp(4),
        otp3  => otp(3),
        otp2  => otp(2),
        otp1  => otp(1),
        otp0  => otp(0));

  end generate;

 ag_4096_1 : if NTTN = 4096 and pe = 1 generate

    AG_4096_pe1_1 : AddressGenerator_4096_pe1
      port map (
        inp13 => inp(13),
        inp12 => inp(12),
        inp11 => inp(11),
        inp10 => inp(10),
        inp9  => inp(9),
        inp8  => inp(8),
        inp7  => inp(7),
        inp6  => inp(6),
        inp5  => inp(5),
        inp4  => inp(4),
        inp3  => inp(3),
        inp2  => inp(2),
        inp1  => inp(1),
        inp0  => inp(0),
        otp43 => otp(43),
        otp42 => otp(42),
        otp41 => otp(41),
        otp40 => otp(40),
        otp39 => otp(39),
        otp38 => otp(38),
        otp37 => otp(37),
        otp36 => otp(36),
        otp35 => otp(35),
        otp34 => otp(34),
        otp33 => otp(33),
        otp32 => otp(32),
        otp31 => otp(31),
        otp30 => otp(30),
        otp29 => otp(29),
        otp28 => otp(28),
        otp27 => otp(27),
        otp26 => otp(26),
        otp25 => otp(25),
        otp24 => otp(24),
        otp23 => otp(23),
        otp22 => otp(22),
        otp21 => otp(21),
        otp20 => otp(20),
        otp19 => otp(19),
        otp18 => otp(18),
        otp17 => otp(17),
        otp16 => otp(16),
        otp15 => otp(15),
        otp14 => otp(14),
        otp13 => otp(13),
        otp12 => otp(12),
        otp11 => otp(11),
        otp10 => otp(10),
        otp9  => otp(9),
        otp8  => otp(8),
        otp7  => otp(7),
        otp6  => otp(6),
        otp5  => otp(5),
        otp4  => otp(4),
        otp3  => otp(3),
        otp2  => otp(2),
        otp1  => otp(1),
        otp0  => otp(0));

  end generate;

  addr_generate : for i in 0 to 4*local_PE-1 generate
    addr_idx(i) <= otp((i + 1) * addr_idx(i)'length-1 downto i * addr_idx(i)'length);
  end generate;

  mem_addr_generate : for i in 4*local_PE-1 downto 0 generate
    mem_idx(i) <= otp(mem_bits*(i+1)-1 + 4*local_PE*local_addr_bits downto mem_bits * i + 4*local_PE*local_addr_bits);
  end generate;

end architecture arch_mult_pe;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
