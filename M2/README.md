# Week 2 — UVM Agents

This week I'm converting the class-based testbench into a proper UVM structure. The goal is to have working UVM agents for the AXI side and both DLL sides (TX and RX) by the end of the week.

---

## What I studied

- UVM User Guide chapters 3–6: components, phases, TLM ports, agents
- `uvm_driver`, `uvm_monitor`, `uvm_sequencer`, `uvm_agent` class reference
- How `uvm_resource_db` works for passing virtual interfaces

---

## Things I needed to get straight before coding

**UVM component hierarchy:**
```
uvm_test → uvm_env → uvm_agent → driver/monitor/sequencer
```
Agents extend `uvm_agent`. Environments extend `uvm_env`. Not `uvm_test`. I mixed these up on my first pass.

**Phases run in order:** `build_phase` → `connect_phase` → `run_phase`.  
Create sub-components in `build_phase`. Wire ports in `connect_phase`. Drive/monitor in `run_phase`.

**Clocking blocks matter:** Always drive the interface through `vif.bfm_cb.signal <= value`, not directly. Driving without a clocking block can cause race conditions with the DUT.

**Virtual interface vs interface:** The interface lives in the testbench module. The class-side code gets a `virtual` handle to it. Pass it through `uvm_resource_db` in `top_tb`, retrieve it in `build_phase`.

---

## UVM/ — What I built this week

### AXI agent

**`axi_tx.sv`** — sequence item
```
Fields: txid, addr, dataQ[$], strbQ[$], wr_rd, burst_len, burst_type, burst_size, resp
Constraints:
  dataQ.size() == burst_len + 1
  burst_type != RSVD_BT
  soft defaults: INCR burst, 4-byte wide, 1 beat, 32-bit aligned, write
```

**`axi_drv.sv`** — drives the processor AXI interface
```
get_next_item → drive_tx → item_done (forever loop)
write path: write_addr() → write_data() → write_resp()
read path:  read_addr() → read_data()
Use vif.bfm_cb for all signal drives
Wait for awready/wready/bvalid using wait()
```

**`axi_mon.sv`** — observes the AXI interface, assembles complete transactions
```
Watch mon_cb each cycle
awvalid && awready → start capturing write tx
wvalid && wready → collect data beats
bvalid && bready → send completed axi_tx to ap_port
Same logic for read channel
```

**`axi_agent.sv`** — extends `uvm_agent` (not `uvm_test`)
```
build_phase:   create drv, sqr, mon, cov
connect_phase: drv.seq_item_port.connect(sqr.seq_item_export)
               mon.ap_port.connect(cov.analysis_export)
```

---

### DLL TX agent — the responder pattern

This one is different. The DUT is the one sending TLPs out on `tx_data_o`. My responder watches what comes out, parses the TLP fields, and drives `tx_ready_i` back.

**`dll_tx_responder.sv`** — state machine running on `posedge tl_dll_clk`
```
S_IDLE_DUMMY → S_IDLE → S_TLP_FIRST_DW → S_TLP_SECOND_DW → S_TLP_THIRD_DW → S_TLP_PAYLOAD

S_TLP_FIRST_DW:
  extract FMT[31:29], TYPE[28:24], Tag, TC, packet_len from tx_data_o
  store into pcie_common:: static variables

S_TLP_SECOND_DW:
  extract Requester ID, Tag[7:0], DW byte enables

S_TLP_THIRD_DW:
  extract Target B/D/F and RegNum (for CFG) or Address (for MEM)
  set pcie_common::rcvd_tlp (e.g. CfgRd0)
  set pcie_common::transmit_tlp (e.g. CplD)
  increment pcie_common::rcvd_tlp_count

Always drive tx_ready_i=1 when tx_valid_o=1
```

**`dll_tx_mon.sv`** — collects complete TLPs from DUT TX output, sends to `ap_port`

**`dll_tx_agent.sv`** — extends `uvm_agent`, creates responder + monitor

---

### DLL RX agent — injects TLPs into the DUT

**`dll_rx_drv.sv`** — drives the DLL RX interface
```
if linkup_indicate=1 → vif.linkup = 1
if vc_status_vector=8'hFF → vif.dll_vc_up = 8'hFF
else → drive headerQ DWs then payloadQ DWs with rx_valid_i=1
```

**`dll_rx_mon.sv`** — observes what goes into the DUT on rx_data_i  
**`dll_rx_agent.sv`** — extends `uvm_agent`, creates drv + sqr + mon + cov

---

### Environment

**`pcie_tl_env.sv`** — extends `uvm_env` (not `uvm_test`)
- Creates axi_agent, dll_tx_agent, dll_rx_agent, mem_agent
- No `#1000` timeout in run_phase — the test manages objections, not the env

---

## Mistakes I made / things to watch out for

| What I did wrong | What it should be |
|-----------------|-------------------|
| `axi_agent extends uvm_test` | must be `uvm_agent` |
| `pcie_tl_env extends uvm_test` | must be `uvm_env` |
| Semicolons after `` `include `` | no semicolons — `` `include "file.sv"`` |
| Driving `vif.signal <= value` directly | use `vif.bfm_cb.signal <= value` |
| Forgot to call `super.build_phase(phase)` | always call it first |

---

## How to run

```bash
cd M2/UVM
vlog -sv +incdir+. +incdir+../../Packages/uvm-1.2/src \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```

---

## Done when

- [ ] UVM topology prints (I call `uvm_top.print_topology()` in `end_of_elaboration_phase`)
- [ ] AXI driver completes a write without hanging
- [ ] AXI monitor prints the captured `axi_tx` object
- [ ] DLL TX responder steps through `S_TLP_FIRST_DW → S_TLP_THIRD_DW`
