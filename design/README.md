# design

The DUT, pcie_tl.sv. Single module, three FSMs running in parallel, plus reset
and helper tasks.

## the three fsms

state_axi : the CPU-facing AXI slave. Sits in S_IDLE_AXI, on awvalid goes to
write-addr -> write-data -> write-resp, on arvalid goes to the read path. The
write-data state decodes the address and writes the matching config register
(see the register map in the root README) or the descriptor ram. This is the
only fsm that services CPU register writes, so the test can only write config
regs when this fsm is back in S_IDLE_AXI.

state_dll : the main flow. S_IDLE_DLL -> S_LINK_TRAINING -> 8x S_VC*_FC_INIT ->
enumeration (frames 16 cfg_rd0 tlps reading ep config space, then a cfg_wr0) ->
S_ENUM_COMPL_IDLE. Idle is the dispatch state: when dma_configure_reg[0] is set
it reads tlp_transfer_config_reg and jumps to S_MEM_WR or S_MEM_RD, pulls the tx
descriptor, and drives the tlp. mem_wr is posted (drive and done). mem_rd is
non-posted (drive header, then wait in S_PROCESS_COMPLETION_TLP for the cpld).

state_axi_mem : drives the memory-side AXI bus to write completion data back to
system memory. Starts only when write_to_axi_mem gets set, which happens after a
mem_rd completion buffers 16 dw into cpltlpdataQ. The write states are
implemented, the read states (S_AXI_MEM_AXI_RD_*) are not.

## known DUT gaps

- mem_wr frames its payload from a hardcoded constant (frame_mem_wr_tlp with
  0xEC00_0000) instead of reading system memory. So there is no memory read on
  mem_wr to monitor.
- the axi_mem read path is stubbed (marked not-implemented).
- the mem_rd completion path does not fill cpltlpdataQ to 16 dw in the current
  run, so the memory write-back never triggers.

## fixes applied to the DUT this session

- removed reset assignments to input ports awready_m / wready_m (the DUT was
  driving its own inputs).
- a redundant cosmetic digit warning around line 789 is left as-is.

pcie_common.sv is included here too (shared macros and tlp encodings), but note
it is a class, so this compilation unit gets its own copy of its static members.
That is why the dll-state mirror is driven from top_tb, not from here.
