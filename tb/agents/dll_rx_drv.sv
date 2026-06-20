// dll_rx_drv.sv
// drives dll_item sequences onto the rx interface. handles 3 kinds of items :
// linkup indication, vc_up indication, and actual tlp drive (mostly cpld responses).

class dll_rx_drv extends uvm_driver#(dll_item);
  virtual tl_dll_intf vif;
  `uvm_component_utils(dll_rx_drv)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_resource_db#(virtual tl_dll_intf)::read_by_type("DLL", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve tl_dll_vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_tx(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_tx(dll_item tx);
    if (tx.linkup_indicate == 1) begin
      vif.linkup = 1;
    end else if (tx.vc_status_vector == 8'hFF ) begin
      vif.dll_vc_up = 8'hFF;
    end else begin // drive an actual tlp
      $display("inside dll_rx_drv");
      foreach (tx.headerQ[i]) begin
        @(posedge vif.tl_dll_clk);
        vif.rx_data_i = tx.headerQ[i];
        vif.rx_valid_i = 1;
      end
      // cpld for a cfg read carries the config space value as payload
      if (pcie_common::rcvd_tlp inside {CfgRd0,CfgRd1}) begin
        foreach (tx.payloadQ[i]) begin
          @(posedge vif.tl_dll_clk);
          vif.rx_data_i = tx.payloadQ[i];
          vif.rx_valid_i = 1;
        end
      end
      // cpld for a mem_rd streams the ep's memory contents back, packet_len dw's worth
      if (pcie_common::rcvd_tlp == MRd) begin
        for (int i=0; i <= pcie_common::packet_len; i++) begin
          @(posedge vif.tl_dll_clk);
          vif.rx_data_i = dll_cfg_rx::mem[pcie_common::addr - pcie_common::ep_bar0_base_addr];
          vif.rx_valid_i = 1;
          pcie_common::addr++;
        end
      end
        @(posedge vif.tl_dll_clk);
        vif.rx_data_i = 0;
        vif.rx_valid_i = 0;
    end
  endtask

endclass
