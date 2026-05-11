# M1/UVM — UVM Skeleton (Preview)

This week, just get UVM compiling and a base test running.

## Minimal files to create

- `top_tb.sv` — calls `run_test("pcie_tl_base_test")`
- `test_lib.sv` — `pcie_tl_base_test` that raises/drops objection after `#1000`

You will fill in the full UVM structure in Week 2 (M2).

## Run

```bash
vlog -sv +incdir+. +incdir+../../Packages/uvm-1.2/src \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```
