interface tl_dll_intf(input bit tl_dll_clk,arst);

  // DLL_TX
  bit [31:0] tx_data_o;
  bit tx_valid_o;
  bit tx_ready_i;
 // bit [2:0] vc_num;

  // DLL_RX
  bit [31:0] rx_data_i;
  bit rx_valid_i;
  bit rx_ready_o;
  //bit linkup; // DLL indicating that 'Link is Up'
  //bit [7:0] dll_vc_up; // DLL does Flow Control for VC

  

endinterface