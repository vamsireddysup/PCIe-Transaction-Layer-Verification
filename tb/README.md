# tb/ — My UVM Testbench

This is where I build the verification environment week by week. Each subdirectory has a README explaining what goes in it and what I need to implement.

Don't copy from the reference — build it from scratch using the milestone READMEs as a guide.

---

## Component hierarchy

```
pcie_wr_rd_test  (uvm_test)
  └── env  (pcie_tl_env)                    uvm_env
        ├── axi_agent_i  (axi_agent)         uvm_agent
        │     ├── drv  (axi_drv)
        │     ├── sqr  (uvm_sequencer)
        │     ├── mon  (axi_mon)  ──→ ap_port
        │     └── cov  (axi_cov) ←── analysis_export
        │
        ├── dll_tx_agent_i  (dll_tx_agent)   uvm_agent
        │     ├── responder  (dll_tx_responder)
        │     └── mon        (dll_tx_mon) ──→ ap_port
        │
        ├── dll_rx_agent_i  (dll_rx_agent)   uvm_agent
        │     ├── drv  (dll_rx_drv)
        │     ├── sqr  (uvm_sequencer)
        │     ├── mon  (dll_rx_mon) ──→ ap_port
        │     └── cov  (dll_rx_cov) ←── analysis_export
        │
        ├── mem_agent_i  (mem_agent)          uvm_agent
        │     ├── mem  (memory)
        │     └── mon  (mem_mon) ──→ ap_port
        │
        └── tl_sbd_i  (tl_sbd)               uvm_scoreboard
              ├── axi_fifo    ←── axi_mon.ap_port
              ├── tx_tlp_fifo ←── dll_tx_mon.ap_port
              └── rx_tlp_fifo ←── dll_rx_mon.ap_port
```

---

## Interface → resource DB keys

| Interface | Key | Set by | Used by |
|-----------|-----|--------|---------|
| `axi_intf` proc side | `"AXI"`, `"VIF"` | `top_tb` | `axi_drv`, `axi_mon` |
| `axi_intf` mem side  | `"AXI"`, `"MIF"` | `top_tb` | `memory`, `mem_mon` |
| `tl_dll_intf`        | `"DLL"`, `"VIF"` | `top_tb` | `dll_rx_drv`, `dll_tx_responder`, both monitors |
