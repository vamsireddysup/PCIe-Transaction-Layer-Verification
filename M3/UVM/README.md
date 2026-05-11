# M3/UVM — Sequences & Full Stimulus

Build on your M2 agents. Add sequence libraries and run the full enumeration flow.

See [`M3/README.md`](../README.md) for the complete sequence specifications.

## New files to create this week

- `axi_seq_lib.sv` — `axi_base_seq`, `axi_config_seq`, `axi_dma_descr_load_seq`
- `dll_rx_seq_lib.sv` — `dll_linkup_indicate_seq`, `dll_vc_up_indicate_seq`, `dll_cpl_seq`
- Update `test_lib.sv` — add `pcie_wr_rd_test`

## Run

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test +UVM_VERBOSITY=UVM_LOW -do "run -all; quit"
```
