# tb/dll/ — DLL Agents

Two separate agents for the DLL interface:
- **TX agent** — watches what the DUT sends out, drives `tx_ready_i` back, parses TLP fields
- **RX agent** — drives TLPs (completions, linkup, VC status) into the DUT

---

## Files

| File | Week | What it does |
|------|------|-------------|
| `tl_dll_intf.sv` | M1 | Interface: TX and RX signals + `mon_cb` |
| `dll_item.sv` | M2 | Sequence item representing one complete TLP |
| `dll_tx_responder.sv` | M2 | Parses DUT TX output, stores fields in `pcie_common`, drives `tx_ready_i` |
| `dll_tx_mon.sv` | M2 | Collects complete TLPs from DUT TX, sends to `ap_port` |
| `dll_tx_agent.sv` | M2 | Agent: creates responder + monitor |
| `dll_rx_drv.sv` | M2 | Drives linkup, VC-up, and TLP DWs into DUT RX |
| `dll_rx_mon.sv` | M2 | Observes DUT RX input, sends to `ap_port` |
| `dll_rx_cov.sv` | M4 | Coverage: RX TLP type |
| `dll_rx_agent.sv` | M2 | Agent: creates drv, sqr, mon, cov |
| `dll_rx_seq_lib.sv` | M3 | Sequences: linkup, VC-up, CplD reactor |

---

## Interface signals

**TX (DUT → DLL)**

| Signal | Width | Notes |
|--------|-------|-------|
| `tx_data_o` | 32 | One TLP DW per clock |
| `tx_valid_o` | 1 | DUT has valid data |
| `tx_ready_i` | 1 | Driven by TB — set to 1 when valid |
| `vc_num` | 3 | Which VC is being used |

**RX (DLL → DUT)**

| Signal | Width | Notes |
|--------|-------|-------|
| `rx_data_i` | 32 | One TLP DW per clock — driven by TB |
| `rx_valid_i` | 1 | Driven by TB |
| `rx_ready_o` | 1 | DUT asserts when ready |
| `linkup` | 1 | TB asserts this when link is up |
| `dll_vc_up` | 8 | TB asserts bits as each VC initializes |

---

## TX responder state machine

```
S_IDLE_DUMMY  →  first tx_valid_o seen  →  S_IDLE
S_IDLE        →  tx_valid_o=1           →  S_TLP_FIRST_DW
S_TLP_FIRST_DW   sample DW0: FMT[31:29], TYPE[28:24], Tag, TC, packet_len
                 store into pcie_common::
                 → S_TLP_SECOND_DW
S_TLP_SECOND_DW  sample DW1: requester ID, Tag[7:0], DW byte enables
                 → S_TLP_THIRD_DW
S_TLP_THIRD_DW   sample DW2: target B/D/F, RegNum/Address
                 set pcie_common::rcvd_tlp and transmit_tlp
                 pcie_common::rcvd_tlp_count++
                 if FMT[1]=1 → S_TLP_PAYLOAD
                 else        → S_IDLE_DUMMY
S_TLP_PAYLOAD    collect payload DWs
                 when count==packet_len → S_IDLE_DUMMY
```

Always: `if (tx_valid_o) tx_ready_i = 1; else tx_ready_i = 0;`

---

## Known bugs

**`dll_tx_mon.sv`** — starts capturing at `dw_count==1`, so DW0 (FMT/TYPE) is always missed.  
Fix in Week 5: start at `dw_count==0`.

**`dll_tx_responder.sv`** — in `S_TLP_PAYLOAD`, `pop_front()` is called before `push_back()`.  
Fix in Week 5: push first, then process the previous beat.
