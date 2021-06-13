--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ntt_utils.all;
use work.ntt_utils.all;
use work.ntt_lib.all;
--------------------------------------------------------------------------------
entity ntt is
  generic (p                        : std_logic_vector(pword-1 downto 0) := "111111111111110100000000000001";
           ninv                     : std_logic_vector(pword-1 downto 0) := "000000100000000000000000000000";
           -- shifts for the modulus
           s1                       : integer := 0;
           s2                       : integer := 14;
           s3                       : integer := -16;
           s4                       : integer := 30;
           -- shifts for J
           f1                       : integer := 0;
           f2                       : integer := 14;
           f3                       : integer := -16;
           f4                       : integer := -28;
           f5                       : integer := -30;
           local_levels             : integer := levels;
           local_PE                 : integer := PE;
           local_NTTN               : integer := NTTN;
           local_nttword            : natural := nttword;
           local_addr_bits          : natural := addr_bits;
           local_butterflies_delays : natural := butterflies_delays);
  port (
    clk, rst    : in  std_logic;
    load_ws     : in  std_logic;
    load_wsinv  : in  std_logic;
    load_data   : in  std_logic;
    data_in     : in  std_logic_vector(mword-1 downto 0);
    start_ntt   : in  std_logic;
    start_intt  : in  std_logic;
    out_ntt_res : in  std_logic;
    ntt_done    : out std_logic;
    data_out    : out std_logic_vector(pword-1 downto 0));
end entity;
--------------------------------------------------------------------------------
architecture behavior of ntt is
  type slv_array_t is array(integer range <>) of std_logic_vector;
  type slv_array_of_array_t is array(integer range <>) of slv_array_t;
  type array_of_array_of_tuple_slv_t is array(integer range <>) of array_of_tuple_slv_t;
  type natural_array_t is array(integer range <>) of natural range 0 to 2*local_PE;

  constant bram_coeff_addr_width : integer := clogb2(2*bram_depth);
  constant bram_ws_addr_width    : integer := clogb2(2*bram_ws_depth);

  constant bram_depth_slv : std_logic_vector(bram_coeff_addr_width downto 0) :=
    std_logic_vector(to_unsigned(bram_depth, bram_coeff_addr_width+1));

  constant ws_depth_slv : std_logic_vector(bram_ws_addr_width-1 downto 0) :=
    std_logic_vector(to_unsigned(bram_ws_depth, bram_ws_addr_width));

  constant ntt_uns : unsigned(local_nttword downto 0) :=
    to_unsigned(local_NTTN, local_nttword+1);

  constant total_ws_depth_usn : unsigned(bram_ws_addr_width-1 downto 0) :=
    to_unsigned(2*bram_ws_depth, bram_ws_addr_width);

  constant pe_usn : unsigned(local_nttword-1 downto 0) :=
    to_unsigned(2*local_PE, local_nttword);

  constant op_per_level_usn : unsigned(local_nttword-1 downto 0) :=
    to_unsigned((local_NTTN/2)/local_PE, local_nttword);

  constant local_mem_bits : integer := clogb2(2 * local_PE);

  -----------------------------------------------------------------------------
  -- brams for the coefficients
  -----------------------------------------------------------------------------
  signal even_waddr : slv_array_t(0 to 2*local_PE-1)(bram_coeff_addr_width-2 downto 0);
  signal even_raddr : slv_array_t(0 to 2*local_PE-1)(bram_coeff_addr_width-2 downto 0);
  signal even_data  : slv_array_t(0 to 2*local_PE-1)(bram_width-1 downto 0);
  signal even_dout  : slv_array_t(0 to 2*local_PE-1)(bram_width-1 downto 0);
  signal even_wea   : std_logic_vector(local_PE-1 downto 0);
  signal even_web   : std_logic_vector(local_PE-1 downto 0);

  signal odd_waddr : slv_array_t(0 to 2*local_PE-1)(bram_coeff_addr_width-2 downto 0);
  signal odd_raddr : slv_array_t(0 to 2*local_PE-1)(bram_coeff_addr_width-2 downto 0);
  signal odd_data  : slv_array_t(0 to 2*local_PE-1)(bram_width-1 downto 0);
  signal odd_dout  : slv_array_t(0 to 2*local_PE-1)(bram_width-1 downto 0);
  signal odd_wea   : std_logic_vector(local_PE-1 downto 0);
  signal odd_web   : std_logic_vector(local_PE-1 downto 0);

  -----------------------------------------------------------------------------
  -- brams for the WS
  -----------------------------------------------------------------------------
  signal even_ws_waddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal even_ws_raddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal even_ws_dataa  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal even_ws_douta  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal even_ws_wea    : std_logic_vector(local_PE-1 downto 0);

  signal odd_ws_waddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal odd_ws_raddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal odd_ws_dataa  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal odd_ws_douta  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal odd_ws_wea    : std_logic_vector(local_PE-1 downto 0);

  signal even_wsinv_waddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal even_wsinv_raddra : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal even_wsinv_dataa  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal even_wsinv_douta  : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal even_wsinv_wea    : std_logic_vector(local_PE-1 downto 0);

  signal odd_wsinv_waddra   : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal odd_wsinv_raddra   : slv_array_t(0 to local_PE-1)(bram_ws_addr_width-2 downto 0);
  signal odd_wsinv_dataa    : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal odd_wsinv_douta    : slv_array_t(0 to local_PE-1)(bram_ws_width-1 downto 0);
  signal odd_wsinv_wea      : std_logic_vector(local_PE-1 downto 0);
  -----------------------------------------------------------------------------
  -- butterfly signals
  -----------------------------------------------------------------------------
  -- even part
  signal X_even, Y_even     : slv_array_t(0 to local_PE-1)(mword-1 downto 0);
  signal W_even             : slv_array_t(0 to local_PE-1)(pword-1 downto 0);
  -- signal Xout_even, Yout_even : slv_array_t(0 to local_PE-1)(mword-1 downto 0);
  signal Butterfly_Out_even : slv_array_t(0 to 2*local_PE-1)(mword-1 downto 0);
  signal Butterfly_In_even  : slv_array_t(0 to 2*local_PE-1)(mword-1 downto 0);

  -- odd part
  signal X_odd, Y_odd      : slv_array_t(0 to local_PE-1)(mword-1 downto 0);
  signal W_odd             : slv_array_t(0 to local_PE-1)(pword-1 downto 0);
  -- signal Xout_odd, Yout_odd : slv_array_t(0 to local_PE-1)(mword-1 downto 0);
  signal Butterfly_Out_odd : slv_array_t(0 to 2*local_PE-1)(mword-1 downto 0);
  signal Butterfly_In_odd  : slv_array_t(0 to 2*local_PE-1)(mword-1 downto 0);
  -----------------------------------------------------------------------------
  -- signals for the address generator
  -----------------------------------------------------------------------------
  signal lvl               : unsigned(clogb2(local_levels)-1 downto 0);
  signal lvl_write_back    : std_logic_vector(clogb2(local_levels)-1 downto 0);
  signal en_addr_gen       : std_logic;
  signal en_write_back     : std_logic;
  signal rst_addr_gen      : std_logic;
  signal rst_wb_addr_gen   : std_logic;
  signal mem_addr          : array_of_slv_t(0 to 4*local_PE-1)(clogb2(2*local_PE)-1 downto 0);
  signal addr              : array_of_slv_t(0 to 4*local_PE-1)(local_addr_bits-1 downto 0);
  signal mem_write_back    : array_of_slv_t(0 to 4*local_PE-1)(clogb2(2*local_PE)-1 downto 0);
  signal addr_write_back   : array_of_slv_t(0 to 4*local_PE-1)(local_addr_bits-1 downto 0);

  -----------------------------------------------------------------------------
  type state_type is (idle, load_coeff, load_const, load_inv_const, exe_ntt,
                      out_ntt);
  signal state : state_type;
  -----------------------------------------------------------------------------

  -- signal data_counter : unsigned(nttword-1 downto 0) := (others => '0');
  signal input_buffer       : slv_array_t(0 to local_PE * 2 - 1)(mword-1 downto 0);
  signal output_addr_buffer : slv_array_t(0 to local_PE * 2 - 1)(mword-1 downto 0);
  signal input_buffer_reg   : slv_array_t(0 to local_PE * 2 - 1)(mword-1 downto 0);

  signal max_lvl : unsigned(clogb2(local_levels)-1 downto 0) := (others => '0');

  signal read_mem_delayed_sig : array_of_slv_t(0 to 2*local_PE-1)(clogb2(2*local_PE)-1 downto 0);

  signal cnt_final_stage         : unsigned(clogb2(8*local_PE) downto 0);
  signal cnt_final_stage_delayed : std_logic_vector(clogb2(8*local_PE) downto 0);

  signal data_out_not_reduced : std_logic_vector(mword-1 downto 0);
  signal data_out_reduced     : std_logic_vector(mword-1 downto 0);

  signal enable_input_fifo : std_logic;

begin

  max_lvl <= to_unsigned(local_levels-1, max_lvl'length);

  input_fifo : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        input_buffer <= (others => (others => '0'));
      else
        if enable_input_fifo = '1' then
          -- input buffer, this works like a fifo
          input_buffer(0) <= data_in;
          buffer_input_pe : for i in 1 to 2*local_PE-1 loop
            input_buffer(i) <= input_buffer(i-1);
          end loop;
        else
          input_buffer <= (others => (others => '0'));
        end if;
      end if;
    end if;
  end process;

  fsm : process(clk)
    variable even_wa : std_logic_vector(bram_coeff_addr_width downto 0) := (others => '0');
    variable even_wb : std_logic_vector(bram_coeff_addr_width downto 0) := (others => '0');
    variable odd_wa  : std_logic_vector(bram_coeff_addr_width downto 0) := (others => '0');
    variable odd_wb  : std_logic_vector(bram_coeff_addr_width downto 0) := (others => '0');

    variable even_ws_wa : std_logic_vector(bram_ws_addr_width-1 downto 0) := (others => '0');
    variable even_ws_wb : std_logic_vector(bram_ws_addr_width-1 downto 0) := (others => '0');
    variable odd_ws_wa  : std_logic_vector(bram_ws_addr_width-1 downto 0) := (others => '0');
    variable odd_ws_wb  : std_logic_vector(bram_ws_addr_width-1 downto 0) := (others => '0');

    -- pointer for the memory block
    variable load_cnt : unsigned(2*local_PE-1 downto 0);

    -- counters for the amount of samples loaded
    variable total_load_cnt : unsigned(bram_ws_addr_width-1 downto 0);

    variable mem_input : slv_array_t(0 to local_PE * 2 - 1)(mword-1 downto 0);

    -- counter of the number of operations per each level of the NTT,
    -- depends on the length of the NTT and the number of PE in parallel
    variable op_per_level_cnt : unsigned(local_nttword-1 downto 0);
    variable ws_addr_ptr      : unsigned(bram_ws_addr_width-1 downto 0);

    variable write_back_delay_cnt : unsigned(clogb2(butterflies_delays) downto 0);
    variable final_delay_cnt      : unsigned(clogb2(butterflies_delays) downto 0);

    variable mem_addr_v        : array_of_slv_t(0 to 4*local_PE-1)(clogb2(2*local_PE)-1 downto 0);
    variable addr_v            : array_of_slv_t(0 to 4*local_PE-1)(local_addr_bits-1 downto 0);
    variable mem_write_back_v  : array_of_slv_t(0 to 4*local_PE-1)(clogb2(2*local_PE)-1 downto 0);
    variable addr_write_back_v : array_of_slv_t(0 to 4*local_PE-1)(local_addr_bits-1 downto 0);

    variable read_delayed_mem_v                 : natural_array_t(0 to 2*local_PE-1) := (others => 0);
    variable read_delayed_temp_v                : natural range 0 to 2*local_PE      := 0;
    variable write_wb_mem_0_v, write_wb_mem_1_v : natural range 0 to 2*local_PE      := 0;

    variable final_lvl_cnt               : natural range 0 to 3                  := 0;
    variable output_cnt                  : natural range 0 to local_NTTN+2       := 0;
    variable intt_cnt_butterflies_delays : natural range 0 to butterflies_delays := 0;
    variable pe_cnt_last_lvl             : unsigned(clogb2(2*local_PE)-1 downto 0);
    variable is_intt                     : std_logic;

  begin
    if rising_edge(clk) then
      if rst = '1' then
        state      <= idle;
        even_wa    := (others => '0');
        even_wb    := (others => '0');
        odd_wa     := (others => '0');
        odd_wb     := (others => '0');
        even_ws_wa := (others => '0');
        even_ws_wb := (others => '0');
        odd_ws_wa  := (others => '0');
        odd_ws_wb  := (others => '0');

        load_cnt       := (others => '0');
        total_load_cnt := (others => '0');

        -- ag disabled
        en_addr_gen     <= '0';
        en_write_back   <= '0';
        rst_addr_gen    <= '1';
        rst_wb_addr_gen <= '1';
        -- reset level
        lvl             <= (others => '0');

        -- counter for the number of operations
        op_per_level_cnt := (others => '0');

        -- pointer for the ws constant
        ws_addr_ptr := (others => '0');

        -- disable input fifo
        enable_input_fifo <= '0';

        ntt_done             <= '0';
        write_back_delay_cnt := (others => '0');
        final_delay_cnt      := (others => '0');

        is_intt                     := '0';

        -- reset input butterflies
        Butterfly_In_even <= (others => (others => '0'));
        Butterfly_In_odd <= (others => (others => '0'));
        W_even <= (others => (others => '0'));
        W_odd <= (others => (others => '0'));

        -- reset output
        data_out_not_reduced <= (others => '0');
        -----------------------------------------------------------------------
        mem_addr_v                  := (others => (others => '0'));
        addr_v                      := (others => (others => '0'));
        mem_write_back_v            := (others => (others => '0'));
        addr_write_back_v           := (others => (others => '0'));
        final_lvl_cnt               := 0;
        output_cnt                  := 0;
        intt_cnt_butterflies_delays := 0;
        pe_cnt_last_lvl             := (others => '0');

      -----------------------------------------------------------------------
      else
        case(state) is
          -------------------------------------------------------------------
          when idle =>

            -------------------------------------------------------------------
            load_cnt := (others => '0');

            even_wa        := (others => '0');
            even_wb        := (others => '0');
            odd_wa         := (others => '0');
            odd_wb         := (others => '0');
            total_load_cnt := (others => '0');
            even_ws_wa     := (others => '0');
            even_ws_wb     := (others => '0');
            odd_ws_wa      := (others => '0');
            odd_ws_wb      := (others => '0');

            -- ag disabled
            en_addr_gen     <= '0';
            en_write_back   <= '0';
            rst_addr_gen    <= '1';
            rst_wb_addr_gen <= '1';

            -- reset level
            lvl <= (others => '0');

            -- counter for the number of operations
            op_per_level_cnt := (others => '0');

            -- pointer for the ws constant
            ws_addr_ptr := (others => '0');

            -- disable input fifo
            enable_input_fifo <= '0';

            ntt_done             <= '0';
            write_back_delay_cnt := (others => '0');
            final_delay_cnt      := (others => '0');

            -- disable writes
            even_wea       <= (others => '0');
            even_web       <= (others => '0');
            odd_wea        <= (others => '0');
            odd_web        <= (others => '0');
            even_ws_wea    <= (others => '0');
            odd_ws_wea     <= (others => '0');
            even_wsinv_wea <= (others => '0');
            odd_wsinv_wea  <= (others => '0');
            even_raddr     <= (others => (others => '0'));
            even_waddr     <= (others => (others => '0'));
            odd_raddr      <= (others => (others => '0'));
            odd_waddr      <= (others => (others => '0'));

            -- reset input butterflies
            Butterfly_In_even <= (others => (others => '0'));
            Butterfly_In_odd <= (others => (others => '0'));
            W_even <= (others => (others => '0'));
            W_odd <= (others => (others => '0'));

            -- reset output
            data_out_not_reduced <= (others => '0');
            -----------------------------------------------------------------------
            mem_addr_v        := (others => (others => '0'));
            addr_v            := (others => (others => '0'));
            mem_write_back_v  := (others => (others => '0'));
            addr_write_back_v := (others => (others => '0'));
            final_lvl_cnt     := 0;
            output_cnt                  := 0;
            pe_cnt_last_lvl   := (others => '0');
            -----------------------------------------------------------------------

            -------------------------------------------------------------------
            -- update state
            -------------------------------------------------------------------
            if load_data = '1' and load_ws = '0' and load_wsinv = '0' and start_ntt = '0' and start_intt = '0' and out_ntt_res = '0' then
              state             <= load_coeff;
              enable_input_fifo <= '1';
            elsif load_data = '0' and load_ws = '1' and load_wsinv = '0' and start_ntt = '0' and start_intt = '0' and out_ntt_res = '0' then
              state             <= load_const;
              enable_input_fifo <= '1';
            elsif load_data = '0' and load_ws = '0' and load_wsinv = '1' and start_ntt = '0' and start_intt = '0' and out_ntt_res = '0' then
              state             <= load_inv_const;
              enable_input_fifo <= '1';
            elsif load_data = '0' and load_ws = '0' and load_wsinv = '0' and start_ntt = '1' and start_intt = '0' and out_ntt_res = '0' then
              -- when chaging state it already enables the address generator
              -- this spares one clock cycle later
              -- this is needed because of the first address
              is_intt      := '0';
              en_addr_gen  <= '1';
              rst_addr_gen <= '0';
              state        <= exe_ntt;
            elsif load_data = '0' and load_ws = '0' and load_wsinv = '0' and start_ntt = '0' and start_intt = '1' and out_ntt_res = '0' then
              -- when chaging state it already enables the address generator
              -- this spares one clock cycle later
              -- this is needed because of the first address
              is_intt      := '1';
              en_addr_gen  <= '1';
              rst_addr_gen <= '0';
              state        <= exe_ntt;
            elsif load_data = '0' and load_ws = '0' and load_wsinv = '0' and start_ntt = '0' and start_intt = '0' and out_ntt_res = '1' then
              en_addr_gen  <= '1';
              rst_addr_gen <= '0';
              state        <= out_ntt;
              -- set level to output data
              lvl          <= max_lvl + 1;
            else
              state <= idle;
            end if;
            -------------------------------------------------------------------

          ---------------------------------------------------------------
          -- this state loads the data in the memory blocks for each
          -- part, even and odd, generic for any number of PE
          ---------------------------------------------------------------
          when load_coeff =>

            -- this is to write the values in the input fifo into the ram
            if load_cnt > 2*local_PE-1 then

              input_buffer_reg <= input_buffer;
              mem_input        := input_buffer;
              load_cnt         := (others => '0');

              -- write even
              even_ram : for i in 0 to local_PE-1 loop
                if (even_wa < bram_depth_slv) then
                  -- write on RAMA
                  even_wea(local_PE-i-1) <= '1';
                  even_web(local_PE-i-1) <= '0';
                  even_waddr(2*i)        <= even_wa(even_waddr(2*i)'range);
                  -- even_dataa(local_PE-i-1) <= mem_input(2*i + 1);
                  even_data(2*i)         <= mem_input(2*i + 1);
                  even_wa                := std_logic_vector(unsigned(even_wa) + 1);
                else
                  -- write on RAMB
                  even_wea(local_PE-i-1) <= '0';
                  even_web(local_PE-i-1) <= '1';
                  even_waddr(2*i + 1)    <= even_wb(even_waddr(2*i + 1)'range);
                  -- even_datab(local_PE-i-1) <= mem_input(2*i + 1);
                  even_data(2*i + 1)     <= mem_input(2*i + 1);
                  even_wb                := std_logic_vector(unsigned(even_wb) + 1);
                end if;

              end loop;

              -- write odd, the addresses in the fifo "mem_input" are contraty
              -- ie. the odd are the even ones
              odd_ram : for i in 0 to local_PE-1 loop
                if (odd_wa < bram_depth_slv) then
                  -- write on RAMA
                  odd_wea(local_PE-i-1) <= '1';
                  odd_web(local_PE-i-1) <= '0';
                  odd_waddr(2*i)        <= odd_wa(odd_waddr(2*i)'range);
                  -- odd_dataa(local_PE-i-1) <= mem_input(2*i);
                  odd_data(2*i)         <= mem_input(2*i);
                  odd_wa                := std_logic_vector(unsigned(odd_wa) + 1);
                else
                  -- write on RAMB
                  odd_wea(local_PE-i-1) <= '0';
                  odd_web(local_PE-i-1) <= '1';
                  odd_waddr(2*i + 1)    <= odd_wb(odd_waddr(2*i+1)'range);
                  -- odd_datab(local_PE-i-1) <= mem_input(2*i);
                  odd_data(2*i + 1)     <= mem_input(2*i);
                  odd_wb                := std_logic_vector(unsigned(odd_wb) + 1);
                end if;
              end loop;

              total_load_cnt := total_load_cnt + pe_usn;

            else
              -- after writting disable the write to avoid spurious writes
              ram_disable_write : for i in 0 to local_PE-1 loop
                even_wea(i) <= '0';
                odd_wea(i)  <= '0';
                even_web(i) <= '0';
                odd_web(i)  <= '0';
              end loop;

            end if;

            load_cnt := load_cnt + 1;

            -----------------------------------------------------------------------
            -- ag disabled
            en_addr_gen     <= '0';
            en_write_back   <= '0';
            rst_addr_gen    <= '1';
            rst_wb_addr_gen <= '1';

            -- reset level
            lvl <= (others => '0');

            -- counter for the number of operations
            op_per_level_cnt := (others => '0');

            -- pointer for the ws constant
            ws_addr_ptr := (others => '0');

            ntt_done             <= '0';
            write_back_delay_cnt := (others => '0');
            final_delay_cnt      := (others => '0');

            mem_addr_v        := (others => (others => '0'));
            addr_v            := (others => (others => '0'));
            mem_write_back_v  := (others => (others => '0'));
            addr_write_back_v := (others => (others => '0'));
            final_lvl_cnt     := 0;
            output_cnt                  := 0;
            pe_cnt_last_lvl   := (others => '0');

             -- enable input fifo
            enable_input_fifo <= '1';

            -- reset input butterflies
            Butterfly_In_even <= (others => (others => '0'));
            Butterfly_In_odd <= (others => (others => '0'));
            W_even <= (others => (others => '0'));
            W_odd <= (others => (others => '0'));

            -- reset output
            data_out_not_reduced <= (others => '0');
            -------------------------------------------------------------------
            -------------------------------------------------------------------
            -- update state
            -------------------------------------------------------------------
            if total_load_cnt >= ntt_uns then
              total_load_cnt := (others => '0');
              state          <= idle;
            else
              state <= load_coeff;
            end if;

          -------------------------------------------------------------------
          -- loads the butterfly constants
          -------------------------------------------------------------------
          when load_const =>

            -- this is to write the values in the input fifo into the ram
            if load_cnt > 2*local_PE-1 then

              input_buffer_reg <= input_buffer;
              mem_input        := input_buffer;
              load_cnt         := (others => '0');

              -- write even
              if (even_ws_wa < ws_depth_slv) then

                even_ws_ram : for i in 0 to local_PE-1 loop
                  even_ws_wea(local_PE-i-1)    <= '1';
                  even_ws_waddra(local_PE-i-1) <= even_ws_wa(even_ws_waddra(local_PE-i-1)'range);
                  even_ws_dataa(local_PE-i-1)  <= mem_input(2*i + 1)(bram_ws_width-1 downto 0);
                end loop;

                even_ws_wa := std_logic_vector(unsigned(even_ws_wa) + 1);
              end if;

              -- write odd
              if (odd_ws_wa < ws_depth_slv) then

                odd_ws_ram : for i in 0 to local_PE-1 loop
                  odd_ws_wea(local_PE-i-1)    <= '1';
                  odd_ws_waddra(local_PE-i-1) <= odd_ws_wa(odd_ws_waddra(local_PE-i-1)'range);
                  odd_ws_dataa(local_PE-i-1)  <= mem_input(2*i)(bram_ws_width-1 downto 0);
                end loop;

                odd_ws_wa := std_logic_vector(unsigned(odd_ws_wa) + 1);
              end if;

              total_load_cnt := total_load_cnt + pe_usn;

            else
              -- after writting disable the write to avoid spurious writes
              ram_ws_disable_write : for i in 0 to local_PE-1 loop
                even_ws_wea(i) <= '0';
                odd_ws_wea(i)  <= '0';
              end loop;

            end if;
            load_cnt := load_cnt + 1;

            -----------------------------------------------------------------------
            -- ag disabled
            en_addr_gen     <= '0';
            en_write_back   <= '0';
            rst_addr_gen    <= '1';
            rst_wb_addr_gen <= '1';

            -- reset level
            lvl <= (others => '0');

            -- counter for the number of operations
            op_per_level_cnt := (others => '0');

            -- pointer for the ws constant
            ws_addr_ptr := (others => '0');

            ntt_done             <= '0';
            write_back_delay_cnt := (others => '0');
            final_delay_cnt      := (others => '0');

            mem_addr_v        := (others => (others => '0'));
            addr_v            := (others => (others => '0'));
            mem_write_back_v  := (others => (others => '0'));
            addr_write_back_v := (others => (others => '0'));
            final_lvl_cnt     := 0;
            output_cnt                  := 0;
            pe_cnt_last_lvl   := (others => '0');

            -- enable input fifo
            enable_input_fifo <= '1';

           -- reset input butterflies
            Butterfly_In_even <= (others => (others => '0'));
            Butterfly_In_odd <= (others => (others => '0'));
            W_even <= (others => (others => '0'));
            W_odd <= (others => (others => '0'));

            -- reset output
            data_out_not_reduced <= (others => '0');
            -----------------------------------------------------------------------

            -------------------------------------------------------------------
            -- update state
            -------------------------------------------------------------------
            if total_load_cnt >= total_ws_depth_usn then
              total_load_cnt := (others => '0');
              state          <= idle;
            else
              state <= load_const;
            end if;
          -------------------------------------------------------------------

          -------------------------------------------------------------------
          -- loads the butterfly constants for inverse transform
          -------------------------------------------------------------------
          when load_inv_const =>

            -- this is to write the values in the input fifo into the ram
            if load_cnt > 2*local_PE-1 then

              input_buffer_reg <= input_buffer;
              mem_input        := input_buffer;
              load_cnt         := (others => '0');

              -- write even
              if (even_ws_wa < ws_depth_slv) then

                even_wsinv_ram : for i in 0 to local_PE-1 loop
                  even_wsinv_wea(local_PE-i-1)    <= '1';
                  even_wsinv_waddra(local_PE-i-1) <= even_ws_wa(even_ws_waddra(local_PE-i-1)'range);
                  even_wsinv_dataa(local_PE-i-1)  <= mem_input(2*i + 1)(bram_ws_width-1 downto 0);
                end loop;

                even_ws_wa := std_logic_vector(unsigned(even_ws_wa) + 1);
              end if;

              -- write odd
              if (odd_ws_wa < ws_depth_slv) then

                odd_wsinv_ram : for i in 0 to local_PE-1 loop
                  odd_wsinv_wea(local_PE-i-1)    <= '1';
                  odd_wsinv_waddra(local_PE-i-1) <= odd_ws_wa(odd_ws_waddra(local_PE-i-1)'range);
                  odd_wsinv_dataa(local_PE-i-1)  <= mem_input(2*i)(bram_ws_width-1 downto 0);
                end loop;

                odd_ws_wa := std_logic_vector(unsigned(odd_ws_wa) + 1);
              end if;

              total_load_cnt := total_load_cnt + pe_usn;

            else
              -- after writting disable the write to avoid spurious writes
              ram_wsinv_disable_write : for i in 0 to local_PE-1 loop
                even_wsinv_wea(i) <= '0';
                odd_wsinv_wea(i)  <= '0';
              end loop;

            end if;
            load_cnt := load_cnt + 1;

            -----------------------------------------------------------------------
            -- ag disabled
            en_addr_gen     <= '0';
            en_write_back   <= '0';
            rst_addr_gen    <= '1';
            rst_wb_addr_gen <= '1';

            -- enable input fifo
            enable_input_fifo <= '1';

            -- reset level
            lvl <= (others => '0');

            -- counter for the number of operations
            op_per_level_cnt := (others => '0');

            -- pointer for the ws constant
            ws_addr_ptr := (others => '0');

            ntt_done             <= '0';
            write_back_delay_cnt := (others => '0');
            final_delay_cnt      := (others => '0');

            mem_addr_v        := (others => (others => '0'));
            addr_v            := (others => (others => '0'));
            mem_write_back_v  := (others => (others => '0'));
            addr_write_back_v := (others => (others => '0'));
            final_lvl_cnt     := 0;
            output_cnt                  := 0;
            pe_cnt_last_lvl   := (others => '0');

            -- reset input butterflies
            Butterfly_In_even <= (others => (others => '0'));
            Butterfly_In_odd <= (others => (others => '0'));
            W_even <= (others => (others => '0'));
            W_odd <= (others => (others => '0'));

            -- reset output
            data_out_not_reduced <= (others => '0') ;
            -----------------------------------------------------------------------

            -------------------------------------------------------------------
            -- update state
            -------------------------------------------------------------------
            if total_load_cnt >= total_ws_depth_usn then
              total_load_cnt := (others => '0');
              state          <= idle;
            else
              state <= load_inv_const;
            end if;
          -------------------------------------------------------------------
          -------------------------------------------------------------------
          when exe_ntt =>

            -- enable input fifo
            enable_input_fifo <= '0';

            -------------------------------------------------------------------
            mem_addr_v        := mem_addr;
            addr_v            := addr;
            mem_write_back_v  := mem_write_back;
            addr_write_back_v := addr_write_back;
            rst_addr_gen      <= '0';
            rst_wb_addr_gen   <= '0';
            -- reset input butterflies
            Butterfly_In_even <= (others => (others => '0'));
            Butterfly_In_odd <= (others => (others => '0'));
            W_even <= (others => (others => '0'));
            W_odd <= (others => (others => '0'));

            -- reset output
            data_out_not_reduced <= (others => '0');
            -------------------------------------------------------------------

            for k in 0 to local_PE-1 loop
              -- get integer indexes for the brams
              read_delayed_mem_v(2*k)   := to_integer(unsigned(read_mem_delayed_sig(2*k)));
              read_delayed_mem_v(2*k+1) := to_integer(unsigned(read_mem_delayed_sig(2*k+1)));
              write_wb_mem_0_v          := to_integer(unsigned(mem_write_back_v(4*k + 2)));
              write_wb_mem_1_v          := to_integer(unsigned(mem_write_back_v(4*k + 3)));

              if lvl < max_lvl then
                -----------------------------------------------------------------
                -- even input/output
                -----------------------------------------------------------------
                -- read addresses
                even_raddr(2*k)                              <= addr_v(4*k);
                even_raddr(2*k+1)                            <= addr_v(4*k+1);
                -- input to the butterflies
                Butterfly_In_even(read_delayed_mem_v(2*k))   <= even_dout(2*k);
                Butterfly_In_even(read_delayed_mem_v(2*k+1)) <= even_dout(2*k+1);
                W_even(k)                                    <= even_ws_douta(k) when is_intt = '0' else even_wsinv_douta(k);
                -- write addresses
                even_waddr(2*k)                              <= addr_write_back_v(4*k + 2);
                even_waddr(2*k+1)                            <= addr_write_back_v(4*k + 3);
                -- output from the butterflies into the bram
                even_data(write_wb_mem_0_v)                  <= Butterfly_Out_even(2*k);
                even_data(write_wb_mem_1_v)                  <= Butterfly_Out_even(2*k+1);
                -----------------------------------------------------------------
                -- odd input/ouput
                -----------------------------------------------------------------
                -- read addresses
                odd_raddr(2*k)                               <= addr_v(4*k);
                odd_raddr(2*k+1)                             <= addr_v(4*k+1);
                -- input to the butterflies
                Butterfly_In_odd(read_delayed_mem_v(2*k))    <= odd_dout(2*k);
                Butterfly_In_odd(read_delayed_mem_v(2*k+1))  <= odd_dout(2*k+1);
                W_odd(k)                                     <= odd_ws_douta(k)  when is_intt = '0' else odd_wsinv_douta(k);
                -- write addresses
                odd_waddr(2*k)                               <= addr_write_back_v(4*k + 2);
                odd_waddr(2*k+1)                             <= addr_write_back_v(4*k + 3);
                -- output from the butterflies into the bram
                odd_data(write_wb_mem_0_v)                   <= Butterfly_Out_odd(2*k);
                odd_data(write_wb_mem_1_v)                   <= Butterfly_Out_odd(2*k+1);
              else
                if final_lvl_cnt < 2 then
                  -----------------------------------------------------------------
                  -- even input/output
                  -----------------------------------------------------------------
                  -- read addresses
                  even_raddr(2*k)                              <= addr_v(4*k);
                  even_raddr(2*k+1)                            <= addr_v(4*k+1);
                  -- input to the butterflies
                  Butterfly_In_even(read_delayed_mem_v(2*k))   <= even_dout(2*k);
                  Butterfly_In_even(read_delayed_mem_v(2*k+1)) <= even_dout(2*k+1);
                  W_even(k)                                    <= even_ws_douta(k) when is_intt = '0' else even_wsinv_douta(k);
                  -- write addresses
                  even_waddr(2*k)                              <= addr_write_back_v(4*k + 2);
                  even_waddr(2*k+1)                            <= addr_write_back_v(4*k + 3);
                  -- output from the butterflies into the bram
                  even_data(write_wb_mem_0_v)                  <= Butterfly_Out_even(2*k);
                  even_data(write_wb_mem_1_v)                  <= Butterfly_Out_even(2*k+1);
                  -----------------------------------------------------------------
                  -- odd input/ouput
                  -----------------------------------------------------------------
                  -- read addresses
                  odd_raddr(2*k)                               <= addr_v(4*k);
                  odd_raddr(2*k+1)                             <= addr_v(4*k+1);
                  -- input to the butterflies
                  Butterfly_In_odd(read_delayed_mem_v(2*k))    <= odd_dout(2*k);
                  Butterfly_In_odd(read_delayed_mem_v(2*k+1))  <= odd_dout(2*k+1);
                  W_odd(k)                                     <= odd_ws_douta(k)  when is_intt = '0' else odd_wsinv_douta(k);
                  -- write addresses
                  odd_waddr(2*k)                               <= addr_write_back_v(4*k + 2);
                  odd_waddr(2*k+1)                             <= addr_write_back_v(4*k + 3);
                  -- output from the butterflies into the bram
                  odd_data(write_wb_mem_0_v)                   <= Butterfly_Out_odd(2*k);
                  odd_data(write_wb_mem_1_v)                   <= Butterfly_Out_odd(2*k+1);
                  -- extra counter to finish the arithmetic in the current level
                  final_lvl_cnt                                := final_lvl_cnt + 1;
                else
                  -----------------------------------------------------------------
                  -- even input/output
                  -----------------------------------------------------------------
                  -- read addresses
                  even_raddr(2*k)             <= addr_v(4*k);
                  even_raddr(2*k+1)           <= addr_v(4*k+1);
                  -- input to the butterflies
                  Butterfly_In_even(2*k)      <= even_dout(read_delayed_mem_v(2*k));
                  Butterfly_In_even(2*k+1)    <= odd_dout(read_delayed_mem_v(2*k));
                  W_even(k)                   <= even_ws_douta(k) when is_intt = '0' else even_wsinv_douta(k);
                  -- write addresses
                  even_waddr(2*k)             <= addr_write_back_v(4*k + 2);
                  even_waddr(2*k+1)           <= addr_write_back_v(4*k + 3);
                  -- output from the butterflies into the bram
                  even_data(write_wb_mem_0_v) <= Butterfly_Out_even(2*k);
                  even_data(write_wb_mem_1_v) <= Butterfly_Out_even(2*k+1);
                  -----------------------------------------------------------------
                  -- odd input/ouput
                  -----------------------------------------------------------------
                  -- read addresses
                  odd_raddr(2*k)              <= addr_v(4*k);
                  odd_raddr(2*k+1)            <= addr_v(4*k+1);
                  -- input to the butterflies
                  Butterfly_In_odd(2*k)       <= even_dout(read_delayed_mem_v(2*k+1));
                  Butterfly_In_odd(2*k+1)     <= odd_dout(read_delayed_mem_v(2*k+1));
                  W_odd(k)                    <= odd_ws_douta(k)  when is_intt = '0' else odd_wsinv_douta(k);
                  -- write addresses
                  odd_waddr(2*k)              <= addr_write_back_v(4*k + 2);
                  odd_waddr(2*k+1)            <= addr_write_back_v(4*k + 3);
                  -- output from the butterflies into the bram
                  odd_data(write_wb_mem_0_v)  <= Butterfly_Out_odd(2*k);
                  odd_data(write_wb_mem_1_v)  <= Butterfly_Out_odd(2*k+1);
                end if;
              end if;
            end loop;

            -------------------------------------------------------------------
            -- increment the pointer of the constants ram
            -- last level single constant, thus no increment
            -------------------------------------------------------------------
            -- constants
            ws_from_ram : for i in 0 to local_PE-1 loop
              -- get constants
              if is_intt = '0' then
              even_ws_raddra(i) <= std_logic_vector(ws_addr_ptr(even_ws_raddra(i)'range));
              odd_ws_raddra(i)  <= std_logic_vector(ws_addr_ptr(odd_ws_raddra(i)'range));
              else
                even_wsinv_raddra(i) <= std_logic_vector(ws_addr_ptr(even_ws_raddra(i)'range));
                odd_wsinv_raddra(i)  <= std_logic_vector(ws_addr_ptr(odd_ws_raddra(i)'range));
              end if;
            end loop;

            -- pointer to the constants
            if lvl < max_lvl then
              ws_addr_ptr := ws_addr_ptr + 1;
            else
              ws_addr_ptr := ws_addr_ptr;
            end if;

            -------------------------------------------------------------------
            -- increment level
            -------------------------------------------------------------------
            if (op_per_level_cnt >= op_per_level_usn - 2) then
              -- reset operation count (per level counter)
              op_per_level_cnt := (others => '0');

              if lvl > max_lvl then
                lvl <= lvl;
              else
                lvl <= lvl + 1;
              end if;

            else
              op_per_level_cnt := op_per_level_cnt + pe_usn(op_per_level_cnt'range);
            end if;

            -------------------------------------------------------------------
            -- updat state
            -------------------------------------------------------------------
            if lvl > max_lvl then
              -- disable reading addresses
              en_addr_gen <= '0';

              -- last counter to given enough time to write the results back
              -- to the brams
              if final_delay_cnt > butterflies_delays then
                final_delay_cnt := (others => '0');
                ntt_done        <= '1';
                -- update state
                state           <= idle;

                en_write_back <= '0';

                write_back_delay_cnt := (others => '0');
                disable_write_brams : for i in 0 to local_PE-1 loop
                  even_wea(i) <= '0';
                  even_web(i) <= '0';
                  odd_wea(i)  <= '0';
                  odd_web(i)  <= '0';
                end loop;


              else
                final_delay_cnt := final_delay_cnt + 1;
                ntt_done        <= '0';
                -- update state
                state           <= exe_ntt;

                -------------------------------------------------------------------
                -- write back the results into the ram, this enables
                -- the address generator
                -------------------------------------------------------------------
                if write_back_delay_cnt >= butterflies_delays then
                  -- disable reading addresses
                  en_addr_gen   <= '0';
                  -- enable write
                  en_write_back <= '1';

                  enable_write_brams_last_lvl : for i in 0 to local_PE-1 loop
                    even_wea(i) <= '1';
                    even_web(i) <= '1';
                    odd_wea(i)  <= '1';
                    odd_web(i)  <= '1';
                  end loop;
                end if;

                -- increment the write back up to the point where the butterflies
                -- outputs are updated with the correct values
                if en_write_back = '0' then
                  write_back_delay_cnt := write_back_delay_cnt + 1;
                end if;

              end if;

            else
              -- enable reading addresses
              en_addr_gen     <= '1';
              final_delay_cnt := (others => '0');
              ntt_done        <= '0';
              -- update state
              state           <= exe_ntt;

              -------------------------------------------------------------------
              -- write back the results into the ram, this enables
              -- the address generator
              -------------------------------------------------------------------
              if write_back_delay_cnt >= butterflies_delays then
                -- enable write
                en_write_back <= '1';

                enable_write_brams : for i in 0 to local_PE-1 loop
                  even_wea(i) <= '1';
                  even_web(i) <= '1';
                  odd_wea(i)  <= '1';
                  odd_web(i)  <= '1';
                end loop;
              end if;

              -- increment the write back up to the point where the butterflies
              -- outputs are updated with the correct values
              if en_write_back = '0' then
                write_back_delay_cnt := write_back_delay_cnt + 1;
              end if;

            end if;

          when out_ntt =>

            -------------------------------------------------------------------
            even_wea <= (others => '0');
            even_web <= (others => '0');
            odd_wea  <= (others => '0');
            odd_web  <= (others => '0');
            load_cnt := (others => '0');

            even_wa        := (others => '0');
            even_wb        := (others => '0');
            odd_wa         := (others => '0');
            odd_wb         := (others => '0');
            total_load_cnt := (others => '0');

            -- reading enabled
            en_addr_gen   <= '1';
            -- write back disabled
            en_write_back <= '0';

            rst_addr_gen    <= '0';
            rst_wb_addr_gen <= '0';

            -- counter for the number of operations
            op_per_level_cnt := (others => '0');

            -- pointer for the ws constant
            ws_addr_ptr := (others => '0');

            ntt_done             <= '0';
            write_back_delay_cnt := (others => '0');

            -- disable writes
            even_wea       <= (others => '0');
            even_web       <= (others => '0');
            odd_wea        <= (others => '0');
            odd_web        <= (others => '0');
            even_ws_wea    <= (others => '0');
            odd_ws_wea     <= (others => '0');
            even_wsinv_wea <= (others => '0');
            odd_wsinv_wea  <= (others => '0');

            -- enable input fifo
            enable_input_fifo <= '0';
            -------------------------------------------------------------------
            mem_write_back_v  := (others => (others => '0'));
            addr_write_back_v := (others => (others => '0'));
            final_lvl_cnt     := 0;
            mem_addr_v        := mem_addr;
            addr_v            := addr;
            -----------------------------------------------------------------------

            W_even(0) <= ninv;
            Butterfly_In_even(1) <= (others => '0');

            for k in 0 to local_PE-1 loop

              -- get integer indexes for the brams
              read_delayed_mem_v(2*k)   := to_integer(unsigned(read_mem_delayed_sig(2*k)));
              read_delayed_mem_v(2*k+1) := to_integer(unsigned(read_mem_delayed_sig(2*k+1)));

              if output_cnt < local_NTTN+2 then

                  even_raddr(2*k)   <= addr_v(2*k);
                  even_raddr(2*k+1) <= addr_v(2*k+1);

                  odd_raddr(2*k)   <= addr_v(2*k);
                  odd_raddr(2*k+1) <= addr_v(2*k+1);

                if cnt_final_stage_delayed(0) = '0' then

                  read_delayed_temp_v  := read_delayed_mem_v(to_integer(unsigned(pe_cnt_last_lvl)));

                  if is_intt = '1' then
                    Butterfly_In_even(0) <= even_dout(read_delayed_temp_v);
                  end if;

                  data_out_not_reduced <= even_dout(read_delayed_temp_v) when is_intt = '0' else Butterfly_Out_even(1);

                else

                  read_delayed_temp_v  := read_delayed_mem_v(to_integer(unsigned(pe_cnt_last_lvl)));

                  if is_intt = '1' then
                    Butterfly_In_even(0) <= odd_dout(read_delayed_temp_v);
                  end if;

                  data_out_not_reduced <= odd_dout(read_delayed_temp_v) when is_intt = '0' else Butterfly_Out_even(1);

                end if;

                if pe_cnt_last_lvl < 2*local_PE then
                  pe_cnt_last_lvl := pe_cnt_last_lvl + 1;
                else
                  pe_cnt_last_lvl := (others => '0');
                end if;

                output_cnt := output_cnt + 1;
                -- update state (keep state)
                state      <= out_ntt;
              else
                if is_intt = '1' then
                  if intt_cnt_butterflies_delays < butterflies_delays then
                    is_intt                     := '1';
                    state                       <= out_ntt;
                    intt_cnt_butterflies_delays := intt_cnt_butterflies_delays + 1;
                  else
                    is_intt                     := '0';
                    -- go back to idle
                    state                       <= idle;
                    intt_cnt_butterflies_delays := 0;
                  end if;
                  data_out_not_reduced <= Butterfly_Out_even(1);
                else
                  is_intt                     := '0';
                  -- go back to idle
                  state                       <= idle;
                  intt_cnt_butterflies_delays := 0;
                end if;
              end if;

              if output_cnt > local_NTTN/2-1 then
                lvl <= max_lvl + 2;
              end if;

             end loop;

          when others => state <= idle;
        end case;
      end if;
    end if;
  end process;
  -----------------------------------------------------------------------------
  -- even brams for the coefficients of the inputs X and Y
  -----------------------------------------------------------------------------
  even_bram_generate : for i in 0 to local_PE-1 generate
    even_bram_coeff_1 : entity work.doublebram
      generic map (
        dwidth => bram_width,
        depth  => bram_depth)
      port map (
        clk    => clk,
        dataa  => even_data(2*i),
        waddra => even_waddr(2*i)(clogb2(bram_depth)-1 downto 0),
        raddra => even_raddr(2*i)(clogb2(bram_depth)-1 downto 0),
        wea    => even_wea(i),
        datab  => even_data(2*i + 1),
        waddrb => even_waddr(2*i+1)(clogb2(bram_depth)-1 downto 0),
        raddrb => even_raddr(2*i+1)(clogb2(bram_depth)-1 downto 0),
        web    => even_web(i),
        douta  => even_dout(2*i),
        doutb  => even_dout(2*i + 1));

    even_bram_ws_1 : entity work.bram
      generic map (
        dwidth => bram_ws_width,
        depth  => bram_ws_depth)
      port map (
        data  => even_ws_dataa(i),
        waddr => even_ws_waddra(i),
        raddr => even_ws_raddra(i),
        we    => even_ws_wea(i),
        clk   => clk,
        q     => even_ws_douta(i));

  even_bram_ws_inv_1 : entity work.bram
      generic map (
        dwidth => bram_ws_width,
        depth  => bram_ws_depth)
      port map (
        data  => even_wsinv_dataa(i),
        waddr => even_wsinv_waddra(i),
        raddr => even_wsinv_raddra(i),
        we    => even_wsinv_wea(i),
        clk   => clk,
        q     => even_wsinv_douta(i));
  end generate;

  -----------------------------------------------------------------------------
  -- odd brams for the coefficients of the inputs X and Y
  -----------------------------------------------------------------------------
  odd_bram_generate : for i in 0 to local_PE-1 generate
    odd_bram_coeff_1 : entity work.doublebram
      generic map (
        dwidth => bram_width,
        depth  => bram_depth)
      port map (
        clk    => clk,
        dataa  => odd_data(2*i),
        waddra => odd_waddr(2*i)(clogb2(bram_depth)-1 downto 0),
        raddra => odd_raddr(2*i)(clogb2(bram_depth)-1 downto 0),
        wea    => odd_wea(i),
        datab  => odd_data(2*i + 1),
        waddrb => odd_waddr(2*i+1)(clogb2(bram_depth)-1 downto 0),
        raddrb => odd_raddr(2*i+1)(clogb2(bram_depth)-1 downto 0),
        web    => odd_web(i),
        douta  => odd_dout(2*i),
        doutb  => odd_dout(2*i + 1));

    odd_bram_ws_1 : entity work.bram
      generic map (
        dwidth => bram_ws_width,
        depth  => bram_ws_depth)
      port map (
        data  => odd_ws_dataa(i),
        waddr => odd_ws_waddra(i),
        raddr => odd_ws_raddra(i),
        we    => odd_ws_wea(i),
        clk   => clk,
        q     => odd_ws_douta(i));

    odd_bram_wsinv_1 : entity work.bram
      generic map (
        dwidth => bram_ws_width,
        depth  => bram_ws_depth)
      port map (
        data  => odd_wsinv_dataa(i),
        waddr => odd_wsinv_waddra(i),
        raddr => odd_wsinv_raddra(i),
        we    => odd_wsinv_wea(i),
        clk   => clk,
        q     => odd_wsinv_douta(i));

  end generate;

  -----------------------------------------------------------------------------
  -- even butterflies
  -----------------------------------------------------------------------------
  even_butterflies_generate : for i in 0 to local_PE-1 generate
    -- even butterflies
    butterfly_even : entity work.butterfly_gen_cnt
      generic map (
        betawidth => mword,
        modwidth  => pword,
        p         => p,
        s1        => s1,
        s2        => s2,
        s3        => s3,
        s4        => s4,
        f1        => f1,
        f2        => f2,
        f3        => f3,
        f4        => f4,
        f5        => f5)
      port map (
        X    => Butterfly_In_even(2*i),
        Y    => Butterfly_In_even(2*i+1),
        W    => W_even(i),
        Xout => Butterfly_Out_even(2*i),
        Yout => Butterfly_Out_even(2*i+1),
        clk  => clk,
        rst  => rst);
  end generate;

  -----------------------------------------------------------------------------
  -- odd butterflies
  -----------------------------------------------------------------------------
  odd_butterflies_generate : for i in 0 to local_PE-1 generate
    -- odd butterflies
    butterfly_odd : entity work.butterfly_gen_cnt
      generic map (
        betawidth => mword,
        modwidth  => pword,
        p         => p,
        s1        => s1,
        s2        => s2,
        s3        => s3,
        s4        => s4,
        f1        => f1,
        f2        => f2,
        f3        => f3,
        f4        => f4,
        f5        => f5)
      port map (
        X    => Butterfly_In_odd(2*i),
        Y    => Butterfly_In_odd(2*i+1),
        W    => W_odd(i),
        Xout => Butterfly_Out_odd(2*i),
        Yout => Butterfly_Out_odd(2*i+1),
        clk  => clk,
        rst  => rst);
  end generate;

  -----------------------------------------------------------------------------
  -- address generation for reading and writing to the brams
  -----------------------------------------------------------------------------
  AddressGenerator_even_and_odd : entity work.AddressGenerator
    generic map (
      local_levels    => local_levels,
      local_PE        => local_PE,
      local_NTTN      => local_NTTN,
      local_nttword   => local_nttword,
      local_addr_bits => local_addr_bits,
      local_mem_bits  => local_mem_bits)
    port map (
      clk          => clk,
      en           => en_addr_gen,
      rst          => rst_addr_gen,
      last_lvl_cnt => cnt_final_stage,
      lvl          => lvl,
      mem_idx      => mem_addr,
      addr_idx     => addr);

  AddressGenerator_even_and_odd_write_back : entity work.AddressGenerator
    generic map (
      local_levels    => local_levels,
      local_PE        => local_PE,
      local_NTTN      => local_NTTN,
      local_nttword   => local_nttword,
      local_addr_bits => local_addr_bits,
      local_mem_bits  => local_mem_bits)
    port map (
      clk          => clk,
      en           => en_write_back,
      rst          => rst_wb_addr_gen,
      last_lvl_cnt => open,
      lvl          => unsigned(lvl_write_back),
      mem_idx      => mem_write_back,
      addr_idx     => addr_write_back);

  -----------------------------------------------------------------------------
  -- write back delay for the level
  -----------------------------------------------------------------------------
  sr_write_back_lvl : entity work.sr
    generic map (
      width => lvl_write_back'length,
      shift => butterflies_delays+1)
    port map (
      d   => std_logic_vector(lvl),
      q   => lvl_write_back,
      clk => clk,
      rst => rst);


  -----------------------------------------------------------------------------
  -- delayed signal to multiplex the output of the bram, ie, input of the
  -- butterflies
  -----------------------------------------------------------------------------
  gen_delayed_butterfly_mux_input : for k in 0 to local_PE-1 generate
    sr_read_0 : entity work.sr
      generic map (
        width => mem_addr(4*k)'length,
        shift => 2)
      port map (
        d   => mem_addr(4*k),
        q   => read_mem_delayed_sig(2*k),
        clk => clk,
        rst => rst);

    sr_read_1 : entity work.sr
      generic map (
        width => mem_addr(4*k+1)'length,
        shift => 2)
      port map (
        d   => mem_addr(4*k+1),
        q   => read_mem_delayed_sig(2*k+1),
        clk => clk,
        rst => rst);

  end generate;

  final_stage_cnt_delay_1 : entity work.sr
    generic map (
      width => cnt_final_stage'length,
      shift => 2)
    port map (
      d   => std_logic_vector(cnt_final_stage),
      q   => cnt_final_stage_delayed,
      clk => clk,
      rst => rst);

  -----------------------------------------------------------------------------
  -- Final subtraction before output
  -----------------------------------------------------------------------------
  subm2p_gen_1 : entity work.subm2p_gen
    generic map (
      width  => mword,
      target => fpga,
      p      => p)
    port map (
      A   => data_out_not_reduced,
      Sub => data_out_reduced);

  -- data out assignment
  data_out <= data_out_reduced(data_out'range);

  -----------------------------------------------------------------------------
  -- for verification
  -----------------------------------------------------------------------------
  -- synthesis translate_off
  gen_conn_tb : for i in 0 to local_PE-1 generate
    X_even(i) <= Butterfly_In_even(2*i);
    Y_even(i) <= Butterfly_In_even(2*i + 1);
    X_odd(i)  <= Butterfly_In_odd(2*i);
    Y_odd(i)  <= Butterfly_In_odd(2*i + 1);
  end generate;
  -- synthesis translate_on

end behavior;
--------------------------------------------------------------------------------
