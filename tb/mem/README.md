# tb/mem — Memory Model

A behavioral memory model that acts as the AXI4 slave on the **memory side** of the DUT.

---

## Files

| File | Week | Description |
|------|------|-------------|
| `mem_agent.sv` | M2 | Contains `memory`, `mem_mon`, `mem_agent` classes |

---

## `memory` — The AXI4 Slave

A 1 MB memory initialized with random data at simulation start.  
Base address: `0x8000_0000`.

### Behavior
- When `awvalid=1` → assert `awready=1`, latch address
- When `wvalid=1` → accept data into `mem[]` array, track address
- When `wlast=1` → send write response (`bvalid=1`, `bresp=OKAY`)
- When `arvalid=1` → assert `arready=1`, latch read address
- Drive `rdata`, `rvalid`, `rlast` for each beat of the burst

### Resource DB Key
```sv
uvm_resource_db#(virtual axi_intf)::read_by_name("AXI", "MIF", vif, this);
```

---

## `mem_mon` — Monitors Memory Transactions

Observes the AXI memory interface and publishes completed `axi_tx` objects.  
Subscribe the scoreboard to this monitor's `ap_port` in Week 5.

**Note:** There is an `ignore_first_dw_f` flag in `mem_mon`.  
The first DW of the DMA payload from the DUT is a descriptor header word,  
not actual payload data. The monitor skips it.

---

## `mem_agent` — The Agent

```sv
class mem_agent extends uvm_agent;  // (not uvm_test!)
  memory mem;
  mem_mon mon;
  // build_phase: create both
endclass
```

Instantiate `mem_agent_i` in `pcie_tl_env` and connect  
`mon.ap_port` to `tl_sbd_i.axi_fifo.analysis_export` in `connect_phase`.
