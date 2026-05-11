# Week 5 — Scoreboard and Bug Fixes

Final week. I'm implementing the scoreboard, fixing all 7 known bugs, and getting a clean TEST PASSED result with real match counts in the report.

---

## What I studied

- UVM User Guide chapter 10: scoreboards, `uvm_tlm_analysis_fifo`
- Traced every bug from the code review — understood the root cause before touching any code

---

## Bug fix checklist

Work through these one at a time. Check each off after testing.

---

### Bug 1 — `test_lib.sv:30` — PASS condition impossible

```sv
// What it says now (always false — can't be >0 AND ==0 at the same time):
(pcie_common::num_tx_rx_matches > 0 && pcie_common::num_tx_rx_matches == 0)

// What it should say:
(pcie_common::num_tx_rx_matches > 0 && pcie_common::num_tx_rx_mismatches == 0)
```
This one bug means the test can never pass, no matter what else is working.

---

### Bug 2 — `design/pcie_tl.sv:564` — Wrong requester ID field

```sv
// Wrong (device_num used twice):
header[1][31:16] = {requester_bus_num, requester_device_num, requester_device_num};

// Correct:
header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
```
Every CFG TLP sent by the DUT has a malformed requester ID until this is fixed.

---

### Bug 3 — `pcie_tl_env.sv` — `mem_agent` never created

In `build_phase`, add:
```sv
mem_agent_i = mem_agent::type_id::create("mem_agent_i", this);
```
And in `connect_phase` wire its monitor's `ap_port` to the scoreboard.

---

### Bug 4 — `dll_item.sv:88` — Hardcoded CplD payload

Remove this line from `header_c`:
```sv
payloadQ[0] == 32'h1234_5678   // delete this
```
`post_randomize()` already sets `payloadQ[0]` correctly from `dll_cfg_rx`. The constraint was overriding it with a fixed value.

---

### Bug 5 — `dll_tx_responder.sv` — Pop before push in `S_TLP_PAYLOAD`

```sv
// Current order (wrong): pops from empty queue on first beat
if (...) pcie_common::ep_bar0_base_addr = payloadQ.pop_front();
count++;
payloadQ.push_back(vif.tx_data_o);   // pushed after the pop

// Fix: push first, process on the next beat (use a one-cycle delay or reorder)
payloadQ.push_back(vif.tx_data_o);
if (count > 0 && ...) pcie_common::ep_bar0_base_addr = payloadQ.pop_front();
count++;
```

---

### Bug 6 — `dll_tx_mon.sv:31` — First TLP DW dropped

```sv
// dw_count starts at 0. Currently captures starting at dw_count==1, skipping DW0.
if (dw_count == 1) begin   // this skips dw_count==0, losing FMT/TYPE DW

// Fix: start capture at dw_count==0
if (dw_count == 0) begin
  tx = new();
  tx.headerQ.push_back(vif.mon_cb.tx_data_o);
  // parse fmt and type here
end
if (dw_count == 1) tx.headerQ.push_back(...);
if (dw_count == 2) tx.headerQ.push_back(...);
if (dw_count >= 3) tx.payloadQ.push_back(...);
```

---

### Bug 7 — All agents extend `uvm_test` instead of `uvm_agent`/`uvm_env`

| File | Change |
|------|--------|
| `axi_agent.sv` | `extends uvm_agent` |
| `dll_rx_agent.sv` | `extends uvm_agent` |
| `dll_tx_agent.sv` | `extends uvm_agent` |
| `mem_agent.sv` | `extends uvm_agent` |
| `pcie_tl_env.sv` | `extends uvm_env` |

---

## Scoreboard — `tl_sbd.sv`

```sv
class tl_sbd extends uvm_scoreboard;

  uvm_tlm_analysis_fifo #(axi_tx)   axi_fifo;
  uvm_tlm_analysis_fifo #(dll_item) tx_tlp_fifo;
  uvm_tlm_analysis_fifo #(dll_item) rx_tlp_fifo;

  // build_phase: new all three fifos

  // connect_phase (in env):
  //   axi_agent_i.mon.ap_port    → tl_sbd_i.axi_fifo.analysis_export
  //   dll_tx_agent_i.mon.ap_port → tl_sbd_i.tx_tlp_fifo.analysis_export
  //   dll_rx_agent_i.mon.ap_port → tl_sbd_i.rx_tlp_fifo.analysis_export

  task run_phase(uvm_phase phase);
    fork
      check_tx_tlps();
      check_rx_tlps();
    join
  endtask
```

**`check_tx_tlps()`** — verify what the DUT sends out
- Pull from `tx_tlp_fifo`
- Check FMT/TYPE encoding matches expected TLP type
- Check requester ID fields are correct
- Check `packet_len` is 0 for CFG_RD, 1 for CFG_WR
- Increment `pcie_common::num_tx_matches` or `num_tx_mismatches`

**`check_rx_tlps()`** — verify the completion payloads are correct
- Pull from `rx_tlp_fifo`
- Compare `payloadQ[0]` against the matching `dll_cfg_rx` register value for that `reg_num`
- Increment `pcie_common::num_rx_matches` or `num_rx_mismatches`

---

## What a passing run looks like

```
# UVM_INFO ... [UVMTOP] UVM testbench topology:
# ...
# AXI_WR: write_addr
# AXI_WR: write_data
# ...
# =================== Driving CplD ============ 1
# =================== Driving CplD ============ 16
# UVM_INFO test_lib.sv @ 1005: [STATUS] TEST PASSED
# UVM_INFO test_lib.sv @ 1005: [STATUS] num_tx_matches=16
# UVM_INFO test_lib.sv @ 1005: [STATUS] num_rx_matches=16
# UVM_INFO test_lib.sv @ 1005: [STATUS] num_tx_rx_matches=16
# UVM_ERROR :    0
# UVM_FATAL :    0
```

---

## Stretch goals

- Implement `S_MEM_WR` in `design/pcie_tl.sv` and add a test for it
- Implement `dll_cfg_rx::vip_cfg_as_switch()` and test with `target_device_type=SWITCH`
- Add a negative test: corrupt the TLP header and confirm the DUT hits `S_ENUM_ERROR`

---

## Done when

- [ ] All 7 bugs fixed
- [ ] Simulation log shows `TEST PASSED`
- [ ] All match counters > 0, all mismatch counters == 0
- [ ] No `UVM_ERROR` or `UVM_FATAL`
- [ ] Final transcript saved to `M5/docs/`
- [ ] Final coverage report saved to `M5/docs/`
