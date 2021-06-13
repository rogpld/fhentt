library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

package ntt_utils is
  --------------------------------------------------------------------------------
  -- aux functions
  --------------------------------------------------------------------------------
  function twoc (inp        :    unsigned) return unsigned;
  function twoc_signed (inp :    signed) return integer;
  function clogb2 (depth    : in natural) return integer;
  function or_reduct(usn    : in unsigned) return std_logic;
  function and_reduct(usn    : in unsigned) return std_logic;
end ntt_utils;

package body ntt_utils is
  -- purpose: returns two complement of inp
  function twoc (
    inp : unsigned)
    return unsigned is
    variable inp_2c : unsigned(inp'range);
  begin  -- function twoc
    return not(inp) + 1;
  end function twoc;

  -- purpose: returns two complement of inp
  function twoc_signed (
    inp : signed)
    return integer is
    variable inp_2c : integer;
  begin  -- function twoc_signed
    inp_2c := to_integer(not inp);
    return inp_2c + 1;
  end function twoc_signed;

  function clogb2(depth : natural) return integer is
    variable ret_val : integer := 0;
  begin
    if depth = 1 or depth = 0 then
      ret_val := 1;
    else
      ret_val := integer(ceil(log2(real(depth))));
    end if;
    return ret_val;
  end function;

  function or_reduct(usn : in unsigned) return std_logic is
    variable res_v : std_logic := '0';  -- Null usn vector will also return '1'
  begin
    for i in usn'range loop
      res_v := res_v or usn(i);
    end loop;
    return res_v;
  end function;

  function and_reduct(usn : in unsigned) return std_logic is
    variable res_v : std_logic := '1';  -- Null usn vector will also return '1'
  begin
    for i in usn'range loop
      res_v := res_v and usn(i);
    end loop;
    return res_v;
  end function;
end package body ntt_utils;
