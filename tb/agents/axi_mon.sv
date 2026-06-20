// axi_mon.sv
// watches the axi bus passively, rebuilds axi_tx items from the handshake and
// broadcasts them on ap_port for the scoreboard and coverage to pick up

class axi_mon extends uvm_monitor;

  virtual axi_intf vif;
  axi_tx tx;
  uvm_analysis_port#(axi_tx) ap_port;
  `uvm_component_utils(axi_mon)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_resource_db#(virtual axi_intf)::read_by_type("AXI", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve axi_vif")
    end
    ap_port = new("ap_port",this);
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.mon_cb.arst == 0);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
        tx = axi_tx::type_id::create("tx");
        tx.wr_rd = 1'b1;
        tx.txid = vif.mon_cb.awid;
        tx.addr = vif.mon_cb.awaddr;
        tx.burst_len = vif.mon_cb.awlen;
        tx.burst_type = burst_type_t'(vif.mon_cb.awburst);
        tx.burst_size = vif.mon_cb.awsize;
        $display("%t : AXI_MON - completed write address phase", $time);
      end

      if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        tx.dataQ.push_back(vif.mon_cb.wdata);
        tx.strbQ.push_back(vif.mon_cb.wstrb);
        $display("%t : AXI_MON - completed write data phase", $time);
      end

      if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
        tx.resp = vif.mon_cb.bresp;

        ap_port.write(tx);
        $display("%t : AXI_MON - completed write response phase", $time);
        tx.print();
      end

      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        tx = axi_tx::type_id::create("tx");
        tx.wr_rd = 1'b0;
        tx.txid = vif.mon_cb.arid;
        tx.addr = vif.mon_cb.araddr;
        tx.burst_len = vif.mon_cb.arlen;
        // note : original was missing this cast on the read path, write path already had it.
        // added so both build the enum consistently
        tx.burst_type = burst_type_t'(vif.mon_cb.arburst);
        tx.burst_size = vif.mon_cb.arsize;
      end

      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        tx.dataQ.push_back(vif.mon_cb.rdata);
        tx.resp = vif.mon_cb.rresp;
        if (vif.mon_cb.rlast == 1) begin
          ap_port.write(tx);
        end
      end
    end
  endtask

endclass
