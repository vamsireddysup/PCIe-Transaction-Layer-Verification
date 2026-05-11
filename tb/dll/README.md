# tb/dll — DLL Agents

Two separate agents handle the DLL interface:
- **DLL TX Agent** — observes what the DUT sends to the DLL, drives `tx_ready_i` back
- **DLL RX Agent** — drives TLPs (completions, linkup, VC status) into the DUT

---

## Files

| File | Week | Description |
|------|------|-------------|
| `tl_dll_intf.sv`      | M1 | TL-DLL interface with `mon_cb` clocking block |
| `dll_item.sv`         | M2 | Sequence item representing a full TLP |
| `dll_tx_responder.sv` | M2 | State machine that samples DUT TX output, parses TLP fields |
| `dll_tx_mon.sv`       | M2 | Monitor: collects complete TLPs from DUT TX path |
| `dll_tx_agent.sv`     | M2 | Agent: creates responder + monitor |
| `dll_rx_drv.sv`       | M2 | Driver: injects TLPs into DUT RX path |
| `dll_rx_mon.sv`       | M2 | Monitor: observes DUT RX path |
| `dll_rx_cov.sv`       | M4 | Coverage: RX TLP type covergroup |
| `dll_rx_agent.sv`     | M2 | Agent: creates drv, sqr, mon, cov |
| `dll_rx_seq_lib.sv`   | M3 | Sequences: linkup, VC-up, CplD reactive driver |

---

## DLL Interface Signals

### TX (DUT → DLL)
| Signal | Width | Description |
|--------|-------|-------------|
| `tx_data_o`  | 32 | One DW of TLP data per clock |
| `tx_valid_o` | 1  | DUT has valid data to send |
| `tx_ready_i` | 1  | DLL is ready to accept (driven by TB) |
| `vc_num`     | 3  | Which Virtual Channel is being used |

### RX (DLL → DUT)
| Signal | Width | Description |
|--------|-------|-------------|
| `rx_data_i`   | 32 | One DW of incoming TLP per clock |
| `rx_valid_i`  | 1  | DLL has valid data (driven by TB) |
| `rx_ready_o`  | 1  | DUT is ready to receive |
| `linkup`      | 1  | DLL reports link is up (driven by TB) |
| `dll_vc_up`   | 8  | Bitmask: which VCs are initialized (driven by TB) |

---

## DLL TX Responder — State Machine

The responder is **not a typical sequence driver**. It runs autonomously,  
watching the DUT output and parsing TLP fields into `pcie_common` static variables.

```
S_IDLE_DUMMY  →  (first tx_valid_o) → S_IDLE
S_IDLE        →  (tx_valid_o=1)    → S_TLP_FIRST_DW
S_TLP_FIRST_DW  → parse DW0 (FMT, TYPE, Tag, TC, packet_len)
                → S_TLP_SECOND_DW
S_TLP_SECOND_DW → parse DW1 (Requester ID, Tag[7:0], DW BE)
                → S_TLP_THIRD_DW
S_TLP_THIRD_DW  → parse DW2 (Target B/D/F, RegNum or Address)
                → determine TLP type → set pcie_common::rcvd_tlp
                → if FMT[1]=1 (has payload) → S_TLP_PAYLOAD
                → else → S_IDLE_DUMMY
S_TLP_PAYLOAD   → collect payload DWs
                → when count==packet_len → S_IDLE_DUMMY
```

Always drive `tx_ready_i=1` when `tx_valid_o=1`.

---

## TLP Type Detection (DW0)

| FMT[2:0] | TYPE[4:0] | Meaning |
|----------|-----------|---------|
| `000` | `00100` | CfgRd0 |
| `010` | `00100` | CfgWr0 |
| `000` | `00101` | CfgRd1 |
| `010` | `00101` | CfgWr1 |
| `000` | `00000` | MRd    |
| `010` | `00000` | MWr    |

`FMT[1]=1` means the TLP has a payload.

---

## Known Bug

**`dll_tx_mon.sv`** — First TLP DW is silently dropped because `dw_count` starts at 0  
but the capture begins at `dw_count==1`. Fix this in Week 5.

**`dll_tx_responder.sv`** — In `S_TLP_PAYLOAD`, `pop_front()` is called before  
`push_back()`. Fix the ordering in Week 5.
