# Week 4 — Functional Coverage and SVA

This week I'm adding coverage to understand what my test is actually exercising, and writing SVA properties to catch protocol violations early — before the scoreboard catches them.

---

## What I studied

- UVM User Guide chapter 9: covergroups inside subscribers
- IEEE 1800-2017 section 19: covergroup, coverpoint, bins, cross
- IEEE 1800-2017 section 16: concurrent assertions, `property`, `|->`, `##N`, `$past()`

---

## UVM/ — What I built this week

### `axi_cov.sv` — AXI coverage subscriber

Extends `uvm_subscriber#(axi_tx)`. The `write()` function is called every time `axi_mon` fires `ap_port.write()`.

```sv
covergroup tl_axi_cg;

  // Which payload sizes get configured
  PAYLOAD_SIZE_CP: coverpoint tx.dataQ[0] iff (tx.addr == 32'h1018) {
    bins SIZE_128  = {128};
    bins SIZE_256  = {256};
    bins SIZE_512  = {512};
    bins SIZE_1024 = {1024};
    bins SIZE_2048 = {2048};
    bins SIZE_4096 = {4096};
  }

  // Read vs write transactions
  WR_RD_CP: coverpoint tx.wr_rd {
    bins WRITE = {1};
    bins READ  = {0};
  }

  // Which registers are accessed
  REG_ADDR_CP: coverpoint tx.addr {
    bins TC_VC_MAP    = {32'h1000};
    bins LINK_CTRL    = {32'h1004};
    bins VC_FC_STATUS = {32'h1008};
    bins BAR0         = {32'h100C};
    bins DMA_CFG      = {32'h1010};
    bins TLP_XFER_CFG = {32'h1014};
    bins MAX_PAYLOAD  = {32'h1018};
    bins DEV_TYPE     = {32'h101C};
    bins TX_DESCR     = {[32'h2000:32'h27FF]};
    bins RX_DESCR     = {[32'h2800:32'h2FFF]};
  }

  // Did I both read and write each register?
  WR_RD_X_REG: cross WR_RD_CP, REG_ADDR_CP;

endgroup
```

---

### `dll_rx_cov.sv` — DLL RX coverage

Extends `uvm_subscriber#(dll_item)`. Connected to `dll_rx_mon.ap_port`.

```sv
covergroup dll_rx_cg;
  TLP_TYPE_CP: coverpoint tlp.tlp_type {
    bins CplD_bin   = {CplD};
    bins CfgWr0_bin = {CfgWr0};
  }
endgroup
```

---

### `dll_tx_cov.sv` — DLL TX coverage (new file)

Extends `uvm_subscriber#(dll_item)`. Connected to `dll_tx_mon.ap_port`.  
This tells me what TLP types the DUT actually transmitted.

```sv
covergroup dll_tx_cg;
  TX_TLP_TYPE_CP: coverpoint tlp.tlp_type {
    bins CfgRd0_bin = {CfgRd0};
    bins CfgWr0_bin = {CfgWr0};
    bins MWr_bin    = {MWr};
    bins MRd_bin    = {MRd};
  }
endgroup
```

Don't forget to connect this in `dll_tx_agent.connect_phase` — the reference implementation left this disconnected.

---

### `axi_assertions.sv` — SVA properties

I wrote these as a module that I bind to the AXI interface, or just add directly inside the interface.

**AXI protocol rules:**

```sv
// awvalid must hold until awready
property p_awvalid_stable;
  @(posedge aclk) disable iff (arst)
  awvalid && !awready |=> awvalid;
endproperty
assert property (p_awvalid_stable)

// wdata must be stable when wvalid is high and wready hasn't come yet
property p_wdata_stable;
  @(posedge aclk) disable iff (arst)
  wvalid && !wready |=> wvalid && $stable(wdata);
endproperty
assert property (p_wdata_stable)

// bvalid must eventually see bready (within 100 cycles)
property p_bvalid_acked;
  @(posedge aclk) disable iff (arst)
  bvalid |-> ##[1:100] bready;
endproperty
assert property (p_bvalid_acked)

// arvalid must hold until arready
property p_arvalid_stable;
  @(posedge aclk) disable iff (arst)
  arvalid && !arready |=> arvalid;
endproperty
assert property (p_arvalid_stable)

// rvalid must eventually see rready
property p_rvalid_acked;
  @(posedge aclk) disable iff (arst)
  rvalid |-> ##[1:100] rready;
endproperty
assert property (p_rvalid_acked)

// After reset deasserts, outputs should be 0
property p_reset_clears_outputs;
  @(posedge aclk)
  $rose(!arst) |-> !awready && !wready && !bvalid && !arready && !rvalid;
endproperty
assert property (p_reset_clears_outputs)
```

**DLL TX protocol:**

```sv
// tx_data_o must hold while tx_valid_o=1 and tx_ready_i=0
property p_tx_data_stable;
  @(posedge tl_dll_clk) disable iff (arst)
  tx_valid_o && !tx_ready_i |=> $stable(tx_data_o);
endproperty
assert property (p_tx_data_stable)
```

---

## Coverage closure

After running, I check which bins are still zero. Then I write a targeted sequence to hit them.

Things likely to be uncovered after my M3 test:
- `WR_RD_CP.READ` for registers I only wrote, never read back (`0x1010`, `0x1014`, `0x101C`)
- `TX_TLP_TYPE_CP.MWr` and `MRd` — not hit yet since S_MEM_WR/RD are still empty in DUT

---

## How to run with coverage

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test \
     -coverage -do "coverage save -onexit cov.ucdb; run -all; quit"
vcover report cov.ucdb -details
```

---

## Done when

- [ ] `tl_axi_cg` hitting >80% after test run
- [ ] `dll_tx_cg` showing CfgRd0 and CfgWr0 bins covered
- [ ] At least 5 SVA assertions active with no violations
- [ ] Tested that deliberately dropping `awvalid` early fires the assertion
- [ ] Coverage report saved to `M4/docs/`
