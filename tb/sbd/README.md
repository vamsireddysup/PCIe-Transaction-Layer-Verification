# tb/sbd — Scoreboard

The scoreboard verifies end-to-end data integrity by comparing  
what the DUT **transmits** against what it **receives** and what was **configured**.

---

## Files

| File | Week | Description |
|------|------|-------------|
| `tl_sbd.sv` | M5 | Scoreboard: TX TLP checker, RX TLP checker, AXI data checker |

---

## What to Check

### TX TLP Verification (`check_tx_tlps`)

For each TLP the DUT sends out (captured by `dll_tx_mon`):

| Check | Expected Value | Source |
|-------|---------------|--------|
| `FMT[2:0]` | Matches TLP type | `pcie_common` defines |
| `TYPE[4:0]` | Matches TLP type | `pcie_common` defines |
| `Tag` | Consistent with request | `pcie_common::tag` |
| `packet_len` | 0 for CFG_RD, 1 for CFG_WR | PCIe spec |
| Target B/D/F | Matches configured target | DUT register values |

### RX TLP Verification (`check_rx_tlps`)

For each CplD the testbench drives in (captured by `dll_rx_mon`):

| Check | Expected Value |
|-------|---------------|
| `FMT` = `010` | CplD always has data |
| `TYPE` = `01010` | Completion with Data |
| `payload[0]` | Matches `dll_cfg_rx` value for that `reg_num` |

### TX↔RX Correlation (`num_tx_rx_matches`)

For each CFG_RD TLP sent: verify that exactly one matching CplD was received  
with the correct `tag` and `requester_id`.

---

## Scoreboard Pattern

```
monitor ap_port → uvm_tlm_analysis_fifo → scoreboard get()
```

```sv
class tl_sbd extends uvm_scoreboard;
  uvm_tlm_analysis_fifo #(axi_tx)   axi_fifo;
  uvm_tlm_analysis_fifo #(dll_item) tx_tlp_fifo;
  uvm_tlm_analysis_fifo #(dll_item) rx_tlp_fifo;

  task run_phase(uvm_phase phase);
    fork
      forever begin
        axi_tx tx;
        axi_fifo.get(tx);
        // check tx
      end
      forever begin
        dll_item tlp;
        tx_tlp_fifo.get(tlp);
        // check tlp
      end
    join
  endtask
endclass
```

---

## Counter Variables (in `pcie_common`)

| Variable | Incremented when |
|----------|-----------------|
| `num_tx_matches`      | DUT TX TLP fields are correct |
| `num_tx_mismatches`   | DUT TX TLP has a wrong field |
| `num_rx_matches`      | CplD payload matches expected register value |
| `num_rx_mismatches`   | CplD payload doesn't match |
| `num_tx_rx_matches`   | Each CFG_RD has a matching CplD |
| `num_tx_rx_mismatches`| CFG_RD with no matching or wrong CplD |

---

## Bug to Fix (Week 5)

`test_lib.sv:30` — The PASS condition checks `num_tx_rx_matches == 0`  
instead of `num_tx_rx_mismatches == 0`. This makes the test always fail.
