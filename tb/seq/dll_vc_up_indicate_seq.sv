// dll_vc_up_indicate_seq.sv
// tells the dut all 8 vc's are flow-control ready. no tlp, just sets vc_status_vector.

class dll_vc_up_indicate_seq extends dll_rx_base_seq;
  dll_item tx;
  dll_item txQ[$];
  `uvm_object_utils(dll_vc_up_indicate_seq)
  `NEW_OBJ

  task body();
    `uvm_do_with(req, {req.vc_status_vector == 8'hFF;}) // no tlp here, just the vc up flag
  endtask
endclass
