# tb/sbd/ — Scoreboard

Verifies end-to-end correctness. Three things to check:
1. TLPs the DUT sends out have correct header fields
2. Completion payloads match the endpoint's actual register values
3. Every CFG_RD has exactly one matching CplD returned

---

## Files

| File | Week |
|------|------|
| `tl_sbd.sv` | M5 |

---

## Structure

```sv
class tl_sbd extends uvm_scoreboard;

  uvm_tlm_analysis_fifo #(axi_tx)   axi_fifo;    // from mem_mon
  uvm_tlm_analysis_fifo #(dll_item) tx_tlp_fifo; // from dll_tx_mon
  uvm_tlm_analysis_fifo #(dll_item) rx_tlp_fifo; // from dll_rx_mon

  task run_phase;
    fork
      check_tx_tlps();
      check_rx_tlps();
    join
  endtask
```

---

## What each checker does

**`check_tx_tlps()`** — pulls from `tx_tlp_fifo`
- For each CFG_RD: verify FMT=`000`, TYPE=`00100`, packet_len=0
- For each CFG_WR: verify FMT=`010`, TYPE=`00100`, packet_len=1
- Check requester ID fields match configured values
- Increment `pcie_common::num_tx_matches` or `num_tx_mismatches`

**`check_rx_tlps()`** — pulls from `rx_tlp_fifo`
- For each CplD: look up `dll_cfg_rx` register value for `pcie_common::reg_num`
- Compare against `payloadQ[0]`
- Increment `pcie_common::num_rx_matches` or `num_rx_mismatches`

---

## Counters (all in `pcie_common`)

| Counter | Meaning |
|---------|---------|
| `num_tx_matches` | DUT TX TLPs with correct fields |
| `num_tx_mismatches` | DUT TX TLPs with wrong fields |
| `num_rx_matches` | CplD payloads that matched expected register data |
| `num_rx_mismatches` | CplD payloads that didn't match |
| `num_tx_rx_matches` | CFG_RDs that got a correct completion back |
| `num_tx_rx_mismatches` | CFG_RDs with no or wrong completion |

---

## Known bug in `test_lib.sv`

The `report_phase` PASS condition has a typo — it checks `num_tx_rx_matches == 0` instead of `num_tx_rx_mismatches == 0`. So the pass branch is logically impossible. Fix this in Week 5.
