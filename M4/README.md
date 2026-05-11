# Week 4 — M4: Functional Coverage & Assertions

**Goal:** Add functional coverage models to measure what your test exercises,  
and write SystemVerilog Assertions (SVA) to catch AXI and TLP protocol violations.

---

## What to Study This Week

1. **UVM User Guide** — Chapter 9 (coverage)
2. **IEEE 1800-2017** — Section 19 (covergroups) and Section 16 (assertions)
3. Review `tb/axi/axi_cov.sv` skeleton — understand the subscriber pattern
4. Review `tb/dll/dll_rx_cov.sv` skeleton — same pattern for DLL side

---

## Learning Objectives

- Write `covergroup` with `coverpoint`, `bins`, and `cross`
- Connect a `uvm_subscriber` to a monitor `ap_port`
- Write concurrent SVA properties with `@(posedge clk) property ... endproperty`
- Understand the difference between `assert property` (check) and `cover property` (coverage)
- Know how to use `$past()`, `##N`, `|->`, `|->`

---

## UVM/ — What to Implement

Work in `M4/UVM/`. Build on top of your M3 testbench.

---

### AXI Coverage (`axi_cov.sv`)

Extend `uvm_subscriber#(axi_tx)`. Implement in `write(axi_tx t)` task.

```
covergroup tl_axi_cg;

  // Payload size register writes (addr=0x1018)
  PAYLOAD_SIZE_CP: coverpoint tx.dataQ[0] iff (tx.addr == 32'h1018) {
    bins PAYLOAD_SIZE_128  = {128};
    bins PAYLOAD_SIZE_256  = {256};
    bins PAYLOAD_SIZE_512  = {512};
    bins PAYLOAD_SIZE_1024 = {1024};
    bins PAYLOAD_SIZE_2048 = {2048};
    bins PAYLOAD_SIZE_4096 = {4096};
  }

  // Write vs Read
  WR_RD_CP: coverpoint tx.wr_rd {
    bins WRITE = {1};
    bins READ  = {0};
  }

  // Burst type used
  BURST_TYPE_CP: coverpoint tx.burst_type {
    bins FIXED = {FIXED};
    bins INCR  = {INCR};
    bins WRAP  = {WRAP};
  }

  // Register address accessed
  REG_ADDR_CP: coverpoint tx.addr {
    bins TC_VC_MAP    = {32'h1000};
    bins LINK_CTRL    = {32'h1004};
    bins VC_FC_STATUS = {32'h1008};
    bins BAR0_ADDR    = {32'h100C};
    bins DMA_CFG      = {32'h1010};
    bins TLP_XFER_CFG = {32'h1014};
    bins MAX_PAYLOAD  = {32'h1018};
    bins DEV_TYPE     = {32'h101C};
    bins TX_DESCR     = {[32'h2000:32'h27FF]};
    bins RX_DESCR     = {[32'h2800:32'h2FFF]};
  }

  // Cross: write vs. register address
  WR_RD_X_REG: cross WR_RD_CP, REG_ADDR_CP;

endgroup
```

---

### DLL RX Coverage (`dll_rx_cov.sv`)

Extend `uvm_subscriber#(dll_item)`. Subscribe to `dll_rx_mon.ap_port`.

```
covergroup dll_rx_cg;

  // TLP type received by DUT from DLL (incoming completions)
  TLP_TYPE_CP: coverpoint tlp.tlp_type {
    bins CplD_bin  = {CplD};
    bins CfgWr0_bin = {CfgWr0};
    // add others as you implement them
  }

  // CplD payload value range (per register)
  // Add when you have time

endgroup
```

### DLL TX Coverage (`dll_tx_cov.sv`) — Create this new file

Extend `uvm_subscriber#(dll_item)`. Subscribe to `dll_tx_mon.ap_port`.

```
covergroup dll_tx_cg;

  // TLP types transmitted by DUT to DLL (outgoing requests)
  TX_TLP_TYPE_CP: coverpoint tlp.tlp_type {
    bins CfgRd0_bin = {CfgRd0};
    bins CfgWr0_bin = {CfgWr0};
    bins MWr_bin    = {MWr};
    bins MRd_bin    = {MRd};
  }

  // Virtual Channel used
  VC_NUM_CP: coverpoint tlp.headerQ[0][22:20] {
    bins VC0 = {0};
    bins VC1 = {1};
    // ...
  }

endgroup
```

---

### SystemVerilog Assertions (SVA)

Create `tb/axi/axi_assertions.sv`. Bind it into the testbench or instantiate in `top_tb.sv`.

#### AXI Write Protocol Assertions

```sv
// AW: once awvalid is asserted, it must not drop until awready
property p_awvalid_stable;
  @(posedge aclk) disable iff (arst)
  awvalid && !awready |=> awvalid;
endproperty
assert property (p_awvalid_stable) else
  `uvm_error("AXI_SVA", "awvalid dropped before awready")

// W: wdata must be stable when wvalid is high and wready is low
property p_wdata_stable;
  @(posedge aclk) disable iff (arst)
  wvalid && !wready |=> wvalid && $stable(wdata);
endproperty
assert property (p_wdata_stable)

// B: bvalid must eventually be followed by bready (liveness)
property p_bvalid_followed_by_bready;
  @(posedge aclk) disable iff (arst)
  bvalid |-> ##[1:100] bready;
endproperty
assert property (p_bvalid_followed_by_bready)
```

#### AXI Read Protocol Assertions

```sv
// AR: arvalid must not drop until arready
property p_arvalid_stable;
  @(posedge aclk) disable iff (arst)
  arvalid && !arready |=> arvalid;
endproperty
assert property (p_arvalid_stable)

// R: rvalid must eventually be followed by rready
property p_rvalid_followed_by_rready;
  @(posedge aclk) disable iff (arst)
  rvalid |-> ##[1:100] rready;
endproperty
assert property (p_rvalid_followed_by_rready)

// Reset: all outputs deasserted after reset
property p_outputs_clear_after_reset;
  @(posedge aclk)
  $rose(!arst) |-> !awready && !wready && !bvalid && !arready && !rvalid;
endproperty
assert property (p_outputs_clear_after_reset)
```

#### TLP Protocol Assertions (bind to `tl_dll_intf`)

```sv
// tx_valid_o must be stable until tx_ready_i
property p_tx_valid_stable;
  @(posedge tl_dll_clk) disable iff (arst)
  tx_valid_o && !tx_ready_i |=> tx_valid_o;
endproperty
assert property (p_tx_valid_stable)

// tx_data_o must be stable when tx_valid_o=1 and tx_ready_i=0
property p_tx_data_stable;
  @(posedge tl_dll_clk) disable iff (arst)
  tx_valid_o && !tx_ready_i |=> $stable(tx_data_o);
endproperty
assert property (p_tx_data_stable)
```

---

### Connect Coverage to Environment

In `pcie_tl_env.sv`:
- `dll_tx_cov` instance must be created and connected to `dll_tx_agent_i.mon.ap_port`
- All `ap_port.connect(cov.analysis_export)` calls must be in `connect_phase`

---

## Coverage Closure Strategy

After adding coverage:
1. Run your M3 test and collect a coverage report
2. Look at uncovered bins — which register addresses were never read?  
   Which TLP types were never transmitted?
3. Write a new sequence to target those gaps (e.g., write `0x1010` DMA config,  
   trigger a MEM_WR TLP if you have time to implement that FSM state)

---

## Success Criteria

- [ ] `tl_axi_cg` shows >80% coverage after the test run
- [ ] `dll_tx_cg` shows `CfgRd0` and `CfgWr0` bins hit
- [ ] At least 5 SVA properties fire and report no violations
- [ ] If you deliberately inject a bug (e.g., drop `awvalid` early), an assertion fires
- [ ] Coverage report printed in `report_phase`
