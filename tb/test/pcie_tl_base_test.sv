// pcie_tl_base_test.sv
// base test. builds the env, then forks off the 3 background sequences that just
// need to run continuously in the background : linkup, vc_up, and the cpld responder.
// actual test-specific stimulus (the real test scenario) goes in tests that extend this.

class pcie_tl_base_test extends uvm_test;

  pcie_tl_env env;
  dll_linkup_indicate_seq linkup_seq;
  dll_vc_up_indicate_seq vc_up_seq;
  dll_cpl_seq cpl_seq;

  `uvm_component_utils(pcie_tl_base_test)
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pcie_tl_env::type_id::create("env",this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    linkup_seq = dll_linkup_indicate_seq::type_id::create("linkup_seq");
    vc_up_seq = dll_vc_up_indicate_seq::type_id::create("vc_up_seq");
    cpl_seq = dll_cpl_seq::type_id::create("cpl_seq");

    fork
      linkup_seq.start(env.dll_rx_agent_i.sqr);
      vc_up_seq.start(env.dll_rx_agent_i.sqr);
      cpl_seq.start(env.dll_rx_agent_i.sqr);
    join_none

    #10000;
    phase.drop_objection(this);
  endtask

endclass
