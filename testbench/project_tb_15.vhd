-------------------------------------------------------------------------
-- Prova Finale di Reti Logiche                                        --
-- Anno Accademico 2023-2024                                           --
-- Politecnico di Milano                                               --
-- Filippo Raimondi                                                    --
-- 10809051                                                            --
-- Testbench 15: Elaborazione di due sequenze di seguito senza reset   --
-------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;

ENTITY project_tb_15 IS
END project_tb_15;

ARCHITECTURE project_tb_15_arch OF project_tb_15 IS

    -- Costanti
    CONSTANT CLOCK_PERIOD        : TIME := 20 ns;
    CONSTANT SCENARIO_LENGTH     : INTEGER := 16;
    CONSTANT SCENARIO_ADDRESS_1  : INTEGER := 1000;
    CONSTANT SCENARIO_ADDRESS_2  : INTEGER := 6000;

    -- Tipi custom
    TYPE ram_type IS ARRAY (0 TO 65535) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE scenario_type IS ARRAY (0 TO SCENARIO_LENGTH * 2 - 1) OF INTEGER;

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
    SIGNAL RAM            : ram_type := (OTHERS => (OTHERS => '0'));

    -- Sequenze di input per le due elaborazioni
    SIGNAL scenario_input_1 : scenario_type :=
        (235, 0, 0, 0, 0, 0, 0, 0, 0, 0, 51, 0, 63, 0, 247, 0,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 134, 0, 124, 0, 0, 0);

    SIGNAL scenario_full_1 : scenario_type :=
        (235, 31, 235, 30, 235, 29, 235, 28, 235, 27, 51, 31,
         63, 31, 247, 31, 247, 30, 247, 29, 247, 28, 247, 27,
         247, 26, 134, 31, 124, 31, 124, 30);

    SIGNAL scenario_input_2 : scenario_type :=
        (87, 0, 0, 0, 4, 0, 175, 0, 88, 0, 0, 0, 0, 0, 0, 0,
         51, 0, 40, 0, 224, 0, 0, 0, 194, 0, 0, 0, 35, 0, 0, 0);

    SIGNAL scenario_full_2 : scenario_type :=
        (87, 31, 87, 30, 4, 31, 175, 31, 88, 31, 88, 30, 88, 29,
         88, 28, 51, 31, 40, 31, 224, 31, 224, 30, 194, 31,
         194, 30, 35, 31, 35, 30);

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
    END COMPONENT;

BEGIN

    -- Istanza del DUT
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
                    RAM(to_integer(unsigned(tb_o_mem_addr)))
                        <= tb_o_mem_data AFTER 1 ns;
                    tb_i_mem_data <= tb_o_mem_data AFTER 1 ns;
                ELSE
                    tb_i_mem_data <= RAM(to_integer(
                        unsigned(tb_o_mem_addr))) AFTER 1 ns;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Scambio segnali memoria
    memory_signal_swapper : PROCESS(memory_control, init_o_mem_addr,
        init_o_mem_data, init_o_mem_en, init_o_mem_we,
        exc_o_mem_addr, exc_o_mem_data, exc_o_mem_en, exc_o_mem_we)
    BEGIN
        IF memory_control = '0' THEN
            tb_o_mem_addr <= init_o_mem_addr;
            tb_o_mem_data <= init_o_mem_data;
            tb_o_mem_en   <= init_o_mem_en;
            tb_o_mem_we   <= init_o_mem_we;
        ELSE
            tb_o_mem_addr <= exc_o_mem_addr;
            tb_o_mem_data <= exc_o_mem_data;
            tb_o_mem_en   <= exc_o_mem_en;
            tb_o_mem_we   <= exc_o_mem_we;
        END IF;
    END PROCESS;

    -- Processo di test principale
    test_process : PROCESS
    BEGIN
        -- Inizializzazione
        tb_rst   <= '1';
        tb_start <= '0';
        tb_add   <= (OTHERS => '0');
        tb_k     <= (OTHERS => '0');
        WAIT FOR 25 ns;  -- Attesa per garantire il reset

        -- Verifica: o_done deve essere '0' durante il reset
        ASSERT tb_done = '0' REPORT "TEST FALLITO: o_done != 0 durante reset"
            SEVERITY FAILURE;

        WAIT FOR 25 ns;  -- Ulteriore attesa durante il reset

        tb_rst <= '0';
        WAIT UNTIL FALLING_EDGE(tb_clk);

        -- Verifica: o_done deve essere '0' dopo il reset e prima dello start
        ASSERT tb_done = '0' REPORT "TEST FALLITO: o_done != 0 dopo reset prima di start"
            SEVERITY FAILURE;

        -- Inizializzazione della memoria
        memory_control <= '0';  -- Memoria controllata dal testbench
        WAIT UNTIL FALLING_EDGE(tb_clk);

        -- Scrittura della prima sequenza nella memoria
        FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
            init_o_mem_addr <= std_logic_vector(to_unsigned(
                SCENARIO_ADDRESS_1 + i, 16));
            init_o_mem_data <= std_logic_vector(to_unsigned(
                scenario_input_1(i), 8));
            init_o_mem_en   <= '1';
            init_o_mem_we   <= '1';
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        -- Scrittura della seconda sequenza nella memoria
        FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
            init_o_mem_addr <= std_logic_vector(to_unsigned(
                SCENARIO_ADDRESS_2 + i, 16));
            init_o_mem_data <= std_logic_vector(to_unsigned(
                scenario_input_2(i), 8));
            init_o_mem_en   <= '1';
            init_o_mem_we   <= '1';
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        -- Fine inizializzazione memoria
        WAIT UNTIL FALLING_EDGE(tb_clk);
        memory_control <= '1';  -- Controllo memoria al componente

        -- Prima elaborazione con START=1 e RESET
        tb_add   <= std_logic_vector(to_unsigned(
            SCENARIO_ADDRESS_1, 16));
        tb_k     <= std_logic_vector(to_unsigned(
            SCENARIO_LENGTH, 10));
        tb_start <= '1';
        WAIT UNTIL RISING_EDGE(tb_clk);  -- Sincronizza con il clock

        -- Attendere che o_done diventi '1' sincronizzato con il clock
        WHILE tb_done /= '1' LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT FOR 10 ns;

        tb_start <= '0';
        WAIT UNTIL RISING_EDGE(tb_clk);

        -- Verifica: o_done deve rimanere '1' dopo il completamento
        ASSERT tb_done = '1' REPORT "TEST FALLITO: o_done != 1 dopo il completamento della prima elaborazione"
            SEVERITY FAILURE;

        -- Attendere il termine del segnale o_done
        WAIT UNTIL FALLING_EDGE(tb_done);

        -- Verifica del contenuto della memoria per la prima sequenza
        FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
            ASSERT RAM(SCENARIO_ADDRESS_1 + i) = std_logic_vector(
                to_unsigned(scenario_full_1(i), 8))
                REPORT "TEST FALLITO: Prima Sequenza - Indirizzo " &
                INTEGER'IMAGE(SCENARIO_ADDRESS_1 + i) & " ATTESO: " &
                INTEGER'IMAGE(scenario_full_1(i)) & " TROVATO: " &
                INTEGER'IMAGE(to_integer(unsigned(
                RAM(SCENARIO_ADDRESS_1 + i)))) SEVERITY FAILURE;
        END LOOP;

        -- Seconda elaborazione senza RESET, solo con START=1
        tb_add   <= std_logic_vector(to_unsigned(
            SCENARIO_ADDRESS_2, 16));
        tb_k     <= std_logic_vector(to_unsigned(
            SCENARIO_LENGTH, 10));
        tb_start <= '1';
        WAIT UNTIL RISING_EDGE(tb_clk);  -- Sincronizza con il clock

        -- Attendere che o_done diventi '1' sincronizzato con il clock
        WHILE tb_done /= '1' LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        WAIT FOR 10 ns;

        tb_start <= '0';
        WAIT UNTIL RISING_EDGE(tb_clk);

        -- Verifica: o_done deve rimanere '1' dopo il completamento
        ASSERT tb_done = '1' REPORT "TEST FALLITO: o_done != 1 dopo il completamento della seconda elaborazione"
            SEVERITY FAILURE;

        -- Attendere il termine del segnale o_done
        WAIT UNTIL FALLING_EDGE(tb_done);

        -- Verifica del contenuto della memoria per la seconda sequenza
        FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
            ASSERT RAM(SCENARIO_ADDRESS_2 + i) = std_logic_vector(
                to_unsigned(scenario_full_2(i), 8))
                REPORT "TEST FALLITO: Seconda Sequenza - Indirizzo " &
                INTEGER'IMAGE(SCENARIO_ADDRESS_2 + i) & " ATTESO: " &
                INTEGER'IMAGE(scenario_full_2(i)) & " TROVATO: " &
                INTEGER'IMAGE(to_integer(unsigned(
                RAM(SCENARIO_ADDRESS_2 + i)))) SEVERITY FAILURE;
        END LOOP;

        -- Verifica che la memoria non sia scritta dopo il completamento
        ASSERT tb_o_mem_en = '0' OR tb_o_mem_we = '0'
            REPORT "TEST FALLITO: o_mem_en o o_mem_we attivi dopo il completamento"
            SEVERITY FAILURE;

        -- Fine della simulazione
        ASSERT FALSE REPORT "Simulazione completata con successo! TEST PASSATO"
            SEVERITY FAILURE;

        WAIT;  -- Termina la simulazione
    END PROCESS;

END ARCHITECTURE;