# PCIe Transaction Layer Verification (UVM)

UVM testbench for a PCIe Transaction Layer DUT. The DUT models the TL flow:
link training, virtual channel flow-control init, config-space enumeration over
cfg_rd0/cfg_wr0, then a DMA-style mem_wr and mem_rd driven by descriptors the CPU
loads over an AXI register interface.

This started from clubbed course code that did not compile. I restructured it into
one-class-per-file UVM, fixed the build, and got the sim running end to end.

## what works

Compiles clean on QuestaSim 2024.2 and runs to completion, no hangs, no crashes.
Full flow executes: enumeration (link train -> 8x VC FC init -> 16x cfg_rd0 ->
cfg_wr0) -> mem_wr -> mem_rd -> scoreboard report. finish at 15235ns, exit 0,
UVM_FATAL = 0.

Getting here took fixing 10 distinct bugs. Full debug log (symptom, root cause,
fix for each) is in sim/errors.md. Highlights:

- UVM version skew: built-in Questa UVM is 1.1d but the repo pointed +incdir at
  1.2, 224 compile errors. Switched everything to 1.1d.
- DUT reset was driving its own input ports (awready_m, wready_m). Removed.
- dll_tx_responder froze on cfg_wr0: that case set rcvd_tlp but never advanced
  n_state, the responder FSM stalled and hung the sim. Made it ack and advance.
- The big one: pcie_tl_dll_state, a package static mirror the tb waits on to sync
  with the DUT fsm, was declared but never written. The mem_wr config sequence
  blocked forever and the DMA enable never got written. Driving it from inside
  the DUT did not work (pcie_common.sv is a class included by two compilation
  units, each gets its own static copy). Fixed by driving it from top_tb.
- mem_mon SIGSEGV: dereferenced a tx handle in the data/resp branches without a
  null/direction check. Guarded the branches.

## known gaps (scoreboard)

Sim runs but the 3 scoreboard checks do not pass yet. This is a DUT data-path
issue, not testbench wiring (all 4 monitor analysis ports are connected, verified).
Details in sim/errors.md section 12.

- MEM_RD vs TLP_TX: empty. DUT never reads system memory on mem_wr (frames payload
  from a hardcoded constant), and the axi_mem read states are not-implemented in
  the DUT. Cannot pass without new DUT rtl.
- MEM_WR vs TLP_RX: empty. The memory-write fsm only starts after a mem_rd
  completion buffers 16 dw, which never filled up. Fixable DUT completion-path bug.
- TLP_TX vs TLP_RX loopback: compared (matches=1 mismatches=255), data flowed but
  byte-misaligned. Only fully-implemented path, closest to passing, fix this first.

## register map (CPU writes over the proc AXI interface)

    0x1000  tc_vc_mapping_reg
    0x1004  link_control_reg
    0x1008  vc_fc_status_reg      (DUT updates this, CPU should not write)
    0x100C  ep_bar0_base_addr
    0x1010  dma_configure_reg     [0] tx_en  [1] rx_en
    0x1014  tlp_transfer_config_reg   [4:0] selects MEM_WR / MEM_RD / etc
    0x1018  max_payload_size
    0x101C  target_device_type
    0x2000-0x27FF  tx descriptor ram (dw0 = addr, dw1 = {length[15:0], flags})
    0x2800-0x2FFF  rx descriptor ram

## how to run

QuestaSim 2024.2 with UVM 1.1d. Set UVM_HOME to the 1.1d src (not 1.2). From repo root:

    vlog -sv +incdir+$UVM_HOME/src +incdir+./tb +incdir+./tb/intf +incdir+./tb/agents +incdir+./tb/seq +incdir+./tb/sbd +incdir+./tb/env +incdir+./tb/test design/pcie_tl.sv tb/top_tb.sv

    vsim -c work.top_tb +UVM_TESTNAME=pcie_wr_rd_test -do "run -all; quit -f"

To examine DUT internal signals (optimized away by default), add
-voptargs=+acc -suppress 3839 to the vsim command.

## architecture docs

`docs/architecture.html` is a self-contained architecture and verification dossier:
seven hand-drawn diagrams (system context, the three DUT FSM lanes, the state_dll
state machine, the UVM topology, an end-to-end sequence diagram, the scoreboard
data flow, and the compilation-unit static bug), a per-file map of all 38 sources,
the phase-by-phase flow, and a section of open defects found by re-reading the
committed code. Open it in a browser.

## layout

    design/    the DUT
    tb/        testbench root (top_tb, pcie_common)
    tb/intf/   axi and dll interfaces
    tb/agents/ the 4 uvm agents + memory slave model
    tb/seq/    sequences
    tb/sbd/    scoreboard
    tb/env/    env
    tb/test/   tests
    sim/       run logs and the debug log (errors.md)

Each folder has its own README with more detail.
