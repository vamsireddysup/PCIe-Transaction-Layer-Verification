// tl_dll_intf.sv
// interface between transaction layer (dut) and the dll side (driven by tb)
// tx_* = dut sending a tlp out to dll. rx_* = dll side sending a tlp into dut

interface tl_dll_intf(input bit tl_dll_clk, arst);

// dll_tx : dut drives this
bit [31:0] tx_data_o;
bit tx_valid_o;
bit tx_ready_i;
bit [2:0] vc_num;

// dll_rx : tb drives this (acting as the dll)
bit [31:0] rx_data_i;
bit rx_valid_i;
bit rx_ready_o;
bit linkup;        // dll telling tl "link is up"
bit [7:0] dll_vc_up; // dll doing flow control init per vc

clocking mon_cb @(posedge tl_dll_clk);
  default input #1;

  input arst;
  input tx_data_o;
  input tx_valid_o;
  input tx_ready_i;
  input vc_num;

  input rx_data_i;
  input rx_valid_i;
  input rx_ready_o;
  input linkup;
  input dll_vc_up;
endclocking

// ---------------- assertions ----------------

// tx_data_o should be known whenever tx_valid_o is high, dut shouldn't drive x on real data
property p_tx_data_known;
  @(posedge tl_dll_clk) disable iff (arst)
    tx_valid_o |-> !$isunknown(tx_data_o);
endproperty

assert property (p_tx_data_known) else $error("tl_dll_intf: tx_data_o unknown while tx_valid_o high");

// same check on rx side, tb itself shouldn't be driving x into the dut
property p_rx_data_known;
  @(posedge tl_dll_clk) disable iff (arst)
    rx_valid_i |-> !$isunknown(rx_data_i);
endproperty

assert property (p_rx_data_known) else $error("tl_dll_intf: rx_data_i unknown while rx_valid_i high");

endinterface
