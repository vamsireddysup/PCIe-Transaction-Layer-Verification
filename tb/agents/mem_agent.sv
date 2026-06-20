// mem_agent.sv
// wraps the memory model + mem_mon into one agent. no driver/sequencer here since
// memory itself acts as a passive slave responder, not something sequences drive.

class mem_agent extends uvm_agent;

  memory mem;
  mem_mon mon;

  `uvm_component_utils(mem_agent);
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mem = memory::type_id::create("mem",this);
    mon = mem_mon::type_id::create("mon",this);
  endfunction

endclass
