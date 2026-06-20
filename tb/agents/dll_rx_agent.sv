// dll_rx_agent.sv
// wraps drv + sqr + mon + cov for the rx side, same pattern as axi_agent

class dll_rx_agent extends uvm_agent;

  dll_rx_drv drv;
  dll_rx_sqr sqr;
  dll_rx_mon mon;
  dll_rx_cov cov;

  `uvm_component_utils(dll_rx_agent);
  `NEW_COMP

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = dll_rx_drv::type_id::create("drv",this);
    sqr = dll_rx_sqr::type_id::create("sqr",this);
    mon = dll_rx_mon::type_id::create("mon",this);
    cov = dll_rx_cov::type_id::create("cov",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap_port.connect(cov.analysis_export);
  endfunction

endclass
