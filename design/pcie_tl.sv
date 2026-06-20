// design.sv
// pcie transaction layer dut. sits between axi (processor side), axi (memory side dma),
// and the dll interface (tx = tlp out, rx = tlp in).
// 3 fsms in here: state_axi (reg access from cpu), state_dll (main flow, link train,
// enumeration, mem_wr, mem_rd), state_axi_mem (writes completion data back to sys memory)

`include "pcie_common.sv"
module pcie_tl(
  aclk, arst,

  // processor side axi
  awvalid_p, awready_p, awid_p, awaddr_p, awlen_p, awburst_p, awsize_p,
  wvalid_p, wready_p, wdata_p, wstrb_p, wid_p, wlast_p,
  bvalid_p, bready_p, bid_p, bresp_p,

  arvalid_p, arready_p, arid_p, araddr_p, arlen_p, arburst_p, arsize_p,
  rvalid_p, rready_p, rdata_p, rid_p, rlast_p, rresp_p,

  // memory side axi (dut is master here, does dma)
  awvalid_m, awready_m, awid_m, awaddr_m, awlen_m, awburst_m, awsize_m,
  wvalid_m, wready_m, wdata_m, wstrb_m, wid_m, wlast_m,
  bvalid_m, bready_m, bid_m, bresp_m,

  arvalid_m, arready_m, arid_m, araddr_m, arlen_m, arburst_m, arsize_m,
  rvalid_m, rready_m, rdata_m, rid_m, rlast_m, rresp_m,

  // dll_tx, dut sends tlp out this way
  tl_dll_clk,
  tx_data_o, tx_valid_o, tx_ready_i,
  vc_num,

  // dll_rx, tlp comes into the dut this way
  rx_data_i, rx_valid_i, rx_ready_o,
  linkup, dll_vc_up

);


// processor interface signals
input aclk, arst;
input awvalid_p, wvalid_p;
output reg awready_p, wready_p;
input [3:0] awid_p; // tx id from cpu
input [31:0] awaddr_p;
input [3:0] awlen_p;
input [1:0] awburst_p;
input [2:0] awsize_p;
input [31:0] wdata_p;
input [3:0]  wstrb_p;
input [3:0]  wid_p;
input  wlast_p;
output reg bvalid_p;
input bready_p;
output reg [1:0] bid_p;
output reg [1:0] bresp_p;

input arvalid_p;
output reg arready_p;
input [3:0] arid_p;
input [31:0] araddr_p;
input [3:0] arlen_p;
input [1:0] arburst_p;
input [2:0] arsize_p;
output reg rvalid_p;
input rready_p;
output reg [31:0] rdata_p;
output reg [3:0]  rid_p;
output reg rlast_p;
output reg [1:0] rresp_p;


// memory interface signals, dut is the axi master on this side
output reg awvalid_m;
input reg awready_m;
output reg [3:0] awid_m;
output reg [31:0] awaddr_m;
output reg [3:0] awlen_m;
output reg [1:0] awburst_m;
output reg [2:0] awsize_m;
output reg wvalid_m;
input reg wready_m;
output reg [31:0] wdata_m;
output reg [3:0]  wstrb_m;
output reg [3:0]  wid_m;
output reg  wlast_m;
input bvalid_m;
output reg bready_m;
input [1:0] bid_m;
input [1:0] bresp_m;

output reg arvalid_m;
input arready_m;
output reg [3:0] arid_m;
output reg [31:0] araddr_m;
output reg [3:0] arlen_m;
output reg [1:0] arburst_m;
output reg [2:0] arsize_m;
input rvalid_m;
output reg rready_m;
input [31:0] rdata_m;
input [3:0]  rid_m;
input rlast_m;
input [1:0] rresp_m;


// dll_tx interface signals
input tl_dll_clk;
output reg [31:0] tx_data_o;
output reg tx_valid_o;
input tx_ready_i;
output reg [2:0] vc_num; // which vc is being used right now

// dll_rx interface signals
input [31:0] rx_data_i;
input rx_valid_i;
output reg rx_ready_o;
input [7:0] dll_vc_up; // which vc's flow control is up
input linkup;

reg [5:0] state_axi, n_state_axi;
reg [5:0] state_dll, n_state_dll;
reg [3:0] state_axi_mem, n_state_axi_mem;
reg [31:0] tc_vc_mapping_reg; // 1000
reg [31:0] link_control_reg; // 1004
reg [31:0] vc_fc_status_reg; // 1008
reg [31:0] ep_bar0_base_addr; // 100C
reg [31:0] dma_configure_reg; // 1010
reg [31:0] tlp_transfer_config_reg; // 1014
reg [31:0] max_payload_size; // 1018
reg [31:0] target_device_type; // 101C

reg [31:0] txDescrRegA[63:0]; // 32 tx descriptors @ 2000, 2 dw per descriptor
reg [31:0] txDescrPtr;
reg [63:0] txDescr;

reg [31:0] rxDescrRegA[63:0]; // 32 rx descriptors @ 2800
reg [31:0] rxDescrPtr;
reg [63:0] rxDescr;

reg ignore_first_beat_f;
int tx_count;

reg [15:0] length;

reg init_link_training;
int cfg_tlp_count;

reg [31:0] header[3:0];
reg [31:0] payloadA[1023:0];
reg [31:0] memdataA[1023:0];

int header_size; // 3 or 4 dw
int payload_size;
int ep_bar0_cfg_done;
int total_cfg_tlp_drv_count;

int count;
int count_p;
int received_bytecount;
int count_axi_mem;
reg[9:0] tag_t;
reg[9:0] attr;
reg[7:0] requester_bus_num;
reg[4:0] requester_device_num;
reg[2:0] requester_function_num;
reg[7:0] target_bus_num;
reg[4:0] target_device_num;
reg[2:0] target_function_num;

reg [31:0] awaddr_temp;
reg [31:0] araddr_temp;
reg [31:0] arid_temp;

reg [2:0] fmt;
reg [4:0] type_t;
reg [9:0] length_tlp;
reg [15:0] completer_id;
reg [2:0] completer_state;
reg bcm;
reg [11:0] bytecount;
reg [15:0] requester_id;
reg [7:0] tag;
reg [6:0] lower_address;

reg write_to_axi_mem;
reg [31:0] cpltlpdataQ[$];

reg [31:0] dummy;

int ignore_count;

// fsm state encodings
// axi reg access side
parameter S_IDLE_AXI                    = 6'b00_0000;
parameter S_REG_WRITE_ADDR              = 6'b00_0001;
parameter S_REG_WRITE_DATA              = 6'b00_0010;
parameter S_REG_WRITE_RESP              = 6'b00_0011;
parameter S_REG_READ                    = 6'b00_0100;

// dll side, this is the big one. link training -> vc init -> enumeration -> mem_wr/mem_rd
parameter S_IDLE_DLL                    = 6'b00_0101;
parameter S_LINK_TRAINING               = 6'b00_0110;
parameter S_VC0_FC_INIT                 = 6'b00_0111;
parameter S_VC1_FC_INIT                 = 6'b00_1000;
parameter S_VC2_FC_INIT                 = 6'b00_1001;
parameter S_VC3_FC_INIT                 = 6'b00_1010;
parameter S_VC4_FC_INIT                 = 6'b00_1011;
parameter S_VC5_FC_INIT                 = 6'b00_1100;
parameter S_VC6_FC_INIT                 = 6'b00_1101;
parameter S_VC7_FC_INIT                 = 6'b00_1110;
parameter S_ENUM_FRAME_TLP              = 6'b00_1111;
parameter S_ENUM_FRAME_TLP_CYCLE_GAP    = 6'b01_0000;
parameter S_ENUMERATION_DRV_TLP         = 6'b01_0001;
parameter S_ENUM_READ_ALL_DW_COMPLETE   = 6'b01_0010;
parameter S_ENUMERATION_DRV_CFG_WR_TLP  = 6'b01_0011;
parameter S_ENUM_COMPL_IDLE             = 6'b01_0100;
parameter S_ENUM_ERROR                  = 6'b01_0101;
parameter S_MEM_WR                      = 6'b01_0110;
parameter S_MEM_WR_READ_ADDR            = 6'b01_0111;
parameter S_MEM_WR_GET_DATA             = 6'b01_1000;
parameter S_TRANSMIT_TLP_POSTED         = 6'b01_1001;
parameter S_TRANSMIT_TLP_NONPOSTED      = 6'b01_1010;
parameter S_PROCESS_COMPLETION_TLP      = 6'b01_1011;
parameter S_MEM_RD                      = 6'b01_1100;
// these below are still stubs, not in scope right now. left empty on purpose,
// not forgotten, just not needed to get enum/mem_wr/mem_rd passing
parameter S_CFG_WR                      = 6'b01_1101; // todo : not implemented
parameter S_CFG_RD                      = 6'b01_1110; // todo : not implemented
parameter S_IO_WR                       = 6'b01_1111; // todo : not implemented
parameter S_IO_RD                       = 6'b10_0000; // todo : not implemented
parameter S_MSG                         = 6'b10_0001; // todo : not implemented
parameter S_ERROR                       = 6'b10_0010;

parameter S_AXI_MEM_IDLE                = 4'b0000;
parameter S_AXI_MEM_AXI_WR_ADDR         = 4'b0001;
parameter S_AXI_MEM_AXI_WR_DATA         = 4'b0010;
parameter S_AXI_MEM_AXI_WR_RESP         = 4'b0011;
parameter S_AXI_MEM_AXI_RD_ADDR         = 4'b0100; // todo : not implemented
parameter S_AXI_MEM_AXI_RD_DATA         = 4'b0101; // todo : not implemented


  reg [4:0] state;
  always@(*) begin
      state        = pcie_common::state;
  end

// axi register access fsm. cpu writes config regs / dma descriptors here,
// also handles register reads back to cpu
always @(posedge aclk) begin
  if (arst == 1) begin
    reset_all_reg_variables();
  end
  else begin
    case (state_axi)
      S_IDLE_AXI               : begin
        if (awvalid_p == 1) begin
          n_state_axi = S_REG_WRITE_ADDR;
          awaddr_temp = awaddr_p;
        end
        if (arvalid_p == 1) begin
          n_state_axi = S_REG_READ;
          araddr_temp = araddr_p;
          arid_temp = arid_p;
        end
      end

      S_REG_WRITE_ADDR     : begin
        awready_p = 1;
        n_state_axi = S_REG_WRITE_DATA;
      end

      S_REG_WRITE_DATA     : begin
        awready_p = 0;
        if(wvalid_p == 1) begin
          wready_p = 1;

          // map the addr to whichever config reg the cpu is writing
          case (awaddr_temp)
            32'h1000: tc_vc_mapping_reg = wdata_p;
            32'h1004: link_control_reg = wdata_p;
            // 32'h1008 : vc_fc_status_reg, this one only the dut updates, cpu shouldn't write it
            32'h100C: ep_bar0_base_addr = wdata_p;
            32'h1010: dma_configure_reg = wdata_p;
            32'h1014: tlp_transfer_config_reg = wdata_p;
            32'h1018: max_payload_size = wdata_p;
            32'h101C: target_device_type = wdata_p;
          endcase

          // tx/rx descriptor ram regions, 32 descriptors each, 2 dw per descriptor
          if (awaddr_temp inside {[32'h2000:32'h27FF]}) begin
            txDescrRegA[(awaddr_temp-32'h2000)/4] = wdata_p;
          end

          if (awaddr_temp inside {[32'h2800:32'h2FFF]}) begin
            rxDescrRegA[(awaddr_temp-32'h2800)/4] = wdata_p;
          end


          if (wlast_p == 1) begin
            n_state_axi = S_REG_WRITE_RESP;
          end
        end
      end

      S_REG_WRITE_RESP     : begin
        wready_p = 0;
        bvalid_p = 1;
        if (bready_p == 1) begin
          @(posedge aclk);
          bvalid_p = 0;
          n_state_axi = S_IDLE_AXI;

          // link_control_reg[0] is the "go" bit, cpu sets it once it's done with cfg writes
          if (link_control_reg[0] == 1) begin
            init_link_training = 1;
          end
        end
      end

      S_REG_READ           : begin
        arready_p = 1;
        read_register();
        if (rready_p == 1) begin // cpu side is ready to take the data
          arready_p = 0;
          n_state_axi = S_IDLE_AXI;
        end
      end
    endcase
  end
end

// main dll fsm. this is the whole flow: link train -> vc fc init x8 -> enumeration
// (reads ep config space via cfg_rd0/cfg_wr0) -> idle loop that dispatches mem_wr / mem_rd
// based on whatever the test wrote into tlp_transfer_config_reg
always @(posedge tl_dll_clk) begin
  if (arst != 1) begin
    case (state_dll)
        S_IDLE_DLL         : begin
        if (init_link_training == 1) begin
          n_state_dll = S_LINK_TRAINING;
        end
      end

      S_LINK_TRAINING      : begin
        if (linkup == 1) begin
          n_state_dll = S_VC0_FC_INIT;
        end
      end

      // vc0-vc7 fc init, just walking the dll_vc_up bits one at a time
      S_VC0_FC_INIT        : begin
        if (dll_vc_up[0] == 1) begin
          vc_fc_status_reg[0] = 1;
          n_state_dll = S_VC1_FC_INIT;
        end
      end

      S_VC1_FC_INIT        : begin
        if (dll_vc_up[1] == 1) begin
          vc_fc_status_reg[1] = 1;
          n_state_dll = S_VC2_FC_INIT;
        end
      end

      S_VC2_FC_INIT        : begin
        if (dll_vc_up[2] == 1) begin
          vc_fc_status_reg[2] = 1;
          n_state_dll = S_VC3_FC_INIT;
        end
      end

      S_VC3_FC_INIT        : begin
        if (dll_vc_up[3] == 1) begin
          vc_fc_status_reg[3] = 1;
          n_state_dll = S_VC4_FC_INIT;
        end
      end

      S_VC4_FC_INIT        : begin
        if (dll_vc_up[4] == 1) begin
          vc_fc_status_reg[4] = 1;
          n_state_dll = S_VC5_FC_INIT;
        end
      end

      S_VC5_FC_INIT        : begin
        if (dll_vc_up[5] == 1) begin
          vc_fc_status_reg[5] = 1;
          n_state_dll = S_VC6_FC_INIT;
        end
      end

      S_VC6_FC_INIT        : begin
        if (dll_vc_up[6] == 1) begin
          vc_fc_status_reg[6] = 1;
          n_state_dll = S_VC7_FC_INIT;
        end
      end

      S_VC7_FC_INIT        : begin
        if (dll_vc_up[7] == 1) begin
          vc_fc_status_reg[7] = 1;
          n_state_dll = S_ENUM_FRAME_TLP;
        end
      end

      // enumeration: frame a cfg_rd0 (or cfg_rd1 if target is a switch), bdf = 1-0-0
      S_ENUM_FRAME_TLP : begin
        if (target_device_type == `ENDPOINT) begin
          frame_cfg_tlp(`CFG_RD0, 1, 1, 0, cfg_tlp_count, 0); // fills header[] array
        end else if (target_device_type == `SWITCH) begin
          frame_cfg_tlp(`CFG_RD1, 1, 1, 0, cfg_tlp_count, 0);
        end else begin
          n_state_dll = S_ENUM_ERROR;
        end

        header_size = 3;
        payload_size = 0;
        count = 0;

        n_state_dll = S_ENUMERATION_DRV_TLP;
      end

      // drive the cfg_rd0 header dw by dw onto tx, 16 of these total during enum
      S_ENUMERATION_DRV_TLP  : begin
        if(count < header_size) tx_data_o = header[count];
        else tx_data_o = payloadA[count-header_size];

        tx_valid_o = 1'b1;
        if (tx_ready_i == 1) begin
          count = count + 1;
        end
        if (count == header_size + payload_size) begin
          cfg_tlp_count = cfg_tlp_count + 1;
          if (cfg_tlp_count == 16) begin
            n_state_dll = S_ENUM_READ_ALL_DW_COMPLETE;
            cfg_tlp_count = 0;
          end else begin
            n_state_dll = S_ENUM_FRAME_TLP_CYCLE_GAP; // more cfg_rd0 still pending
          end
          count = 0;
        end
      end

      S_ENUM_FRAME_TLP_CYCLE_GAP : begin
        tx_valid_o = 1'b0;
        n_state_dll = S_ENUM_FRAME_TLP; // go frame the next one
      end

      // all 16 cfg reads done, now write bar0 base addr into the ep so it knows where its
      // memory window starts
      S_ENUM_READ_ALL_DW_COMPLETE : begin
        tx_valid_o = 1'b0;
        if (target_device_type == `ENDPOINT) begin
          frame_cfg_tlp(`CFG_WR0, 1, 1, 0, 0, 0);
        end else if (target_device_type == `SWITCH) begin
          frame_cfg_tlp(`CFG_WR1, 1, 1, 0, 0, 0);
        end else begin
          n_state_dll = S_ENUM_ERROR;
        end

        payloadA[0] = ep_bar0_base_addr;
        header_size = 3;
        payload_size = 1;
        count = 0;
        @(posedge tl_dll_clk);
        n_state_dll = S_ENUMERATION_DRV_CFG_WR_TLP;
      end

      S_ENUMERATION_DRV_CFG_WR_TLP  : begin
        if(count < header_size) tx_data_o = header[count];
        else tx_data_o = payloadA[count-header_size];

        tx_valid_o = 1'b1;
        if (tx_ready_i == 1) begin
          count = count + 1;
        end
        if (count == header_size + payload_size) begin
          @(posedge tl_dll_clk)
          n_state_dll = S_ENUM_COMPL_IDLE;
          count = 0;
        end
      end

      // enum is done, this is the idle/dispatch state. checks dma_configure_reg[0]
      // and tlp_transfer_config_reg to decide what tlp the test actually wants sent
      S_ENUM_COMPL_IDLE : begin
        rx_ready_o = 0;
        tx_valid_o = 0;
        // dma_configure_reg : [0] tx_en, [1] rx_en
        if (dma_configure_reg[0] == 1) begin
          case (tlp_transfer_config_reg[4:0])
            `MEM_WR: n_state_dll = S_MEM_WR;
            `MEM_RD: n_state_dll = S_MEM_RD;
            `IO_WR: n_state_dll = S_IO_WR;
            `IO_RD: n_state_dll = S_IO_RD;
            `CFG_WR: n_state_dll = S_CFG_WR;
            `CFG_RD: n_state_dll = S_CFG_RD;
            `MSG: n_state_dll = S_MSG;
          endcase
          tx_count = 0;
          // pull the tx descriptor pair for this transfer
          txDescr[31:0] = txDescrRegA[(txDescrPtr-32'h2000)/4];
          txDescr[63:32] = txDescrRegA[(txDescrPtr+4-32'h2000)/4];
          $display("txDescr=0x%0h", txDescr);
          length = txDescr[31:16]; // bytes
          dma_configure_reg[0] = 0;
          count = 0;
        end
      end

      S_ENUM_ERROR  : begin
        n_state_dll = S_IDLE_DLL;
      end

      // mem_wr : dut pulls data from system memory (via axi memory side, dut as master)
      // and frames it into mem_wr tlps, max_payload_size bytes per tlp
      S_MEM_WR : begin
        tx_count = tx_count + 1;
        // each axi burst pulls 64 bytes (16 beats x 4 bytes), so this many bursts needed
        if (tx_count <= length/64) begin
          n_state_dll = S_MEM_WR_READ_ADDR;
        end
        else begin
          n_state_dll = S_ENUM_COMPL_IDLE;
        end
        rready_m = 0;
      end

      // kick off an axi read burst on the memory side to fetch the data we're about to send
      S_MEM_WR_READ_ADDR : begin
        araddr_m = txDescr[63:32];
        arlen_m = 15; // 16 beats
        arid_m = 0;
        arburst_m = 2'b01; // incr
        arsize_m = 2'b10; // 4 bytes/beat
        arvalid_m = 1;
        if (arready_m == 1) begin
          n_state_dll = S_MEM_WR_GET_DATA;
          araddr_m = 0;
          arlen_m = 0;
          arid_m = 0;
          arburst_m = 0;
          arsize_m = 0;
          arvalid_m = 0;
          ignore_first_beat_f = 1;
        end
      end

      // collect the read data beats into payloadA, once we have max_payload_size worth, go transmit
      S_MEM_WR_GET_DATA : begin
        if (rvalid_m == 1) begin
          if (ignore_first_beat_f == 0) begin
            payloadA[count] = rdata_m; // 4 bytes per beat
            count = count + 1;
          end
          ignore_first_beat_f = 0;
          rready_m = 1;
        end
        if (rlast_m == 1) begin
          $display("this is last beat of data");
          n_state_dll = S_MEM_WR;
          txDescr[63:32] += 64;
        end
        // frame the tlp once we've buffered a full payload's worth
        if (count == max_payload_size/4) begin
          n_state_dll = S_TRANSMIT_TLP_POSTED;
          frame_mem_wr_tlp(32'hEC00_0000);
          payload_size = max_payload_size/4;
          count = 0;
        end
      end

      // mem_wr is posted, no completion expected back, just drive header+payload and go idle
      S_TRANSMIT_TLP_POSTED : begin
        if (count <= 2) tx_data_o = header[count];
        if (count >= 3) tx_data_o = payloadA[count-header_size];

        tx_valid_o = 1'b1;

        if (tx_ready_i == 1) begin
          count = count + 1;
        end

        if (count == header_size + payload_size) begin
          n_state_dll = S_ENUM_COMPL_IDLE; // posted, done after drive
          count = 0;
        end

      end

      // mem_rd is non-posted, drive the header then go wait for cpld back
      S_TRANSMIT_TLP_NONPOSTED : begin

        if (count <= 2) tx_data_o = header[count];
        if (count >= 3) tx_data_o = payloadA[count-header_size];

        $display("S_TRANSMIT_TLP_NONPOSTED tx_data_o=0x%0h", tx_data_o);

        tx_valid_o = 1'b1;

        if (tx_ready_i == 1) begin
          count = count + 1;
        end

        if (count == header_size + payload_size) begin
          n_state_dll = S_PROCESS_COMPLETION_TLP; // wait for the cpld now
          count = 0;
          count_p = 0;
          ignore_count = 0;

        end

      end

      // collecting the cpld that comes back after a mem_rd. 3 header dw then payload,
      // stash payload into cpltlpdataQ and once we hit 16 dw kick the axi_mem write fsm
      S_PROCESS_COMPLETION_TLP : begin
        tx_valid_o = 0;
        if (rx_valid_i == 1) begin
          rx_ready_o = 1;
          if (count_p == 0) begin
            fmt = rx_data_i[31:29];
            type_t = rx_data_i[28:24];
            length_tlp = rx_data_i[9:0]; // length in dw
          end
          if (count_p == 1) begin
            completer_id = rx_data_i[31:16];
            completer_state = rx_data_i[15:13];
            bcm = rx_data_i[12];
            bytecount = rx_data_i[11:0];
          end
          if (count_p == 2) begin
            requester_id = rx_data_i[31:16];
            tag_t = rx_data_i[15:8];
            lower_address = rx_data_i[6:0];
            received_bytecount = 0;
          end
          if (count_p >= 3) begin
            cpltlpdataQ.push_back(rx_data_i);
            received_bytecount += 4;

            if (cpltlpdataQ.size() == 16) begin
              write_to_axi_mem = 1;
            end
            if (received_bytecount == bytecount) begin
              n_state_dll = S_ENUM_COMPL_IDLE;
            end
          end
          count_p++;
        end else begin
          rx_ready_o = 0;
        end
      end

      // mem_rd : frame the read request tlp and go drive it non-posted
      S_MEM_RD             : begin
        frame_mem_rd_tlp(32'hEC00_0000);
        count = 0;
        header_size = 3;
        payload_size = 0;
        n_state_dll = S_TRANSMIT_TLP_NONPOSTED;
      end

      // not implemented yet, out of scope for now
      S_CFG_WR             : begin
      end
      S_CFG_RD             : begin
      end
      S_IO_WR              : begin
      end
      S_IO_RD               : begin
      end
      S_MSG                : begin
      end
      S_ERROR              : begin
      end


    endcase
  end
end

// after a mem_rd completion comes back, this fsm drains cpltlpdataQ and writes it into
// system memory over the axi memory side (dut still acting as master)
always @(posedge aclk) begin
  if (arst == 0) begin
    case (state_axi_mem)
      S_AXI_MEM_IDLE : begin
        bready_m = 0;

        if (write_to_axi_mem == 1) begin
          n_state_axi_mem = S_AXI_MEM_AXI_WR_ADDR;
          // pull the rx descriptor for where this data should land
          rxDescr[31:0] = rxDescrRegA[(rxDescrPtr-32'h2800)/4];
          rxDescr[63:32] = rxDescrRegA[(rxDescrPtr+4-32'h2800)/4];
          $display("rxDescr=0x%0h", rxDescr);
          length = rxDescr[31:16];
        end
      end

      S_AXI_MEM_AXI_WR_ADDR : begin
        awaddr_m = rxDescr[63:32];
        awlen_m = 15;
        awid_m = 0;
        awburst_m = 2'b01;
        awsize_m = 2'b10;
        awvalid_m = 1;
        bready_m = 0;
        if (awready_m == 1) begin
          n_state_axi_mem = S_AXI_MEM_AXI_WR_DATA;
          awaddr_m = 0;
          awlen_m = 0;
          awid_m = 0;
          awburst_m = 0;
          awsize_m = 0;
          awvalid_m = 0;
          count_axi_mem = 0;
        end
      end

      S_AXI_MEM_AXI_WR_DATA : begin
        wdata_m = cpltlpdataQ[count_axi_mem];
        wvalid_m = 1'b1;
        wid_m = 0;
        if (wready_m == 1) begin
          count_axi_mem = count_axi_mem + 1;
        end
        if (count_axi_mem == 16) begin
          wlast_m = 1;
          n_state_axi_mem = S_AXI_MEM_AXI_WR_RESP;
        end

      end
      S_AXI_MEM_AXI_WR_RESP : begin
        wlast_m = 0;
        wdata_m = 0;
        write_to_axi_mem = 0;
        if (bvalid_m == 1) begin
          bready_m = 1;
          repeat (16) dummy = cpltlpdataQ.pop_front();

          if (cpltlpdataQ.size() >= 16) begin
            n_state_axi_mem = S_AXI_MEM_AXI_WR_ADDR;
            rxDescr[63:32] += 64;
            write_to_axi_mem = 1;
          end else begin
            n_state_axi_mem = S_AXI_MEM_IDLE;
            write_to_axi_mem = 0;
          end
        end
      end
      // not implemented yet, out of scope for now
      S_AXI_MEM_AXI_RD_ADDR : begin
      end
      S_AXI_MEM_AXI_RD_DATA : begin
      end

    endcase

  end
end

  always@( n_state_axi ) state_axi <= n_state_axi;
  always@( n_state_dll ) state_dll <= n_state_dll;
  always@( n_state_axi_mem ) state_axi_mem <= n_state_axi_mem;


  // cpu reads back one of the status/config regs
  task read_register();
    $display("reading register at addr=0x%0h", araddr_temp);
    case (araddr_temp)
      32'h1000: rdata_p = tc_vc_mapping_reg;
      32'h1004: rdata_p = link_control_reg;
      32'h1008: rdata_p = vc_fc_status_reg;
      32'h100C: rdata_p = ep_bar0_base_addr;
    endcase

    rvalid_p = 1;
    rlast_p = 1;
    rresp_p = 2'b00;
    rid_p = arid_temp;

  endtask

  // builds a 3dw cfg_rd0/cfg_rd1/cfg_wr0/cfg_wr1 header into header[]. used during enumeration.
  function void frame_cfg_tlp(bit [2:0] cfg_tlp_type, bit [7:0] target_bus_num, bit [4:0] target_device_num, bit [2:0] target_function_num, bit [5:0] reg_num, bit [3:0] ext_reg_num);
    tag = 10'h123;
    attr = 3'h000;

    // dw0
    if (cfg_tlp_type inside {`CFG_RD0,`CFG_RD1}) begin
      header[0][31:29] = 3'b000; // fmt
      header[0][9:0] = 10'b0; // packet_len, cfg rd has no payload
    end

    if (cfg_tlp_type inside {`CFG_WR0,`CFG_WR1}) begin
      header[0][31:29] = 3'b010; // fmt
      header[0][9:0] = 10'b1; // packet_len, 1 dw payload
    end

    if (cfg_tlp_type inside {`CFG_RD0,`CFG_WR0}) header[0][28:24] = 5'b00100; // type
    if (cfg_tlp_type inside {`CFG_RD1,`CFG_WR1}) header[0][28:24] = 5'b00101; // type


    header[0][23] = tag[9];
    header[0][22:20] = 3'b000; // traffic class
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 0; // ln
    header[0][16] = 0; // th
    header[0][15] = 0; // td
    header[0][14] = 0; // ep, poisoned
    header[0][13:12] = 2'b00; // attr[1:0]
    header[0][11:10] = 2'b00; // at, address translation


    // dw1 : requester id + tag + byte enables
    // note to self : was a bug here before, this used to repeat requester_device_num
    // twice instead of using requester_function_num. fixed.
    header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'b0;
    header[1][3:0] = 4'hF;

    // dw2 : target bdf + register number
    header[2][31:24] = target_bus_num;
    header[2][23:19] = target_device_num;
    header[2][18:16] = target_function_num;
    header[2][15:12] = 4'b0;
    header[2][11:8] = ext_reg_num;
    header[2][7:2] = reg_num;
    header[2][1:0] = 2'b00;


  endfunction

  // builds a mem_wr tlp header. payload is already sitting in payloadA from the read burst
  function void frame_mem_wr_tlp(bit [31:0] addr);
    tag = 10'h123;
    attr = 3'b000;
    header[0][31:29] = `MEM_WR_FMT;
    header[0][28:24] = `MEM_WR_TYPE;
    header[0][23] = tag[9];
    header[0][22:20] = 3'b000; // todo : traffic class not wired up to anything yet
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 1'b0;
    header[0][16] = 1'b0; // th
    header[0][15] = 1'b0; // td
    header[0][14] = 1'b0; // ep
    header[0][13:12] = 2'b00; // attr[1:0]
    header[0][11:10] = 2'b00; // at
    header[0][9:0] = max_payload_size/4; // length in dw

    header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'hF; // last_dw_be, all bytes valid
    header[1][3:0] = 4'hF; // first_dw_be

    header[2][31:0] = addr; // target addr in ep memory, 32'hEC00_0000 by default
  endfunction

  // builds a mem_rd tlp header, same layout as mem_wr just no payload to send
  function void frame_mem_rd_tlp(bit [31:0] addr);
    tag = 10'h123;
    attr = 3'b000;
    header[0][31:29] = 3'b000;
    header[0][28:24] = 5'b00000;
    header[0][23] = tag[9];
    header[0][22:20] = 3'b000;
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 1'b0;
    header[0][16] = 1'b0; // th
    header[0][15] = 1'b0; // td
    header[0][14] = 1'b0; // ep
    header[0][13:12] = 2'b00; // attr[1:0]
    header[0][11:10] = 2'b00; // at
    $display("max_payload_size/4=0x%0h", max_payload_size/4);
    header[0][9:0] = max_payload_size/4;

    header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'hF;
    header[1][3:0] = 4'hF;

    header[2][31:0] = addr;
  endfunction


  // reset everything back to known values. called on arst
  function void reset_all_reg_variables();
    state_axi = S_IDLE_AXI;
    n_state_axi = S_IDLE_AXI;
    state_dll = S_IDLE_DLL;
    n_state_dll = S_IDLE_DLL;
    state_axi_mem = S_AXI_MEM_IDLE;
    n_state_axi_mem = S_AXI_MEM_IDLE;

    awready_p = 0;
    wready_p = 0;
    awaddr_temp = 0;
    araddr_temp = 0;
    arid_temp = 0;
    bvalid_p = 0;
    bid_p = 0;
    bresp_p = 0;
    arready_p = 0;
    rvalid_p = 0;
    rdata_p = 0;
    rid_p = 0;
    rlast_p = 0;
    rresp_p = 0;

    awvalid_m = 0;
    awid_m = 0;
    awaddr_m = 0;
    awlen_m = 0;
    awburst_m = 0;
    awsize_m = 0;
    wvalid_m = 0;
    wdata_m = 0;
    wstrb_m = 0;
    wid_m = 0;
    wlast_m = 0;
    bready_m = 0;
    arvalid_m = 0;
    arid_m = 0;
    araddr_m = 0;
    arlen_m = 0;
    arburst_m = 0;
    arsize_m = 0;
    rready_m = 0;

    tx_data_o = 0;
    tx_valid_o = 0;
    vc_num = 0;
    rx_ready_o = 0;
    tc_vc_mapping_reg = 0;
    link_control_reg = 0;
    vc_fc_status_reg = 32'hFFFF_FFFF;
    ep_bar0_base_addr = 0;
    dma_configure_reg = 0;
    tlp_transfer_config_reg = 0;
    max_payload_size = 4096;
    target_device_type = 32'h0; // default to endpoint


    for(int i=0; i<64;i++) begin
      txDescrRegA[i] = 0;
      rxDescrRegA[i] = 0;
    end

    txDescrPtr = 32'h2000;
    rxDescrPtr = 32'h2800;


    header[0] = 0;
    header[1] = 0;
    header[2] = 0;

    header[3] = 0;
    header_size = 0;
    count = 0;
    count_p = 0;
    count_axi_mem = 0;
    received_bytecount = 0;
    cfg_tlp_count = 0;
    tag = 0;
    attr = 0;
    requester_bus_num = 0;
    requester_device_num = 0;
    requester_function_num = 0;
    target_bus_num = 0;
    target_device_num = 0;
    target_function_num = 0;

    init_link_training = 0;
  endfunction

endmodule
