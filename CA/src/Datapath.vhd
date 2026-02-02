library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Datapath is
    Port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;

        -- Control signals
        PC_Load_Ctrl    : in std_logic;
        PC_Inc_Ctrl     : in std_logic;
        AR_Load_Ctrl    : in std_logic;
        DR_Load_Ctrl    : in std_logic;
        AC_Load_Ctrl    : in std_logic;
        IR_Load_Ctrl    : in std_logic;
        TR_Load_Ctrl    : in std_logic;

        ALU_Sel_Out     : in std_logic_vector(2 downto 0);

        -- Data interface
        Data_Bus_In     : in  std_logic_vector(15 downto 0);
        Data_Bus_Out    : out std_logic_vector(15 downto 0);

        Address_Bus_Out : out std_logic_vector(11 downto 0);

        -- Memory data signals
        RAM_Data_In     : in  std_logic_vector(15 downto 0);  -- from RAM to datapath
        RAM_Data_Out    : out std_logic_vector(15 downto 0);  -- from datapath to RAM

        -- ALU flags outputs
        Z_Flag          : out std_logic;
        N_Flag          : out std_logic;
        P_Flag          : out std_logic;
        E_Flag          : out std_logic
    );
end Datapath;

architecture Behavioral of Datapath is

    -- Internal registers
    signal PC   : std_logic_vector(11 downto 0) := (others => '0');
    signal AR   : std_logic_vector(11 downto 0) := (others => '0');
    signal AC   : std_logic_vector(15 downto 0) := (others => '0');
    signal DR   : std_logic_vector(15 downto 0) := (others => '0');
    signal TR   : std_logic_vector(15 downto 0) := (others => '0');
    signal IR   : std_logic_vector(15 downto 0) := (others => '0');

    signal ALU_Result  : std_logic_vector(15 downto 0);
    signal ALU_E_Out   : std_logic;
    signal ALU_Z_Flag  : std_logic;
    signal ALU_N_Flag  : std_logic;
    signal ALU_P_Flag  : std_logic;
    signal ALU_Parity_Flag : std_logic;  -- if required

    -- ALU inputs
    signal ALU_A       : unsigned(15 downto 0);
    signal ALU_B       : unsigned(15 downto 0);

    -- Extend flag for ALU
    signal ALU_E_In    : std_logic := '0';

begin

    -- Address Bus output driven by AR register
    Address_Bus_Out <= AR;

    -- Data Bus output is DR contents (for writes)
    Data_Bus_Out <= DR;

    -- RAM Data Out driven by DR (write data)
    RAM_Data_Out <= DR;

    -- Choose ALU inputs
    ALU_A <= unsigned(AC);
    ALU_B <= unsigned(DR);

    -- ALU instantiation
    ALU_inst : entity work.ALU
        port map (
            A           => ALU_A,
            B           => ALU_B,
            ALU_Sel     => ALU_Sel_Out,
            E_In        => ALU_E_In,
            Result      => ALU_Result,
            E_Out       => ALU_E_Out,
            Z_Flag      => ALU_Z_Flag,
            N_Flag      => ALU_N_Flag,
            P_Flag      => ALU_P_Flag,
            Parity_Flag => open  -- if parity is unused, can be left open
        );

    process(CLK, RESET)
    begin
        if RESET = '1' then
            PC <= (others => '0');
            AR <= (others => '0');
            AC <= (others => '0');
            DR <= (others => '0');
            TR <= (others => '0');
            IR <= (others => '0');
            ALU_E_In <= '0';
        elsif rising_edge(CLK) then
            -- PC increment or load
            if PC_Inc_Ctrl = '1' then
                PC <= std_logic_vector(unsigned(PC) + 1);
            end if;
            if PC_Load_Ctrl = '1' then
                PC <= std_logic_vector(unsigned(Data_Bus_In(11 downto 0)));
            end if;

            -- Load AR from Data_Bus or PC (based on control)
            if AR_Load_Ctrl = '1' then
                AR <= std_logic_vector(unsigned(Data_Bus_In(11 downto 0)));
            end if;

            -- Load DR from RAM data in
            if DR_Load_Ctrl = '1' then
                DR <= RAM_Data_In;
            end if;

            -- Load AC from ALU result
            if AC_Load_Ctrl = '1' then
                AC <= ALU_Result;
            end if;

            -- Load IR from RAM data in
            if IR_Load_Ctrl = '1' then
                IR <= RAM_Data_In;
            end if;

            -- Load TR from ALU result
            if TR_Load_Ctrl = '1' then
                TR <= ALU_Result;
            end if;

            -- Update ALU E flag input with previous output
            ALU_E_In <= ALU_E_Out;

        end if;
    end process;

    -- Output flags
    Z_Flag <= ALU_Z_Flag;
    N_Flag <= ALU_N_Flag;
    P_Flag <= ALU_P_Flag;
    E_Flag <= ALU_E_Out;

end Behavioral;
