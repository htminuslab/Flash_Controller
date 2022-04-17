---------------------------------------------------------------------------------------------------
--  Gowin Flash Controller                                                                           
--                                                                            
--  https://github.com/HansTiggeler/Flash_Controller                                                                         
---------------------------------------------------------------------------------------------------
--                                               
---------------------------------------------------------------------------------------------------
--
--  Timing package based on UG295-1.3E, 11/14/2021
-- 
--  Revision History:                                                        
--                                                                           
--  Date:          Revision         Author         
--  08-Jan-2022    0.1              Hans Tiggeler 
---------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Flash_pack IS

    constant CLK_PERIOD   : positive := 20;                         -- Clock period in ns, 50MHz, round downwards
                                                                    -- Minimum clock period is 5ns, for lower values the 
                                                                    -- FSM needs adjusting as a single clk cycle is used for Tpws    
    
    -----------------------------------------------------------------------------------------------
    -- Delays in ns,  see Gowin appsnote UG295-1.3E, 11/14/2021
    -----------------------------------------------------------------------------------------------
    constant Tacc         : positive := 25;                         -- Access time, 40MHz max
    constant Tpws         : positive := 5;  
    constant Tnvs         : positive := 5000;                       -- Wait 5uS 
    constant Tpgs         : positive := 10000;                      -- Wait 10uS
    constant Tprog        : positive := 8000;                       -- Wait 8-16uS
    constant Tadh         : positive := 20;                         -- Wait 20ns, hold data
    constant Trcv         : positive := 10000;                      -- Wait 10us
    constant Terase       : positive := 100000000;                  -- Wait 100-120msec!
    constant Tnvh         : positive := 5000;                       -- Wait 5us
    
    -----------------------------------------------------------------------------------------------
    -- Delays in number of clock cycles, all rounded up, check values
    -----------------------------------------------------------------------------------------------
    constant Tacc_CYCLES  : positive := (Tacc+CLK_PERIOD)/CLK_PERIOD;   
    constant Tpws_CYCLES  : positive := 1;                          -- Maximum 200MHz
    constant Tnvs_CYCLES  : positive := (Tnvs+CLK_PERIOD)/CLK_PERIOD;   -- Wait 5uS 
    constant Tpgs_CYCLES  : positive := (Tpgs+CLK_PERIOD)/CLK_PERIOD;   -- Wait 10uS
    constant Tprog_CYCLES : positive := (Tprog+CLK_PERIOD)/CLK_PERIOD;  -- Wait 8-16uS
    constant Tadh_CYCLES  : positive := (Tadh+CLK_PERIOD)/CLK_PERIOD;   -- Wait 20ns, hold data
    constant Trcv_CYCLES  : positive := (Trcv+CLK_PERIOD)/CLK_PERIOD;   -- Wait 10us
    constant Terase_CYCLES: positive := (Terase+CLK_PERIOD)/CLK_PERIOD; -- Wait 100-120msec!
    constant Tnvh_CYCLES  : positive := (Tnvh+CLK_PERIOD)/CLK_PERIOD;   -- Wait 5us


END Flash_pack;
