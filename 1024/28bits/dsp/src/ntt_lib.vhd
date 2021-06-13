library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use work.ntt_utils.all;

package ntt_lib is
  --------------------------------------------------------------------------------
  -- type of hardware to generate
  -- TODO: currently only FPGA is supported
  --------------------------------------------------------------------------------
  type targetType is (fpga, asic);
  --------------------------------------------------------------------------------
  -- Constants to configure the hardware
  --------------------------------------------------------------------------------
  constant PE              : natural                              := 1;  -- number of processing elements
  constant mword           : natural                              := 30;  -- Montgomery Work used in the hw
  constant pword           : natural                              := 28;  -- size of the prime
  constant NTTN            : natural                              := 1024;  -- size of the NTT
                                        -- (number of the elements
                                        -- in the ring)
  subtype nttword_t is natural range 0 to clogb2(NTTN);
  constant nttword         : nttword_t                            := clogb2(NTTN);
  constant levels          : nttword_t                            := nttword;
  constant AddressRomDepth : natural range 0 to levels * (NTTN/2) := levels * (NTTN/2);

  constant bram_depth    : integer := (NTTN/2)/(2 * PE);
  constant bram_ws_width : integer := pword;
  constant bram_ws_depth : integer := (((levels - 1) * NTTN/2 + 1) + 1) / 2*PE;
  constant bram_width    : integer := mword;

  constant addr_bits : integer := clogb2((NTTN/2)/(2*PE));

  constant butterflies_delays : integer := 9;
  -- constant butterflies_delays : integer := 1;

  -- subtype levels_type is natural range 0 to clogb2(NTTN)-1;
  -- subtype pe_type is natural range 0 to PE-1;
  -- constant levels : levels_type := clogb2(NTTN)-1;
  -- --------------------------------------------------------------------------------
  -- -- Declaration of the addresses types
  -- --------------------------------------------------------------------------------
  -- -- address space, defined by the size of NTT
  -- subtype addr_word is natural range 0 to NTTN-1;
  -- -- addresses for a single butterfly (a tuple)
  -- -- (x, y) s.t. x, y \in [0, NTTN-1]
  -- type tuple is array (natural range 0 to 1) of addr_word;
  -- -- [(x, y), (x, y), ..., (x, y)], s.t. len() = NTTN/2
  -- type address_by_level is array (natural range 0 to NTTN/2-1) of tuple;
  -- -- [[(x, y), (x, y), ..., (x, y)], [(x, y), (x, y), ..., (x, y)]... ]
  -- type ntt_addrs is array (natural range 0 to levels-1) of address_by_level;
  -- -- note, this is addresses by number of processing elements
  -- -- this is addresses by processing elements, for example
  -- -- PE = 2, [(x, y), (x, y)], etc.
  -- type address_by_pe is array (natural range 0 to PE-1) of tuple;
  -- type array_pe is array (natural range 0 to PE-1) of addr_word;
  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector(mword-1 downto 0);
  -- type array_slv_t is array(integer range <>) of word_t;
  type array_of_slv_t is array(integer range <>) of std_logic_vector;
  type array_uns_t is array(integer range <>) of unsigned;
  -- type mem_slv_t is array(integer range <>) of array_slv_t;
  type tuple_slv_t is array(integer range <>) of std_logic_vector;
  type tuple_uns_t is array(integer range <>) of unsigned;
  type array_of_tuple_slv_t is array(integer range <>) of tuple_slv_t;
  type array_of_tuple_uns_t is array(integer range <>) of tuple_uns_t;


  subtype bram_addr_word_t is natural range 0 to bram_depth;
  type array_of_natural_t is array(integer range <>) of bram_addr_word_t;
  -- subtype addr_word is natural range 0 to AddressRomDepth-1;
  -- type array_int_t is array(integer range <>) of addr_word;
  -- type mem_int_t is array(integer range <>) of array_int_t;
  -- type tuple_int_t is array(integer range <>) of natural;
  -- type array_of_tuple_int_t is array(integer range <>) of tuple_int_t;

end ntt_lib;

package body ntt_lib is
end package body ntt_lib;
