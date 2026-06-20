// axi_drv.sv
// drives axi_tx items onto the axi bus, following the standard axi handshake timing

class axi_drv extends uvm_driver#(axi_tx);
  virtual axi_intf vif;
  `uvm_component_utils(axi_drv)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_resource_db#(virtual axi_intf)::read_by_type("AXI", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve axi_vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.bfm_cb.arst == 0);
    forever begin
      seq_item_port.get_next_item(req);
      drive_tx(req);
      seq_item_port.item_done();
    end
  endtask

  // splits write vs read path based on wr_rd
  task drive_tx(axi_tx tx);
    if (tx.wr_rd == 1) begin
      write_addr(tx);
      write_data(tx);
      write_resp(tx);
    end
    else begin
      read_addr(tx);
      read_data(tx);
    end
  endtask

  task write_addr(axi_tx tx);
    `uvm_info("AXI_WR", "write_addr", UVM_LOW)
    @(vif.bfm_cb);
    vif.bfm_cb.awvalid <= 1;
    vif.bfm_cb.awaddr <= tx.addr;
    vif.bfm_cb.awlen <= tx.burst_len;
    vif.bfm_cb.awsize <= tx.burst_size;
    vif.bfm_cb.awburst <= tx.burst_type;
    vif.bfm_cb.awid <= tx.txid;
    wait (vif.bfm_cb.awready == 1);
    @(vif.bfm_cb);
    vif.bfm_cb.awvalid <= 0;
    vif.bfm_cb.awaddr <= 0;
    vif.bfm_cb.awlen <= 0;
    vif.bfm_cb.awsize <= 0;
    vif.bfm_cb.awburst <= 0;
    vif.bfm_cb.awid <= 0;
  endtask

  task write_data(axi_tx tx);
    `uvm_info("AXI_WR", "write_data", UVM_LOW)
    for (int i = 0; i < tx.burst_len+1; i++) begin
      @(vif.bfm_cb);
      vif.bfm_cb.wid <= tx.txid;
      vif.bfm_cb.wdata <= tx.dataQ.pop_front();
      vif.bfm_cb.wstrb <= tx.strbQ.pop_front();
      vif.bfm_cb.wvalid <= 1;
      if (i == tx.burst_len) vif.bfm_cb.wlast <= 1'b1;
      wait (vif.bfm_cb.wready == 1);
    end
      @(vif.bfm_cb);
      vif.bfm_cb.wid <= 0;
      vif.bfm_cb.wdata <= 0;
      vif.bfm_cb.wstrb <= 0;
      vif.bfm_cb.wvalid <= 0;
      vif.bfm_cb.wlast <= 1'b0;
  endtask

  task write_resp(axi_tx tx);
    `uvm_info("AXI_WR", "write_resp", UVM_LOW)
    while (vif.bfm_cb.bvalid == 1'b0) begin
      @(vif.bfm_cb);
    end
    vif.bfm_cb.bready <= 1;
    @(vif.bfm_cb);
    vif.bfm_cb.bready <= 0;
  endtask

  task read_addr(axi_tx tx);
    `uvm_info("AXI_RD", "read_addr", UVM_LOW)
    @(vif.bfm_cb);
    vif.bfm_cb.arvalid <= 1;
    vif.bfm_cb.araddr <= tx.addr;
    vif.bfm_cb.arlen <= tx.burst_len;
    vif.bfm_cb.arsize <= tx.burst_size;
    vif.bfm_cb.arburst <= tx.burst_type;
    vif.bfm_cb.arid <= tx.txid;
    wait (vif.bfm_cb.arready == 1);
    @(vif.bfm_cb);
    vif.bfm_cb.arvalid <= 0;
    vif.bfm_cb.araddr <= 0;
    vif.bfm_cb.arlen <= 0;
    vif.bfm_cb.arsize <= 0;
    vif.bfm_cb.arburst <= 0;
    vif.bfm_cb.arid <= 0;
  endtask

  task read_data(axi_tx tx);
  for (int i = 0; i <= tx.burst_len; i++) begin
    `uvm_info("AXI_RD", "read_data", UVM_LOW)
    @(vif.bfm_cb);
    vif.bfm_cb.rready <= 1;
    wait (vif.bfm_cb.rvalid == 1'b1);
  end
    @(vif.bfm_cb);
    @(vif.bfm_cb); // todo : figure out why 2 cycles needed here, leaving as-is for now
    vif.bfm_cb.rready <= 0;
    @(vif.bfm_cb); // gap before next tx starts
  endtask

  task set_default_values();
  endtask

endclass
