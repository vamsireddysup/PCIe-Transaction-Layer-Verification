// top_tb.sv
// top level. generates clocks/reset, instantiates the dut + all 3 interfaces,
// publishes the vifs into the resource db, then kicks off uvm.
//
// include order matters here since these are all `include, not a package. rule i'm
// following : pcie_common first (everyone needs the macros/typedefs), then interfaces,
// then agent classes (items before drivers/monitors that use them), then seq, then
// sbd, then env, then test. dut itself gets compiled separately, not included here,
// since it's its own top level module instantiated below.

`include "uvm_macros.svh"
import uvm_pkg::*;

// shared macros/typedefs/static classes, needs to come before anything that uses them
`include "pcie_common.sv"

// interfaces
`include "axi_intf.sv"
`include "tl_dll_intf.sv"

// axi agent : item first, then drv/mon which use it, then sqr/cov, then agent wrapper
`include "axi_tx.sv"
`include "axi_drv.sv"
`include "axi_sqr.sv"
`include "axi_mon.sv"
`include "axi_cov.sv"
`include "axi_agent.sv"

// mem agent : no item of its own, reuses axi_tx
`include "memory.sv"
`include "mem_mon.sv"
`include "mem_agent.sv"

// dll agents : item first (dll_item also declares state_t enum used by responder)
`include "dll_item.sv"
`include "dll_tx_responder.sv"
`include "dll_tx_mon.sv"
`include "dll_tx_agent.sv"
`include "dll_rx_drv.sv"
`include "dll_rx_mon.sv"
`include "dll_rx_sqr.sv"
`include "dll_rx_cov.sv"
`include "dll_rx_agent.sv"

// sequences : base seq before the seqs that extend it
`include "axi_base_seq.sv"
`include "axi_config_seq.sv"
`include "axi_dma_descr_load_seq.sv"
`include "axi_mem_wr_cfg_seq.sv"
`include "dll_rx_base_seq.sv"
`include "dll_linkup_indicate_seq.sv"
`include "dll_vc_up_indicate_seq.sv"
`include "dll_cpl_seq.sv"

// scoreboard
`include "tl_sbd.sv"

// env
`include "pcie_tl_env.sv"

// tests : base test before the test that extends it
`include "pcie_tl_base_test.sv"
`include "pcie_wr_rd_test.sv"

module top_tb;

  // single 100mhz clock drives both aclk and tl_dll_clk. dut has no cdc between the
  // 2 clock domains so they need to stay aligned, see note in step 11 chat history
  bit clk;
  bit arst;

  always #5 clk = ~clk; // 10ns period, 100mhz

  initial begin
    clk = 0;
    arst = 1;
    repeat (5) @(posedge clk); // hold reset 5 cycles
    arst = 0;
  end

  // processor side axi interface
  axi_intf proc_if(.aclk(clk), .arst(arst));

  // memory side axi interface, dut is master here
  axi_intf mem_if(.aclk(clk), .arst(arst));

  // dll interface
  tl_dll_intf dll_if(.tl_dll_clk(clk), .arst(arst));

  // dut
  pcie_tl dut (
    .aclk(clk),
    .arst(arst),

    // processor axi
    .awvalid_p(proc_if.awvalid), .awready_p(proc_if.awready),
    .awid_p(proc_if.awid), .awaddr_p(proc_if.awaddr),
    .awlen_p(proc_if.awlen), .awburst_p(proc_if.awburst), .awsize_p(proc_if.awsize),
    .wvalid_p(proc_if.wvalid), .wready_p(proc_if.wready),
    .wdata_p(proc_if.wdata), .wstrb_p(proc_if.wstrb),
    .wid_p(proc_if.wid), .wlast_p(proc_if.wlast),
    .bvalid_p(proc_if.bvalid), .bready_p(proc_if.bready),
    .bid_p(proc_if.bid), .bresp_p(proc_if.bresp),

    .arvalid_p(proc_if.arvalid), .arready_p(proc_if.arready),
    .arid_p(proc_if.arid), .araddr_p(proc_if.araddr),
    .arlen_p(proc_if.arlen), .arburst_p(proc_if.arburst), .arsize_p(proc_if.arsize),
    .rvalid_p(proc_if.rvalid), .rready_p(proc_if.rready),
    .rdata_p(proc_if.rdata), .rid_p(proc_if.rid),
    .rlast_p(proc_if.rlast), .rresp_p(proc_if.rresp),

    // memory axi, dut as master
    .awvalid_m(mem_if.awvalid), .awready_m(mem_if.awready),
    .awid_m(mem_if.awid), .awaddr_m(mem_if.awaddr),
    .awlen_m(mem_if.awlen), .awburst_m(mem_if.awburst), .awsize_m(mem_if.awsize),
    .wvalid_m(mem_if.wvalid), .wready_m(mem_if.wready),
    .wdata_m(mem_if.wdata), .wstrb_m(mem_if.wstrb),
    .wid_m(mem_if.wid), .wlast_m(mem_if.wlast),
    .bvalid_m(mem_if.bvalid), .bready_m(mem_if.bready),
    .bid_m(mem_if.bid), .bresp_m(mem_if.bresp),

    .arvalid_m(mem_if.arvalid), .arready_m(mem_if.arready),
    .arid_m(mem_if.arid), .araddr_m(mem_if.araddr),
    .arlen_m(mem_if.arlen), .arburst_m(mem_if.arburst), .arsize_m(mem_if.arsize),
    .rvalid_m(mem_if.rvalid), .rready_m(mem_if.rready),
    .rdata_m(mem_if.rdata), .rid_m(mem_if.rid),
    .rlast_m(mem_if.rlast), .rresp_m(mem_if.rresp),

    // dll
    .tl_dll_clk(clk),
    .tx_data_o(dll_if.tx_data_o), .tx_valid_o(dll_if.tx_valid_o), .tx_ready_i(dll_if.tx_ready_i),
    .vc_num(dll_if.vc_num),
    .rx_data_i(dll_if.rx_data_i), .rx_valid_i(dll_if.rx_valid_i), .rx_ready_o(dll_if.rx_ready_o),
    .linkup(dll_if.linkup), .dll_vc_up(dll_if.dll_vc_up)
  );

  // mirror the dut's dll fsm state into pcie_common::pcie_tl_dll_state from HERE (inside
  // top_tb, same compilation unit as the pcie_common copy the sequences/monitors use).
  // doing this from inside the dut did not work : pcie_common.sv is included by both the
  // dut unit and the tb unit, and the include guard only stops double-include within one
  // unit, so each unit gets its own separate copy of the static. the dut was writing its
  // copy while the tb read a different copy. driving it tb-side keeps write and read in the
  // same unit. see errors.md #9
  always @(dut.state_dll) pcie_common::pcie_tl_dll_state = dut.state_dll;

  initial begin
    // processor axi vif, scope "AXI" name "PIF". axi_drv/axi_mon use read_by_type("AXI",...)
    // which ignores name, so as long as this is the only OTHER vif under scope "AXI" besides
    // the mem one, should resolve fine. flagging this as a step 12 debug item if it doesn't.
    uvm_resource_db#(virtual axi_intf)::set("AXI", "PIF", proc_if);

    // memory axi vif, scope "AXI" name "MIF". memory/mem_mon use read_by_name("AXI","MIF",...)
    uvm_resource_db#(virtual axi_intf)::set("AXI", "MIF", mem_if);

    // dll vif, scope "DLL". all 4 dll components use read_by_type("DLL",...), only one
    // tl_dll_intf exists so no collision here
    uvm_resource_db#(virtual tl_dll_intf)::set("DLL", "DLL_IF", dll_if);

    run_test();
  end

endmodule
