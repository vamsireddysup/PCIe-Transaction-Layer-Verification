# PCIe TLP Verification — Team 2

A UVM-based SystemVerilog verification environment for PCIe Transaction Layer Packet (TLP) generation, transmission, and checking, developed as a team project.

## Repository Structure

```
team_2_pcie_tlp/
├── design/              # RTL design under test (DUT)
├── tb/                  # UVM testbench: agents, drivers, monitors, scoreboards
├── sim/                 # Simulation run scripts and results
├── Packages/            # SystemVerilog packages, enums, type definitions
├── Reference_Docs/      # PCIe specification and reference materials
├── M1/                  # Milestone 1 — TLP packet classes and base environment
├── M2/                  # Milestone 2 — Agent and sequencer setup
├── M3/                  # Milestone 3 — Coverage groups and assertions
├── M4/                  # Milestone 4 — Directed and constrained-random tests
├── M5/                  # Milestone 5 — Coverage closure and final report
└── README.md
```

## TLP Types Verified

| TLP Type             | Description                         |
|----------------------|-------------------------------------|
| Memory Read Request  | 3DW / 4DW header, 32/64-bit addr    |
| Memory Write Request | With payload, byte enables          |
| Completion w/ Data   | CplD with byte count and status     |
| Configuration R/W    | Type 0 and Type 1                   |

## UVM Architecture

- **Sequence / Sequencer**: TLP transaction generation
- **Driver**: Protocol-compliant TLP injection
- **Monitor**: Bus observation and transaction capture
- **Scoreboard**: Response checking and coverage tracking
- **Coverage**: Functional coverage closure for TLP fields

## Tools

- **QuestaSim / ModelSim**: Simulation
- **SystemVerilog UVM 1.2**: Verification methodology
- **Python / TCL**: Run automation
