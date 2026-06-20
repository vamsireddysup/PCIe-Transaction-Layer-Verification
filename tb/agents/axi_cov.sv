// axi_cov.sv
// coverage on the axi side. right now just tracking payload size values written
// into the 1018 reg during config. can add more bins/coverpoints later once
// enum/mem_wr/mem_rd are confirmed passing

class axi_cov extends uvm_subscriber#(axi_tx);
  axi_tx tx;
  `uvm_component_utils(axi_cov);

  covergroup tl_axi_cg;
    PAYLOAD_SIZE_CP : coverpoint tx.dataQ[0] iff (tx.addr == 32'h1018) {
      bins PAYLOAD_SIZE_128 = {128};
      bins PAYLOAD_SIZE_256 = {256};
      bins PAYLOAD_SIZE_512 = {512};
      bins PAYLOAD_SIZE_1024 = {1024};
      bins PAYLOAD_SIZE_2048 = {2048};
      bins PAYLOAD_SIZE_4096 = {4096};
    }
  endgroup


  function new(string name, uvm_component parent);
    super.new(name,parent);
    tl_axi_cg = new();
  endfunction

  function void write(axi_tx t);
    $cast(tx,t);
    tl_axi_cg.sample();
  endfunction

endclass
