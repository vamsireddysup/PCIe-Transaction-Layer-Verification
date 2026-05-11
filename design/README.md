# design/pcie_tl.sv

This is the DUT. I'm not changing this file — my job is to write a testbench that catches bugs in it.

---

## Module ports at a glance

```
pcie_tl(
  aclk, arst,

  // processor side (AXI4 master drives this)
  awvalid_p, awready_p, awid_p, awaddr_p, awlen_p, awburst_p, awsize_p,
  wvalid_p,  wready_p,  wdata_p, wstrb_p, wid_p,   wlast_p,
  bvalid_p,  bready_p,  bid_p,   bresp_p,
  arvalid_p, arready_p, arid_p,  araddr_p, arlen_p, arburst_p, arsize_p,
  rvalid_p,  rready_p,  rdata_p, rid_p,   rlast_p, rresp_p,

  // memory side (DUT drives this)
  awvalid_m ... rresp_m   (same signals, opposite direction)

  // DLL TX (DUT → DLL)
  tl_dll_clk, tx_data_o[31:0], tx_valid_o, tx_ready_i, vc_num[2:0],

  // DLL RX (DLL → DUT)
  rx_data_i[31:0], rx_valid_i, rx_ready_o, linkup, dll_vc_up[7:0]
)
```

---

## Register map

The processor writes to these over AXI before anything else happens.

| Address | Register | Notes |
|---------|----------|-------|
| `0x1000` | `tc_vc_mapping_reg` | Traffic class → virtual channel mapping |
| `0x1004` | `link_control_reg` | Write bit[0]=1 to start link training |
| `0x1008` | `vc_fc_status_reg` | Read-only. Bit N goes 1 when VC N is initialized |
| `0x100C` | `ep_bar0_base_addr` | Base address of the endpoint's BAR0 |
| `0x1010` | `dma_configure_reg` | Bit[0]=1 starts the DMA transfer |
| `0x1014` | `tlp_transfer_config_reg` | Bits[4:0] pick the TLP type (MEM_WR, MEM_RD, etc.) |
| `0x1018` | `max_payload_size` | Max TLP payload in bytes, default 4096 |
| `0x101C` | `target_device_type` | 0 = Endpoint, 1 = Switch |
| `0x2000–0x27FF` | TX descriptors | 32 transmit descriptors, 2 DWs each |
| `0x2800–0x2FFF` | RX descriptors | 32 receive descriptors |

### TX descriptor layout

```
DW0[31:16] = transfer length in bytes
DW0[15:13] = control flags
DW1[31:0]  = source address (where DMA reads from)
```

---

## AXI-side FSM

Clocked on `aclk`.

```
S_IDLE_AXI
  ├── awvalid_p=1 → S_REG_WRITE_ADDR
  └── arvalid_p=1 → S_REG_READ

S_REG_WRITE_ADDR   asserts awready_p → S_REG_WRITE_DATA
S_REG_WRITE_DATA   latches wdata_p into register → S_REG_WRITE_RESP  (when wlast_p=1)
S_REG_WRITE_RESP   asserts bvalid_p → S_IDLE_AXI  (when bready_p=1)
                   if link_control_reg[0]=1 → sets init_link_training flag

S_REG_READ         asserts arready_p, drives rdata_p → S_IDLE_AXI
```

---

## DLL-side FSM

Clocked on `tl_dll_clk`.

```
S_IDLE_DLL          → S_LINK_TRAINING  (when init_link_training=1)
S_LINK_TRAINING     → S_VC0_FC_INIT   (when linkup=1)
S_VC0..VC7_FC_INIT  walk through all 8 VCs as dll_vc_up[N] goes high
S_ENUM_FRAME_TLP    builds a CFG_RD0 or CFG_RD1 TLP header
S_ENUMERATION_DRV_TLP  streams TLP DWs over tx_data_o / tx_valid_o
S_ENUM_FRAME_TLP_CYCLE_GAP  one cycle gap between back-to-back CFG reads
S_ENUM_READ_ALL_DW_COMPLETE  after 16 CFG reads → sends CFG_WR0 to set BAR0
S_ENUMERATION_DRV_CFG_WR_TLP
S_ENUM_COMPL_IDLE   waits for dma_configure_reg[0]=1

S_MEM_WR / S_MEM_RD / S_IO_WR / S_IO_RD / S_CFG_WR / S_CFG_RD / S_MSG
  → all empty stubs, not implemented yet
```

---

## TLP header format (3-DW, 32-bit wide serial)

```
DW0: [31:29] FMT   [28:24] TYPE   [23] T9   [22:20] TC   [19] T8
     [18] Attr2    [17] LN        [16] TH   [15] TD       [14] EP
     [13:12] Attr[1:0]            [11:10] AT               [9:0] Length

DW1: [31:16] Requester ID (Bus[7:0] | Dev[4:0] | Func[2:0])
     [15:8] Tag    [7:4] LastDWBE    [3:0] FirstDWBE

DW2 (CFG): [31:24] TargetBus  [23:19] TargetDev  [18:16] TargetFunc
           [11:8] ExtRegNum   [7:2] RegNum         [1:0] = 00

DW2 (MEM): [31:0] Address
```

### TLP types I care about

| Type | FMT | TYPE |
|------|-----|------|
| CfgRd0 | `000` | `00100` |
| CfgWr0 | `010` | `00100` |
| CfgRd1 | `000` | `00101` |
| CfgWr1 | `010` | `00101` |
| MRd    | `000` | `00000` |
| MWr    | `010` | `00000` |
| CplD   | `010` | `01010` |

FMT bit[1]=1 means the TLP carries a payload.

---

## Known bug in this file

Line 564 in `frame_cfg_tlp()`:

```sv
// wrong — device_num used twice
header[1][31:16] = {requester_bus_num, requester_device_num, requester_device_num};

// correct
header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
```

This makes every outgoing CFG TLP carry a malformed requester ID. I'll fix it in Week 5.
