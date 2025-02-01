module pcie_tl(
	//Processor => AXI Lite
	aclk, arst, 
	awvalid_p, awready_p, awid_p, awaddr_p, awlen_p, awburst_p, 
	wvalid_p, wready_p, wdata_p, wstrb_p, wid_p, wlast_p,
	bvalid_p, bready_p, bid_p, bresp_p,
	
	arvalid_p, arready_p, arid_p, araddr_p, arlen_p, arburst_p,
	rvalid_p, rready_p, rdata_p, rid_p, rlast_p, rresp_p,

	//Memory
	awvalid_m, awready_m, awid_m, awaddr_m, awlen_m, awburst_m,
	wvalid_m, wready_m, wdata_m, wstrb_m, wid_m, wlast_m,
	bvalid_m, bready_m, bid_m, bresp_m,
	
	arvalid_m, arready_m, arid_m, araddr_m, arlen_m, arburst_m,
	rvalid_m, rready_m, rdata_m, rid_m, rlast_m, rresp_m,
  
	//DLL_TX
	tl_dll_clk,
	tx_data_o, tx_valid_o, tx_ready_i,

	//DLL_RX
	rx_data_i, rx_valid_i, rx_ready_o,
);

	parameter S_IDLE 		= 5'b0_0000;
	parameter S_REG_WRITE	 	= 5'b0_0001;
	parameter S_REG_READ	 	= 5'b0_0010; 
	parameter S_LINK_TRAINING 	= 5'b0_0011;
	parameter S_VC0_FC_INIT 	= 5'b0_0100;
	parameter S_VC1_FC_INIT 	= 5'b0_0101;
	parameter S_VC2_FC_INIT 	= 5'b0_0110;
	parameter S_VC3_FC_INIT 	= 5'b0_0111;
	parameter S_VC4_FC_INIT 	= 5'b0_1000;
	parameter S_VC5_FC_INIT 	= 5'b0_1001;
	parameter S_VC6_FC_INIT 	= 5'b0_1010;
	parameter S_VC7_FC_INIT 	= 5'b0_1011;
	parameter S_ENUMERATION 	= 5'b0_1100;
	parameter S_ENUM_COMPLETE_IDLE 	= 5'b0_1101;
	parameter S_MEM_WR 		= 5'b0_1110;
	parameter S_MEM_RD 		= 5'b0_1111;
	parameter S_CFG_WR 		= 5'b0_0000;
	parameter S_CFG_RD 		= 5'b1_0001;
	parameter S_IO_WD 		= 5'b1_0010;
	parameter S_IO_RD 		= 5'b1_0011;
	parameter S_MSG 		= 5'b1_0100;
	parameter S_ERROR 		= 5'b1_0101;

// Processor Interface Signals
input aclk, arst, awvalid_p, wvalid_p;
output reg awready_p, wready_p;
input [3:0] awid_p; // This is used for transaction ID
input [31:0] awaddr_p;
input [3:0] awlen_p;
input [1:0] awburst_p;
input [31:0] wdata_p;
input [3:0] wstrb_p;
input [3:0] wid_p;
input wlast_p;
output reg bvalid_p;
input bready_p;
output reg [3:0] bid_p;
output reg [1:0] bresp_p;

input arvalid_p;
output reg arready_p;
input [3:0] arid_p; // This is used for transaction ID
input [31:0] araddr_p;
input [3:0] arlen_p;
input [1:0] arburst_p;
output reg rvalid_p;
input rready_p;
output reg [31:0] rdata_p;
output reg [3:0]  rid_p;
output reg rlast_p;
output reg [1:0] rresp_p;

// Memory Interface Signals
//output reg aclk, arst, awvalid_m, wvalid_m;
output reg awvalid_m, wvalid_m;
input awready_m, wready_m;
output reg [3:0] awid_m; // This is used for transaction ID
output reg [31:0] awaddr_m;
output reg [3:0] awlen_m;
output reg [1:0] awburst_m;
output reg [31:0] wdata_m;
output reg [3:0] wstrb_m;
output reg [3:0] wid_m;
output reg wlast_m;
input bvalid_m;
output reg bready_m;
input [3:0] bid_m;
input [1:0] bresp_m;

output reg arvalid_m;
input arready_m;
output reg [3:0] arid_m; // This is used for transaction ID
output reg [31:0] araddr_m;
output reg [3:0] arlen_m;
output reg [1:0] arburst_m;
input rvalid_m;
output reg rready_m;
input [31:0] rdata_m;
input [3:0]  rid_m;
input rlast_m;
input [1:0] rresp_m;
// DLL_TX

input tl_dll_clk;
output reg [31:0] tx_data_o;
output reg tx_valid_o; 
input tx_ready_i;

// DLL_RX

input [31:0] rx_data_i;
input rx_valid_i; 
output reg rx_ready_o;


reg [4:0] state, n_state;

always @(posedge aclk) begin
	if (arst == 1) begin
		state = S_IDLE;
		n_state = S_IDLE;
	end
	else begin
	case (state)

		S_IDLE : begin
                	if (awvalid_p ==1) begin
				n_state = S_REG_WRITE;
			end
			if (arvalid_p ==1) begin
				n_state = S_REG_READ; 
			end
		end
		S_REG_WRITE : begin
			awready_p = 1;
			write_register();
		end	
		S_REG_READ : begin
			arready_p = 1;
			read_register();
		end
		S_LINK_TRAINING : begin

		end
		S_VC0_FC_INIT : begin

		end
		S_VC1_FC_INIT : begin

		end
		S_VC2_FC_INIT : begin

		end
		S_VC3_FC_INIT : begin

		end
		S_VC4_FC_INIT : begin

		end
		S_VC5_FC_INIT : begin

		end
		S_VC6_FC_INIT : begin

		end
		S_VC7_FC_INIT : begin

		end
		S_ENUMERATION : begin

		end
		S_ENUM_COMPLETE_IDLE: begin

		end
		S_MEM_WR : begin

		end
		S_MEM_RD : begin

		end
		S_CFG_WR : begin

		end
		S_CFG_RD : begin

		end
		S_IO_WD : begin

		end
		S_IO_RD : begin

		end
		S_MSG : begin

		end

	endcase

	end
end

always @(n_state) state <= n_state;

task write_register();
	$display("Performing write to register at addr = %h", awaddr_p);
endtask

task read_register();
	$display("Performing read to register at addr = %h", araddr_p);
endtask

endmodule
