//`include "pcie_common.sv"
module pcie_tl(
  aclk, arst, 

  // processor
  awvalid_p, awready_p, awid_p, awaddr_p, awlen_p, awburst_p, awsize_p,
  wvalid_p, wready_p, wdata_p, wstrb_p, wid_p, wlast_p,
  bvalid_p, bready_p, bid_p, bresp_p,
  
  arvalid_p, arready_p, arid_p, araddr_p, arlen_p, arburst_p, arsize_p,
  rvalid_p, rready_p, rdata_p, rid_p, rlast_p, rresp_p,
  
  // memory
  awvalid_m, awready_m, awid_m, awaddr_m, awlen_m, awburst_m, awsize_m,
  wvalid_m, wready_m, wdata_m, wstrb_m, wid_m, wlast_m,
  bvalid_m, bready_m, bid_m, bresp_m,

  arvalid_m, arready_m, arid_m, araddr_m, arlen_m, arburst_m, arsize_m,
  rvalid_m, rready_m, rdata_m, rid_m, rlast_m, rresp_m,

  // DLL_TX
  tl_dll_clk,
  tx_data_o, tx_valid_o, tx_ready_i,
  vc_num,

  // DLL_RX
  rx_data_i, rx_valid_i, rx_ready_o,
  linkup, dll_vc_up

);


// Processor Interface Signals
input aclk, arst;
input awvalid_p, wvalid_p;
output reg awready_p, wready_p;
input [3:0] awid_p; // This is used for transaction ID
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
input [3:0] arid_p; // This is used for transaction ID
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


// Memory Interface Signals
output reg awvalid_m;
input logic awready_m;
output reg [3:0] awid_m; // This is used for transaction ID
output reg [31:0] awaddr_m;
output reg [3:0] awlen_m;
output reg [1:0] awburst_m;
output reg [2:0] awsize_m;
output reg wvalid_m;
input logic wready_m;
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
output reg [3:0] arid_m; // This is used for transaction ID
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


// DLL_TX Interface signals
input tl_dll_clk;
output reg [31:0] tx_data_o;
output reg tx_valid_o;
input tx_ready_i;
output reg [2:0] vc_num; // Which VC is currently used?

// DLL_RX Interface signals
input [31:0] rx_data_i;
input rx_valid_i;
output reg rx_ready_o;
input [7:0] dll_vc_up; // which VC is up?
input linkup;

reg [4:0] state_axi, n_state_axi;
reg [4:0] state_dll, n_state_dll;
reg [31:0] tc_vc_mapping_reg; // 1000
reg [31:0] link_control_reg; // 1004
reg [31:0] vc_fc_status_reg; // 1008
reg [31:0] ep_bar0_base_addr; // 100C
reg [31:0] dma_configure_reg; // 1010
reg [31:0] tlp_transfer_config_reg; // 1014
reg [31:0] max_payload_size; // 1018
reg [31:0] target_device_type; // 101C

reg [31:0] txDescrRegA[63:0]; // 32 Transmit Descriptors => 2000. Each descriptor is made up of 2 32 bit blocks
reg [31:0] txDescrPtr;
reg [63:0] txDescr;

// each register is 32 bits, it takes 4 addr for each register
reg [31:0] rxDescrRegA[63:0]; // 32 Receive Descriptors => 2800. Each descriptor is made up of 2 32 bit blocks
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

int header_size; // 3 or 4
int payload_size;
int ep_bar0_cfg_done;
int total_cfg_tlp_drv_count;

int count;
int count_p;
int received_bytecount;
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

reg [31:0] cpltlpdataQ[$];

reg [31:0] dummy;

int ignore_count;
 
//Check Adding
//reg awready_m_temp;
//reg wready_m_temp;


// FSM State
parameter S_IDLE_AXI                    = 5'b0_0000;
parameter S_REG_WRITE_ADDR              = 5'b0_0001;
parameter S_REG_WRITE_DATA              = 5'b0_0010;
parameter S_REG_WRITE_RESP              = 5'b0_0011;
parameter S_REG_READ                    = 5'b0_0100;

parameter S_IDLE_DLL                    = 5'b0_0101;
parameter S_LINK_TRAINING               = 5'b0_0110;
parameter S_VC0_FC_INIT                 = 5'b0_0111;
parameter S_VC1_FC_INIT                 = 5'b0_1000;
parameter S_VC2_FC_INIT                 = 5'b0_1001;
parameter S_VC3_FC_INIT                 = 5'b0_1010;
parameter S_VC4_FC_INIT                 = 5'b0_1011;
parameter S_VC5_FC_INIT                 = 5'b0_1100;
parameter S_VC6_FC_INIT                 = 5'b0_1101;
parameter S_VC7_FC_INIT                 = 5'b0_1110;
parameter S_ENUM_FRAME_TLP              = 5'b0_1111;
parameter S_ENUM_FRAME_TLP_CYCLE_GAP    = 5'b1_0000; 
parameter S_ENUMERATION_DRV_TLP         = 5'b1_0001;
parameter S_ENUM_READ_ALL_DW_COMPLETE   = 5'b1_0010;
parameter S_ENUMERATION_DRV_CFG_WR_TLP  = 5'b1_0011;
parameter S_ENUM_COMPL_IDLE             = 5'b1_0100;
parameter S_ENUM_ERROR                  = 5'b1_0101;
parameter S_MEM_WR                      = 5'b1_0110;
parameter S_MEM_RD                      = 5'b1_0111;
parameter S_CFG_WR                      = 5'b1_1000;
parameter S_CFG_RD                      = 5'b1_1001;
parameter S_IO_WR                       = 5'b1_1010;
parameter S_IO_RD                       = 5'b1_1011;
parameter S_MSG                         = 5'b1_1100;
parameter S_ERROR                       = 5'b1_1101;

  reg [4:0] state;
  always@(*) begin
      state        = pcie_common::state;
  end
  
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

          case (awaddr_temp)
            32'h1000: tc_vc_mapping_reg = wdata_p;
            32'h1004: link_control_reg = wdata_p;
            // 32'h1008: vc_fc_status_reg = wdata_p; // Will be updated by the design
            32'h100C: ep_bar0_base_addr = wdata_p;
            32'h1010: dma_configure_reg = wdata_p;
            32'h1014: tlp_transfer_config_reg = wdata_p;
            32'h1018: max_payload_size = wdata_p;
            32'h101C: target_device_type = wdata_p;
          endcase    

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
          // 0th bit -> initiate_link_training
          n_state_axi = S_IDLE_AXI;

          if (link_control_reg[0] == 1) begin
            init_link_training = 1;
            // n_state_axi = S_LINK_TRAINING;
          end
        end
      end

      S_REG_READ           : begin
        arready_p = 1;
        read_register();
        if (rready_p == 1) begin // Driver(Processor) is ready to receive
          arready_p = 0;
          n_state_axi = S_IDLE_AXI;
        end
      end
    endcase
  end
end

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
      
      S_VC0_FC_INIT        : begin // VC0 INIT completion
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

      S_ENUM_FRAME_TLP : begin
//         $display("In Enumeration");
        // B-D-F : 1-0-0
        if (target_device_type == `ENDPOINT) begin
          frame_cfg_tlp(`CFG_RD0, 1, 1, 0, cfg_tlp_count, 0); // populates header array
        end else if (target_device_type == `SWITCH) begin
          frame_cfg_tlp(`CFG_RD1, 1, 1, 0, cfg_tlp_count, 0); // populates header array
        end else begin
          n_state_dll = S_ENUM_ERROR;
        end
        
        header_size = 3;
        payload_size = 0;
        count = 0;
        // total_cfg_tlp_drv_count = 16;
        // ep_bar0_cfg_done = 0;
        
        n_state_dll = S_ENUMERATION_DRV_TLP;
      end

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
            n_state_dll = S_ENUM_FRAME_TLP_CYCLE_GAP; //Since CFG_RD/WR pending
          end
          count = 0;
        end
      end
      
      S_ENUM_FRAME_TLP_CYCLE_GAP : begin
        tx_valid_o = 1'b0;
        n_state_dll = S_ENUM_FRAME_TLP; //Since CFG_RD/WR pending
      end

      S_ENUM_READ_ALL_DW_COMPLETE : begin
        tx_valid_o = 1'b0;
        // perform memory write to base address BAR0
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
        // total_cfg_tlp_drv_count = 1;
//         ep_bar0_cfg_done = 1;
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

      S_ENUM_COMPL_IDLE : begin //S_START_TLP_TFRS
        rx_ready_o = 0;
        tx_valid_o = 0;
        //[0] : TX_EN, [1] : RX_EN
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
          //get the Tx descritprs
          txDescr[31:0] = txDescrRegA[(txDescrPtr-32'h2000)/4];
          txDescr[63:32] = txDescrRegA[(txDescrPtr+4-32'h2000)/4];
          $display("txDescr=%h",txDescr);
          length = txDescr[31:16]; //4096 bytes
          dma_configure_reg[0] = 0;
          count = 0;
        end
      end

      S_ENUM_ERROR  : begin
        n_state_dll = S_IDLE_DLL;
      end

      S_MEM_WR : begin
      end

      S_MEM_RD             : begin
      end

      S_CFG_WR             : begin
      end
      S_CFG_RD             : begin
      end
      S_IO_WR              : begin
      end
      S_IO_RD              : begin
      end
      S_MSG                : begin
      end
      S_ERROR              : begin
      end

    endcase
  end
end

  always@( n_state_axi ) state_axi <= n_state_axi;
  always@( n_state_dll ) state_dll <= n_state_dll;

  task read_register();
    $display("Performing read to Register at addr=%h",araddr_temp);
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

  function void frame_cfg_tlp(bit [2:0] cfg_tlp_type, bit [7:0] target_bus_num, bit [4:0] target_device_num, bit [2:0] target_function_num, bit [5:0] reg_num, bit [3:0] ext_reg_num);
    tag = 10'h123;
    attr = 3'h000;

    // 1st DW
    if (cfg_tlp_type inside {`CFG_RD0,`CFG_RD1}) begin
      header[0][31:29] = 3'b000; // FMT
      header[0][9:0] = 10'b0; // PACKET_LEN
    end

    if (cfg_tlp_type inside {`CFG_WR0,`CFG_WR1}) begin
      header[0][31:29] = 3'b010; // FMT
      header[0][9:0] = 10'b1; // PACKET_LEN
    end

    if (cfg_tlp_type inside {`CFG_RD0,`CFG_WR0}) header[0][28:24] = 5'b00100; // TYPE
    if (cfg_tlp_type inside {`CFG_RD1,`CFG_WR1}) header[0][28:24] = 5'b00101; // TYPE


    header[0][23] = tag[9];
    header[0][22:20] = 3'b000; // Traffic Class
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 0; // Lightweight Notification
    header[0][16] = 0; // TH : TLP Hints
    header[0][15] = 0; // TD : TLP Digest
    header[0][14] = 0; // EP : TLP Poisoned
    header[0][13:12] = 2'b00; // Attr[1:0]
    header[0][11:10] = 2'b00; // AT[1:0] : Address Translation


    // 2nd DW  
    header[1][31:16] = {requester_bus_num, requester_device_num, requester_device_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'b0;
    header[1][3:0] = 4'hF;

    // 3rd DW
    header[2][31:24] = target_bus_num;
    header[2][23:19] = target_device_num;
    header[2][18:16] = target_function_num;
    header[2][15:12] = 4'b0;
    header[2][11:8] = ext_reg_num;
    header[2][7:2] = reg_num;
    header[2][1:0] = 2'b00;


  endfunction

  function void frame_mem_wr_tlp(bit [31:0] addr);
    //header[0]
    tag = 10'h123;
    attr = 3'b000;
    header[0][31:29] = `MEM_WR_FMT;
    header[0][28:24] = `MEM_WR_TYPE;
    header[0][23] = tag[9];
    header[0][22:20] = 3'b000; //TODO
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 1'b0;
    header[0][16] = 1'b0; //TH
    header[0][15] = 1'b0; //TD
    header[0][14] = 1'b0; //EP
    header[0][13:12] = 2'b00; //Attr1:0
    header[0][11:10] = 2'b00; //AT
    header[0][9:0] = max_payload_size/4;

    //header[1]
    header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'hF;
    header[1][3:0] = 4'hF;

    //header[2]
    header[2][31:0] = addr; //32'hEC00_0000;
    //header[2][1:0] = 2'b00;
  endfunction

  function void frame_mem_rd_tlp(bit [31:0] addr);
    //header[0]
    tag = 10'h123;
    attr = 3'b000;
    header[0][31:29] = 3'b000;
    header[0][28:24] = 5'b00000;
    header[0][23] = tag[9];
    header[0][22:20] = 3'b000; //TODO
    header[0][19] = tag[8];
    header[0][18] = attr[2];
    header[0][17] = 1'b0;
    header[0][16] = 1'b0; //TH
    header[0][15] = 1'b0; //TD
    header[0][14] = 1'b0; //EP
    header[0][13:12] = 2'b00; //Attr1:0
    header[0][11:10] = 2'b00; //AT
    $display("max_payload_size/4 : %h",max_payload_size/4);
    header[0][9:0] = max_payload_size/4;

    //header[1]
    header[1][31:16] = {requester_bus_num, requester_device_num, requester_function_num};
    header[1][15:8] = tag[7:0];
    header[1][7:4] = 4'hF;
    header[1][3:0] = 4'hF;

    //header[2]
    header[2][31:0] = addr; //32'hEC00_0000;
    //header[2][1:0] = 2'b00;
  endfunction


  function void reset_all_reg_variables();
    state_axi = S_IDLE_AXI;
    n_state_axi = S_IDLE_AXI;
    state_dll = S_IDLE_DLL;
    n_state_dll = S_IDLE_DLL;

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
    target_device_type = 32'h0; // ENDPOINT


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
