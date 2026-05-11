# Week 2 — M2: UVM Agents (AXI + DLL)

**Goal:** Convert the class-based testbench into a proper UVM agent structure.  
By the end of this week you will have a working UVM environment that drives  
AXI transactions and responds to DLL interface signals.

---

## What to Study This Week

1. **UVM User Guide** — Chapters 3–6 (components, phases, TLM, agents)
2. **UVM Class Reference** — `uvm_driver`, `uvm_monitor`, `uvm_sequencer`, `uvm_agent`
3. Review `tb/axi/` skeleton files — understand the structure before filling them in
4. Review `tb/dll/` skeleton files — DLL responder pattern is different from a typical driver

---

## Learning Objectives

- Understand the UVM component hierarchy: `uvm_test` → `uvm_env` → `uvm_agent`
- Understand UVM phases: `build_phase` → `connect_phase` → `run_phase`
- Know the difference between a **driver** (active, drives interface) and a **monitor** (passive, observes)
- Understand `uvm_resource_db` / `uvm_config_db` for passing virtual interfaces
- Understand **clocking blocks** — why `bfm_cb` uses `@(posedge clk)` timing

---

## UVM/ — What to Implement

Work in `M2/UVM/`. Copy the interface files from `M1/CLASS/` or `tb/` as your starting point.

### AXI Agent (`tb/axi/`)

#### `axi_tx.sv` — Sequence Item
```
Fields:     txid, addr, dataQ[$], strbQ[$], wr_rd, burst_len, burst_type, burst_size, resp
Constraints:
  - dataQ.size() == burst_len + 1
  - burst_type != RSVD_BT
  - soft: burst_type==INCR, burst_size==2, burst_len==0, addr%4==0, wr_rd==1
```

#### `axi_drv.sv` — Driver
```
- Extend uvm_driver#(axi_tx)
- build_phase: retrieve virtual axi_intf from resource_db ("AXI")
- run_phase: forever loop — get_next_item → drive_tx → item_done
- drive_tx: call write_addr/write_data/write_resp OR read_addr/read_data
- Implement each task using vif.bfm_cb (clocking block)
- Wait for awready/wready/bvalid using wait() or @(vif.bfm_cb)
```

#### `axi_mon.sv` — Monitor
```
- Extend uvm_monitor
- build_phase: retrieve virtual axi_intf from resource_db; create ap_port
- run_phase: observe mon_cb; when awvalid&&awready → capture write address
             when wvalid&&wready → capture data beats
             when bvalid&&bready → send completed axi_tx to ap_port
             similarly for read channel
```

#### `axi_agent.sv` — Agent
```
- Extend uvm_agent (NOT uvm_test)
- build_phase: create drv, sqr, mon, cov
- connect_phase: drv.seq_item_port.connect(sqr.seq_item_export)
                 mon.ap_port.connect(cov.analysis_export)
```

---

### DLL TX Agent (`tb/dll/`) — Responder Pattern

The DLL TX agent observes what the **DUT sends** out and drives back `tx_ready_i`.  
This is the opposite of a normal driver — it reacts to DUT output.

#### `dll_tx_responder.sv`
```
- Extend uvm_driver#(dll_item) — but it doesn't consume sequence items normally
- State machine: S_IDLE → S_TLP_FIRST_DW → S_TLP_SECOND_DW → S_TLP_THIRD_DW → S_TLP_PAYLOAD
- On each posedge tl_dll_clk: if tx_valid_o==1, sample tx_data_o and advance state
- In S_TLP_FIRST_DW: extract FMT[31:29] and TYPE[28:24] from DW0
                      store fields into pcie_common:: static variables
- In S_TLP_SECOND_DW: extract Requester ID, Tag, DW BE fields
- In S_TLP_THIRD_DW: extract Target B/D/F, RegNum, Address
                      determine TLP type → set pcie_common::rcvd_tlp
                      increment pcie_common::rcvd_tlp_count
- Drive vif.tx_ready_i=1 when vif.tx_valid_o==1
```

#### `dll_tx_mon.sv`
```
- Extend uvm_monitor; observe tx_data_o/tx_valid_o/tx_ready_i via mon_cb
- When both valid and ready: collect DWs into headerQ then payloadQ
- When valid drops: call ap_port.write(tx)
```

---

### DLL RX Agent (`tb/dll/`) — Drives TLPs into the DUT

#### `dll_rx_drv.sv`
```
- Extend uvm_driver#(dll_item)
- build_phase: retrieve virtual tl_dll_intf from resource_db ("DLL")
- drive_tx: if linkup_indicate==1 → set vif.linkup=1
             if vc_status_vector==8'hFF → set vif.dll_vc_up=8'hFF
             else → drive headerQ DWs then payloadQ DWs with rx_valid_i=1
```

---

### Environment + Test

#### `pcie_tl_env.sv`
```
- Extend uvm_env (NOT uvm_test)
- Instantiate: axi_agent_i, dll_tx_agent_i, dll_rx_agent_i, mem_agent_i
- DO NOT add a run_phase timeout here — let the test manage objections
```

#### `test_lib.sv` — Base test
```
- pcie_tl_base_test extends uvm_test
- build_phase: create env
- run_phase: raise objection, #1000, drop objection (placeholder)
```

---

## Common Mistakes to Avoid

| Mistake | Correct Approach |
|---------|-----------------|
| Agent extends `uvm_test` | Agent must extend `uvm_agent` |
| Environment extends `uvm_test` | Environment must extend `uvm_env` |
| Driving interface signals directly (not via clocking block) | Always use `vif.bfm_cb.signal <= value` |
| Semicolons after `` `include `` | Remove them — `` `include "file.sv"`` not `` `include "file.sv";`` |
| `wait(vif.signal)` without clocking block | Can cause zero-time loops; use `@(vif.bfm_cb)` first |

---

## Success Criteria

- [ ] UVM topology prints all agents (use `uvm_top.print_topology()` in `end_of_elaboration_phase`)
- [ ] AXI driver completes a write transaction without hanging
- [ ] AXI monitor captures the write and prints the `axi_tx` object
- [ ] DLL TX responder transitions through `S_TLP_FIRST_DW → S_TLP_THIRD_DW`

---

## Run Instructions

```bash
cd M2/UVM
vlog -sv +incdir+. +incdir+../../tb/common +incdir+../../tb/axi +incdir+../../tb/dll \
     ../../Packages/uvm-1.2/src/uvm_pkg.sv \
     ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb +UVM_TESTNAME=pcie_tl_base_test -do "run -all; quit"
```
