# PCIe TLP Verification from Scratch

A 5-week self-paced challenge to design and verify a **PCIe Transaction Layer (TL)** using **SystemVerilog** and **UVM 1.2**.

You start from a hardware design specification and work your way up to a complete UVM testbench — one milestone per week.

---

## What You Are Verifying

The **PCIe Transaction Layer** sits between the CPU/memory subsystem (AXI) and the Data Link Layer (DLL). Its job is to:

- Accept read/write commands from the processor over AXI
- Frame them into **TLP (Transaction Layer Packets)** and send them to the DLL
- Receive completion TLPs from the DLL and return data to the processor
- Manage link training, VC (Virtual Channel) initialization, and enumeration

```
Processor <--AXI--> [ PCIe TL DUT ] <--DLL_TX/RX--> Data Link Layer
                            |
                       <--AXI--> Memory
```

---

## Weekly Milestone Overview

| Week | Milestone | Goal |
|------|-----------|------|
| 1 | [M1 — Design Exploration](./M1/README.md) | Understand the DUT, write a class-based testbench, observe waveforms |
| 2 | [M2 — UVM Agents](./M2/README.md) | Build UVM AXI and DLL agents (driver, monitor, sequencer) |
| 3 | [M3 — Sequences & Stimulus](./M3/README.md) | Write sequence libraries; drive link training and enumeration |
| 4 | [M4 — Coverage & Assertions](./M4/README.md) | Add functional coverage and SVA protocol checks |
| 5 | [M5 — Scoreboard & Closure](./M5/README.md) | Implement the scoreboard, wire the full environment, achieve test pass |

---

## Repository Structure

```
.
├── design/          # DUT: pcie_tl.sv with FSM, register map, TLP framing
├── tb/              # UVM testbench skeletons (fill these in each week)
│   ├── common/      # Shared defines, typedefs, pcie_common class
│   ├── axi/         # AXI agent (driver, monitor, sequencer, coverage)
│   ├── dll/         # DLL TX/RX agents (responder, monitor, sequences)
│   ├── mem/         # Memory model and monitor
│   ├── sbd/         # Scoreboard
│   └── top/         # Environment, test library, top-level testbench
├── sim/             # Simulation scripts (Makefile + Questa run.do)
├── M1/ … M5/        # Weekly milestone working directories
│   ├── CLASS/       # Class-based (non-UVM) work for that week
│   ├── UVM/         # UVM-based work for that week
│   └── docs/        # Notes, waveforms, transcripts
├── Packages/        # UVM 1.2 library
└── Reference_Docs/  # PCIe 5.0 spec, AXI spec, UVM user guide
```

---

## Key Concepts by Week

### Week 1 — PCIe TL Architecture
- AXI4 write/read channel handshaking (`awvalid/awready`, `wvalid/wready`, `bvalid/bready`)
- TL register map (base address `0x1000`, descriptors at `0x2000`/`0x2800`)
- TL FSM states: `S_IDLE_AXI` → `S_REG_WRITE_*` / `S_REG_READ`

### Week 2 — UVM Agent Structure
- `uvm_driver`, `uvm_monitor`, `uvm_sequencer`, `uvm_agent`
- Clocking blocks and virtual interfaces
- `uvm_resource_db` for passing interfaces

### Week 3 — Sequences
- `uvm_sequence`, `uvm_sequence_item`, ``uvm_do_with``
- Stimulus flow: DMA load → config → linkup → VC-up → enumeration
- TLP packet framing (CFG_RD0, CFG_WR0 header structure)

### Week 4 — Coverage & Assertions
- `covergroup`, `coverpoint`, `cross`
- Concurrent SVA: `@(posedge clk) property`
- AXI handshake properties, TLP type coverage

### Week 5 — Scoreboard
- `uvm_scoreboard`, `uvm_tlm_analysis_fifo`
- Connecting monitor `ap_port` to scoreboard `analysis_export`
- Pass/fail checking: TX TLP ↔ RX CplD data integrity

---

## Known Bugs to Fix (from code review)

These bugs exist in the reference implementation. Finding and fixing them is part of the challenge:

| # | File | Bug |
|---|------|-----|
| 1 | `test_lib.sv:30` | PASS condition is always false (contradictory `num_tx_rx_matches` check) |
| 2 | `design/pcie_tl.sv:564` | `requester_device_num` used twice — should be `requester_function_num` |
| 3 | `tb/sbd/tl_sbd.sv` | Scoreboard is empty — no logic, no UVM base class |
| 4 | `dll_item.sv:88` | CplD payload constraint hardcoded to `32'h1234_5678` |
| 5 | `tb/top/pcie_tl_env.sv` | `mem_agent` never instantiated |
| 6 | `dll_tx_mon.sv:31` | First TLP DW silently dropped |
| 7 | `dll_tx_responder.sv` | `payloadQ.pop_front()` called before data is pushed |

---

## Reference Documents

| Document | Location |
|----------|----------|
| PCIe 5.0 Specification | `Reference_Docs/PCIe-5.0_Specifications.pdf` |
| AXI Protocol Specification | `Reference_Docs/AMBA_AXI_Protocol_Specification.pdf` |
| UVM 1.2 User Guide | `Reference_Docs/UVM_USER_Guide_1.2.pdf` |
| UVM 1.2 Class Reference | `Reference_Docs/UVM_Class_Reference_Manual_1.2.pdf` |
| Design Specification | `M1/docs/ece593w25-DesignSpec_PCIe_Transaction_Layer.pdf` |
| Verification Plan | `M1/docs/ece593w25-FunctionVerificationTestPlan_PCIe_Transaction_Layer.pdf` |

---

## How to Run (Questa/ModelSim)

```bash
cd sim
make questa          # compile + simulate
make clean           # remove work library and logs
```

See [`sim/README.md`](./sim/README.md) for VCS/Xcelium options.
