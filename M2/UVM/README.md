# M2/UVM — UVM Agents

Write your UVM agents here. Copy your M1/CLASS interface files as a starting point.

See [`M2/README.md`](../README.md) for the full implementation guide.

## Files to create this week

- `axi_intf.sv` + `tl_dll_intf.sv` (copy from M1/CLASS or tb/)
- `pcie_common.sv` (defines + empty classes)
- `axi_tx.sv` — sequence item
- `axi_drv.sv` — driver
- `axi_mon.sv` — monitor
- `axi_agent.sv` — agent (extends uvm_agent)
- `dll_item.sv` — TLP sequence item (fields only, constraints later)
- `dll_tx_responder.sv` — TX responder state machine
- `dll_tx_mon.sv` — TX monitor
- `dll_tx_agent.sv` — TX agent
- `dll_rx_drv.sv` — RX driver
- `dll_rx_mon.sv` — RX monitor
- `dll_rx_agent.sv` — RX agent
- `pcie_tl_env.sv` — environment (extends uvm_env)
- `test_lib.sv` — base test
- `top_tb.sv` — top level

## Run

```bash
cd M2/UVM
vlog -sv +incdir+. +incdir+../../Packages/uvm-1.2/src \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```
