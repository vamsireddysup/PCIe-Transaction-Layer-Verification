// dll_linkup_indicate_seq.sv
// tells the dut the link is up. no actual tlp involved, just sets linkup_indicate.

class dll_linkup_indicate_seq extends dll_rx_base_seq;
  dll_item tx;
  dll_item txQ[$];
  `uvm_object_utils(dll_linkup_indicate_seq)
  `NEW_OBJ

  task body();
    `uvm_do_with(req, {req.linkup_indicate==1'b1;}) // no tlp here, just the linkup flag
  endtask
endclass
