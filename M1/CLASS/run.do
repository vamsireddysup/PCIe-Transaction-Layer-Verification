vlog +incdir+/u/allada/Documents/M1/uvm-1.2/src top_tb.sv

vsim -novopt -suppress 12110 top_tb -sv_lib uvm_dpi +UVM_TESTNAME=pcie_tl_base_test

do wave.do

run -all
