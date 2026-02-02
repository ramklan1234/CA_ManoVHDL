--==========================================================
--  Morris_Computer_Top.vhd  (Final Corrected Version)
--  Morris Mano Basic Computer (16-bit) with Single-Level Interrupt
--==========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Morris_Computer_Top is
    Port (
        CLK         : in  std_logic;
        RESET       : in  std_logic;

        -- I/O interface
        INPR_In     : in  std_logic_vector(7 downto 0);   -- input register
        OUTR_Out    : out std_logic_vector(7 downto 0);   -- output register

        -- Interrupt line
        INT_In      : in  std_logic
    );
end Morris_Computer_Top;

architecture Structural of Morris_Computer_Top is

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal s_Data_Bus        : std_logic_vector(15 downto 0);
    signal s_Address_Bus     : std_logic_vector(11 downto 0);

    -- RAM signals
    signal s_RAM_Data_In     : std_logic_vector(15 downto 0);
    signal s_RAM_Data_Out    : std_logic_vector(15 downto 0);
    signal s_RAM_WE_n        : std_logic;

    -- Control from CU to Datapath
    signal s_PC_Load_Ctrl    : std_logic;
    signal s_PC_Inc_Ctrl     : std_logic;
    signal s_AR_Load_Ctrl    : std_logic;
    signal s_DR_Load_Ctrl    : std_logic;
    signal s_AC_Load_Ctrl    : std_logic;
    signal s_IR_Load_Ctrl    : std_logic;
    signal s_TR_Load_Ctrl    : std_logic;
    signal s_ALU_Sel_Out     : std_logic_vector(2 downto 0);

    signal s_IEN             : std_logic;
    signal s_ISR_Address     : std_logic_vector(11 downto 0);

    -- CU–RAM control
    signal s_RAM_Read_Ctrl   : std_logic;
    signal s_RAM_Write_Ctrl  : std_logic;

    -- Datapath flags to CU
    signal s_Z_Flag, s_N_Flag, s_P_Flag, s_E_Flag : std_logic;

begin

    --------------------------------------------------------------------
    --  RAM 4Kx16
    --------------------------------------------------------------------
    U_RAM : entity work.RAM_4K
        port map (
            Clk        => CLK,
            Address_In => s_Address_Bus,
            Data_In    => s_RAM_Data_In,
            Data_Out   => s_RAM_Data_Out,
            WE_n       => s_RAM_WE_n
        );

    --------------------------------------------------------------------
    --  Datapath
    --------------------------------------------------------------------
    U_DATAPATH : entity work.Datapath
        port map (
            CLK             => CLK,
            RESET           => RESET,

            -- Memory interface
            Data_Bus_In     => s_Data_Bus,
            Data_Bus_Out    => s_RAM_Data_In,
            Address_Bus_Out => s_Address_Bus,
            RAM_Data_In     => s_RAM_Data_Out,
            RAM_Data_Out    => open,      -- not used directly at top

            -- Control signals
            PC_Load_Ctrl    => s_PC_Load_Ctrl,
            PC_Inc_Ctrl     => s_PC_Inc_Ctrl,
            AR_Load_Ctrl    => s_AR_Load_Ctrl,
            DR_Load_Ctrl    => s_DR_Load_Ctrl,
            AC_Load_Ctrl    => s_AC_Load_Ctrl,
            IR_Load_Ctrl    => s_IR_Load_Ctrl,
            TR_Load_Ctrl    => s_TR_Load_Ctrl,
            ALU_Sel_Out     => s_ALU_Sel_Out,

            -- Flags
            Z_Flag          => s_Z_Flag,
            N_Flag          => s_N_Flag,
            P_Flag          => s_P_Flag,
            E_Flag          => s_E_Flag
        );

    --------------------------------------------------------------------
    --  Control Unit
    --------------------------------------------------------------------
    U_CONTROL : entity work.Control_Unit
        port map (
            CLK             => CLK,
            RESET           => RESET,

            -- Interrupts
            INT             => INT_In,
            IEN_In          => s_IEN,

            -- Instruction register contents from datapath (simplified demo)
            IR_In           => s_RAM_Data_Out,

            -- Flags
            Z_Flag          => s_Z_Flag,
            N_Flag          => s_N_Flag,
            P_Flag          => s_P_Flag,
            E_Flag          => s_E_Flag,

            -- Control outputs
            PC_Load_Ctrl    => s_PC_Load_Ctrl,
            PC_Inc_Ctrl     => s_PC_Inc_Ctrl,
            AR_Load_Ctrl    => s_AR_Load_Ctrl,
            DR_Load_Ctrl    => s_DR_Load_Ctrl,
            AC_Load_Ctrl    => s_AC_Load_Ctrl,
            IR_Load_Ctrl    => s_IR_Load_Ctrl,
            TR_Load_Ctrl    => s_TR_Load_Ctrl,
            RAM_Read_Ctrl   => s_RAM_Read_Ctrl,
            RAM_Write_Ctrl  => s_RAM_Write_Ctrl,
            ALU_Sel_Out     => s_ALU_Sel_Out,
            IEN_Out         => s_IEN,
            ISR_Address_Out => s_ISR_Address
        );

    --------------------------------------------------------------------
    --  BUS and memory arbitration
    --------------------------------------------------------------------
    -- RAM write enable control (active LOW)
    s_RAM_WE_n <= not s_RAM_Write_Ctrl;

    -- Data bus direction: read from RAM when read control is high
    s_Data_Bus <= s_RAM_Data_Out when s_RAM_Read_Ctrl = '1' else (others => 'Z');

end Structural;
