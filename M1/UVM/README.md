# M1/UVM/

Just a stub this week. The goal was to get UVM compiling and a base test running.

The full UVM build is in M2.

## Files I created here

- `top_tb.sv` — calls `run_test("pcie_tl_base_test")`
- `test_lib.sv` — base test that raises/drops objection after `#1000`

## How to run

```bash
vlog -sv +incdir+. +incdir+../../Packages/uvm-1.2/src \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```
