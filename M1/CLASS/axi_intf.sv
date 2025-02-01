interface axi_intf(input bit aclk, arst);
	bit awvalid, wvalid;
	bit awready, wready;
	bit [3:0] awid; // This is used for transaction ID
	bit [31:0] awaddr;
	bit [3:0] awlen;
	bit [1:0] awburst;
	bit [31:0] wdata;
	bit [3:0] wstrb;
	bit [3:0] wid;
	bit wlast;
	bit bvalid;
	bit bready;
	bit [3:0] bid;
	bit [1:0] bresp;

	bit arvalid, arready;
	bit rvalid, rready;
	bit [3:0] arid;
	bit [31:0] araddr;
	bit [3:0] arlen;
	bit [1:0] arburst;
	bit [31:0] rdata;
	bit [3:0] rid;
	bit rlast;
	bit [1:0] rresp;
endinterface
	
