# tb/mem/ — Memory Model

A behavioral AXI4 slave that acts as the memory connected to the DUT's memory-side interface.  
1 MB, initialized with random data at simulation start. Base address: `0x8000_0000`.

---

## Files

| File | What it does |
|------|-------------|
| `mem_agent.sv` | Contains `memory`, `mem_mon`, and `mem_agent` all in one file |

---

## `memory` — AXI4 slave behavior

```
awvalid=1  → assert awready, latch address
wvalid=1   → write wdata into mem[], increment address
wlast=1    → send write response (bvalid=1, bresp=OKAY)
arvalid=1  → assert arready, latch read address
           → drive rdata/rvalid/rlast for each burst beat
```

Gets its interface via:
```sv
uvm_resource_db#(virtual axi_intf)::read_by_name("AXI", "MIF", vif, this);
```

---

## `mem_mon` — memory-side observer

Monitors the DUT's memory AXI interface and publishes completed `axi_tx` objects.  
Has an `ignore_first_dw_f` flag — the first DW of a DMA payload coming from the DUT is a descriptor header, not actual data, so the monitor skips it.

Connect `mon.ap_port` to `tl_sbd_i.axi_fifo.analysis_export` in Week 5.

---

## `mem_agent`

Extends `uvm_agent` (not `uvm_test`). Creates `memory` and `mem_mon` in `build_phase`.

This agent is not instantiated in the reference implementation (Bug #3). Fix it in Week 5.
