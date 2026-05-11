# Design — `pcie_tl.sv`

This directory contains the **DUT (Device Under Test)**: the PCIe Transaction Layer module.  
Do **not** modify this file during the weekly challenges — your job is to verify it.

---

## Module Interface

```
pcie_tl(
  aclk, arst,

  // Processor AXI4 (master drives this side)
  awvalid_p / awready_p / awid_p / awaddr_p / awlen_p / awburst_p / awsize_p
  wvalid_p  / wready_p  / wdata_p / wstrb_p / wid_p / wlast_p
  bvalid_p  / bready_p  / bid_p / bresp_p
  arvalid_p / arready_p / arid_p / araddr_p / arlen_p / arburst_p / arsize_p
  rvalid_p  / rready_p  / rdata_p / rid_p / rlast_p / rresp_p

  // Memory AXI4 (DUT drives this side)
  awvalid_m ... rresp_m   (same structure, opposite direction)

  // DLL TX (DUT → DLL)
  tl_dll_clk / tx_data_o [31:0] / tx_valid_o / tx_ready_i / vc_num [2:0]

  // DLL RX (DLL → DUT)
  rx_data_i [31:0] / rx_valid_i / rx_ready_o / linkup / dll_vc_up [7:0]
)
```

---

## Register Map (AXI address space)

| Address    | Register                 | Description |
|------------|--------------------------|-------------|
| `0x1000`   | `tc_vc_mapping_reg`      | Traffic Class to Virtual Channel mapping |
| `0x1004`   | `link_control_reg`       | Bit[0]=1 triggers link training |
| `0x1008`   | `vc_fc_status_reg`       | Read-only: bit N=1 when VC N is up |
| `0x100C`   | `ep_bar0_base_addr`      | Base address of endpoint BAR0 |
| `0x1010`   | `dma_configure_reg`      | Bit[0]=1 starts DMA transfer |
| `0x1014`   | `tlp_transfer_config_reg`| Bits[4:0] select TLP type (MEM_WR, MEM_RD …) |
| `0x1018`   | `max_payload_size`       | Max TLP payload in bytes (default 4096) |
| `0x101C`   | `target_device_type`     | 0=Endpoint, 1=Switch |
| `0x2000–0x27FF` | `txDescrRegA[0..63]` | TX DMA descriptors (32 × 2 DW each) |
| `0x2800–0x2FFF` | `rxDescrRegA[0..63]` | RX DMA descriptors |

### TX Descriptor Format (2 × 32-bit DW)

```
DW0 [31:16] = transfer length in bytes
DW0 [15:13] = control flags
DW1 [31:0]  = source address (where DMA reads from memory)
```

---

## AXI-Side FSM (`state_axi`, clocked on `aclk`)

```
S_IDLE_AXI
  │ awvalid_p=1 → S_REG_WRITE_ADDR
  │ arvalid_p=1 → S_REG_READ

S_REG_WRITE_ADDR  → asserts awready_p
  └─→ S_REG_WRITE_DATA

S_REG_WRITE_DATA  → accepts wdata_p, writes register
  │ wlast_p=1 → S_REG_WRITE_RESP

S_REG_WRITE_RESP  → asserts bvalid_p
  │ bready_p=1 → S_IDLE_AXI
  │ (if link_control_reg[0]=1, sets init_link_training flag)

S_REG_READ        → asserts arready_p, drives rdata_p, rvalid_p
  └─→ S_IDLE_AXI
```

---

## DLL-Side FSM (`state_dll`, clocked on `tl_dll_clk`)

```
S_IDLE_DLL
  └─ init_link_training=1 → S_LINK_TRAINING

S_LINK_TRAINING
  └─ linkup=1 → S_VC0_FC_INIT

S_VC0_FC_INIT … S_VC7_FC_INIT   (wait for dll_vc_up[N]=1 each)
  └─ all VCs up → S_ENUM_FRAME_TLP

S_ENUM_FRAME_TLP          → builds CFG_RD0/CFG_RD1 TLP header
S_ENUMERATION_DRV_TLP     → streams header DWs to DLL (tx_data_o, tx_valid_o)
S_ENUM_FRAME_TLP_CYCLE_GAP → one cycle gap between CFG TLPs
S_ENUM_READ_ALL_DW_COMPLETE → after 16 CFG reads, sends CFG_WR to set BAR0
S_ENUMERATION_DRV_CFG_WR_TLP
S_ENUM_COMPL_IDLE          → waits for dma_configure_reg[0]=1

S_MEM_WR / S_MEM_RD / S_IO_WR / S_IO_RD / S_CFG_WR / S_CFG_RD / S_MSG
  (currently empty — to be implemented)
```

---

## TLP Header Format (3-DW, 32-bit serial)

```
DW0: [31:29]=FMT  [28:24]=TYPE  [23]=T9  [22:20]=TC  [19]=T8
     [18]=Attr2  [17]=LN  [16]=TH  [15]=TD  [14]=EP
     [13:12]=Attr[1:0]  [11:10]=AT  [9:0]=Length

DW1: [31:16]=Requester ID (Bus[7:0] Dev[4:0] Func[2:0])
     [15:8]=Tag  [7:4]=LastDWBE  [3:0]=FirstDWBE

DW2 (CFG): [31:24]=TargetBus  [23:19]=TargetDev  [18:16]=TargetFunc
           [15:12]=0  [11:8]=ExtRegNum  [7:2]=RegNum  [1:0]=0

DW2 (MEM): [31:0]=Address
```

### TLP Type Encodings

| TLP Type | FMT[2:0] | TYPE[4:0] |
|----------|----------|-----------|
| MRd (Memory Read) | `000` | `00000` |
| MWr (Memory Write) | `010` | `00000` |
| IORd | `000` | `00010` |
| IOWr | `010` | `00010` |
| CfgRd0 | `000` | `00100` |
| CfgWr0 | `010` | `00100` |
| CfgRd1 | `000` | `00101` |
| CfgWr1 | `010` | `00101` |
| Msg | `001` | `10000` |
| CplD | `010` | `01010` |

---

## Known Bug in This File

**Line 564** — `requester_device_num` is used twice in the CFG TLP header DW1:
```sv
// BUG:
header[1][31:16] = {requester_bus_num, requester_device_num, requester_device_num};
// CORRECT:
header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
```
Finding this during Week 3 (when you implement your own `frame_cfg_tlp`) is intentional.
