library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM_4K is
    port (
        Clk         : in  std_logic;
        Address_In  : in  std_logic_vector(11 downto 0); -- 12-bit Address (from AR/PC)
        Data_In     : in  std_logic_vector(15 downto 0); -- Data to write
        Data_Out    : out std_logic_vector(15 downto 0); -- Data read
        WE_n        : in  std_logic -- Write Enable (Active Low)
    );
end RAM_4K;

architecture Behavioral of RAM_4K is
    --
    type Memory_Array is array (0 to 4095) of std_logic_vector(15 downto 0);  -- 16 bits memory 
    --signal RAM : Memory_Array := (others => (others => '0'));	
	-- A program in the Ram to execute during the simulations
	/*
	ORG 0
	LDA NUM1
	ADD NUM2
	OUT
	HLT

	ORG 10
	NUM1, DEC 3
	NUM2, DEC 5

	*/
	signal RAM : Memory_Array := (
    0  => "0010000000001010", -- LDA 10
    1  => "0001000000001011", -- ADD 11
    2  => "1111000000000000", -- OUT
    3  => "1110000000000001", -- HLT

    10 => "0000000000000011", -- NUM1 = 3
    11 => "0000000000000101", -- NUM2 = 5


    others => (others => '0')
);

begin

    -- 
    Data_Out <= RAM(to_integer(unsigned(Address_In)));	   -- Write the 

    -- 
    process(Clk)
    begin
        if rising_edge(Clk) then
            if WE_n = '0' then --  this means that write is disabled and the data is loaded on the RAM
                RAM(to_integer(unsigned(Address_In))) <= Data_In;
            end if;
        end if;
    end process;

end Behavioral;
