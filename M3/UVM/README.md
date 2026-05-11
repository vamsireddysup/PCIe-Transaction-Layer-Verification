# M3/UVM/

Week 3 — sequence libraries on top of the M2 agents.

See [M3/README.md](../README.md) for sequence specs and the full DUT flow walkthrough.

## New files this week

- `axi_seq_lib.sv` — `axi_base_seq`, `axi_config_seq`, `axi_dma_descr_load_seq`
- `dll_rx_seq_lib.sv` — `dll_linkup_indicate_seq`, `dll_vc_up_indicate_seq`, `dll_cpl_seq`
- Updated `test_lib.sv` — added `pcie_wr_rd_test`

## How to run

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test +UVM_VERBOSITY=UVM_LOW \
     -do "run -all; quit"
```
