// dll_rx_cov.sv
// coverage on the rx side, tracking which tlp fmt/type combos actually got driven in.
// helps confirm the test actually exercised cfg_rd0/cfg_wr0/mem_rd cpld etc, not just one path

class dll_rx_cov extends uvm_subscriber#(dll_item);
  dll_item tlp;
  `uvm_component_utils(dll_rx_cov);

  covergroup dll_rx_cg;
    CP_FMT :  coverpoint {tlp.headerQ[0][31:29], tlp.headerQ[0][28:24]} {
      bins MEM_RD = {{`MEM_RD_FMT,`MEM_RD_TYPE}};
      bins MEM_WR = {{`MEM_WR_FMT,`MEM_WR_TYPE}};
      bins CFG_RD0 = {{`CFG_RD0_FMT,`CFG_RD0_TYPE}};
      bins CFG_RD1 = {{`CFG_RD1_FMT,`CFG_RD1_TYPE}};
      bins CFG_WR0 = {{`CFG_WR0_FMT,`CFG_WR0_TYPE}};
      bins CFG_WR1 = {{`CFG_WR1_FMT,`CFG_WR1_TYPE}};
      bins CPLD = {{`CPLD_FMT,`CPLD_TYPE}};
    }
  endgroup


  function new(string name, uvm_component parent);
    super.new(name,parent);
    dll_rx_cg = new();
  endfunction

  function void write(dll_item t);
    $cast(tlp,t);
    dll_rx_cg.sample();
  endfunction

endclass
