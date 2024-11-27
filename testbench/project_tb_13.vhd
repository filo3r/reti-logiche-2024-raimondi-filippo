-------------------------------------------------------------------------
-- Prova Finale di Reti Logiche                                        --
-- Anno Accademico 2023-2024                                           --
-- Politecnico di Milano                                               --
-- Filippo Raimondi                                                    --
-- 10809051                                                            --
-- Testbench 13: Sequenza in memoria più lunga del valore K            --
-------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;

ENTITY project_tb_13 IS
END project_tb_13;

ARCHITECTURE project_tb_13_arch OF project_tb_13 IS

    -- Costanti
    CONSTANT CLOCK_PERIOD : TIME := 20 ns;
    CONSTANT SCENARIO_ADDRESS : INTEGER := 14800;
    CONSTANT SCENARIO_LENGTH : INTEGER := 11;
    CONSTANT K_TRANSMITTED : INTEGER := 9;

    -- Tipi custom
    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
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
    SIGNAL RAM            : ram_type := (OTHERS => "00000000");

    SIGNAL scenario_input : scenario_type := (96, 0, 162, 0, 82, 0, 0, 0, 152, 0, 0, 0, 0, 0, 196, 0, 21, 0, 69, 0, 192, 0);

    SIGNAL scenario_full : scenario_type := (96, 31, 162, 31, 82, 31, 82, 30, 152, 31, 152, 30, 152, 29, 196, 31, 21, 31, 69, 0, 192, 0);

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
        tb_k   <= std_logic_vector(to_unsigned(K_TRANSMITTED, 10));
        tb_start <= '1';

        -- Attendere che il componente completi l'elaborazione
        WHILE tb_done /= '1' LOOP
            WAIT UNTIL RISING_EDGE(tb_clk);
        END LOOP;

        -- Disabilitazione di start
        WAIT FOR 5 ns;
        tb_start <= '0';

        WAIT; -- Terminazione della simulazione
    END PROCESS;

        -- Routine di verifica
        test_routine : PROCESS
        BEGIN
            -- Attendere l'attivazione del reset
            WAIT UNTIL tb_rst = '1';
            WAIT FOR 25 ns;
    
            -- Verifica: o_done deve essere '0' durante il reset
            ASSERT tb_done = '0' REPORT "TEST FALLITO: o_done != 0 durante reset" SEVERITY FAILURE;
    
            -- Attendere la disattivazione del reset
            WAIT UNTIL tb_rst = '0';
    
            -- Verifica: o_done deve essere '0' dopo il reset e prima dello start
            WAIT UNTIL FALLING_EDGE(tb_clk);
            ASSERT tb_done = '0' REPORT "TEST FALLITO: o_done != 0 dopo reset prima di start" SEVERITY FAILURE;
    
            -- Attendere l'attivazione del segnale di start
            WAIT UNTIL RISING_EDGE(tb_start);
    
            -- Attendere il completamento del componente
            WHILE tb_done /= '1' LOOP
                WAIT UNTIL RISING_EDGE(tb_clk);
            END LOOP;
    
            -- Verifica: dopo il completamento, la memoria non deve essere scritta
            ASSERT tb_o_mem_en = '0' OR tb_o_mem_we = '0' REPORT "TEST FALLITO: o_mem_en != 0, la memoria non dovrebbe essere scritta dopo il completamento" SEVERITY FAILURE;
    
            -- Verifica: il contenuto della RAM corrisponde ai dati attesi
            FOR i IN 0 TO SCENARIO_LENGTH * 2 - 1 LOOP
                ASSERT RAM(SCENARIO_ADDRESS + i) = std_logic_vector(to_unsigned(scenario_full(i), 8)) REPORT "TEST FALLITO: OFFSET = " & INTEGER'IMAGE(i) & " ATTESO = " & INTEGER'IMAGE(scenario_full(i)) & " TROVATO = " & INTEGER'IMAGE(to_integer(unsigned(RAM(SCENARIO_ADDRESS + i)))) SEVERITY FAILURE;
            END LOOP;
    
            -- Attendere la disattivazione di start
            WAIT UNTIL FALLING_EDGE(tb_start);
    
            -- Verifica: o_done deve rimanere '1' dopo il completamento
            ASSERT tb_done = '1' REPORT "TEST FALLITO: o_done != 0 dopo reset prima di start" SEVERITY FAILURE;
    
            -- Attendere il termine del segnale o_done
            WAIT UNTIL FALLING_EDGE(tb_done);
    
            -- Segnalazione di successo della simulazione
            ASSERT FALSE REPORT "Simulazione completata! TEST PASSATO" SEVERITY FAILURE;
        END PROCESS;
    
END ARCHITECTURE;