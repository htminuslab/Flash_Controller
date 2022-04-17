# Simple Modelsim/Questa .do file
# Execute with vsim -c -do run.do

onerror {resume}

# Change the line below to point to your directory!
vmap gw1n H:/simlib/Gowin/gw1n


# Create work library.
if ![file exists work] {
	echo "Creating Work Directory"
	vlib work    
}

# Compile Design
vcom -quiet -2008 ../rtl/Flash_pack.vhd
vcom -quiet -2008 ../rtl/FlashCTRL.vhd
vcom -quiet -2008 ../rtl/flashctrl_top.vhd

# Compile Testbench
vcom -quiet -2008 ../testbench/flashctrl_top_tb.vhd
vcom -quiet -2008 ../testbench/flashctrl_top_tester.vhd

# set StdArithNoWarnings 1
vsim -quiet FlashCTRL_Top_tb -L gw1n
nolog -all
run -all
