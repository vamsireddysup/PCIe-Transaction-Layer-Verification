// axi_agent.sv
// standard agent, wires drv + sqr + mon + cov together. always active in this project,
// the env always wants a driver so no is_active config knob added

class axi_agent extends uvm_agent;

  axi_drv drv;
  axi_sqr sqr;
  axi_mon mon;
  axi_cov cov;

  `uvm_component_utils(axi_agent);
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = axi_drv::type_id::create("drv",this);
    sqr = axi_sqr::type_id::create("sqr",this);
    mon = axi_mon::type_id::create("mon",this);
    cov = axi_cov::type_id::create("cov",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap_port.connect(cov.analysis_export);
  endfunction

endclass
