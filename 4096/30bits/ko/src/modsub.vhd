library ieee;
use work.ntt_utils.all;
use work.ntt_lib.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
entity modsub is
  generic (width  : positive   := 8;                        -- word width
           target : targetType := fpga);                    -- target type
  port (A, B    : in  std_logic_vector(width-1 downto 0);   -- operands
        modulus : in  std_logic_vector(width-1 downto 0);
        Sub     : out std_logic_vector(width-1 downto 0));  -- sub
end modsub;
-------------------------------------------------------------------------------
architecture structural of modsub is
  signal Asig, Bsig : signed(width downto 0);            -- signed
  signal Subsig     : signed(width downto 0);
begin
  -- default ripple-carry suber as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> signed
    Asig   <= signed('0' & A);
    Bsig   <= signed('0' & B);
    Subsig <= Asig - Bsig;
    Sub    <= std_logic_vector(Subsig(Sub'range));
  end generate fpga_target;

-- asic_target : if target /= fgpa generate
-- TODO: implement the asic architecture
-- end generate asic_target;
end structural;
-------------------------------------------------------------------------------
