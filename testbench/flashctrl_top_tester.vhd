---------------------------------------------------------------------------------------------------
--  Gowin Flash Controller                                                                           
--                                                                                                                                                
--                                                                           
---------------------------------------------------------------------------------------------------
--                                                       
---------------------------------------------------------------------------------------------------
--
--  TestBench Stimuli generator
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

ENTITY FlashCTRL_Top_tester IS
   PORT( 
      DBUSO    : IN     std_logic_vector (31 DOWNTO 0);
      READY    : IN     std_logic;
      ADDR     : OUT    std_logic_vector (17 DOWNTO 0);
      CLK      : OUT    std_logic;
      CS       : OUT    std_logic;
      CSUNLOCK : OUT    std_logic;
      DBUSI    : OUT    std_logic_vector (31 DOWNTO 0);
      RESETN   : OUT    std_logic;
      WR       : OUT    std_logic);
END ENTITY FlashCTRL_Top_tester ;


ARCHITECTURE rtl OF FlashCTRL_Top_tester IS

    signal clk_s     : std_logic:='0';                              
                     
    signal addr_s    : std_logic_vector(31 downto 0);               -- Port Address
    signal dbus_s    : std_logic_vector(31 downto 0);               -- Port Data

    constant test0_c : std_logic_vector(31 downto 0) := X"11223344";-- Some test data
    constant test1_c : std_logic_vector(31 downto 0) := X"55667788";    
    constant test2_c : std_logic_vector(31 downto 0) := X"99AABBCC";    

BEGIN

    clk_s <= NOT clk_s after 10 ns;                                 -- 50MHz
    CLK <= clk_s;   

    process
        variable page_v : std_logic_vector(5 downto 0);             -- Page 0 to 37
                        
        procedure write_flash(                             
             addr_p : in std_logic_vector(31 downto 0);     
             dbus_p : in std_logic_vector(31 downto 0)) is 
            begin 
                
                wait until rising_edge(clk_s);                      -- Unlock Flash
                ADDR     <= "000000000000100000";               
                DBUSI(0) <= '1';                                
                CSUNLOCK <= '1';
                WR       <= '1';
                wait until rising_edge(clk_s);
                CSUNLOCK <= '0';
                WR       <= '0';    
                
                wait until rising_edge(clk_s);                      -- Write to flash   
                ADDR     <= addr_p(17 downto 0);                                    
                DBUSI    <= dbus_p;                                 
                CS       <= '1';
                WR       <= '1';
                wait until rising_edge(clk_s);
                CS       <= '0';
                WR       <= '0';

                wait until rising_edge(clk_s);                      -- Wait for busy bit to clear
                ADDR     <= "000000000000100000";                   -- Read unlock register
                CSUNLOCK <= '1';                        
                loop                
                    wait until rising_edge(clk_s);                  -- Read unlock register busy bit0                   
                    CSUNLOCK <= '0';
                    exit when DBUSO(0)='0';                         -- if busy=0 then page has been erased
                    wait until rising_edge(clk_s);
                    CSUNLOCK <= '1';
                end loop;
                
        end write_flash;

        procedure read_flash(                              
            addr_p : in std_logic_vector(31 downto 0);      
            signal dbus_p : out std_logic_vector(31 downto 0)) is 
            begin 
                wait until rising_edge(clk_s);              
                ADDR     <= addr_p(17 downto 0);                    
                DBUSI    <= dbus_p;                                 
                CS       <= '1';
                wait until falling_edge(READY);             
                dbus_p   <= DBUSO;      
                CS       <= '0';    
                wait until rising_edge(clk_s);              
        end read_flash;
        
        
    begin
        RESETN   <= '0';
        ADDR     <= (others => '1');        
        CS       <= '0';
        CSUNLOCK <= '0';
        DBUSI    <= (others => '-');
        RESETN   <= '0';
        WR       <= '0';
        
        wait for 140 ns;
        RESETN <= '1';
        wait until rising_edge(clk_s);
        
        -------------------------------------------------------------------------------------------
        -- Initiate Flash Erase Page 0
        -------------------------------------------------------------------------------------------     
        report "Erasing Page0";
            
        -------------------------------------------------------------------------------------------
        -- Next perform a dummy write to the page erase address which start from address 0x200000 
        -- ADDR = '1' & XADR(9) & YADR(6) & "00"
        -- XADR = Page(6) & "000"
        -- ADDR = '1' & Page(6) & "000" & YADR(6) & "00"
        -------------------------------------------------------------------------------------------
        page_v := "000000";                                         -- total 38 pages each 2048 bytes
        addr_s(17 downto 0) <= '1' & page_v & "00000000000";        -- Notice A17=1 (above 256K is for erase)
        write_flash(addr_s,X"00000000");                            -- X"00000000" is dummy value
        
        report "Page0 has been erased";
        
        -------------------------------------------------------------------------------------------     
        -- Write some test values to page0
        ------------------------------------------------------------------------------------------- 
        write_flash(X"00000000",test0_c);
        write_flash(X"0000003C",test1_c);   
        write_flash(X"00000154",test2_c);
        
        -------------------------------------------------------------------------------------------     
        -- Read back test values
        ------------------------------------------------------------------------------------------- 
        read_flash(X"00000000",dbus_s);
        if dbus_s=test0_c then
            report("Reading "&to_hstring(unsigned(test0_c))&"...pass");
        else
            assert false report("Reading "&to_hstring(unsigned(dbus_s))&" expecting "&to_hstring(unsigned(test0_c))) severity error;
        end if;
        
        read_flash(X"0000003C",dbus_s);
            if dbus_s=test1_c then
            report("Reading "&to_hstring(unsigned(test1_c))&"...pass");
        else
            assert false report("Reading "&to_hstring(unsigned(dbus_s))&" expecting "&to_hstring(unsigned(test1_c))) severity error;
        end if;
        
        read_flash(X"00000154",dbus_s);
            if dbus_s=test2_c then
            report("Reading "&to_hstring(unsigned(test2_c))&"...pass");
        else
            assert false report("Reading "&to_hstring(unsigned(dbus_s))&" expecting "&to_hstring(unsigned(test2_c))) severity error;
        end if;
                
        STOP(1);                                                    -- VHDL2008 ENV package
    end process;


END ARCHITECTURE rtl;

