# Week 3 — M3: Sequences & Full Stimulus

**Goal:** Write a complete sequence library that drives the DUT through the full  
operational flow: register config → link training → enumeration → DMA transfer.

---

## What to Study This Week

1. **UVM User Guide** — Chapter 7 (sequences), Chapter 8 (virtual sequences)
2. **PCIe TLP packet format** — `design/README.md` (TLP header encoding table)
3. Understand the full DUT stimulus flow by tracing the DLL FSM in `design/pcie_tl.sv`
4. Study `pcie_common.sv` — it is the shared blackboard between sequences and the responder

---

## Learning Objectives

- Write `uvm_sequence` and `uvm_sequence_item` classes with constraints
- Use `` `uvm_do_with `` to override constraints inline
- Understand `pre_body` / `post_body` for objection management
- Understand how sequences communicate through shared static variables (`pcie_common`)
- Know the full enumeration TLP exchange: 16× CFG_RD0 → read completions → 1× CFG_WR0 → set BAR0

---

## UVM/ — What to Implement

Work in `M3/UVM/`. Build on top of your M2 agents.

---

### AXI Sequence Library (`axi_seq_lib.sv`)

#### `axi_base_seq`
```
- Extend uvm_sequence#(axi_tx)
- pre_body:  raise_objection on starting_phase
- post_body: drop_objection on starting_phase
```

#### `axi_dma_descr_load_seq`
```
Goal: Load TX and RX DMA descriptors before configuring the link.

TX descriptor at 0x2000/0x2004:
  DW0 (0x2000): {length[15:0], flags[2:0], 13'b0}  — length = PAYLOAD_SIZE (e.g. 256)
  DW1 (0x2004): source address = 0x8000_0000

RX descriptor at 0x2800/0x2804:
  DW0 (0x2800): same format
  DW1 (0x2804): dest address = 0x8800_0000

Drive 4 AXI write transactions using `uvm_do_with.
```

#### `axi_config_seq`
```
Goal: Configure registers, read them back, then kick off link training.

Steps:
  1. Write 0x1000 (tc_vc_mapping_reg) — any value with bit[0]=0
  2. Write 0x1004 (link_control_reg)  — bit[0]=0 (not yet)
  3. Write 0x100C (ep_bar0_base_addr) = 0xEC00_0000
  4. Write 0x1018 (max_payload_size)  = PAYLOAD_SIZE
  5. Read back 0x1000 and 0x1004 — verify values match
  6. Write 0x1004 with bit[0]=1  ← triggers link training
```

---

### DLL RX Sequence Library (`dll_rx_seq_lib.sv`)

These sequences drive the DLL-side inputs into the DUT.

#### `dll_linkup_indicate_seq`
```
- Drive one dll_item with linkup_indicate=1
- This sets vif.linkup=1 → DUT FSM: S_LINK_TRAINING → S_VC0_FC_INIT
```

#### `dll_vc_up_indicate_seq`
```
- Drive one dll_item with vc_status_vector=8'hFF
- This sets vif.dll_vc_up=8'hFF → DUT FSM walks through all 8 VC init states
```

#### `dll_cpl_seq` — The reactive completion driver
```
- Runs forever in a fork/join_none
- Wait for pcie_common::rcvd_tlp_count to change (use @(pcie_common::rcvd_tlp_count))
- When it changes: randomize a dll_item with tlp_type = pcie_common::transmit_tlp
  (which will be CplD after a CFG_RD0)
- Drive the CplD TLP via the DLL RX driver

CplD Header encoding:
  DW0: FMT=010, TYPE=01010 (CplD), packet_len=1
  DW1: Completer ID = {target_bus_num, target_device_num, target_func_num}
       ByteCount=4, BCM=0
  DW2: Requester ID, Tag, LowerAddress=0

Payload DW: the register data for reg_num from dll_cfg_rx::*
```

#### `dll_item` constraint guidance
```
For CplD response, headerQ constraints must match:
  headerQ[0][31:29] == 3'b010   (FMT with data)
  headerQ[0][28:24] == 5'b01010 (CplD type)
  headerQ[0][9:0]   == 10'd1    (1 DW payload)
  headerQ[1][31:16] == {target_bus_num, target_device_num, target_func_num}
  headerQ[2][31:16] == {requester_bus_num, requester_device_num, requester_func_num}
  headerQ[2][15:8]  == tag[7:0]

Payload: use post_randomize() to fill payloadQ[0] from dll_cfg_rx based on reg_num
  DO NOT use a hardcoded value like 32'h1234_5678 (that is bug #4)
```

---

### Test: `pcie_wr_rd_test`

```
task run_phase:
  1. dma_load_seq.start(env.axi_agent_i.sqr)
  2. config_seq.start(env.axi_agent_i.sqr)
  3. dll_link_seq.start(env.dll_rx_agent_i.sqr)
  4. dll_vc_seq.start(env.dll_rx_agent_i.sqr)
  5. fork
       dll_cpl.start(env.dll_rx_agent_i.sqr)  // runs forever
     join_none
  6. drop_objection
```

---

## Full DUT Flow to Verify

```
[TEST]                          [DUT DLL FSM]
dma_load_seq ──────────────→   registers loaded
config_seq   ──────────────→   link_control_reg[0]=1 set
                              → S_LINK_TRAINING
linkup_indicate_seq ───────→   linkup=1
                              → S_VC0_FC_INIT ... S_VC7_FC_INIT
vc_up_indicate_seq ────────→   dll_vc_up=8'hFF
                              → S_ENUM_FRAME_TLP
                              → drives CFG_RD0 TLP (DW0, DW1, DW2)
dll_cpl_seq hears count++ ─→  drives CplD back (16 times for 16 registers)
                              → S_ENUM_READ_ALL_DW_COMPLETE
                              → drives CFG_WR0 TLP (BAR0 address)
                              → S_ENUM_COMPL_IDLE
```

---

## Debugging Tips

- Add `$display` in `dll_tx_responder` to print each TLP DW as it arrives
- Print `pcie_common::rcvd_tlp_count` in `dll_cpl_seq` to confirm it increments
- Use `+UVM_VERBOSITY=UVM_LOW` to see `uvm_info` messages from your sequences
- If the DUT hangs in `S_ENUM_FRAME_TLP`, check that `tx_ready_i` is being driven by the responder

---

## Success Criteria

- [ ] All 16 CFG_RD TLPs are transmitted by the DUT
- [ ] CplD is driven back for each one by `dll_cpl_seq`
- [ ] CFG_WR TLP is transmitted to write BAR0 address
- [ ] DUT reaches `S_ENUM_COMPL_IDLE`
- [ ] Simulation log shows all steps without `UVM_ERROR`
