# Week 5 — M5: Scoreboard, Bug Fixes & Test Closure

**Goal:** Implement the scoreboard, fix all known bugs, wire the complete  
environment, and achieve a **TEST PASSED** result with meaningful match counts.

---

## What to Study This Week

1. **UVM User Guide** — Chapter 10 (scoreboards, TLM FIFOs)
2. Review the **Known Bugs** table in the root `README.md`
3. Study `tb/sbd/tl_sbd.sv` skeleton — understand what it needs to check
4. Understand `uvm_tlm_analysis_fifo` — how to buffer transactions for comparison

---

## Learning Objectives

- Implement a `uvm_scoreboard` that connects to multiple monitors
- Use `uvm_tlm_analysis_fifo` to decouple producer (monitor) and consumer (scoreboard)
- Understand how to match TX (AXI write) transactions to RX (memory) transactions
- Understand the PASS/FAIL reporting pattern in `report_phase`
- Practice reading simulation logs to diagnose failures

---

## UVM/ — What to Implement

Work in `M5/UVM/`. This is your final, complete testbench.

---

### Scoreboard (`tl_sbd.sv`)

```
class tl_sbd extends uvm_scoreboard;

  uvm_tlm_analysis_fifo #(axi_tx)  axi_fifo;    // from axi_mon
  uvm_tlm_analysis_fifo #(dll_item) tx_tlp_fifo; // from dll_tx_mon
  uvm_tlm_analysis_fifo #(dll_item) rx_tlp_fifo; // from dll_rx_mon

  `uvm_component_utils(tl_sbd)

  function void build_phase(uvm_phase phase);
    axi_fifo    = new("axi_fifo",    this);
    tx_tlp_fifo = new("tx_tlp_fifo", this);
    rx_tlp_fifo = new("rx_tlp_fifo", this);
  endfunction

  // Connections (in pcie_tl_env connect_phase):
  //   axi_agent_i.mon.ap_port      → tl_sbd_i.axi_fifo.analysis_export
  //   dll_tx_agent_i.mon.ap_port   → tl_sbd_i.tx_tlp_fifo.analysis_export
  //   dll_rx_agent_i.mon.ap_port   → tl_sbd_i.rx_tlp_fifo.analysis_export

  task run_phase(uvm_phase phase);
    fork
      check_tx_tlps();   // verify DUT sends correct TLPs for given AXI commands
      check_rx_tlps();   // verify CplD payload matches dll_cfg_rx config data
    join
  endtask

  task check_tx_tlps();
    // For each CFG_RD0 TLP in tx_tlp_fifo:
    //   Verify FMT/TYPE encoding is correct
    //   Verify tag matches pcie_common::tag
    //   Verify target B/D/F matches what was configured
    //   Increment pcie_common::num_tx_matches or num_tx_mismatches
  endtask

  task check_rx_tlps();
    // For each CplD TLP in rx_tlp_fifo:
    //   Compare payloadQ[0] against expected value from dll_cfg_rx::mem[reg_num]
    //   Increment pcie_common::num_rx_matches or num_rx_mismatches
  endtask

endclass
```

---

### Bug Fix Checklist

Fix each of the following before running M5. Check them off as you go.

#### Bug 1 — `test_lib.sv:30` — PASS condition always false
```sv
// Current (WRONG): num_tx_rx_matches > 0 && num_tx_rx_matches == 0  ← contradiction
// Fix: change the second part to check mismatches
(pcie_common::num_tx_rx_matches > 0 && pcie_common::num_tx_rx_mismatches == 0)
```

#### Bug 2 — `design/pcie_tl.sv:564` — Wrong requester ID field
```sv
// Current (WRONG):
header[1][31:16] = {requester_bus_num, requester_device_num, requester_device_num};
// Fix:
header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
```

#### Bug 3 — `tb/top/pcie_tl_env.sv` — mem_agent not instantiated
```sv
// Add to build_phase:
mem_agent_i = mem_agent::type_id::create("mem_agent_i", this);
// And connect in connect_phase:
mem_agent_i.mon.ap_port.connect(tl_sbd_i.axi_fifo.analysis_export);
//   (or whichever fifo is appropriate)
```

#### Bug 4 — `dll_item.sv:88` — Hardcoded CplD payload
```sv
// Current (WRONG):
payloadQ[0] == 32'h1234_5678
// Remove this line from header_c constraint.
// The post_randomize() already fills payloadQ[0] correctly from dll_cfg_rx.
```

#### Bug 5 — `tb/dll/dll_tx_responder.sv` — pop before push in S_TLP_PAYLOAD
```sv
// Reorder: push first, then pop on the next clock cycle.
// One fix: use a separate 'first_payload_beat' flag to delay the pop by one beat.
```

#### Bug 6 — `tb/dll/dll_tx_mon.sv:31` — First DW silently dropped
```sv
// dw_count starts at 0. The check 'if (dw_count == 1)' skips DW index 0.
// Fix: change to 'if (dw_count == 0)' and update subsequent indices accordingly.
// Or initialize dw_count to 0 and change the check logic to match.
```

---

### Complete `pcie_tl_env.sv`

```
class pcie_tl_env extends uvm_env;

  axi_agent     axi_agent_i;
  dll_tx_agent  dll_tx_agent_i;
  dll_rx_agent  dll_rx_agent_i;
  mem_agent     mem_agent_i;
  tl_sbd        tl_sbd_i;

  // build_phase: create all above
  // connect_phase:
  //   axi_agent_i.mon.ap_port    → tl_sbd_i.axi_fifo.analysis_export
  //   dll_tx_agent_i.mon.ap_port → tl_sbd_i.tx_tlp_fifo.analysis_export
  //   dll_rx_agent_i.mon.ap_port → tl_sbd_i.rx_tlp_fifo.analysis_export

  // DO NOT add a run_phase timeout here
endclass
```

---

### `report_phase` in `pcie_tl_base_test`

After fixing Bug 1, the report logic should be:

```sv
function void report_phase(uvm_phase phase);
  if (pcie_common::num_tx_matches > 0       && pcie_common::num_tx_mismatches == 0 &&
      pcie_common::num_rx_matches > 0       && pcie_common::num_rx_mismatches == 0 &&
      pcie_common::num_tx_rx_matches > 0    && pcie_common::num_tx_rx_mismatches == 0) begin
    `uvm_info("STATUS", "TEST PASSED", UVM_NONE)
  end else begin
    `uvm_error("STATUS", "TEST FAILED")
    // print all counters
  end
endfunction
```

---

## Expected Simulation Log (passing)

```
UVM_INFO @ 0: reporter [UVMTOP] UVM testbench topology:
...
# AXI_WR: write_addr
# AXI_WR: write_data
# AXI_WR: write_resp
...
# Performing write to Register at addr=00001004
# =================== Driving CplD ============ 1
# Inside dll_rx_drv
# tlp_first_dw = 000000c4
# fmt = 000, type = 00100
...
# =================== Driving CplD ============ 16
# UVM_INFO ... [STATUS] TEST PASSED
# UVM_INFO ... [STATUS] num_tx_matches=16
# UVM_INFO ... [STATUS] num_rx_matches=16
# UVM_INFO ... [STATUS] num_tx_rx_matches=16
```

---

## Final Deliverables

- [ ] All 7 bugs fixed (checked off in the Bug Fix Checklist above)
- [ ] Simulation log shows `TEST PASSED`
- [ ] `num_tx_matches`, `num_rx_matches`, `num_tx_rx_matches` all > 0
- [ ] `num_*_mismatches` all == 0
- [ ] Coverage report shows >80% on all covergroups
- [ ] No `UVM_ERROR` or `UVM_FATAL` messages
- [ ] Final waveform saved to `M5/docs/`
- [ ] Final transcript saved to `M5/docs/`

---

## Stretch Goals (if time allows)

- Implement `S_MEM_WR` in the DUT and verify a full DMA write transfer end-to-end
- Add a memory read-back sequence that reads via `S_MEM_RD` and verifies data integrity
- Implement `dll_cfg_rx::vip_cfg_as_switch()` and test with `target_device_type=SWITCH`
- Add a negative test: drive a malformed TLP and verify the DUT enters `S_ENUM_ERROR`
