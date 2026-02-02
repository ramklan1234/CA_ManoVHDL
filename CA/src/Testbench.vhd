-- =============================================================================
-- Testbench.vhd
-- Testbench for Morris_Computer_Top (16-bit Basic Computer + Interrupt)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Testbench is
end Testbench;

architecture Behavioral of Testbench is

    -----------------------------------------------------------------------
    --  Component Declaration for the Unit Under Test (UUT)
    -----------------------------------------------------------------------
    component Morris_Computer_Top is
        port (
            CLK         : in  std_logic;
            RESET       : in  std_logic;
            INT_In      : in  std_logic;                           -- Interrupt Request
            INPR_In     : in  std_logic_vector(7 downto 0);        -- External input
            OUTR_Out    : out std_logic_vector(7 downto 0)         -- External output
        );
    end component;

    -----------------------------------------------------------------------
    --  Signal Declarations
    -----------------------------------------------------------------------
    constant CLK_PERIOD : time := 20 ns;                          -- Clock period
    signal Clk_s        : std_logic := '0';                      -- Clock signal
    signal Reset_s      : std_logic := '1';                      -- Reset signal
    signal INT_Signal_s : std_logic := '0';                      -- Interrupt signal
    signal Data_In_IO_s : std_logic_vector(7 downto 0) := (others => '0'); -- Input Data
    signal Data_Out_IO_s: std_logic_vector(7 downto 0);          -- Output Data

begin

    -----------------------------------------------------------------------
    --  Clock Generation Process (Always Running)
    -----------------------------------------------------------------------
    Clock_Process : process
    begin
        while true loop
            Clk_s <= '0';
            wait for CLK_PERIOD / 2;
            Clk_s <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process Clock_Process;

    -----------------------------------------------------------------------
    --  Instantiate UUT
    -----------------------------------------------------------------------
    UUT: Morris_Computer_Top
        port map (
            CLK         => Clk_s,
            RESET       => Reset_s,
            INT_In      => INT_Signal_s,
            INPR_In     => Data_In_IO_s,
            OUTR_Out    => Data_Out_IO_s
        );

    -----------------------------------------------------------------------
    --  Stimulus / Test procedure process
    -----------------------------------------------------------------------
    Stimulus_Process : process
    begin
        -- Step 0: Initialization
        report "--- Starting simulation. System in reset ---" severity note;
        Reset_s <= '1'; -- Assert Reset
        wait for CLK_PERIOD * 5;

        -- Step 1: Release Reset
        report "--- Releasing reset to start CPU program execution ---" severity note;
        Reset_s <= '0'; -- Release Reset
        wait for CLK_PERIOD * 50;

        -- Step 2: Simulate Normal CPU Run
        report "--- CPU running normal program ---" severity note;
        Data_In_IO_s <= X"3A"; -- Simulate an external input
        wait for CLK_PERIOD * 120;

        -- Step 3: Trigger Interrupt
        report "--- Triggering interrupt (setting INT_Signal high) ---" severity note;
        INT_Signal_s <= '1';
        wait for CLK_PERIOD * 10;
        INT_Signal_s <= '0';

        wait for CLK_PERIOD * 100; -- Wait for more cycles

        -- Step 4: Final Output
        report "--- Final output captured (see waveform) ---" severity note;

        -- Step 5: End Simulation
        wait;
    end process Stimulus_Process;

end Behavioral;
