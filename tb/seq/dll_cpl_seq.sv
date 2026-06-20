// dll_cpl_seq.sv
// background sequence that runs the whole test, forked off with join_none from the test.
// waits for rcvd_tlp_count to bump (responder saw something needing a cpld) then drives one.

class dll_cpl_seq extends dll_rx_base_seq;
  `uvm_object_utils(dll_cpl_seq)
  `NEW_OBJ

  task body();
    forever begin
      @(pcie_common::rcvd_tlp_count);
      $display("=================== driving cpld ============ count=%0d", pcie_common::rcvd_tlp_count);
      fork
        `uvm_do_with(req, {req.tlp_type == pcie_common::transmit_tlp;}) // cpld
      join_none
    end
  endtask
endclass
