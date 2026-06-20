// dll_tx_agent.sv
// wraps the tx responder + tx monitor. no sequencer here, the responder reacts to
// whatever the dut sends rather than being driven by sequences.

class dll_tx_agent extends uvm_agent;

  dll_tx_responder responder;
  dll_tx_mon mon;

  `uvm_component_utils(dll_tx_agent);
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    responder = dll_tx_responder::type_id::create("responder",this);
    mon = dll_tx_mon::type_id::create("mon",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass
