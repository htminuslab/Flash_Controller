---------------------------------------------------------------------------------------------------
--  Gowin Flash Controller                                                                           
--                                        
--  https://github.com/htminuslab         
---------------------------------------------------------------------------------------------------
--              
---------------------------------------------------------------------------------------------------
--
--	Top Level
--  Instantiate controller and flash primitive
-- 
--  Revision History:                                                        
--                                                                           
--  Date:          Revision         Author         
--  08-Jan-2022    0.1				Hans Tiggeler 
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FlashCTRL_Top IS
   PORT( 
      ADDR     : IN     std_logic_vector (17 DOWNTO 0);
      CLK      : IN     std_logic;
      CS       : IN     std_logic;
      CSUNLOCK : IN     std_logic;
      DBUSI    : IN     std_logic_vector (31 DOWNTO 0);
      RESETN   : IN     std_logic;
      WR       : IN     std_logic;
      DBUSO    : OUT    std_logic_vector (31 DOWNTO 0);
      READY    : OUT    std_logic);
END ENTITY FlashCTRL_Top ;

ARCHITECTURE struct OF FlashCTRL_Top IS

   -- Internal signal declarations
   SIGNAL dbusi_flash : std_logic_vector(31 DOWNTO 0);
   SIGNAL dbuso_flash : std_logic_vector(31 DOWNTO 0);
   SIGNAL erase       : std_logic;
   SIGNAL nvstr       : std_logic;
   SIGNAL prog        : std_logic;
   SIGNAL se          : std_logic;
   SIGNAL xadr        : std_logic_vector(8 DOWNTO 0);
   SIGNAL xe          : std_logic;
   SIGNAL yadr        : std_logic_vector(5 DOWNTO 0);
   SIGNAL ye          : std_logic;


	-- Component Declarations
	COMPONENT FlashCTRL
	PORT (
		ADDR     : IN     std_logic_vector (17 DOWNTO 0);
		CLK      : IN     std_logic;
		CS       : IN     std_logic;
		CSUNLOCK : IN     std_logic;
		DBUSI    : IN     std_logic_vector (31 DOWNTO 0);
		DIN      : IN     std_logic_vector (31 DOWNTO 0);
		RESETN   : IN     std_logic;
		WR       : IN     std_logic;
		DBUSO    : OUT    std_logic_vector (31 DOWNTO 0);
		DOUT     : OUT    std_logic_vector (31 DOWNTO 0);
		ERASE    : OUT    std_logic;
		NVSTR    : OUT    std_logic;
		PROG     : OUT    std_logic;
		READY    : OUT    std_logic;
		SE       : OUT    std_logic;
		XADR     : OUT    std_logic_vector (8 DOWNTO 0);
		XE       : OUT    std_logic;
		YADR     : OUT    std_logic_vector (5 DOWNTO 0);
		YE       : OUT    std_logic);
	END COMPONENT FlashCTRL;

	component FLASH608K
    port (
        DOUT : out std_logic_vector(31 downto 0);
        XE   : in std_logic;
        YE   : in std_logic;
        SE   : in std_logic;
        PROG : in std_logic;
        ERASE: in std_logic;
        NVSTR: in std_logic;
        XADR : in std_logic_vector(8 downto 0);
        YADR : in std_logic_vector(5 downto 0);
        DIN  : in std_logic_vector(31 downto 0)
    );
    end component;


BEGIN

   U_FCTRL : FlashCTRL
      PORT MAP (
         ADDR     => ADDR,
         CLK      => CLK,
         CS       => CS,
         CSUNLOCK => CSUNLOCK,
         DBUSI    => DBUSI,
         RESETN   => RESETN,
         WR       => WR,
         DIN      => dbuso_flash,
         DOUT     => dbusi_flash,
         DBUSO    => DBUSO,
         ERASE    => erase,
         NVSTR    => nvstr,
         PROG     => prog,
         READY    => READY,
         SE       => se,
         XADR     => xadr,
         XE       => ye,
         YADR     => yadr,
         YE       => xe
      );
   U_FLASH : FLASH608K
      PORT MAP (
         dout  => dbuso_flash,
         xe    => ye,
         ye    => xe,
         se    => se,
         prog  => prog,
         erase => erase,
         nvstr => nvstr,
         xadr  => xadr,
         yadr  => yadr,
         din   => dbusi_flash
      );

END ARCHITECTURE struct;
