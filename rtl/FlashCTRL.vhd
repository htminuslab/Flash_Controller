---------------------------------------------------------------------------------------------------
--  Gowin Flash Controller                           
--                                                                           
--  https://github.com/htminuslab                                                   
---------------------------------------------------------------------------------------------------
--                                                    
---------------------------------------------------------------------------------------------------
--
--  Control logic/FSM
-- 
--  Revision History:                                                        
--                                                                           
--  Date:          Revision         Author         
--  08-Jan-2022    0.1              Hans Tiggeler 
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY std;
USE std.textio.all;

USE work.flash_pack.ALL;

ENTITY FlashCTRL IS
   PORT( 
      ADDR     : IN   std_logic_vector (17 DOWNTO 0);
      CLK      : IN   std_logic;
      CS       : IN   std_logic;                                    -- Need to address 512Kbyte section of the memory map
      CSUNLOCK : IN   std_logic;                                    -- Read/Write to Control/Status register
      DBUSI    : IN   std_logic_vector (31 DOWNTO 0);               -- CPU input databus
      RESETN   : IN   std_logic;
      WR       : IN   std_logic;
      DIN      : IN   std_logic_vector (31 DOWNTO 0);
      DOUT     : OUT  std_logic_vector (31 DOWNTO 0);
      DBUSO    : OUT  std_logic_vector (31 DOWNTO 0);               -- CPU output databus
      ERASE    : OUT  std_logic;
      NVSTR    : OUT  std_logic;
      PROG     : OUT  std_logic;
      READY    : OUT  std_logic;
      SE       : OUT  std_logic;
      XADR     : OUT  std_logic_vector (8 DOWNTO 0);
      XE       : OUT  std_logic;
      YADR     : OUT  std_logic_vector (5 DOWNTO 0);
      YE       : OUT  std_logic);
END ENTITY FlashCTRL;

--
ARCHITECTURE rtl OF FlashCTRL IS

    type flash_state_type is (sIdle,sReadSE,sReadData,sReadReady,sWritecps,sWritenvs,sWritepgs,sWriteProg,sWriteadh,sWritenvh,sWritewhd,sWaitrcv,sErasecps,sErasenvs,sEraserase,sErasenvh,sErasewhd);   
    signal current_state_s : flash_state_type;

    signal cnt_delay_s : integer RANGE 100000000 DOWNTO 0;      
    signal unlock_write_erase_s : std_logic;
    signal busy_s      : std_logic;                                 -- Write or Erase is done, set by write
    
BEGIN

    -- pragma synthesis_off
    assert (CLK_PERIOD>=Tpws) report "Minimum clock period supported is 5ns, 1 clock cycle is used for Tpws" severity failure;
    -- pragma synthesis_on       


    DBUSO(31 downto 1) <= DIN(31 downto 1);
    DBUSO(0) <= busy_s when CSUNLOCK='1' else DIN(0);
    
    READY    <= '1' when current_state_s=sReadReady OR CSUNLOCK='1' OR (CS='1' AND WR='1') else '0';

    process (clk)
    begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                unlock_write_erase_s <= '0';
                busy_s      <= '0';             
                XE          <= '0';
                YE          <= '0';
                SE          <= '0';
                PROG        <= '0';
                ERASE       <= '0';
                NVSTR       <= '0'; 
                XADR        <= (others => '0');                     -- 76Kbyte or 9.5KDword
                YADR        <= (others => '0'); 
                cnt_delay_s <= 0;
                current_state_s <= sIdle;
            else
            
                if CSUNLOCK='1' AND WR='1' AND DBUSI(0)='1' then    -- unlock Page erase/write
                    unlock_write_erase_s <= '1';
                end if;
            
                case current_state_s is
                    when sIdle =>                   
                        DOUT    <= DBUSI;                           -- Register bus
                        YADR    <= ADDR(7 downto 2);                -- Latch XADR/YADR
                        XADR    <= ADDR(16 downto 8);               -- 38 Pages of 2048 bytes                   
                        busy_s  <= '0'; 
                        if CS='1' AND WR='0' then                   -- Start of Read Cycle
                            unlock_write_erase_s <= '0';            -- Any read will lock
                            XE     <= '1';
                            YE     <= '1';
                            current_state_s <= sReadSE;             
                        elsif CS='1' AND WR='1' AND ADDR(17)='1' AND unlock_write_erase_s='1' then                                                              
                            unlock_write_erase_s <= '0';            -- lock again after page erase
                            busy_s <= '1';  
                            XE     <= '1';                          
                            current_state_s <= sErasecps;   
                        elsif CS='1' AND WR='1' AND unlock_write_erase_s='1' then-- Writes are slow
                            unlock_write_erase_s <= '0';            -- lock again after single write (too restrictive?)
                            busy_s <= '1';
                            XE     <= '1';                          
                            current_state_s <= sWritecps;   
                        end if;
                                                
                    -------------------------------------------------------------------------------
                    -- Read 
                    -------------------------------------------------------------------------------
                    when sReadSE =>                                 -- 1 CLK assert SE, max 200MHz clk
                        SE <= '1';
                        current_state_s <= sReadData;
                        cnt_delay_s <= Tacc_CYCLES-Tpws_CYCLES;     -- Wait for 25-5ns                      
                    when sReadData =>
                        SE <= '0';  
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            current_state_s <= sReadReady;
                        end if;                     
                    when sReadReady =>
                        current_state_s <= sIdle;
                        XE        <= '0';
                        YE        <= '0';
                                                                    
                    -------------------------------------------------------------------------------
                    -- Write
                    -------------------------------------------------------------------------------                     
                    when sWritecps =>
                        PROG   <= '1';
                        cnt_delay_s <= Tnvs_CYCLES;                 -- Start with a 5uS wait
                        current_state_s <= sWritenvs;   
                            
                    when sWritenvs =>
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            cnt_delay_s <= Tpgs_CYCLES;             -- Set counter to wait for 10uS                         
                            current_state_s <= sWritepgs;
                        end if;                                     
                    when sWritepgs =>                               -- Wait for 10us
                        NVSTR <= '1';
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            cnt_delay_s <= Tprog_CYCLES;            -- Set counter to wait for 16uS                         
                            current_state_s <= sWriteProg;
                        end if;
                    when sWriteProg =>                              -- Write the data for 16us
                        YE <= '1';
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            cnt_delay_s <= Tadh_CYCLES;             -- Set counter to wait for 20ns, hold data                          
                            current_state_s <= sWriteadh;
                        end if;
                    when sWriteadh =>                               -- Hold data for 20ns
                        YE <= '0';
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            cnt_delay_s <= Tnvs_CYCLES;             -- Set counter to wait for 5us                          
                            current_state_s <= sWritenvh;
                        end if;                     
                    when sWritenvh =>                               -- Wait for 5us                         
                        PROG <= '0';
                        cnt_delay_s <= cnt_delay_s-1;                       
                        if (cnt_delay_s=1) then 
                            current_state_s <= sWritewhd;           --   The -1 in "Trcv_CYCLES-1" is for the last Ready state.     
                        end if;                 
                    when sWritewhd =>                               -- Twhd specified as >0 but primitive uses 1ns delay 
                        NVSTR <= '0';                               
                        cnt_delay_s <= Trcv_CYCLES;                 -- Set counter to wait for 10us Trecv? (Trcv) before we can raise PROG again    
                        current_state_s <= sWaitrcv;                --  this can be removed if required as it is unlikely to issue to erase cycles after each other     
                        
                    -------------------------------------------------------------------------------
                    -- Erase
                    -------------------------------------------------------------------------------                                     
                    when sErasecps =>
                        ERASE <= '1';
                        cnt_delay_s <= Tnvs_CYCLES;                 -- Set counter to wait for 5us 
                        current_state_s <= sErasenvs;                       
                    when sErasenvs =>                               -- Wait 5 us
                        cnt_delay_s <= cnt_delay_s-1;   
                        if (cnt_delay_s=1) then                             
                            cnt_delay_s <= Terase_CYCLES;           -- Set counter to wait for 120ms!
                            current_state_s <= sEraserase;                          
                        end if;                     
                    when sEraserase =>                              -- Wait 120ms
                        NVSTR <= '1';
                        cnt_delay_s <= cnt_delay_s-1;   
                        if (cnt_delay_s=1) then 
                            cnt_delay_s <= Tnvh_CYCLES;             -- Wait 5us                         
                            current_state_s <= sErasenvh;
                        end if;
                    when sErasenvh =>   
                        ERASE <= '0';
                        cnt_delay_s <= cnt_delay_s-1;   
                        if (cnt_delay_s=1) then                                                 
                            current_state_s <= sErasewhd;           
                        end if; 
                    when sErasewhd =>                               -- Twhd specified as >0 but primitive uses 1ns delay 
                        NVSTR <= '0';                               
                        cnt_delay_s <= Trcv_CYCLES;                 -- Set counter to wait for 10us Trecv? (Trcv) before we can raise ERASE again   
                        current_state_s <= sWaitrcv;                --  this can be removed if required as it is unlikely to issue to erase cycles after each other     

                    when sWaitrcv =>                                -- Wait 10us before we can assert ERASE/Prog again.
                        XE <= '0';
                        cnt_delay_s <= cnt_delay_s-1;               
                        if (cnt_delay_s=1) then 
                            current_state_s <= sIdle;   
                        end if;
                                    
                    
                    when others =>
                        current_state_s <= sIdle;
                end case;
            end if;
        end if;
    end process;
END ARCHITECTURE rtl;

