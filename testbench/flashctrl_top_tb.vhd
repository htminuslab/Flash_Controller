---------------------------------------------------------------------------------------------------
--  Gowin Flash Controller                                                                           
--                                                                                                                                                
--  HT-Lab                                                                         
---------------------------------------------------------------------------------------------------
--                                                       
---------------------------------------------------------------------------------------------------
--
--  TestBench
-- 
--  Revision History:                                                        
--                                                                           
--  Date:          Revision         Author         
--  08-Jan-2022    0.1              Hans Tiggeler 
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

library std;
use std.env.all;

ENTITY FlashCTRL_Top_tb IS
END ENTITY FlashCTRL_Top_tb ;


ARCHITECTURE struct OF FlashCTRL_Top_tb IS

   -- Internal signal declarations
   SIGNAL ADDR     : std_logic_vector(17 DOWNTO 0);
   SIGNAL CLK      : std_logic;
   SIGNAL CS       : std_logic;
   SIGNAL CSUNLOCK : std_logic;
   SIGNAL DBUSI    : std_logic_vector(31 DOWNTO 0);
   SIGNAL DBUSO    : std_logic_vector(31 DOWNTO 0);
   SIGNAL READY    : std_logic;
   SIGNAL RESETN   : std_logic;
   SIGNAL WR       : std_logic;


   -- Component Declarations
   COMPONENT FlashCTRL_Top
   PORT (
      ADDR     : IN     std_logic_vector (17 DOWNTO 0);
      CLK      : IN     std_logic ;
      CS       : IN     std_logic ;
      CSUNLOCK : IN     std_logic ;
      DBUSI    : IN     std_logic_vector (31 DOWNTO 0);
      RESETN   : IN     std_logic ;
      WR       : IN     std_logic ;
      DBUSO    : OUT    std_logic_vector (31 DOWNTO 0);
      READY    : OUT    std_logic 
   );
   END COMPONENT FlashCTRL_Top;
   COMPONENT FlashCTRL_Top_tester
   PORT (
      DBUSO    : IN     std_logic_vector (31 DOWNTO 0);
      READY    : IN     std_logic ;
      ADDR     : OUT    std_logic_vector (17 DOWNTO 0);
      CLK      : OUT    std_logic ;
      CS       : OUT    std_logic ;
      CSUNLOCK : OUT    std_logic ;
      DBUSI    : OUT    std_logic_vector (31 DOWNTO 0);
      RESETN   : OUT    std_logic ;
      WR       : OUT    std_logic 
   );
   END COMPONENT FlashCTRL_Top_tester;


BEGIN

   -- Instance port mappings.
   U_DUT : FlashCTRL_Top
      PORT MAP (
         ADDR     => ADDR,
         CLK      => CLK,
         CS       => CS,
         CSUNLOCK => CSUNLOCK,
         DBUSI    => DBUSI,
         RESETN   => RESETN,
         WR       => WR,
         DBUSO    => DBUSO,
         READY    => READY
      );
   U_TEST : FlashCTRL_Top_tester
      PORT MAP (
         DBUSO    => DBUSO,
         READY    => READY,
         ADDR     => ADDR,
         CLK      => CLK,
         CS       => CS,
         CSUNLOCK => CSUNLOCK,
         DBUSI    => DBUSI,
         RESETN   => RESETN,
         WR       => WR
      );

END ARCHITECTURE struct;
