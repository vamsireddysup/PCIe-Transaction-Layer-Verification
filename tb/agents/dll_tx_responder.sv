// dll_tx_responder.sv
// watches the dut's tx_data_o stream dw by dw, decodes what tlp is being sent, and
// tracks state needed to know when a cpld is owed back (sets rcvd_tlp_count).
// also models the ep's memory for mem_wr writes / mem_rd reads.

class dll_tx_responder extends uvm_driver#(dll_item);
  virtual tl_dll_intf vif;
  state_t state,n_state;
  int header_size;
  int count;

  bit [31:0] tlp_first_dw,tlp_second_dw,tlp_third_dw;

  bit [31:0] rxdataQ[$];
  bit [31:0] payloadQ[$];

  `uvm_component_utils(dll_tx_responder)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    state = S_IDLE_DUMMY;
    n_state = S_IDLE_DUMMY;
    if (!uvm_resource_db#(virtual tl_dll_intf)::read_by_type("DLL", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve tl_dll_vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    // dut keeps sending tlp dw's, i need to decode them and figure out if a response is owed
    fork
      forever begin
        @(n_state);
        state = n_state;
        pcie_common::state = state;
      end
      forever begin
        @(posedge vif.tl_dll_clk);
        case (state)
          S_IDLE_DUMMY : begin
            if (vif.tx_valid_o == 1) begin
              n_state = S_IDLE;
            end
          end

          S_IDLE      : begin
            if (vif.tx_valid_o == 1) begin
              n_state = S_TLP_FIRST_DW;
            end
          end

          S_TLP_FIRST_DW : begin
            tlp_first_dw = vif.tx_data_o;
            $display("%t : tlp_first_dw=0x%0h", $time, tlp_first_dw);
            // dw0 fields, same layout for every tlp
            pcie_common::fmt = tlp_first_dw[31:29];
            pcie_common::type_t = tlp_first_dw[28:24];
            $display("%t : fmt=0b%0b, type=0b%0b", $time, pcie_common::fmt, pcie_common::type_t);

            header_size = 3; // update later if a 4dw header tlp shows up

            pcie_common::tag[9]  = tlp_first_dw[23];
            pcie_common::tc  = tlp_first_dw[22:20];
            pcie_common::tag[8]  = tlp_first_dw[19];
            pcie_common::attr[2] = tlp_first_dw[18];
            pcie_common::ln = tlp_first_dw[17];
            pcie_common::th = tlp_first_dw[16];
            pcie_common::td = tlp_first_dw[15];
            pcie_common::ep = tlp_first_dw[14];
            pcie_common::attr[1:0] = tlp_first_dw[13:12];
            pcie_common::at = tlp_first_dw[11:10];
            pcie_common::packet_len = tlp_first_dw[9:0];
            $display("pcie_common::packet_len=0x%0h", pcie_common::packet_len);
            if (vif.tx_valid_o == 1) begin
              n_state = S_TLP_SECOND_DW;
            end else begin
                n_state = S_IDLE;
            end

            $display("%t : s_tlp_first_dw packet_len=0x%0h", $time, pcie_common::packet_len);
          end

          S_TLP_SECOND_DW : begin
            tlp_second_dw = vif.tx_data_o;
            pcie_common::requester_bus_num = tlp_second_dw[31:24];
            pcie_common::requester_device_num = tlp_second_dw[23:19];
            pcie_common::requester_func_num = tlp_second_dw[18:16];
            pcie_common::tag[7:0] = tlp_second_dw[15:8];
            pcie_common::last_dw_be = tlp_second_dw[7:4];
            pcie_common::first_dw_be = tlp_second_dw[3:0];
            $display("pcie_common::packet_len=0x%0h", pcie_common::packet_len);

            if (vif.tx_valid_o == 1) begin
                n_state = S_TLP_THIRD_DW;
            end else begin
                n_state = S_IDLE;
            end

            $display("%t : s_tlp_second_dw packet_len=0x%0h", $time, pcie_common::packet_len);
          end

          S_TLP_THIRD_DW  : begin
            tlp_third_dw = vif.tx_data_o;
            pcie_common::target_bus_num = tlp_third_dw[31:24];
            pcie_common::target_device_num = tlp_third_dw[23:19];
            pcie_common::target_func_num = tlp_third_dw[18:16];
            pcie_common::ext_reg_num = tlp_third_dw[11:8];
            pcie_common::reg_num = tlp_third_dw[7:2];

            // mem_wr/mem_rd dw2 is just the address, not a bdf/reg_num like cfg tlps
            if (pcie_common::type_t inside {5'b0,5'b1}) begin
              pcie_common::addr = tlp_third_dw;
            end

            // figure out which tlp this is from fmt+type, then decide if a cpld is owed
            case ({pcie_common::fmt,pcie_common::type_t})
              {`CFG_RD0_FMT,`CFG_RD0_TYPE}   : begin
                pcie_common::rcvd_tlp = CfgRd0;
                $display("cfg_rd0 seen in dll_tx_responder");
                $display("=========== need to send cpld ============");
                pcie_common::transmit_tlp = CplD;
                pcie_common::rcvd_tlp_count++;
                n_state = S_IDLE_DUMMY;
              end

              {`CFG_WR0_FMT,`CFG_WR0_TYPE}   : begin
                $display("cfg_wr0 seen in dll_tx_responder");
                pcie_common::rcvd_tlp = CfgWr0;
              end

              {`CFG_RD1_FMT,`CFG_RD1_TYPE}   : begin
                $display("cfg_rd1 seen in dll_tx_responder");
                pcie_common::rcvd_tlp = CfgRd1;
                $display("=========== need to send cpld ============");
                pcie_common::transmit_tlp = CplD;
                pcie_common::rcvd_tlp_count++;
                n_state = S_IDLE_DUMMY;
              end

              {`CFG_WR1_FMT,`CFG_WR1_TYPE}   : begin
                $display("cfg_wr1 seen in dll_tx_responder");
                pcie_common::rcvd_tlp = CfgWr1;
              end

              {`MEM_WR_FMT,`MEM_WR_TYPE}    : begin
                $display("mem_wr seen in dll_tx_responder");
                $display("fmt=0b%0b", pcie_common::fmt);
                $display("addr=0x%0h bar0=0x%0h", pcie_common::addr, pcie_common::ep_bar0_base_addr);
                pcie_common::rcvd_tlp = MWr;
                pcie_common::addr = tlp_third_dw;
              end

              {`MEM_RD_FMT,`MEM_RD_TYPE}    : begin
                $display("mem_rd seen in dll_tx_responder");
                pcie_common::rcvd_tlp = MRd;
                pcie_common::transmit_tlp = CplD;
                pcie_common::rcvd_tlp_count++;
                n_state = S_IDLE_DUMMY;
              end

            endcase

            // fmt[1] set means there's a payload following the header
            if (pcie_common::fmt[1] == 1) begin
              count = 0;
              n_state = S_TLP_PAYLOAD;
            end

            $display("%t : s_tlp_third_dw packet_len=0x%0h", $time, pcie_common::packet_len);
          end

          S_TLP_PAYLOAD : begin

            if (count == pcie_common::packet_len) begin
              n_state = S_IDLE_DUMMY;
            end

            // mem_wr payload, write it into the ep's memory model at the right offset
            if (pcie_common::rcvd_tlp == MWr) begin
                dll_cfg_rx::mem[pcie_common::addr - pcie_common::ep_bar0_base_addr + count] = vif.tx_data_o;
            end

            // cfg_wr payload is just the bar0 base addr the host is programming into the ep
            if ( (pcie_common::fmt == `CFG_WR0 && pcie_common::type_t == 5'b00100) ||
                (pcie_common::fmt == `CFG_WR1 && pcie_common::type_t == 5'b00101) ) begin
              pcie_common::ep_bar0_base_addr = payloadQ.pop_front();
            end

            count = count + 1;
            payloadQ.push_back(vif.tx_data_o);

          end

        endcase

        if (vif.tx_valid_o == 1) begin
          rxdataQ.push_back(vif.tx_data_o);
          vif.tx_ready_i = 1;
        end else begin
          vif.tx_ready_i = 0;
        end
      end
    join
  endtask

endclass
