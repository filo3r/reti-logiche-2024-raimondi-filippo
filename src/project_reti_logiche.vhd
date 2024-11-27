-------------------------------------------------------------------------
-- Prova Finale di Reti Logiche                                        --
-- Anno Accademico 2023-2024                                           --
-- Politecnico di Milano                                               --
-- Filippo Raimondi                                                    --
-- 10809051                                                            --
-------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY project_reti_logiche IS
    PORT (
        i_clk      : IN  STD_LOGIC;
        i_rst      : IN  STD_LOGIC;
        i_start    : IN  STD_LOGIC;
        i_add      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        i_k        : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        o_done     : OUT STD_LOGIC;
        o_mem_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        i_mem_data : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_mem_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_mem_we   : OUT STD_LOGIC;
        o_mem_en   : OUT STD_LOGIC
    );
END project_reti_logiche;


ARCHITECTURE Behavioral OF project_reti_logiche IS
    
    TYPE state_enum          IS (IDLE, CHECK_ADDR, SET_READ_W, READ_W, PROCESS_W, SET_WRITE_W, WRITE_W, SET_WRITE_C, WRITE_C, CHECK_COUNTER, DONE);
    TYPE check_addr_enum     IS (ADDR_W, ADDR_C, ADDR_NULL);
    SIGNAL state_reg         : state_enum := IDLE;
    SIGNAL state_next        : state_enum := IDLE;
    SIGNAL check_addr_reg    : check_addr_enum := ADDR_NULL;
    SIGNAL check_addr_next   : check_addr_enum := ADDR_NULL;
    SIGNAL o_done_next       : STD_LOGIC := '0';
    SIGNAL o_mem_addr_next   : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL o_mem_data_next   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL o_mem_we_next     : STD_LOGIC := '0';
    SIGNAL o_mem_en_next     : STD_LOGIC := '0';
    SIGNAL last_valid_w_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL last_valid_w_next : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL counter_reg       : INTEGER RANGE 0 TO 1023 := 0;
    SIGNAL counter_next      : INTEGER RANGE 0 TO 1023 := 0;
    SIGNAL credibility_reg   : INTEGER RANGE 0 TO 31 := 0;
    SIGNAL credibility_next  : INTEGER RANGE 0 TO 31 := 0;

BEGIN
    
    PROCESS (i_clk, i_rst)
    BEGIN
        IF (i_rst = '1') THEN
            state_reg        <= IDLE;
            check_addr_reg   <= ADDR_NULL;
            o_done           <= '0';
            o_mem_addr       <= (OTHERS => '0');
            o_mem_data       <= (OTHERS => '0');
            o_mem_we         <= '0';
            o_mem_en         <= '0';
            last_valid_w_reg <= (OTHERS => '0');
            counter_reg      <= 0;
            credibility_reg  <= 0;
        ELSIF (rising_edge(i_clk)) THEN
            state_reg        <= state_next;
            check_addr_reg   <= check_addr_next;
            o_done           <= o_done_next;
            o_mem_addr       <= o_mem_addr_next;
            o_mem_data       <= o_mem_data_next;
            o_mem_we         <= o_mem_we_next;
            o_mem_en         <= o_mem_en_next;
            last_valid_w_reg <= last_valid_w_next;
            counter_reg      <= counter_next;
            credibility_reg  <= credibility_next;
        END IF;
    END PROCESS;

    PROCESS (i_start, i_add, i_k, i_mem_data, state_reg, check_addr_reg, last_valid_w_reg, counter_reg, credibility_reg)
    BEGIN
        state_next        <= state_reg;
        check_addr_next   <= ADDR_NULL;
        o_done_next       <= '0';
        o_mem_addr_next   <= (OTHERS => '0');
        o_mem_data_next   <= (OTHERS => '0');
        o_mem_we_next     <= '0';
        o_mem_en_next     <= '0';
        last_valid_w_next <= last_valid_w_reg;
        counter_next      <= counter_reg;
        credibility_next  <= credibility_reg;

        CASE state_reg IS
            WHEN IDLE =>
                IF (i_start = '1') THEN
                    IF (i_k /= "0000000000") THEN
                        last_valid_w_next <= (OTHERS => '0');
                        counter_next      <= 0;
                        credibility_next  <= 0;
                        check_addr_next   <= ADDR_W;
                        state_next        <= CHECK_ADDR;
                    ELSE
                        o_done_next <= '1';
                        state_next  <= DONE;
                    END IF;
                END IF;
            WHEN CHECK_ADDR =>
                IF (check_addr_reg = ADDR_W) THEN
                    IF (to_integer(unsigned(i_add)) + counter_reg * 2 > 2**16 - 1) THEN
                        o_done_next <= '1';
                        state_next  <= DONE;
                    ELSE
                        state_next <= SET_READ_W;
                    END IF;
                ELSIF (check_addr_reg = ADDR_C) THEN
                    IF (to_integer(unsigned(i_add)) + counter_reg * 2 + 1 > 2**16 - 1) THEN
                        o_done_next <= '1';
                        state_next  <= DONE;
                    ELSE
                        state_next <= SET_WRITE_C;
                    END IF;
                ELSE
                    o_done_next <= '1';
                    state_next  <= DONE;
                END IF;
            WHEN SET_READ_W =>
                o_mem_addr_next <= std_logic_vector(to_unsigned(to_integer(unsigned(i_add)) + counter_reg * 2, 16));
                o_mem_en_next   <= '1';
                state_next      <= READ_W;
            WHEN READ_W =>
                state_next <= PROCESS_W;
            WHEN PROCESS_W =>
                IF (i_mem_data /= "00000000") THEN
                    last_valid_w_next <= i_mem_data;
                    credibility_next  <= 31;
                ELSIF (credibility_reg > 0) THEN
                    credibility_next <= credibility_reg - 1;
                END IF;
                state_next <= SET_WRITE_W;
            WHEN SET_WRITE_W =>
                o_mem_we_next   <= '1';
                o_mem_en_next   <= '1';
                o_mem_addr_next <= std_logic_vector(to_unsigned(to_integer(unsigned(i_add)) + counter_reg * 2, 16));
                o_mem_data_next <= last_valid_w_reg;
                state_next      <= WRITE_W;
            WHEN WRITE_W =>
                check_addr_next <= ADDR_C;
                state_next      <= CHECK_ADDR;
            WHEN SET_WRITE_C =>
                o_mem_we_next   <= '1';
                o_mem_en_next   <= '1';
                o_mem_addr_next <= std_logic_vector(to_unsigned(to_integer(unsigned(i_add)) + counter_reg * 2 + 1, 16));
                o_mem_data_next <= std_logic_vector(to_unsigned(credibility_reg, 8));
                state_next      <= WRITE_C;
            WHEN WRITE_C =>
                state_next <= CHECK_COUNTER;
            WHEN CHECK_COUNTER =>
                IF (counter_reg < to_integer(unsigned(i_k)) - 1) THEN
                    counter_next    <= counter_reg + 1;
                    check_addr_next <= ADDR_W;
                    state_next      <= CHECK_ADDR;
                ELSE
                    o_done_next <= '1';
                    state_next  <= DONE;
                END IF;
            WHEN DONE =>
                IF (i_start = '0') THEN
                    last_valid_w_next <= (OTHERS => '0');
                    counter_next      <= 0;
                    credibility_next  <= 0;
                    state_next        <= IDLE;
                ELSE
                    o_done_next <= '1';
                END IF;
        END CASE;
    END PROCESS;

END Behavioral;