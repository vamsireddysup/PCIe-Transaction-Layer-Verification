# Week 1 — M1: Design Exploration & Class-Based Testbench

**Goal:** Understand the DUT architecture, AXI protocol, and write a plain SystemVerilog  
(non-UVM) testbench that performs basic register writes and reads.

---

## What to Study This Week

1. **PCIe TL Block Diagram** — `docs/PCIe TL Block Diagram.jpg`
2. **Design Specification** — `docs/ece593w25-DesignSpec_PCIe_Transaction_Layer.pdf`
3. **Verification Plan** — `docs/ece593w25-FunctionVerificationTestPlan_PCIe_Transaction_Layer.pdf`
4. **AXI4 Protocol** — `Reference_Docs/AMBA_AXI_Protocol_Specification.pdf` (Chapters 2–4)
5. **DUT source** — `design/pcie_tl.sv` (read every line; understand the FSM and register map)

---

## Learning Objectives

- Understand AXI4 write channel: `awvalid/awready` → `wvalid/wready` → `bvalid/bready`
- Understand AXI4 read channel: `arvalid/arready` → `rvalid/rready`
- Know the DUT register map (`0x1000` – `0x101C`, `0x2000` – `0x2FFF`)
- Understand what the AXI FSM does in `S_REG_WRITE_ADDR` → `S_REG_WRITE_DATA` → `S_REG_WRITE_RESP`
- Trace `init_link_training` flag: what sets it, what reacts to it

---

## CLASS/ — What to Implement

Work in the `M1/CLASS/` directory. You are writing **plain SystemVerilog** (no UVM).

### Files to create

| File | What it does |
|------|-------------|
| `axi_intf.sv` | AXI4 interface with two clocking blocks (`bfm_cb` for driver, `mon_cb` for monitor) |
| `tl_dll_intf.sv` | DLL TX/RX interface (just needs signals + monitor clocking block this week) |
| `top_tb.sv` | Top-level module: clock/reset gen, interface instances, DUT instantiation |
| `axi_drv_class.sv` | A plain class with tasks: `write_addr()`, `write_data()`, `write_resp()`, `read_addr()`, `read_data()` |
| `axi_test.sv` | A class that creates the driver and runs test scenarios |

### Test scenarios to drive

1. **Write** to `tc_vc_mapping_reg` (addr=`0x1000`) with data `0xDEAD_BEEF`
2. **Read back** from `0x1000` — check rdata_p equals what you wrote
3. **Write** to `ep_bar0_base_addr` (addr=`0x100C`) with `0xEC00_0000`
4. **Write** to `max_payload_size` (addr=`0x1018`) with `256`
5. **Write** to `link_control_reg` (addr=`0x1004`) with `0x1` — this triggers link training

### Success criteria

- `$display` or waveform shows correct `rdata_p` on read-back
- No simulation hang (proper `awready`/`wready`/`bvalid` handshake)
- See DUT FSM move from `S_IDLE_AXI` → `S_REG_WRITE_ADDR` → `S_REG_WRITE_DATA` → `S_REG_WRITE_RESP`
- After writing `link_control_reg[0]=1`, the DLL FSM transitions to `S_LINK_TRAINING`

---

## UVM/ — Preview (optional this week)

If you finish early, look at `M1/UVM/test_lib.sv` — it calls `run_test("pcie_tl_base_test")`.  
Start reading UVM Chapter 1–2 of the User Guide in `Reference_Docs/`.  
You will build a proper UVM version in Week 2.

---

## AXI Write Timing Diagram

```
         ___     ___     ___     ___     ___
aclk  __|   |___|   |___|   |___|   |___|   |__

          ┌───────────────┐
awvalid   │               │
──────────┘               └─────────────────────

                    ┌──────┐
awready             │      │
────────────────────┘      └────────────────────
         ^-- DUT asserts awready when it sees awvalid

                           ┌───────────────┐
wvalid                     │               │
───────────────────────────┘               └────
                                    ┌──────┐
wready                              │      │
────────────────────────────────────┘      └────
```

---

## AXI Read Timing Diagram

```
         ___     ___     ___     ___     ___
aclk  __|   |___|   |___|   |___|   |___|   |__

          ┌───────────────┐
arvalid   │               │
──────────┘               └─────────────────────
                    ┌──────┐
arready             │      │
────────────────────┘      └────────────────────
                                  ┌──────┐
rvalid                            │      │
──────────────────────────────────┘      └──────
rdata                             [valid data]
                                  ┌──────┐
rready                            │      │
──────────────────────────────────┘      └──────
```

---

## Run Instructions (Questa)

```bash
cd M1/CLASS
vlog -sv +incdir+. axi_intf.sv tl_dll_intf.sv ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb -do "run -all; quit"
```

---

## Deliverables

- [ ] Simulation runs without errors
- [ ] Waveform screenshot saved to `M1/docs/`
- [ ] Transcript saved to `M1/docs/transcript`
- [ ] All 5 test scenarios complete successfully
- [ ] Brief notes: what was confusing, what surprised you
