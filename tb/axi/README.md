# tb/axi — AXI Agent

Implements the UVM agent for the **AXI4 processor-side interface** of the DUT.  
The driver acts as the processor (master) and the monitor observes both  
the processor-side and can be reused for the memory-side.

---

## Files

| File | Week | Description |
|------|------|-------------|
| `axi_intf.sv`    | M1 | AXI4 interface with `bfm_cb` (driver) and `mon_cb` (monitor) clocking blocks |
| `axi_tx.sv`      | M2 | Sequence item: addr, dataQ, strbQ, burst params, wr_rd |
| `axi_drv.sv`     | M2 | UVM driver: drives AXI4 write/read transactions on `bfm_cb` |
| `axi_mon.sv`     | M2 | UVM monitor: observes `mon_cb`, assembles complete axi_tx, writes to `ap_port` |
| `axi_cov.sv`     | M4 | UVM subscriber: samples `tl_axi_cg` covergroup |
| `axi_agent.sv`   | M2 | UVM agent: creates and connects drv, sqr, mon, cov |
| `axi_seq_lib.sv` | M3 | Sequences: `axi_base_seq`, `axi_config_seq`, `axi_dma_descr_load_seq` |

---

## AXI4 Interface Signals (Processor Side, `_p` suffix in DUT)

### Write Address Channel
| Signal | Direction (DUT view) | Width |
|--------|---------------------|-------|
| `awvalid` | in | 1 |
| `awready` | out | 1 |
| `awid`    | in | 4 |
| `awaddr`  | in | 32 |
| `awlen`   | in | 4 |
| `awburst` | in | 2 |
| `awsize`  | in | 3 |

### Write Data Channel
| Signal | Direction | Width |
|--------|-----------|-------|
| `wvalid` | in | 1 |
| `wready` | out | 1 |
| `wdata`  | in | 32 |
| `wstrb`  | in | 4 |
| `wid`    | in | 4 |
| `wlast`  | in | 1 |

### Write Response Channel
| Signal | Direction | Width |
|--------|-----------|-------|
| `bvalid` | out | 1 |
| `bready` | in  | 1 |
| `bid`    | out | 2 |
| `bresp`  | out | 2 |

### Read Address Channel
| Signal | Direction | Width |
|--------|-----------|-------|
| `arvalid` | in | 1 |
| `arready` | out | 1 |
| `arid`    | in | 4 |
| `araddr`  | in | 32 |
| `arlen`   | in | 4 |
| `arburst` | in | 2 |
| `arsize`  | in | 3 |

### Read Data Channel
| Signal | Direction | Width |
|--------|-----------|-------|
| `rvalid` | out | 1 |
| `rready` | in  | 1 |
| `rdata`  | out | 32 |
| `rid`    | out | 4 |
| `rlast`  | out | 1 |
| `rresp`  | out | 2 |

---

## Clocking Block Guidance

`bfm_cb` (driver uses this):
- Outputs: all signals that the **master** drives (aw*, w*, ar*, rready, bready)
- Inputs: all signals the **slave/DUT** drives (awready, wready, bvalid, bid, bresp, arready, rvalid, rdata, rid, rlast, rresp, arst)
- Default timing: `output #0 input #0` (sample/drive at clock edge)

`mon_cb` (monitor uses this):
- All signals are inputs (monitor never drives)
- Same list as bfm_cb but all as `input`
