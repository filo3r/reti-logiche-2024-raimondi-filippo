---------------------------------------------------------------------------
-- Prova Finale di Reti Logiche                                         --
-- Anno Accademico 2023-2024                                            --
-- Politecnico di Milano                                                --
-- Filippo Raimondi                                                     --
-- 10809051                                                             --
-- Testbench 16: Segnale di reset durante l'elaborazione                --
---------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;

ENTITY project_tb_16 IS
END project_tb_16;

ARCHITECTURE project_tb_16_arch OF project_tb_16 IS

    -- Costanti
    CONSTANT CLOCK_PERIOD : TIME := 20 ns;
    CONSTANT SCENARIO_ADDRESS : INTEGER := 1234;
    CONSTANT SCENARIO_LENGTH : INTEGER := 14;
    CONSTANT SCENARIO2_ADDRESS : INTEGER := 5135;
    CONSTANT SCENARIO2_LENGTH : INTEGER := 15;

    -- Tipi custom
    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE scenario_type IS ARRAY (0 TO SCENARIO_LENGTH * 2 - 1) OF INTEGER;
    TYPE scenario2_type IS ARRAY (0 TO SCENARIO2_LENGTH * 2 - 1) OF INTEGER;

    -- Segnali principali
    SIGNAL tb_clk         : STD_LOGIC := '0';
    SIGNAL tb_rst         : STD_LOGIC;
    SIGNAL tb_start       : STD_LOGIC;
    SIGNAL tb_done        : STD_LOGIC;
    SIGNAL tb_add         : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tb_k           : STD_LOGIC_VECTOR(9 DOWNTO 0);

    SIGNAL tb_o_mem_addr  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tb_o_mem_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_i_mem_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_o_mem_we    : STD_LOGIC;
    SIGNAL tb_o_mem_en    : STD_LOGIC;

    SIGNAL exc_o_mem_addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL exc_o_mem_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL exc_o_mem_we   : STD_LOGIC;
    SIGNAL exc_o_mem_en   : STD_LOGIC;

    SIGNAL init_o_mem_addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL init_o_mem_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL init_o_mem_we   : STD_LOGIC;
    SIGNAL init_o_mem_en   : STD_LOGIC;

    SIGNAL memory_control : STD_LOGIC := '0';
    SIGNAL RAM            : ram_type := (OTHERS => "00000000");

    SIGNAL scenario_input : scenario_type := (128, 0,  64, 0,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 100,  0, 1,  0, 0,  0, 5,  0, 23,  0, 200,  0,   0,  0);
    SIGNAL scenario_full : scenario_type := (128, 31, 64, 31, 64, 30, 64, 29, 64, 28, 64, 27, 64, 26, 100, 31, 1, 31, 1, 30, 5, 31, 23, 31, 200, 31, 200, 30);

    SIGNAL scenario2_input : scenario2_type := (0, 0, 0, 0, 64, 0,   0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 150,  0, 1,  0, 0,  0, 5,  0, 23,  0, 0,  0,   0,  0);
    SIGNAL scenario2_full : scenario2_type := (0, 0, 0, 0, 64, 31, 64, 30, 64, 29, 64, 28, 64, 27, 64, 26, 150, 31, 1, 31, 1, 30, 5, 31, 23, 31, 23, 30, 23, 29);

    -- Componenti
    COMPONENT project_reti_logiche IS
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
    END COMPONENT project_reti_logiche;

BEGIN

    -- Instanza del DUT
    UUT : project_reti_logiche
        PORT MAP (
            i_clk      => tb_clk,
            i_rst      => tb_rst,
            i_start    => tb_start,
            i_add      => tb_add,
            i_k        => tb_k,
            o_done     => tb_done,
            o_mem_addr => exc_o_mem_addr,
            i_mem_data => tb_i_mem_data,
            o_mem_data => exc_o_mem_data,
            o_mem_we   => exc_o_mem_we,
            o_mem_en   => exc_o_mem_en
        );

    -- Generazione del clock
    tb_clk <= NOT tb_clk AFTER CLOCK_PERIOD / 2;

    -- Comportamento della memoria
    MEM : PROCESS(tb_clk)
    BEGIN
        IF tb_clk'EVENT AND tb_clk = '1' THEN
            IF tb_o_mem_en = '1' THEN
                IF tb_o_mem_we = '1' THEN
                    RAM(to_integer(unsigned(tb_o_mem_addr))) <= tb_o_mem_data AFTER 1 ns;
                    tb_i_mem_data <= tb_o_mem_data AFTER 1 ns;
                ELSE
                    tb_i_mem_data <= RAM(to_integer(unsigned(tb_o_mem_addr))) AFTER 1 ns;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Scambio segnali memoria
    memory_signal_swapper : PROCESS(memory_control, init_o_mem_addr, init_o_mem_data, init_o_mem_en, init_o_mem_we, 
                                    exc_o_mem_addr, exc_o_mem_data, exc_o_mem_en, exc_o_mem_we)
    BEGIN
        tb_o_mem_addr <= init_o_mem_addr;
        tb_o_mem_data <= init_o_mem_data;
        tb_o_mem_en   <= init_o_mem_en;
        tb_o_mem_we   <= init_o_mem_we;

        IF memory_control = '1' THEN
            tb_o_mem_addr <= exc_o_mem_addr;
            tb_o_mem_data <= exc_o_mem_data;
            tb_o_mem_en   <= exc_o_mem_en;
            tb_o_mem_we   <= exc_o_mem_we;
        END IF;
    END PROCESS;

    -- Generazione scenario iniziale
    create_scenario : PROCESS
    BEGIN
        WAIT FOR 50 ns;

        -- Inizializzazione segnali e reset del componente
        tb_start <= '0';
        tb_add <= (OTHERS => '0');
        tb_k   <= (OTHERS => '0');
        tb_rst <= '1';

        -- Attendere un po' di tempo per il reset
        WAIT FOR 50 ns;

        tb_rst <= '0';
        memory_control <= '0';  -- Memoria controllata dal testbench

        -- Skew dei segnali del testbench rispetto al clock
        WAIT UNTIL FALLING_EDGE(tb_clk);

        -- Configurazione della memoria
        FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
            init_o_mem_addr <= std_logic_vector(to_unsigned(SCENARIO_ADDRESS + i, 16));
            init_o_mem_data <= std_logic_vector(to_unsigned(scenario_input(i), 8));
            init_o_mem_en   <= '1';
            init_o_mem_we   <= '1';
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT UNTIL FALLING_EDGE(tb_clk);

        -- Passaggio del controllo memoria al componente
        memory_control <= '1';

        -- Configurazione dei segnali di input per il componente
        tb_add <= std_logic_vector(to_unsigned(SCENARIO_ADDRESS, 16));
        tb_k   <= std_logic_vector(to_unsigned(SCENARIO_LENGTH, 10));
        tb_start <= '1';

        -- Dopo 20 cicli di clock, esegui un reset intermedio
        FOR i IN 0 TO 20 LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT UNTIL FALLING_EDGE(tb_clk);
        tb_rst <= '1';

        WAIT FOR 10 ns;
        tb_start <= '0';
        WAIT FOR 25 ns;
        tb_rst <= '0';

        -- Configurazione del secondo scenario
        memory_control <= '0';
        WAIT UNTIL FALLING_EDGE(tb_clk);

        FOR i IN 0 TO SCENARIO2_LENGTH * 2 - 1 LOOP
            init_o_mem_addr <= std_logic_vector(to_unsigned(SCENARIO2_ADDRESS + i, 16));
            init_o_mem_data <= std_logic_vector(to_unsigned(scenario2_input(i), 8));
            init_o_mem_en   <= '1';
            init_o_mem_we   <= '1';
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT UNTIL FALLING_EDGE(tb_clk);
        memory_control <= '1';

        tb_add <= std_logic_vector(to_unsigned(SCENARIO2_ADDRESS, 16));
        tb_k   <= std_logic_vector(to_unsigned(SCENARIO2_LENGTH, 10));
        tb_start <= '1';

        -- Attendi che il componente completi l'elaborazione
        WHILE tb_done /= '1' LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT FOR 5 ns;
        tb_start <= '0';

        WAIT; -- Terminazione della simulazione
    END PROCESS;

    -- Routine di verifica
    test_routine : PROCESS
    BEGIN

        WAIT UNTIL tb_rst = '1';
        WAIT FOR 25 ns;
        ASSERT tb_done = '0' REPORT "TEST FALLITO o_done !=0 during reset" SEVERITY FAILURE;
        WAIT UNTIL tb_rst = '0';

        WAIT UNTIL FALLING_EDGE(tb_clk);
        ASSERT tb_done = '0' REPORT "TEST FALLITO o_done !=0 after reset before start" SEVERITY FAILURE;

        WAIT UNTIL RISING_EDGE(tb_start);

        WAIT UNTIL tb_rst = '1';
        WAIT FOR 25 ns;
        ASSERT tb_done = '0' REPORT "TEST FALLITO o_done !=0 during mid reset" SEVERITY FAILURE;
        WAIT UNTIL tb_rst = '0';

        WAIT UNTIL FALLING_EDGE(tb_clk);
        ASSERT tb_done = '0' REPORT "TEST FALLITO o_done !=0 after mid reset before start" SEVERITY FAILURE;

        -- Fine del primo scenario (reset intermedio)

        WAIT UNTIL RISING_EDGE(tb_start);
        ASSERT tb_done = '0' REPORT "TEST FALLITO o_done != 0 after 2nd start" SEVERITY FAILURE;

        WHILE tb_done /= '1' LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        ASSERT tb_o_mem_en = '0' OR tb_o_mem_we = '0' 
            REPORT "TEST FALLITO o_mem_en !=0 memory should not be written after done. (2nd scenario)" SEVERITY FAILURE;

        FOR i IN 0 TO SCENARIO2_LENGTH * 2 - 1 LOOP
            ASSERT RAM(SCENARIO2_ADDRESS + i) = std_logic_vector(to_unsigned(scenario2_full(i), 8))
                REPORT "TEST (2nd) FALLITO @ OFFSET=" & INTEGER'IMAGE(i) & 
                       " expected= " & INTEGER'IMAGE(scenario2_full(i)) & 
                       " actual=" & INTEGER'IMAGE(to_integer(unsigned(RAM(SCENARIO2_ADDRESS + i)))) SEVERITY FAILURE;
        END LOOP;

        WAIT UNTIL FALLING_EDGE(tb_start);
        ASSERT tb_done = '1' REPORT "TEST FALLITO o_done !=0 after reset before start (2nd scenario)" SEVERITY FAILURE;
        WAIT UNTIL FALLING_EDGE(tb_done);

        ASSERT FALSE REPORT "Simulation Ended! TEST PASSATO (2 SCENARIOS with mid reset)" SEVERITY FAILURE;
    END PROCESS;

END ARCHITECTURE;