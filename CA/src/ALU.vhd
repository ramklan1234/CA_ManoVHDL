library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    port (
        A, B        : in  unsigned(15 downto 0);  -- Inputs from AC and Bus/DR
        ALU_Sel     : in  std_logic_vector(2 downto 0);   -- Operation selector
        E_In        : in  std_logic;                      -- Carry/Extend flag input
        Result      : out std_logic_vector(15 downto 0);  -- ALU result
        E_Out       : out std_logic;                      -- Carry/Extend flag output
        Z_Flag      : out std_logic;                      -- Zero flag
        N_Flag      : out std_logic;                      -- Negative flag
        P_Flag      : out std_logic;                      -- Positive flag
        Parity_Flag : out std_logic                       -- Even parity flag
    );
end ALU;

architecture Behavioral of ALU is

    signal temp_result : unsigned(16 downto 0);
    signal shifted     : std_logic_vector(15 downto 0);
    signal result_int  : std_logic_vector(15 downto 0);  -- Internal signal for Result

    -- Helper function: even parity calculation
    function calc_even_parity(data : std_logic_vector) return std_logic is
        variable count : integer := 0;
    begin
        for i in data'range loop
            if data(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        if (count mod 2) = 0 then
            return '1';
        else
            return '0';
        end if;
    end function calc_even_parity;

begin

    process(A, B, ALU_Sel, E_In)
        variable temp_sum : unsigned(16 downto 0);
        variable temp_a   : unsigned(15 downto 0);
        variable temp_b   : unsigned(15 downto 0);
    begin
        temp_a := A;
        temp_b := B;
        E_Out  <= E_In;   -- default, may update later
        result_int <= (others => '0');

        case ALU_Sel is

            when "000" =>  -- ADD
                temp_sum := ('0' & temp_a) + ('0' & temp_b);
                result_int <= std_logic_vector(temp_sum(15 downto 0));
                E_Out    <= temp_sum(16);  -- Carry out

            when "001" =>  -- AND
                result_int <= std_logic_vector(temp_a and temp_b);
                E_Out  <= '0';

            when "010" =>  -- CMA (Complement A)
                result_int <= std_logic_vector(not temp_a);
                E_Out  <= E_In; -- unchanged

            when "011" =>  -- INC (Increment A)
                temp_sum := ('0' & temp_a) + 1;
                result_int <= std_logic_vector(temp_sum(15 downto 0));
                E_Out    <= temp_sum(16);

            when "100" =>  -- CIR (Rotate right with E)
                shifted(14 downto 0) <= std_logic_vector(A(15 downto 1));
                shifted(15)          <= E_In;  -- E shifts into MSB
                result_int           <= shifted;
                E_Out                <= A(0);  -- LSB moves into E

            when "101" =>  -- CIL (Rotate left with E)
                shifted(15 downto 1) <= std_logic_vector(A(14 downto 0));
                shifted(0)           <= E_In;  -- E into LSB
                result_int           <= shifted;
                E_Out                <= A(15); -- MSB moves into E

            when "110" =>  -- PASSB (Pass input B through)
                result_int <= std_logic_vector(B);
                E_Out  <= E_In;

            when others =>  -- NOP / undefined operation
                result_int <= (others => '0');
                E_Out  <= E_In;										

        end case;
    end process;

    -- Connect internal signal to output port
    Result <= result_int;

    -- Status Flags generation (using result_int)
    Z_Flag      <= '1' when result_int = (result_int'range => '0') else '0';
    N_Flag      <= result_int(15);                    -- Negative flag = MSB
    P_Flag      <= not result_int(15);                -- Positive flag
    Parity_Flag <= calc_even_parity(result_int);      -- Even parity

end Behavioral;
