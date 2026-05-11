## PCIe TLP Verification from Scratch — Simulation Makefile

DESIGN   := ../design/pcie_tl.sv
UVM_PKG  := ../Packages/uvm-1.2/src/uvm_pkg.sv
UVM_LIB  := ../Packages/uvm-1.2

TB_TOP   := ../tb/top/top_tb.sv

INCDIRS  := +incdir+../tb/common \
            +incdir+../tb/axi    \
            +incdir+../tb/dll    \
            +incdir+../tb/mem    \
            +incdir+../tb/sbd    \
            +incdir+../tb/top    \
            +incdir+$(UVM_LIB)/src

TEST     ?= pcie_wr_rd_test
LOG       = $(TEST)_$(shell date +%Y%m%dT%H%M%S).log

# --------------------------------------------------------------------
# Questa / ModelSim
# --------------------------------------------------------------------
.PHONY: questa questa_compile questa_sim wave clean

questa: questa_compile questa_sim

questa_compile:
	vlib work
	vlog -sv -suppress 2583 $(INCDIRS) $(UVM_PKG) $(TB_TOP)

questa_sim:
	vsim -c top_tb \
	     +UVM_TESTNAME=$(TEST) \
	     +UVM_TIMEOUT=500000 \
	     -sv_lib $(UVM_LIB)/lib/uvm_dpi \
	     -do "run -all; quit" \
	     -l $(LOG)

wave:
	vsim -view vsim.wlf &

# --------------------------------------------------------------------
# VCS (Synopsys)
# --------------------------------------------------------------------
.PHONY: vcs

vcs:
	vcs -sverilog -ntb_opts uvm-1.2 \
	    $(INCDIRS) \
	    $(UVM_PKG) $(TB_TOP) \
	    +UVM_TESTNAME=$(TEST) \
	    -l $(LOG)

# --------------------------------------------------------------------
# Xcelium (Cadence)
# --------------------------------------------------------------------
.PHONY: xcelium

xcelium:
	xrun -sv -uvm \
	     $(INCDIRS) \
	     $(TB_TOP) \
	     +UVM_TESTNAME=$(TEST) \
	     -l $(LOG)

# --------------------------------------------------------------------
clean:
	rm -rf work vsim.wlf *.log transcript *.vcd *.vstf
