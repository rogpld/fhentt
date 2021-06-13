-------------------------------------------------------------------------------
library ieee;
use work.ntt_utils.all;
use work.ntt_lib.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity modadd is
  generic (width  : positive   := 8;                        -- word width
           target : targetType := fpga);                    -- target type
  port (A, B    : in  std_logic_vector(width-1 downto 0);   -- operands
        Add     : out std_logic_vector(width-1 downto 0));  -- sub
end modadd;
-------------------------------------------------------------------------------
architecture structural of modadd is
  signal Ausn, Busn : unsigned(width downto 0);            -- unsigned
  signal Addusn     : unsigned(width downto 0);
begin
  -- default ripple-carry suber as slow implementation
  fpga_target : if target = fpga generate
    -- type conversion: std_logic_vector -> unsigned
    Ausn   <= unsigned('0' & A);
    Busn   <= unsigned('0' & B);
    Addusn <= Ausn + Busn;
    Add    <= std_logic_vector(Addusn(Add'range));
  end generate fpga_target;

-- asic_target : if target /= fgpa generate
-- TODO: implement the asic architecture
-- end generate asic_target;
end structural;
-------------------------------------------------------------------------------
