# PCIe TLP Verification from Scratch

This is my 5-week personal challenge to design and verify a PCIe Transaction Layer using SystemVerilog and UVM 1.2. I'm doing this one milestone at a time — starting from reading the spec, writing a basic testbench, and working up to a full UVM environment with a scoreboard.

The goal is to actually understand what's happening at every step, not just get something running.

---

## What I'm verifying

The PCIe Transaction Layer sits between the processor (AXI side) and the Data Link Layer (DLL side). It takes read/write requests from the CPU, wraps them into TLP packets, and sends them out to the DLL. On the receive side it takes incoming completions from the DLL and hands data back to the processor.

```
Processor <--AXI--> [ pcie_tl ] <--DLL TX/RX--> Data Link Layer
                        |
                   <--AXI--> Memory
```

The DUT has two FSMs — one watching the AXI side, one watching the DLL side. They communicate through internal registers and a flag (`init_link_training`).

---

## My weekly plan

| Week | Folder | What I'm building |
|------|--------|-------------------|
| 1 | [M1](./M1/README.md) | Read the design spec, write a plain SV testbench, drive AXI register writes and reads, look at waveforms |
| 2 | [M2](./M2/README.md) | Convert to UVM — build AXI and DLL agents from scratch |
| 3 | [M3](./M3/README.md) | Write sequence libraries, drive the full link training and enumeration flow |
| 4 | [M4](./M4/README.md) | Add functional coverage and SVA assertions |
| 5 | [M5](./M5/README.md) | Build the scoreboard, fix all the known bugs, get TEST PASSED |

---

## Repo layout

```
.
├── design/          # The DUT — pcie_tl.sv. I don't modify this, I verify it.
├── tb/              # My UVM testbench. Skeletons I fill in each week.
│   ├── common/      # Shared defines, typedefs, pcie_common class
│   ├── axi/         # AXI agent (driver, monitor, sequencer, coverage)
│   ├── dll/         # DLL TX and RX agents
│   ├── mem/         # Memory model
│   ├── sbd/         # Scoreboard
│   └── top/         # Environment, tests, top_tb
├── sim/             # Makefile for running sims (Questa/VCS/Xcelium)
├── M1/ … M5/        # My working directories, one per week
│   ├── CLASS/       # Class-based (non-UVM) work
│   ├── UVM/         # UVM work
│   └── docs/        # My notes, waveforms, transcripts
├── Packages/        # UVM 1.2
└── Reference_Docs/  # PCIe 5.0 spec, AXI spec, UVM guides
```

---

## Bugs I found in the reference code

These exist in the uploaded reference implementation. Part of the challenge is finding and fixing them.

| # | File | What's wrong |
|---|------|-------------|
| 1 | `test_lib.sv:30` | PASS condition is logically impossible — checks `num_tx_rx_matches > 0 && num_tx_rx_matches == 0` |
| 2 | `design/pcie_tl.sv:564` | `requester_device_num` written twice, should be `requester_function_num` in the second slot |
| 3 | `pcie_tl_env.sv` | `mem_agent` is never instantiated in the environment |
| 4 | `dll_item.sv:88` | CplD payload constrained to a hardcoded `32'h1234_5678` instead of real register data |
| 5 | `dll_tx_responder.sv` | In `S_TLP_PAYLOAD`, tries to `pop_front()` before anything has been pushed |
| 6 | `dll_tx_mon.sv:31` | Starts capturing at `dw_count==1`, so the first TLP DW (FMT/TYPE) is always dropped |
| 7 | All agents | Every agent and the environment extend `uvm_test` instead of `uvm_agent`/`uvm_env` |

---

## Reference material

| Doc | Where |
|-----|-------|
| PCIe 5.0 spec | `Reference_Docs/PCIe-5.0_Specifications.pdf` |
| AXI spec | `Reference_Docs/AMBA_AXI_Protocol_Specification.pdf` |
| UVM 1.2 User Guide | `Reference_Docs/UVM_USER_Guide_1.2.pdf` |
| UVM Class Reference | `Reference_Docs/UVM_Class_Reference_Manual_1.2.pdf` |
| Design spec | `M1/docs/ece593w25-DesignSpec_PCIe_Transaction_Layer.pdf` |
| Verification plan | `M1/docs/ece593w25-FunctionVerificationTestPlan_PCIe_Transaction_Layer.pdf` |

---

## Running simulations

```bash
cd sim
make questa            # compile + simulate
make questa TEST=pcie_tl_base_test
make clean
```

See `sim/README.md` for VCS and Xcelium options.
