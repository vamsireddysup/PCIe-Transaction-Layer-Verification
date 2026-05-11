# tb/top — Environment, Tests, Top Testbench

---

## Files

| File | Description |
|------|-------------|
| `pcie_common.sv` | Shared defines, typedefs, `pcie_common` class, `dll_cfg_rx` class |
| `pcie_tl_env.sv` | UVM environment (extends `uvm_env`) |
| `test_lib.sv`    | `pcie_tl_base_test` and `pcie_wr_rd_test` |
| `top_tb.sv`      | Module: clock/reset gen, interface instantiation, DUT bind, `run_test` |

---

## `top_tb.sv` — Key Responsibilities

1. Generate `aclk` (period = 1ns, `#0.5`) and `tl_dll_clk` (same)
2. Generate `arst` (assert 2 cycles, then deassert)
3. Instantiate `axi_intf axi_p_pif(aclk, arst)` — processor side
4. Instantiate `axi_intf axi_m_pif(aclk, arst)` — memory side
5. Instantiate `tl_dll_intf tl_dll_pif(tl_dll_clk, arst)`
6. Set virtual interfaces into resource DB:
   ```sv
   uvm_resource_db#(virtual axi_intf)::set("AXI","VIF", axi_p_pif, null);
   uvm_resource_db#(virtual axi_intf)::set("AXI","MIF", axi_m_pif, null);
   uvm_resource_db#(virtual tl_dll_intf)::set("DLL","VIF", tl_dll_pif, null);
   ```
7. Instantiate and connect DUT (`pcie_tl dut(...)`)
8. Call `dll_cfg_rx::vip_cfg_as_ep()` and `run_test("pcie_wr_rd_test")`
9. Always block to mirror DUT FSM state into `pcie_common::pcie_tl_dll_state`

---

## `pcie_tl_env.sv` — Common Mistakes

- **Extends `uvm_env`** (not `uvm_test`)
- **Do not** add a `#1000` timeout in `run_phase` — let the test own objections
- **Do** instantiate `mem_agent_i` (it is missing in the reference version — Bug #5)
- **Do** instantiate `tl_sbd_i` and connect all `ap_port` → `analysis_export`

---

## `test_lib.sv` — `pcie_wr_rd_test` Flow

```
run_phase:
  1. dma_load_seq.start(env.axi_agent_i.sqr)    // load TX/RX descriptors
  2. config_seq.start(env.axi_agent_i.sqr)       // configure registers, kick link training
  3. dll_link_seq.start(env.dll_rx_agent_i.sqr)  // assert linkup=1
  4. dll_vc_seq.start(env.dll_rx_agent_i.sqr)    // assert dll_vc_up=8'hFF
  5. fork
       dll_cpl.start(...)   // runs forever, drives CplD for each incoming CFG_RD
     join_none
  6. drop_objection          // simulation ends after drain_time
```

---

## Include Order in `top_tb.sv`

The order matters for forward declarations:

```sv
`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "pcie_common.sv"    // defines + classes (no semicolon!)
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
`include "pcie_tl.sv"        // DUT last
```
