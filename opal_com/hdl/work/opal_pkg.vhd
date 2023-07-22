library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package opal_pkg is

    constant OPAL_INPUT_WIDTH   : integer := 16;
    constant OPAL_OUTPUT_WIDTH  : integer := 27;
    constant OPAL_OUTPUT_QN_BASE : integer := 16;
    constant OPAL_DATA_CNT_WIDTH : integer := integer(ceil(log2(real(OPAL_INPUT_WIDTH))));
    constant OPAL_CHANNEL_LENGTH    : integer := 24;
    constant OPAL_TIMEOUT_WIDTH : integer := 12;
    constant OPAL_TIMEOUT_VALUE : integer := 1500;

    constant OPAL_CHANNEL_WIDTH : integer := integer(ceil(log2(real(OPAL_CHANNEL_LENGTH))));
    type opal_qn_base_t is array(0 to OPAL_CHANNEL_LENGTH-1) of integer range 0 to 31;
    constant OPAL_QN_BASE   : opal_qn_base_t := (
        0  to 2   => 9,
        3  to 5   => 5,
        6  to 7   => 9,
        8  to 10  => 9,
        11 to 13  => 5,
        14 to 15  => 9,
        others => OPAL_OUTPUT_QN_BASE
        -- 16 to 19  => 7,
        -- 20 to 23  => 5
    );

    
    type opal_s2p_data_t is array(0 to OPAL_CHANNEL_LENGTH-1) of signed(OPAL_INPUT_WIDTH-1 downto 0);
    type opal_mem_t is array(0 to OPAL_CHANNEL_LENGTH-1) of signed(OPAL_OUTPUT_WIDTH-1 downto 0);
    type opal_interface_t is record
        clk     : std_logic;
        start   : std_logic;
        rx      : std_logic_vector(OPAL_CHANNEL_LENGTH-1 downto 0);
        data    : opal_mem_t;
    end record opal_interface_t;

    type meas_cl_t is array(natural range <>) of signed(OPAL_OUTPUT_WIDTH-1 downto 0);
    type opal_meas_t is record
        curr    : meas_cl_t(0 to 2);
        volt    : meas_cl_t(0 to 1);
        dc      : signed(OPAL_OUTPUT_WIDTH-1 downto 0);
        ref     : meas_cl_t(0 to 1);
        freq    : signed(OPAL_OUTPUT_WIDTH-1 downto 0);
        delta   : signed(OPAL_OUTPUT_WIDTH-1 downto 0);
        cext    : meas_cl_t(0 to 1);
        vext    : meas_cl_t(0 to 1);
    end record opal_meas_t;

    constant c_init_opal_meas   : opal_meas_t := (
        curr => (others => (others => '0')),
        volt => (others => (others => '0')),
        dc   => (others => '0'),
        ref  => (others => (others => '0')),
        freq => (others => '0'),
        delta => (others => '0'),
        cext => (others => (others => '0')),
        vext => (others => (others => '0'))
    );

    type opal_data_t is array(0 to 1) of opal_meas_t;

    component opal_spi is
        generic	(
            CHANNEL_WIDTH : natural := OPAL_CHANNEL_LENGTH;
            DATA_WIDTH	  : natural := OPAL_INPUT_WIDTH
        );
        port	(
            CLOCK	 : in std_logic;
            RESET	 : in std_logic;
            ENABLE	 : in std_logic;
            START	 : in std_logic;
            OPAL_CLK : in std_logic;
            DATA_IN	 : in std_logic_vector(CHANNEL_WIDTH-1 downto 0);
            DATA_OUT : out opal_mem_t;
            OPAL_CS	 : out std_logic;
            END_ACQ	 : out std_logic
        );
    end component opal_spi;

    component opal_driver is
        port    (
            clk     : in std_logic;
            rst_n   : in std_logic;
            i_start : in std_logic;
            i_clk   : in std_logic;
            i_data  : in std_logic_vector(OPAL_CHANNEL_LENGTH-1 downto 0);
            o_dout  : out opal_mem_t;
            o_busy  : out std_logic
        );
    end component opal_driver;

    component opal_vsi_interface is
        generic (
            CHANNEL_LENGTH  : integer := OPAL_CHANNEL_LENGTH;
            OUTPUT_WIDTH    : integer := OPAL_OUTPUT_WIDTH
        );
        port    (
            clk     : in std_logic;
            rst_n   : in std_logic;
            i_opal_rx   : in std_logic_vector(31 downto 0);
            -- conv #1
            o1_curr_1   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_curr_2   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_curr_3   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_volt_1   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_volt_2   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_vdc      : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_ref_1    : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_ref_2    : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_freq     : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_delta    : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_crr_ph   : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_freq_flag    : out std_logic_vector(1 downto 0);
            -- conv #2
            o2_curr_1   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_curr_2   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_curr_3   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_volt_1   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_volt_2   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_vdc      : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_ref_1    : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_ref_2    : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_freq     : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_delta    : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_crr_ph   : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_freq_flag    : out std_logic_vector(1 downto 0);
            -- extra measurements conv #1
            o1_if_1     : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_if_2     : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_vd_1     : out signed(OUTPUT_WIDTH-1 downto 0);
            o1_vd_2     : out signed(OUTPUT_WIDTH-1 downto 0);
            -- extra measurements conv #2
            o2_if_1     : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_if_2     : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_vd_1     : out signed(OUTPUT_WIDTH-1 downto 0);
            o2_vd_2     : out signed(OUTPUT_WIDTH-1 downto 0);
            -- interrupt
            o_intx      : out std_logic
        );
    end component opal_vsi_interface;

end package opal_pkg;
