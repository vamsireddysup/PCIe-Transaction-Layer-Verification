// dll_rx_base_seq.sv
// base class for all dll rx sequences. same objection raise/drop pattern as axi_base_seq.

class dll_rx_base_seq extends uvm_sequence#(dll_item);
  `uvm_object_utils(dll_rx_base_seq)
  `NEW_OBJ

  task pre_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) begin
      phase.phase_done.set_drain_time(this, 100);
      phase.raise_objection(this);
    end
  endtask
  task post_body();
    uvm_phase phase = get_starting_phase();
    if (phase != null) begin
      phase.drop_objection(this);
    end
  endtask
endclass
