# Week 3 — Sequences and Full Stimulus

This week I'm writing sequence libraries to drive the DUT through the complete operational flow: load descriptors → configure registers → assert link up → initialize VCs → run enumeration → receive completions.

This is where `pcie_common` starts mattering — it's the shared blackboard between the DLL TX responder (which parses what the DUT sends) and the DLL RX sequences (which need to send the right completion back).

---

## What I studied

- UVM User Guide chapters 7–8: sequences, `uvm_do_with`, virtual sequences
- TLP packet encoding — read `design/README.md` header format section carefully
- Traced the DLL FSM in `design/pcie_tl.sv` to understand exactly what triggers each state transition

---

## The full flow I'm driving

```
1. dma_load_seq      → writes TX/RX descriptors to 0x2000 and 0x2800
2. axi_config_seq    → writes config registers, reads back, writes link_control_reg[0]=1
                        → DUT FSM: S_IDLE_DLL → S_LINK_TRAINING
3. dll_linkup_seq    → drives linkup=1
                        → DUT FSM: S_LINK_TRAINING → S_VC0_FC_INIT
4. dll_vc_up_seq     → drives dll_vc_up=8'hFF
                        → DUT FSM walks S_VC0..S_VC7_FC_INIT → S_ENUM_FRAME_TLP
5. DUT sends 16× CFG_RD0 TLPs out on tx_data_o
6. dll_cpl_seq       → drives CplD back for each one (runs forever in fork/join_none)
                        → after 16 reads: DUT → S_ENUM_READ_ALL_DW_COMPLETE
                        → DUT sends CFG_WR0 to set BAR0
                        → DUT → S_ENUM_COMPL_IDLE
```

---

## UVM/ — What I built this week

### `axi_seq_lib.sv`

**`axi_base_seq`**  
Base class. `pre_body` raises objection on starting phase. `post_body` drops it.

**`axi_dma_descr_load_seq`**  
Loads TX and RX DMA descriptors before the link comes up.
```
TX descriptor:
  addr 0x2004 = 0x8000_0000   (DMA source address)
  addr 0x2000 = {length, flags, 13'b0}   (length = PAYLOAD_SIZE bytes)

RX descriptor:
  addr 0x2804 = 0x8800_0000
  addr 0x2800 = same format
```

**`axi_config_seq`**  
Configure registers, read them back, then kick off link training.
```
1. Write 0x1000 with bit[0]=0
2. Write 0x1004 with bit[0]=0
3. Write 0x100C = 0xEC00_0000  (BAR0 base address)
4. Write 0x1018 = PAYLOAD_SIZE
5. Read back 0x1000 and 0x1004
6. Write 0x1004 with bit[0]=1  ← triggers link training
```

---

### `dll_rx_seq_lib.sv`

**`dll_linkup_indicate_seq`**  
Drives one `dll_item` with `linkup_indicate=1`. The driver sets `vif.linkup=1`.

**`dll_vc_up_indicate_seq`**  
Drives one `dll_item` with `vc_status_vector=8'hFF`. The driver sets `vif.dll_vc_up=8'hFF`.

**`dll_cpl_seq`**  
This runs in a `fork/join_none` and reacts to DUT output forever.
```
forever begin
  @(pcie_common::rcvd_tlp_count)  ← fires when responder increments this
  fork
    `uvm_do_with(req, {req.tlp_type == pcie_common::transmit_tlp;})
  join_none
end
```
When `transmit_tlp == CplD`, the `dll_item` constraint and `post_randomize()` build the correct completion header and fill `payloadQ[0]` from `dll_cfg_rx` based on `reg_num`.

---

### `dll_item` constraints for CplD

The header_c constraint must build a valid CplD:
```
DW0: FMT=010, TYPE=01010, packet_len=1
DW1: Completer ID = {target_bus_num, target_device_num, target_func_num}
     BCM=0, ByteCount=4
DW2: Requester ID, Tag, LowerAddress=0
```

For the payload, use `post_randomize()` to look up the right value from `dll_cfg_rx`:
```sv
case (pcie_common::reg_num)
  0: payloadQ[0] = {dll_cfg_rx::device_id, dll_cfg_rx::vendor_id};
  1: payloadQ[0] = {dll_cfg_rx::status,    dll_cfg_rx::command};
  // ... etc for all 16 registers
endcase
```
**Do not hardcode** `payloadQ[0] == 32'h1234_5678` — that's Bug #4.

---

### `pcie_wr_rd_test` (in `test_lib.sv`)

```sv
task run_phase(uvm_phase phase);
  phase.phase_done.set_drain_time(this, 5);
  phase.raise_objection(this);

  dma_load_seq.start(env.axi_agent_i.sqr);
  config_seq.start(env.axi_agent_i.sqr);
  dll_link_seq.start(env.dll_rx_agent_i.sqr);
  dll_vc_seq.start(env.dll_rx_agent_i.sqr);
  fork
    dll_cpl.start(env.dll_rx_agent_i.sqr);
  join_none

  phase.drop_objection(this);
endtask
```

---

## Debugging tips

- Add `$display` in the responder to print each TLP DW as it's sampled
- Print `pcie_common::rcvd_tlp_count` in `dll_cpl_seq` body to confirm it's triggering
- If DUT hangs in `S_ENUMERATION_DRV_TLP`, check that `tx_ready_i` is being driven
- Run with `+UVM_VERBOSITY=UVM_LOW` to see sequence info messages

---

## How to run

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test +UVM_VERBOSITY=UVM_LOW \
     -do "run -all; quit"
```

---

## Done when

- [ ] All 16 CFG_RD TLPs transmitted by DUT (visible in transcript or waveform)
- [ ] CplD driven for each one by `dll_cpl_seq`
- [ ] CFG_WR TLP transmitted to write BAR0
- [ ] DUT reaches `S_ENUM_COMPL_IDLE`
- [ ] No `UVM_ERROR` in the log
