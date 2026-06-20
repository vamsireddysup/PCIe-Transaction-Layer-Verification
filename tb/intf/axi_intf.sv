// axi_intf.sv
// axi4 interface, used for both processor side and memory side (2 instances in top_tb)

interface axi_intf(input bit aclk, arst);

// write address channel
bit awvalid, awready;
bit [3:0] awid;
bit [31:0] awaddr;
bit [3:0] awlen;
bit [1:0] awburst;
bit [2:0] awsize;

// write data channel
bit wvalid, wready;
bit [31:0] wdata;
bit [3:0] wstrb;
bit [3:0] wid;
bit wlast;

// write response channel
bit bvalid;
bit bready;
bit [1:0] bid;
bit [1:0] bresp;

// read address channel
bit arvalid, arready;
bit [3:0] arid;
bit [31:0] araddr;
bit [3:0] arlen;
bit [1:0] arburst;
bit [2:0] arsize;

// read data channel
bit rvalid, rready;
bit [31:0] rdata;
bit [3:0] rid;
bit rlast;
bit [1:0] rresp;

// driver side clocking block, used by axi_drv and the memory bfm
clocking bfm_cb @(posedge aclk);
  default input #0 output #0;
  output awid, awaddr, awlen, awsize, awburst, awvalid;
  input arst, awready, wready;
  output wid, wdata, wstrb, wlast, wvalid;
  input bid, bresp, bvalid;
  output bready;

  output arid, araddr, arlen, arsize, arburst, arvalid;
  input arready;
  input rid, rdata, rlast, rvalid, rresp;
  output rready;
endclocking

// monitor side clocking block, everything is input, mon never drives
clocking mon_cb @(posedge aclk);
  default input #0 output #0;
  input awid, awaddr, awlen, awsize, awburst, awvalid;
  input arst;
  input awready, wready;
  input wid, wdata, wstrb, wlast, wvalid;
  input bid, bresp, bvalid;
  input bready;

  input arid, araddr, arlen, arsize, arburst, arvalid;
  input arready;
  input rid, rdata, rlast, rvalid, rresp;
  input rready;
endclocking

// ---------------- assertions ----------------
// keeping this light on purpose, just enough to catch handshake bugs while we
// bring up enumeration/mem_wr/mem_rd. can add more once those are stable.

// valid signals should never go to x or z once reset is deasserted
property p_known(bit sig);
  @(posedge aclk) disable iff (arst) !$isunknown(sig);
endproperty

assert property (p_known(awvalid)) else $error("axi_intf: awvalid is x/z");
assert property (p_known(wvalid))  else $error("axi_intf: wvalid is x/z");
assert property (p_known(bvalid))  else $error("axi_intf: bvalid is x/z");
assert property (p_known(arvalid)) else $error("axi_intf: arvalid is x/z");
assert property (p_known(rvalid))  else $error("axi_intf: rvalid is x/z");

// axi rule : once valid goes high it must stay high until ready, can't yank it back
property p_valid_stable(bit valid, bit ready);
  @(posedge aclk) disable iff (arst)
    (valid && !ready) |=> valid;
endproperty

assert property (p_valid_stable(awvalid, awready)) else $error("axi_intf: awvalid dropped before awready");
assert property (p_valid_stable(wvalid, wready))   else $error("axi_intf: wvalid dropped before wready");
assert property (p_valid_stable(arvalid, arready)) else $error("axi_intf: arvalid dropped before arready");

endinterface
