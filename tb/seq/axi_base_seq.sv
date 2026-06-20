// axi_base_seq.sv
// base class for all axi sequences. just handles objection raise/drop around the
// sequence body so the test doesn't end mid-sequence.

class axi_base_seq extends uvm_sequence#(axi_tx);
  `uvm_object_utils(axi_base_seq)
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
