# Gowin gw1n-9 Flash Controller

This repository contains a simple Gowin gw1n-9 FPGA Flash Controller in VHDL.

![Tang Nano 9K Development Board](https://github.com/HansTiggeler/Flash_Controller/blob/main/tangnano9k.PNG?raw=true)

The Gowin gw1n family of FPGA's have embedded flash which can be used for user designs. 
The largest Flash IP block of 608Kbits can be found on the gw1n-9 family which is used for this project.

*The timing used is based on the Gowin **UG295-1.3E, 11/14/2021**
There are a few typos in the doc, **Trecv** is not specified but most likely should be **Trcv**, similarly **Tnhv** should be **Tnvh***.


 
## Operations
 
The Flash Controller is a simple state machine which controls the timing used to read, write and erase the flash. 
The usage model for the flash controller is as a simple static memory device attached to an embedded CPU. 

### Read Operation
Reading the flash is similar to reading from SRAM, the CPU needs to keep the bus active until the flash controller asserts the READY signal. This is required as reading from the FLASH is relative slow (25ns access time). 
### Write Operation
For writing the CPU first "unlocks" the flash by writing a 1 to the flash unlock register (CSUNLOCK asserted) and then write the 32bits data to the flash. After writing to the flash the flash controller automatically locks itself again. After the write the CPU needs to poll a **busy** bit located in the unlock register until it is cleared, the data is now written to flash. Note that the READY signal for write is asserted immediately as the busy bit it used to indicate when the write has been completed. A flash write can take between 30-40us.
### Erase Operation
The gw1n-9 flash primitive contains 38 pages of 2048 bytes each ((38 * 2048 * 8)/1024=608Kb). To make the erase simple each flash page is mapped to a single memory location starting at 0x200000 (256KByte). To erase a page the CPU simple write a dummy value to address 256KB+page_number (A17=1 indicates accessing a page location). 
Erasing a page is similar to writing to flash, the CPU unlocks the flash, write to 256KB+page_number and then polls the busy bit until it is cleared. The READY signal is asserted immediately as the busy bit is used to indicate when the erase cycle is done. Note that an erase cycle can take more than 100ms per page!


![Top Level](https://github.com/HansTiggeler/Flash_Controller/blob/main/top.PNG?raw=true)
 
## Pin Description

|Pin Name|Function |
|----------|----------|
| CLK      | Input clock maximum 200MHz |
| RESETN   | Active Low Reset |
| ADDR     | 17bits wide Address |
| READY     | Active high bus termination signal |
| WR     | Active high Write strobe |
| CS     | Chip Select for Flash Read/Write/Erase |
| CSUNLOCK   | Chip Select for Flash Unlock and status register |
| DBUSI     | Input Databus |
| DBUSO     | Output Databus |

## Before running Simulation 

1) Correct the path to the gw1n primitive library (which contains the FLASH608K primitive) in the **sim/run.do** file.
2) Correct the CLK_PERIOD value for your clock in the **rtl/flash_pack.vhd** file.

## Simulation

The sim directory contains a simple .do file for Modelsim/Questa. To run the simulation open a CMD prompt/terminal, navigate to the sim directory and execute:

```
vsim -c -do "do run.do;quit -f"
```

The testbench will erase page0 following by writing and reading back 3 test values.

```
# do run.do
# Model Technology ModelSim DE-64 vmap 2022.1 Lib Mapping Utility 2022.01 Jan 29 2022
# vmap gw1n H:/simlib/Gowin/gw1n
# Copying c:/modelsim_de_2022/win64pe/../modelsim.ini to modelsim.ini
# Modifying modelsim.ini
# Creating Work Directory
# vsim -quiet FlashCTRL_Top_tb -L gw1n
# //  ModelSim DE-64 2022.1 Jan 29 2022
# //
# //  Copyright 1991-2022 Mentor Graphics Corporation
# //  All Rights Reserved.
# //
# //  ModelSim DE-64 and its associated documentation contain trade
# //  secrets and commercial or financial information that are the property of
# //  Mentor Graphics Corporation and are privileged, confidential,
# //  and exempt from disclosure under the Freedom of Information Act,
# //  5 U.S.C. Section 552. Furthermore, this information
# //  is prohibited from disclosure under the Trade Secrets Act,
# //  18 U.S.C. Section 1905.
# //
# ** Note: Erasing Page0
#    Time: 150 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# ** Note: Page0 has been erased
#    Time: 100020390 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# ** Note: Reading 11223344...pass
#    Time: 100135330 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# ** Note: Reading 55667788...pass
#    Time: 100135430 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# ** Note: Reading 99AABBCC...pass
#    Time: 100135530 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# ** Note: stop
#    Time: 100135530 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_TEST
# Break in Process line__54 at ../testbench/flashctrl_top_tester.vhd line 168
# Stopped at ../testbench/flashctrl_top_tester.vhd line 168
# quit -f
# Errors: 0, Warnings: 0
```

## Troubleshooting

If modelsim/Questa can't find the gw1n primitive library you may get:
``` 
# ** Warning: (vsim-3473) Component instance "U_FLASH : FLASH608K" is not bound.
#    Time: 0 ns  Iteration: 0  Instance: /flashctrl_top_tb/U_DUT File: ../rtl/flashctrl_top.vhd
```
Correct the path to the gw1n file by running **vmap gw1n <path_to_compiled_library>** or edit the [PATH] section in the local **modelsim.ini** file.


## Improvements
1) The write operation only writes to one flash location. The flash primitive can handle 64 writes in a sequence (each write takes 8-16us), see figure 3-26 in the **UG295** technote.
2) The timing values used are rounded up with an extra **PERIOD** delay, this can be tweaked to improve timing. 
3) Timing values specified as ">0" are implemented with a full clock period. It is not clear if the gw1n **FF CLK-to-Q + Routing delay** is sufficient for ">0"

## License

This project is licensed under the MIT License - see the LICENSE file for details
