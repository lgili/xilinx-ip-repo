library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.opal_pkg.all;

entity opal_driver is
    port    (
        clk     : in std_logic;
        rst_n   : in std_logic;
        i_start : in std_logic;
        i_clk   : in std_logic;
        i_data  : in std_logic_vector(OPAL_CHANNEL_LENGTH-1 downto 0);
        o_dout  : out opal_mem_t;
        o_busy  : out std_logic
    );
end entity opal_driver;

architecture beh of opal_driver is

    type fsm_states_t is (S_IDLE, S_HIGH, S_GET, S_LOW, S_WAIT, S_FAIL);
    type fsm_t is record
        cur : fsm_states_t;
        nxt : fsm_states_t;
        sigma   : std_logic_vector(4 downto 0);
        delta   : std_logic_vector(4 downto 0);
        tocnt   : unsigned(OPAL_TIMEOUT_WIDTH-1 downto 0);
    end record fsm_t;
    signal fsm  : fsm_t := (cur => S_IDLE, nxt => S_IDLE, sigma => (others => '0'), delta => (others => '0'), tocnt => (others => '0'));

    
    type opal_driver_t is record
        cnt  : unsigned(OPAL_DATA_CNT_WIDTH-1 downto 0);
        din  : std_logic_vector(i_data'range);
        dout : opal_s2p_data_t;
    end record opal_driver_t;
    signal opal : opal_driver_t := (cnt => (others => '0'), din => (others => '0'), dout => (others => (others => '0')));


begin

--! Input Mapping
    fsm.delta(0) <= i_start;
    fsm.delta(1) <= i_clk;
    opal.din   <= i_data;

--! FSM
    fsm_seq_beh : process(clk, rst_n, fsm)
    begin
        
        if rising_edge(clk) then
            if rst_n = '0' then
                fsm.cur <= S_IDLE;
            elsif fsm.delta(3) = '1' then
                fsm.cur <= S_FAIL;
            else
                fsm.cur <= fsm.nxt;
            end if;
        end if;
    end process;

    fsm_comb_beh    : process(fsm)
    begin
        fsm.sigma <= (others => '0');
        case fsm.cur is
            when S_IDLE =>
                fsm.sigma(0) <= '1';
                if fsm.delta(0) = '1' then
                    if fsm.delta(1) = '0' then
                        fsm.nxt <= S_LOW;
                    else
                        fsm.nxt <= S_HIGH;
                    end if;
                else
                    fsm.nxt <= S_IDLE;
                end if;

            when S_HIGH =>
                fsm.sigma(1) <= '1';
                if fsm.delta(1) = '0' then
                    fsm.nxt <= S_GET;
                else
                    fsm.nxt <= S_HIGH;
                end if;

            when S_LOW =>
                fsm.sigma(1) <= '1';
                if fsm.delta(1) = '1' then
                    fsm.nxt <= S_HIGH;
                else
                    fsm.nxt <= S_LOW;
                end if;
            
            when S_GET  => 
                fsm.sigma(2) <= '1';
                if fsm.delta(2) = '1' then
                    fsm.nxt <= S_WAIT;
                else
                    fsm.nxt <= S_LOW;
                end if;

            when S_WAIT =>
                fsm.sigma(3) <= '1';
                if fsm.delta(0) = '0' then
                    fsm.nxt <= S_IDLE;
                else
                    fsm.nxt <= S_WAIT;
                end if;
            
            when S_FAIL =>
            fsm.sigma(0) <= '1';
                fsm.nxt <= S_IDLE;

            when others =>
                fsm.nxt <= S_IDLE;

        end case;
    end process;

    --! Serial Reception
    process(clk, rst_n, fsm, opal)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                opal.dout <= (others => (others => '0'));
                opal.cnt  <= (others => '0');
                o_dout <= (others => (others => '0'));
                fsm.delta(2) <= '0';
            elsif fsm.sigma(0) = '1' then
                fsm.delta(2) <= '0';
                opal.dout <= (others => (others => '0'));
                opal.cnt  <= (others => '0');
            elsif fsm.sigma(1) = '1' then
                if opal.cnt = OPAL_INPUT_WIDTH-1 then
                    fsm.delta(2) <= '1';
                end if;
            elsif fsm.sigma(2) = '1' then
                opal.cnt <= opal.cnt + 1;
                for i in opal.dout'range loop
                    opal.dout(i)(opal.dout(i)'high downto 1) <=
                        opal.dout(i)(opal.dout(i)'high-1 downto 0);
                    opal.dout(i)(0) <= opal.din(i);
                end loop;
            elsif fsm.sigma(3) = '1' then
                fsm.delta(2) <= '0';
                opal.cnt   <= (others => '0');
                for i in opal.dout'range loop
                    o_dout(i) <= resize(opal.dout(i), o_dout(i)'length);
                end loop;
            end if;
        end if;
    end process;

    process(clk, fsm)
    begin
        if rising_edge(clk) then
            if fsm.sigma(0) = '1' then
                fsm.delta(3) <= '0';
                fsm.tocnt <= (others => '0');
            elsif fsm.tocnt < OPAL_TIMEOUT_VALUE then
                fsm.tocnt <= fsm.tocnt + 1;
                fsm.delta(3) <= '0';
            else
                fsm.delta(3) <= '1';
            end if;
        end if;
    end process;



    o_busy <= fsm.sigma(0) or fsm.sigma(3);

end architecture beh;


