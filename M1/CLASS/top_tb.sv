`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "pcie_tl.sv"
`include "axi_intf.sv"
`include "tl_dll_intf.sv"
`include "test_lib.sv"
module top_tb;
	reg aclk, arst, tl_dll_clk;
	axi_intf axi_p_pif(aclk, arst);
	axi_intf axi_m_pif(aclk, arst);
	tl_dll_intf tl_dll_pif(tl_dll_clk, arst);
	
	initial begin
		aclk = 0;
		forever #5 aclk = ~aclk;
	end
	
	initial begin
		tl_dll_clk = 0;
		forever #5 tl_dll_clk = ~tl_dll_clk;
	end

	initial begin
		arst = 1;
		repeat(2) @(posedge aclk);
		arst = 0;
	end
	// DUT instantiation
	pcie_tl DUT (
		//Processor => AXI Lite
		.aclk(aclk),
		.arst(arst),
		.awvalid_p(axi_p_pif.awvalid),
		.awready_p(axi_p_pif.awready),
		.awid_p(axi_p_pif.awid),
		.awaddr_p(axi_p_pif.awaddr),
		.awlen_p(axi_p_pif.awlen),
		.awburst_p(axi_p_pif.awburst), 
		.wvalid_p(axi_p_pif.wvalid),
		.wready_p(axi_p_pif.wready),
		.wdata_p(axi_p_pif.wdata),
		.wstrb_p(axi_p_pif.wstrb),
		.wid_p(axi_p_pif.wid),
		.wlast_p(axi_p_pif.wlast),
		.bvalid_p(axi_p_pif.bvalid),
		.bready_p(axi_p_pif.bready),
		.bid_p(axi_p_pif.bid),
		.bresp_p(axi_p_pif.bresp),

		.arvalid_p(axi_p_pif.arvalid),
		.arready_p(axi_p_pif.arready),
		.arid_p(axi_p_pif.arid),
		.araddr_p(axi_p_pif.araddr),
		.arlen_p(axi_p_pif.arlen),
		.arburst_p(axi_p_pif.arburst),
		//.arsize_p(axi_p_pif.arsize),
		.rvalid_p(axi_p_pif.rvalid),
		.rready_p(axi_p_pif.rready),
		.rdata_p(axi_p_pif.rdata),
		.rid_p(axi_p_pif.rid),
		.rlast_p(axi_p_pif.rlast),
		.rresp_p(axi_p_pif.rresp),
		
		//Memory
		.awvalid_m(axi_m_pif.awvalid),
		.awready_m(axi_m_pif.awready),
		.awid_m(axi_m_pif.awid),
		.awaddr_m(axi_m_pif.awaddr),
		.awlen_m(axi_m_pif.awlen),
		.awburst_m(axi_m_pif.awburst), 
		.wvalid_m(axi_m_pif.wvalid),
		.wready_m(axi_m_pif.wready),
		.wdata_m(axi_m_pif.wdata),
		.wstrb_m(axi_m_pif.wstrb),
		.wid_m(axi_m_pif.wid),
		.wlast_m(axi_m_pif.wlast),
		.bvalid_m(axi_m_pif.bvalid),
		.bready_m(axi_m_pif.bready),
		.bid_m(axi_m_pif.bid),
		.bresp_m(axi_m_pif.bresp),
		
		.arvalid_m(axi_m_pif.arvalid),
		.arready_m(axi_m_pif.arready),
		.arid_m(axi_m_pif.arid),
		.araddr_m(axi_m_pif.araddr),
		.arlen_m(axi_m_pif.arlen),
		.arburst_m(axi_m_pif.arburst),
		//.arsize_m(axi_m_pif.arsize),
		.rvalid_m(axi_m_pif.rvalid),
		.rready_m(axi_m_pif.rready),
		.rdata_m(axi_m_pif.rdata),
		.rid_m(axi_m_pif.rid),
		.rlast_m(axi_m_pif.rlast),
		.rresp_m(axi_m_pif.rresp),
		
		//DLL_TX
		.tl_dll_clk(tl_dll_pif.tl_dll_clk),
		.tx_data_o(tl_dll_pif.tx_data_o),
		.tx_valid_o(tl_dll_pif.tx_valid_o),
		.tx_ready_i(tl_dll_pif.tx_ready_i),

		//DLL_RX
		.rx_data_i(tl_dll_pif.rx_data_i),
		.rx_valid_i(tl_dll_pif.rx_valid_i),
		.rx_ready_o(tl_dll_pif.rx_ready_o)
	);
	
	initial begin
		run_test("pcie_tl_base_test");
	end
endmodule
