# tb/common — Shared Definitions

Files in this directory are included first by `top_tb.sv`.

---

## `pcie_common.sv`

A static class used as a **shared blackboard** between the DLL TX responder and the DLL RX driver.

### Why static?
The `dll_tx_responder` parses TLP fields from what the DUT sends.  
The `dll_cpl_seq` / `dll_rx_drv` needs to know what TLP was received  
to build a matching completion. Static variables are visible across all class instances.

### Key fields

| Field | Set by | Read by |
|-------|--------|---------|
| `pcie_tl_dll_state` | `top_tb` (always block) | debug |
| `rcvd_tlp` | `dll_tx_responder` | `dll_item` constraints |
| `transmit_tlp` | `dll_tx_responder` | `dll_cpl_seq` |
| `rcvd_tlp_count` | `dll_tx_responder` | `dll_cpl_seq` (event trigger) |
| `fmt`, `type_t`, `tag`, `tc` | `dll_tx_responder` | `dll_item` constraints |
| `requester_*/target_*` | `dll_tx_responder` | `dll_item` constraints |
| `num_tx_matches` etc. | scoreboard | `report_phase` |

### Defines (``define`)

| Define | Value | Meaning |
|--------|-------|---------|
| `` `CFG_RD0 `` | `3'b000` | CFG Read Type 0 index |
| `` `CFG_WR0 `` | `3'b010` | CFG Write Type 0 index |
| `` `MEM_WR ``  | `5'b0_0001` | tlp_transfer_config_reg value for Mem Write |
| `` `MEM_RD ``  | `5'b0_0010` | tlp_transfer_config_reg value for Mem Read |
| `` `ENDPOINT `` | `32'h0` | target_device_type value |
| `` `SWITCH ``   | `32'h1` | target_device_type value |
| `` `PAYLOAD_SIZE `` | `256` | Default max payload in bytes |
| `` `NEW_COMP `` | macro | Boilerplate `new(name, parent)` for components |
| `` `NEW_OBJ ``  | macro | Boilerplate `new(name="")` for objects |

---

## `dll_cfg_rx`

A static class that holds the configuration space registers of the **endpoint device** being enumerated.

Call `dll_cfg_rx::vip_cfg_as_ep()` once at the start of simulation  
(from `top_tb` initial block) to populate default values.

Register layout matches PCIe Type 0 Configuration Space Header:

| reg_num | Register |
|---------|---------|
| 0  | Device ID + Vendor ID |
| 1  | Status + Command |
| 2  | Class Code + Revision ID |
| 3  | BIST + Header Type + Latency Timer + Cache Line Size |
| 4–9 | BAR0–BAR5 |
| 10 | Cardbus CIS Pointer |
| 11 | Subsystem ID + Subsystem Vendor ID |
| 12 | Expansion ROM Base Address |
| 13 | Capability Pointer |
| 14 | Reserved |
| 15 | Max Lat + Min Gnt + Interrupt Pin + Interrupt Line |
