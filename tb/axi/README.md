# tb/axi/ — AXI Agent

Handles the processor-side AXI4 interface. The driver acts as the processor (master). The monitor watches both write and read transactions and sends them to the scoreboard and coverage.

---

## Files (build in Week 2, coverage in Week 4)

| File | What it is |
|------|-----------|
| `axi_intf.sv` | AXI4 interface with `bfm_cb` and `mon_cb` clocking blocks |
| `axi_tx.sv` | Sequence item: addr, dataQ, strbQ, burst params, wr_rd |
| `axi_drv.sv` | Driver: drives write and read transactions over `bfm_cb` |
| `axi_mon.sv` | Monitor: observes `mon_cb`, assembles complete transactions |
| `axi_cov.sv` | Subscriber: samples `tl_axi_cg` covergroup |
| `axi_agent.sv` | Agent: creates drv, sqr, mon, cov and wires them |
| `axi_seq_lib.sv` | Sequences: config, DMA descriptor load |

---

## Interface signal directions (processor side, from DUT's perspective)

### Write channels
```
awvalid  (in)   awready  (out)  awid[3:0]  (in)   awaddr[31:0]  (in)
awlen[3:0] (in) awburst[1:0] (in) awsize[2:0] (in)

wvalid (in)  wready (out)  wdata[31:0] (in)  wstrb[3:0] (in)
wid[3:0] (in)  wlast (in)

bvalid (out)  bready (in)  bid[1:0] (out)  bresp[1:0] (out)
```

### Read channels
```
arvalid (in)  arready (out)  arid[3:0] (in)  araddr[31:0] (in)
arlen[3:0] (in)  arburst[1:0] (in)  arsize[2:0] (in)

rvalid (out)  rready (in)  rdata[31:0] (out)  rid[3:0] (out)
rlast (out)  rresp[1:0] (out)
```

---

## Clocking block setup

`bfm_cb` — the driver uses this
- Outputs: everything the master drives (aw*, w*, ar*, rready, bready)
- Inputs: everything the DUT/slave drives (awready, wready, bvalid, bid, bresp, arready, rvalid, rdata, rid, rlast, rresp, arst)
- Timing: `default input #0 output #0`

`mon_cb` — the monitor uses this
- All signals are inputs
- Same list, just observing
