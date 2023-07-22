library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.opal_pkg.all;

entity opal_vsi_interface is
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
end entity opal_vsi_interface;

architecture beh of opal_vsi_interface is

    signal opal : opal_interface_t := (
        clk => '0', start => '0',
        rx => (others => '0'), data => (others => (others => '0'))
    );
    type meas_t is array(0 to OPAL_CHANNEL_LENGTH) of signed(OPAL_OUTPUT_WIDTH-1 downto 0);
    signal meas : meas_t := (others => (others => '0'));

    signal intx : std_logic := '0';

    

begin

    opal_rx_reg_p   : process(clk, i_opal_rx)
    begin
        if rising_edge(clk) then
            opal.clk <= i_opal_rx(24);
            opal.start <= i_opal_rx(25);
            opal.rx <= i_opal_rx(opal.rx'range);
        end if;
    end process;

    -- opal_spi_i  : opal_spi
    --     port map    (
    --         CLOCK    => clk,
    --         RESET    => rst_n,
    --         ENABLE   => '1',
    --         START    => opal.start,
    --         OPAL_CLK => opal.clk,
    --         DATA_IN  => opal.rx,
    --         DATA_OUT => opal.data,
    --         OPAL_CS  => open,
    --         END_ACQ  => intx
    --     );
    opal_driver_i   : opal_driver
        port map    (
            clk     => clk,
            rst_n   => rst_n,
            i_start => opal.start,
            i_clk   => opal.clk,
            i_data  => opal.rx,
            o_dout  => opal.data,
            o_busy  => open
        );
    
    opal_meas_p : process(clk, opal)
    begin
        if rising_edge(clk) then
            for i in opal.data'range loop
                meas(i) <= shift_left(signed(opal.data(i)), OPAL_OUTPUT_QN_BASE-OPAL_QN_BASE(i));
            end loop;
        end if;
    end process;

    -- bus 1 (conv 1 measurements)
    o1_curr_1 <= meas(0);
    o1_curr_2 <= meas(1);
    o1_curr_3 <= meas(2);
    o1_volt_1 <= meas(3);
    o1_volt_2 <= meas(4);
    o1_vdc    <= meas(5);
    o1_ref_1  <= meas(6);
    o1_ref_2  <= meas(7);

    -- bus 2 (conv 2 measurements)
    o2_curr_1 <= meas(8);
    o2_curr_2 <= meas(9);
    o2_curr_3 <= meas(10);
    o2_volt_1 <= meas(11);
    o2_volt_2 <= meas(12);
    o2_vdc    <= meas(13);
    o2_ref_1  <= meas(14);
    o2_ref_2  <= meas(15);

    -- bus 3 (pll related)

    o1_freq   <= meas(16);
    o1_delta  <= meas(17);
    o2_freq   <= meas(18);
    o2_delta  <= meas(19);
    o1_crr_ph <= meas(20);
    o2_crr_ph <= meas(21);
    o1_freq_flag <= std_logic_vector(meas(22)(1 downto 0));
    o2_freq_flag <= std_logic_vector(meas(22)(3 downto 2));
    
    -- bus 3 (new) (shit!)
    o1_if_1   <= meas(16);
    o1_if_2   <= meas(17);
    o1_vd_1   <= meas(20);
    o1_vd_2   <= meas(21);
    o2_if_1   <= meas(18);
    o2_if_2   <= meas(19);
    o2_vd_1   <= meas(22);
    o2_vd_2   <= meas(23);

    o_intx    <= intx;

end architecture beh;