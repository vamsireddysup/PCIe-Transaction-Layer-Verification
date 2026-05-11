# Testbench — UVM Architecture

This directory contains skeleton files for the complete UVM testbench.  
Fill in the logic week by week following the milestone READMEs.  
**Do not copy the reference implementation** — the point is to build it yourself.

---

## Component Hierarchy

```
uvm_test_top (pcie_wr_rd_test)
  └── env (pcie_tl_env)              ← uvm_env
        ├── axi_agent_i (axi_agent)  ← uvm_agent
        │     ├── drv  (axi_drv)
        │     ├── sqr  (axi_sqr)
        │     ├── mon  (axi_mon) ──→ ap_port
        │     └── cov  (axi_cov) ←── analysis_export
        │
        ├── dll_tx_agent_i (dll_tx_agent)  ← uvm_agent
        │     ├── responder (dll_tx_responder)
        │     └── mon       (dll_tx_mon) ──→ ap_port
        │
        ├── dll_rx_agent_i (dll_rx_agent)  ← uvm_agent
        │     ├── drv  (dll_rx_drv)
        │     ├── sqr  (dll_rx_sqr)
        │     ├── mon  (dll_rx_mon) ──→ ap_port
        │     └── cov  (dll_rx_cov) ←── analysis_export
        │
        ├── mem_agent_i (mem_agent)   ← uvm_agent
        │     ├── mem  (memory)
        │     └── mon  (mem_mon) ──→ ap_port
        │
        └── tl_sbd_i (tl_sbd)        ← uvm_scoreboard
              ├── axi_fifo    ←── axi_mon.ap_port
              ├── tx_tlp_fifo ←── dll_tx_mon.ap_port
              └── rx_tlp_fifo ←── dll_rx_mon.ap_port
```

---

## Subdirectories

| Directory | Contents |
|-----------|---------|
| `common/` | Shared defines, typedefs, `pcie_common` class, `dll_cfg_rx` class |
| `axi/`    | AXI interface, sequence item, driver, monitor, coverage, agent, sequence library |
| `dll/`    | DLL interface, TLP item, TX responder+monitor+agent, RX driver+monitor+agent+sequences |
| `mem/`    | Memory model, memory monitor, memory agent |
| `sbd/`    | TL scoreboard |
| `top/`    | Environment, test library, top-level testbench |

---

## Interface → Resource DB Keys

| Interface | Resource DB Key | Who sets it | Who reads it |
|-----------|----------------|-------------|--------------|
| `axi_intf` (proc) | `"AXI"`, `"VIF"` | `top_tb` | `axi_drv`, `axi_mon` |
| `axi_intf` (mem)  | `"AXI"`, `"MIF"` | `top_tb` | `memory`, `mem_mon` |
| `tl_dll_intf`     | `"DLL"`, `"VIF"` | `top_tb` | `dll_rx_drv`, `dll_tx_responder`, `dll_tx_mon`, `dll_rx_mon` |
