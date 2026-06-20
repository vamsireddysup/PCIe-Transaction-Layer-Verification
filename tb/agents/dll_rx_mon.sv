// dll_rx_mon.sv
// passive monitor on the rx side, same idea as dll_tx_mon but watching rx_data_i instead.

class dll_rx_mon extends uvm_monitor;

  virtual tl_dll_intf vif;
  dll_item tx;
  uvm_analysis_port#(dll_item) ap_port;
  `uvm_component_utils(dll_rx_mon)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_resource_db#(virtual tl_dll_intf)::read_by_type("DLL", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve tl_dll_vif")
    end
    ap_port = new("ap_port",this);
  endfunction

  task run_phase(uvm_phase phase);
    int dw_count;
    bit tlp_collect_f;
    bit [31:0] tlp_header_first_dw;
    bit [31:0] tlp_header_second_dw;
    bit [31:0] tlp_header_third_dw;
    bit [2:0] fmt;
    bit [4:0] type_t;

    wait (vif.mon_cb.arst == 0);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rx_valid_i && vif.mon_cb.rx_ready_o) begin
        tlp_collect_f = 1;
        if (dw_count == 0) begin
          tx = new();

          tlp_header_first_dw = vif.mon_cb.rx_data_i;
          fmt = tlp_header_first_dw[31:29];
          type_t = tlp_header_first_dw[28:24];

          case ({fmt,type_t})
              {`CFG_RD0_FMT,`CFG_RD0_TYPE}   : begin
                tx.tlp_type = CfgRd0;
              end

              {`CFG_WR0_FMT,`CFG_WR0_TYPE}   : begin
                tx.tlp_type = CfgWr0;
              end

              {`CFG_RD1_FMT,`CFG_RD1_TYPE}   : begin
                tx.tlp_type = CfgRd1;
              end

              {`CFG_WR1_FMT,`CFG_WR1_TYPE}   : begin
                tx.tlp_type = CfgWr1;
              end

              {`MEM_WR_FMT,`MEM_WR_TYPE}    : begin
                tx.tlp_type = MWr;
              end

              {`MEM_RD_FMT,`MEM_RD_TYPE}    : begin
                tx.tlp_type = MRd;
              end

            endcase
          tx.headerQ.push_back(vif.mon_cb.rx_data_i);
        end
        if (dw_count == 1) begin
          tx.headerQ.push_back(vif.mon_cb.rx_data_i);
          tlp_header_second_dw = vif.mon_cb.rx_data_i;
        end
        if (dw_count == 2) begin
          tx.headerQ.push_back(vif.mon_cb.rx_data_i);
          tlp_header_third_dw = vif.mon_cb.rx_data_i;
        end

        if (dw_count >= 3) begin
          tx.payloadQ.push_back(vif.mon_cb.rx_data_i);
        end else begin
          // dll_tl_dll_state 6'h1b marks "currently streaming ep memory back", flag it
          if (pcie_common::pcie_tl_dll_state == 6'h1b) begin
            tx.mem_data_f = 1;
          end
        end
        dw_count++;
      end else begin
        if (tlp_collect_f == 1) begin
          tlp_collect_f = 0;
          dw_count = 0;
          $display("%t : collected tlp_data at dll_rx_mon", $time);
          tx.print();
          ap_port.write(tx);
        end
      end
    end
  endtask
endclass
