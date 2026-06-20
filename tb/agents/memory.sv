// memory.sv
// models the system memory the dut does dma against. acts as the axi slave on the
// memory side interface. responds to both read bursts (mem_wr path pulls data from
// here) and write bursts (mem_rd completion data gets written back here).

class memory extends uvm_component;
  bit [3:0] arid_t;
  bit [31:0] araddr_t;
  bit [3:0] arlen_t;
  bit [1:0] arburst_t;
  bit [1:0] arsize_t;

  bit [3:0] awid_t;
  bit [31:0] awaddr_t;
  bit [3:0] awlen_t;
  bit [1:0] awburst_t;
  bit [1:0] awsize_t;
  virtual axi_intf vif;
  bit [31:0] offset;
  byte mem[1024*1024-1:0]; // 1mb, base addr is 8000_0000
    // 1mb addr range needs 20 bits, 20'h0_0000 to 20'hF_FFFF
  `uvm_component_utils(memory)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_resource_db#(virtual axi_intf)::read_by_name("AXI", "MIF", vif, this);
  endfunction

  // fill memory with random bytes so reads aren't all zero, makes data mismatches
  // easier to actually notice if something's wrong
  function void start_of_simulation_phase(uvm_phase phase);
    offset = 32'h8000_0000;
    for (int i = 0; i < 1024*1024; i++) begin
      mem[i] = $random;
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.aclk);
      if (vif.arvalid == 1) begin
        vif.arready = 1;
        araddr_t = vif.araddr;
        arlen_t = vif.arlen;
        arid_t = vif.arid;
        arburst_t = vif.arburst;
        arsize_t = vif.arsize;
        fork
        drive_read_data();
        @(posedge vif.aclk) vif.arready = 0;
        join
      end
      if (vif.awvalid == 1) begin
        vif.awready = 1;
        awaddr_t = vif.awaddr;
        awlen_t = vif.awlen;
        awid_t = vif.awid;
        awburst_t = vif.awburst;
        awsize_t = vif.awsize;
      end
      else begin
        vif.awready = 0;
      end
      if (vif.wvalid == 1) begin
        vif.wready = 1;
        mem[awaddr_t] = vif.wdata[7:0];
        mem[awaddr_t+1] = vif.wdata[15:8];
        mem[awaddr_t+2] = vif.wdata[23:16];
        mem[awaddr_t+3] = vif.wdata[31:24];
        awaddr_t += 4;
        if (vif.wlast == 1) begin
          fork
            do_write_resp();
            @(posedge vif.aclk) vif.wready = 0;
          join
        end
      end
      else begin
        vif.wready = 0;
      end
    end
  endtask

  task do_write_resp();
    @(posedge vif.aclk);
    vif.bid = 0;
    vif.bvalid = 1;
    vif.bresp = 2'b0;
    wait (vif.bready == 1);
    @(posedge vif.aclk);
    vif.bvalid = 0;
  endtask

  task drive_read_data();
    for (int j = 0; j <= arlen_t; j++) begin
      @(posedge vif.aclk);
      vif.rdata = {
        mem[araddr_t-offset+3],
        mem[araddr_t-offset+2],
        mem[araddr_t-offset+1],
        mem[araddr_t-offset+0]
      };
      vif.rid = arid_t;
      vif.rresp = 2'b00; // okay
      vif.rvalid = 1'b1;
      if (j == arlen_t) vif.rlast = 1;
      wait (vif.rready == 1);
      araddr_t = araddr_t + 4;
    end
    @(posedge vif.aclk);
    vif.rdata = 0;
    vif.rid = 0;
    vif.rvalid = 0;
    vif.rlast = 0;
  endtask
endclass
