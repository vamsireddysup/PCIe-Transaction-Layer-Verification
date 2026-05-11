# M4/UVM/

Week 4 — coverage and assertions added to the M3 testbench.

See [M4/README.md](../README.md) for covergroup specs and SVA property templates.

## New files this week

- `axi_cov.sv` — `tl_axi_cg` with payload size, address, and write/read coverage
- `dll_rx_cov.sv` — `dll_rx_cg` TLP type coverage
- `dll_tx_cov.sv` — `dll_tx_cg` outgoing TLP type coverage (new, not in reference)
- `axi_assertions.sv` — SVA properties for AXI and DLL TX protocols

## How to run with coverage

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test -coverage \
     -do "coverage save -onexit cov.ucdb; run -all; quit"
vcover report cov.ucdb -details
```
