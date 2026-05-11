# Week 1 — Design Exploration & Class-Based Testbench

This week is about understanding the DUT before writing any serious testbench code. I read the spec, traced the FSM, and wrote a plain SystemVerilog testbench to drive AXI transactions and check the register map works.

---

## What I studied

- `docs/PCIe TL Block Diagram.jpg` — got a picture of what connects to what
- `docs/ece593w25-DesignSpec_PCIe_Transaction_Layer.pdf` — read the register map and signal descriptions
- `docs/ece593w25-FunctionVerificationTestPlan_PCIe_Transaction_Layer.pdf` — what needs to be verified
- `design/pcie_tl.sv` — read every line of the FSM before writing any TB code
- AXI spec chapters 2–4 — write channel, read channel, handshaking rules

---

## Things I needed to understand before starting

**AXI write flow:**
1. Assert `awvalid` + `awaddr`. Wait for `awready` from DUT.
2. Assert `wvalid` + `wdata`. Wait for `wready`. Assert `wlast` on last beat.
3. Wait for `bvalid` from DUT. Assert `bready`. Transaction done.

**AXI read flow:**
1. Assert `arvalid` + `araddr`. Wait for `arready` from DUT.
2. Wait for `rvalid` from DUT. Assert `rready`. Read `rdata`. Check `rlast`.

**The key flag:** Writing `1` to bit[0] of `link_control_reg` (`0x1004`) sets `init_link_training=1` internally. That's what kicks the DLL FSM out of `S_IDLE_DLL`.

---

## CLASS/ — What I built

No UVM. Just plain SystemVerilog classes with tasks.

| File | What it does |
|------|-------------|
| `axi_intf.sv` | AXI4 interface — two clocking blocks, one for driving (`bfm_cb`), one for monitoring (`mon_cb`) |
| `tl_dll_intf.sv` | DLL interface — just signals + `mon_cb` this week |
| `pcie_tl_drv.sv` | Class with tasks: `write_addr()`, `write_data()`, `write_resp()`, `read_addr()`, `read_data()` |
| `top_tb.sv` | Clock gen, reset, interface instances, DUT, test scenarios |

### Test scenarios I ran

1. Write `0xDEAD_BEEF` to `tc_vc_mapping_reg` (`0x1000`), read it back
2. Write `0xEC00_0000` to `ep_bar0_base_addr` (`0x100C`)
3. Write `256` to `max_payload_size` (`0x1018`)
4. Write `0x1` to `link_control_reg` (`0x1004`) — should trigger link training
5. Read `vc_fc_status_reg` (`0x1008`) — should come back `0xFFFFFFFF` after reset

### What I was checking

- Does `awready` actually go high when `awvalid` is asserted?
- Does `rdata` match what I wrote?
- Does the FSM leave `S_IDLE_AXI` and come back after a write completes?
- Does `init_link_training` get set after writing `link_control_reg[0]=1`?

---

## UVM/ — Just getting it to compile

This week I only created a minimal UVM stub — `top_tb.sv` calling `run_test()` and a `pcie_tl_base_test` that raises and drops an objection after `#1000`. The actual UVM work starts in Week 2.

---

## AXI timing reference

Write:
```
clk   __|‾|_|‾|_|‾|_|‾|_|‾|_
          ┌───┐
awvalid   │   │
──────────┘   └─────────────
                  ┌──┐
awready           │  │
──────────────────┘  └──────
                       ┌───┐
wvalid                 │   │
───────────────────────┘   └
                         ┌─┐
wready                   │ │
─────────────────────────┘ └
```

Read:
```
clk   __|‾|_|‾|_|‾|_|‾|_|‾|_
          ┌───┐
arvalid   │   │
──────────┘   └─────────────
                  ┌──┐
arready           │  │
──────────────────┘  └──────
                         ┌─┐
rvalid                   │ │
─────────────────────────┘ └
rdata                    [D]
                         ┌─┐
rready                   │ │
─────────────────────────┘ └
```

---

## How to run

```bash
cd M1/CLASS
vlog -sv +incdir+. axi_intf.sv tl_dll_intf.sv ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb -do "run -all; quit"
```

---

## Done when

- [ ] Read-back values match what was written
- [ ] No sim hangs waiting for ready signals
- [ ] FSM transitions visible in waveform
- [ ] Transcript saved to `M1/docs/`
