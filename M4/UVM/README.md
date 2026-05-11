# M4/UVM — Coverage & Assertions

Add coverage and SVA to your M3 testbench.

See [`M4/README.md`](../README.md) for covergroup specs and SVA property templates.

## New files to create this week

- `axi_cov.sv` — `tl_axi_cg` covergroup  
- `dll_rx_cov.sv` — `dll_rx_cg` covergroup
- `dll_tx_cov.sv` — `dll_tx_cg` covergroup (new file)
- `axi_assertions.sv` — SVA property module

## Run with coverage

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test \
     -coverage -do "coverage save -onexit cov.ucdb; run -all; quit"
vcover report cov.ucdb -details
```
