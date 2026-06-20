// mem_mon.sv
// watches the memory side axi bus, builds axi_tx items same as axi_mon does on the
// processor side. used by the scoreboard to compare what actually landed in memory
// against what the tlp said should be there.

class mem_mon extends uvm_monitor;

  virtual axi_intf vif;
  axi_tx tx;
  uvm_analysis_port#(axi_tx) ap_port;
  `uvm_component_utils(mem_mon)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_resource_db#(virtual axi_intf)::read_by_name("AXI","MIF", vif, this)) begin
      `uvm_error("RESOURCE_DB_ERROR", "not able to retrieve mem_vif")
    end
    ap_port = new("ap_port",this);
  endfunction

  task run_phase(uvm_phase phase);
    bit ignore_first_dw_f;

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
        ignore_first_dw_f = 1;
        $display("MEM_MON - completed write address phase");
      end

      if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
        // first dw written here is junk/leftover from a previous tx, skip it.
        // not totally sure why this is needed but original code did this so keeping it
        if (ignore_first_dw_f == 1) begin
          ignore_first_dw_f = 0;
        end else begin
          tx.dataQ.push_back(vif.mon_cb.wdata);
          tx.strbQ.push_back(vif.mon_cb.wstrb);
          $display("MEM_MON - completed write data phase");
        end
      end

      if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
        tx.resp = vif.mon_cb.bresp;

        ap_port.write(tx);
        $display("MEM_MON - completed write response phase");
        $display("%t : collected write axi_data at mem_mon", $time);

        tx.print();
      end

      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        tx = axi_tx::type_id::create("tx");
        tx.wr_rd = 1'b0;
        tx.txid = vif.mon_cb.arid;
        tx.addr = vif.mon_cb.araddr;
        tx.burst_len = vif.mon_cb.arlen;
        tx.burst_type = vif.mon_cb.arburst;
        tx.burst_size = vif.mon_cb.arsize;
        $display("MEM_MON - completed read address phase");
      end

      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        tx.dataQ.push_back(vif.mon_cb.rdata);
        tx.resp = vif.mon_cb.rresp;
        if (vif.mon_cb.rlast == 1) begin
          ap_port.write(tx);
        end
        $display("MEM_MON - completed read data phase");
        $display("%t : collected read axi_data at mem_mon", $time);

        tx.print();
      end
    end
  endtask

endclass
