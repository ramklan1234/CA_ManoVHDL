--==========================================================
--  Control_Unit.vhd
--  Morris Mano 16-bit Basic Computer Control Unit
--  Includes: Fetch/Decode/Execute Timings, Interrupt & IRET
--==========================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Control_Unit is
    port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;

        -- Interrupts
        INT             : in  std_logic;   -- External interrupt request
        IEN_In          : in  std_logic;   -- Interrupt enable flag

        -- Instruction Register input (from Datapath)
        IR_In           : in  std_logic_vector(15 downto 0);

        -- Status flags from Datapath
        Z_Flag          : in  std_logic;
        N_Flag          : in  std_logic;
        P_Flag          : in  std_logic;
        E_Flag          : in  std_logic;

        -- Control signals output to Datapath
        PC_Load_Ctrl    : out std_logic;
        PC_Inc_Ctrl     : out std_logic;
        AR_Load_Ctrl    : out std_logic;
        DR_Load_Ctrl    : out std_logic;
        AC_Load_Ctrl    : out std_logic;
        IR_Load_Ctrl    : out std_logic;
        TR_Load_Ctrl    : out std_logic;
        RAM_Read_Ctrl   : out std_logic;
        RAM_Write_Ctrl  : out std_logic;
        ALU_Sel_Out     : out std_logic_vector(2 downto 0);

        -- Interrupt enable output
        IEN_Out         : out std_logic;

        -- ISR address for interrupt sequence
        ISR_Address_Out : out std_logic_vector(11 downto 0)
    );
end Control_Unit;

architecture Behavioral of Control_Unit is

    -------------------------------------------------
    -- Type and signal declarations
    -------------------------------------------------
    type T_State_Type is (T0, T1, T2, EXEC, INT_SEQ, IRET_SEQ);
    signal Current_State, Next_State : T_State_Type;

    signal Opcode      : std_logic_vector(3 downto 0);
    signal I_Flag      : std_logic; -- indirect address flag IR(15)
    signal INT_Active  : std_logic := '0';
    signal IEN_Reg     : std_logic := '0';

begin

    --=======================================================
    -- Decode Opcode and indirect flag
    --=======================================================
    Opcode  <= IR_In(14 downto 11);  -- main opcode field
    I_Flag  <= IR_In(15);            -- indirect addressing indicator

    ISR_Address_Out <= x"001";       -- Fixed ISR memory address (interrupt vector)

    -------------------------------------------------
    -- 1. Sequential process for state transitions
    -------------------------------------------------
    process(CLK, RESET)
    begin
        if RESET = '1' then
            Current_State <= T0;
            IEN_Reg <= '0';
        elsif rising_edge(CLK) then
            -- Interrupt detection logic
            if INT = '1' and IEN_In = '1' and (Current_State = EXEC) then
                Current_State <= INT_SEQ;
            else
                Current_State <= Next_State;
            end if;
        end if;
    end process;


    -------------------------------------------------
    -- 2. Next state combinational logic
    -------------------------------------------------
    process(Current_State, Opcode)
    begin
        Next_State <= T0; -- default next
        case Current_State is
            when T0 =>
                Next_State <= T1;
            when T1 =>
                Next_State <= T2;
            when T2 =>
                Next_State <= EXEC;
            when EXEC =>
                Next_State <= T0;
            when INT_SEQ =>
                Next_State <= T0;
            when IRET_SEQ =>
                Next_State <= T0;
            when others =>
                Next_State <= T0;
        end case;
    end process;


    -------------------------------------------------
    -- 3. Control signal generation
    -------------------------------------------------
    process(Current_State, Opcode, INT, IEN_Reg)
    begin
        -- Default values (inactive)
        PC_Load_Ctrl <= '0';
        PC_Inc_Ctrl  <= '0';
        AR_Load_Ctrl <= '0';
        DR_Load_Ctrl <= '0';
        AC_Load_Ctrl <= '0';
        IR_Load_Ctrl <= '0';
        TR_Load_Ctrl <= '0';
        RAM_Read_Ctrl  <= '0';
        RAM_Write_Ctrl <= '0';
        ALU_Sel_Out    <= "000";
        IEN_Out        <= IEN_Reg;

        case Current_State is

            -------------------------------------------------
            -- Fetch Phase
            -------------------------------------------------
            when T0 =>
                AR_Load_Ctrl <= '1';      -- AR <- PC
                PC_Inc_Ctrl  <= '1';      -- PC <- PC + 1
                RAM_Read_Ctrl <= '1';     -- initiate memory read

            when T1 =>
                IR_Load_Ctrl <= '1';      -- IR <- M[AR]
                RAM_Read_Ctrl <= '1';     -- continue reading
                AR_Load_Ctrl <= '0';

            -------------------------------------------------
            -- Decode and Execute Phase
            -------------------------------------------------
            when EXEC =>
                -- Opcode-based control mapping
                case Opcode is
                    when "0000" => -- ADD
                        ALU_Sel_Out <= "001"; -- ALU ADD
                        AC_Load_Ctrl <= '1';
                        DR_Load_Ctrl <= '1';
                    when "0001" => -- AND
                        ALU_Sel_Out <= "000"; -- ALU AND
                        AC_Load_Ctrl <= '1';
                    when "0010" => -- LDA
                        RAM_Read_Ctrl <= '1';
                        AC_Load_Ctrl  <= '1';
                    when "0011" => -- STA
                        RAM_Write_Ctrl <= '1';
                    when "0100" => -- ISZ (Increment and Skip if zero)
                        ALU_Sel_Out <= "011"; -- INC
                        DR_Load_Ctrl <= '1';
                        -- skip logic handled via Z_Flag in CU if integrated later
                    when "0101" => -- BUN (Branch Unconditional)
                        PC_Load_Ctrl <= '1';
                    when "0110" => -- BSA (Branch and Save Return Address)
                        TR_Load_Ctrl <= '1'; -- Save PC to TR
                        RAM_Write_Ctrl <= '1';
                    when "0111" => -- I/O instructions (represented abstractly)
                        null;
                    when others =>
                        null;
                end case;

            -------------------------------------------------
            -- Interrupt Sequence (Single-Level)
            -------------------------------------------------
            when INT_SEQ =>
                IEN_Out <= '0';           -- Disable further interrupts
                TR_Load_Ctrl <= '1';      -- TR <- PC
                AR_Load_Ctrl <= '1';
                RAM_Write_Ctrl <= '1';    -- Save PC to M[0001h]
                PC_Load_Ctrl <= '1';      -- PC <- 0001h (ISR start)

            -------------------------------------------------
            -- Interrupt Return Sequence (IRET)
            -------------------------------------------------
            when IRET_SEQ =>
                AR_Load_Ctrl <= '1';      -- AR <- 0001h
                RAM_Read_Ctrl <= '1';     -- Read PC back from M[0001h]
                PC_Load_Ctrl <= '1';      -- Restore PC from ISR storage
                IEN_Out <= '1';           -- Re-enable interrupt system

            when others =>
                null;
        end case;
    end process;

end Behavioral;
