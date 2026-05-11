# tb/top/ — Environment, Tests, Top Testbench

---

## Files

| File | What it does |
|------|-------------|
| `pcie_common.sv` | Defines, typedefs, `pcie_common` class, `dll_cfg_rx` class |
| `pcie_tl_env.sv` | UVM environment — creates and connects all agents and scoreboard |
| `test_lib.sv` | Base test and `pcie_wr_rd_test` |
| `top_tb.sv` | Top module: clocks, resets, interfaces, DUT, `run_test()` |

---

## `top_tb.sv` checklist

Things I need to make sure are in here:

- [ ] `aclk` and `tl_dll_clk` generation (`#0.5` half-period = 1 GHz)
- [ ] `arst` asserted for 2 cycles then deasserted
- [ ] `axi_intf axi_p_pif(aclk, arst)` and `axi_intf axi_m_pif(aclk, arst)`
- [ ] `tl_dll_intf tl_dll_pif(tl_dll_clk, arst)`
- [ ] Resource DB sets for all three interfaces
- [ ] DUT instantiation with all ports connected to the right interface
- [ ] `dll_cfg_rx::vip_cfg_as_ep()` called before `run_test()`
- [ ] `run_test("pcie_wr_rd_test")`
- [ ] Always block mirroring `dut.n_state_dll` into `pcie_common::pcie_tl_dll_state`
- [ ] `$dumpfile` / `$dumpvars` for waveform

---

## `pcie_tl_env.sv` — what not to do

- Do **not** extend `uvm_test` — extend `uvm_env`
- Do **not** add a `#1000` timeout in `run_phase` — the env shouldn't manage objections
- Do **not** forget `mem_agent_i` — it's missing in the reference (Bug #3)

---

## `include` order in `top_tb.sv`

Order matters — use this:

```sv
`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "pcie_common.sv"
`include "axi_intf.sv"
`include "tl_dll_intf.sv"
`include "axi_tx.sv"
`include "axi_drv.sv"
`include "axi_mon.sv"
`include "axi_cov.sv"
`include "axi_agent.sv"
`include "dll_item.sv"
`include "dll_tx_responder.sv"
`include "dll_tx_mon.sv"
`include "dll_tx_agent.sv"
`include "dll_rx_drv.sv"
`include "dll_rx_mon.sv"
`include "dll_rx_cov.sv"
`include "dll_rx_agent.sv"
`include "axi_seq_lib.sv"
`include "dll_rx_seq_lib.sv"
`include "tl_sbd.sv"
`include "pcie_tl_env.sv"
`include "test_lib.sv"
`include "pcie_tl.sv"
```

No semicolons after `include` lines — some simulators reject them.
