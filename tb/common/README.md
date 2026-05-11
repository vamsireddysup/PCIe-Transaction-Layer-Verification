# tb/common/ — Shared Definitions

These files get included first in `top_tb.sv`. Everything else depends on them.

---

## `pcie_common.sv`

A static class used as a shared blackboard across all UVM components.  
The DLL TX responder writes to it as it parses outgoing TLPs.  
The DLL RX sequences read from it to build the right completion response.

Static variables because class instances can't see each other's state — but they can all see `pcie_common::`.

Key fields:

| Field | Who writes | Who reads |
|-------|-----------|-----------|
| `rcvd_tlp` | `dll_tx_responder` | `dll_item` constraints |
| `transmit_tlp` | `dll_tx_responder` | `dll_cpl_seq` |
| `rcvd_tlp_count` | `dll_tx_responder` | `dll_cpl_seq` (triggers on change) |
| `fmt`, `type_t`, `tag`, `tc` | `dll_tx_responder` | `dll_item` |
| `requester_*`, `target_*` | `dll_tx_responder` | `dll_item` |
| `num_tx_matches`, etc. | scoreboard | `report_phase` |
| `pcie_tl_dll_state` | `top_tb` always block | debug |

Also defines all the `` `define `` macros (TLP types, FMT values, `ENDPOINT`, `SWITCH`, `PAYLOAD_SIZE`, `NEW_COMP`, `NEW_OBJ`).

---

## `dll_cfg_rx`

Another static class. Holds the PCIe Type 0 Configuration Space registers of the endpoint being enumerated. Call `dll_cfg_rx::vip_cfg_as_ep()` at the start of simulation in `top_tb`.

When the DUT sends a CFG_RD for register N, the `dll_item.post_randomize()` looks up `dll_cfg_rx::` to fill `payloadQ[0]` with the right data.

Register layout:

| reg_num | Content |
|---------|---------|
| 0 | `{device_id, vendor_id}` |
| 1 | `{status, command}` |
| 2 | `{class_code, revision_id}` |
| 3 | `{bist, header_type, latency_timer, cache_line_size}` |
| 4–9 | BAR0–BAR5 |
| 10 | cardbus_cis_pointer |
| 11 | `{subsystem_id, subsystem_vendor_id}` |
| 12 | expansion_rom_base_addr |
| 13 | `{24'h0, capability_pointer}` |
| 14 | reserved, return 0 |
| 15 | `{max_lat, min_gnt, interrupt_pin, interrupt_line}` |
