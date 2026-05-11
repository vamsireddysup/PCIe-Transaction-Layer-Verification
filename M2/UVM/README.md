# M2/UVM/

My Week 2 UVM agents. Built from scratch — no copy-paste from the reference.

See [M2/README.md](../README.md) for the full implementation guide and common mistakes I made.

## Files I created here

- `pcie_common.sv`, `axi_intf.sv`, `tl_dll_intf.sv`
- `axi_tx.sv`, `axi_drv.sv`, `axi_mon.sv`, `axi_agent.sv`
- `dll_item.sv`, `dll_tx_responder.sv`, `dll_tx_mon.sv`, `dll_tx_agent.sv`
- `dll_rx_drv.sv`, `dll_rx_mon.sv`, `dll_rx_agent.sv`
- `mem_agent.sv`, `pcie_tl_env.sv`, `test_lib.sv`, `top_tb.sv`

## How to run

```bash
vlog -sv +incdir+. +incdir+../../Packages/uvm-1.2/src \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```
