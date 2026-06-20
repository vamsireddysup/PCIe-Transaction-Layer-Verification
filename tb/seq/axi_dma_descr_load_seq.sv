// axi_dma_descr_load_seq.sv
// loads one tx descriptor and one rx descriptor into the dut's descriptor ram.
// descriptor format : dw0 = addr, dw1 = {length[15:0], 3 flag bits, 13 reserved}

class axi_dma_descr_load_seq extends axi_base_seq;
  axi_tx tx;
  axi_tx txQ[$];
  `uvm_object_utils(axi_dma_descr_load_seq)
  `NEW_OBJ

  task body();
  bit [15:0] length;
  bit [31:0] data_t;
    // tx descriptor : where dma should read from
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h2004; req.dataQ[0]==32'h8000_0000;})
    length = `PAYLOAD_SIZE; // bytes
    data_t = {length, 1'b1, 1'b1, 1'b1, 13'b0};
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0;req.addr == 32'h2000; req.dataQ[0]==data_t;})

    // rx descriptor : where completion data should land
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h2804; req.dataQ[0]==32'h8800_0000;})
    length = `PAYLOAD_SIZE; // bytes
    data_t = {length, 1'b1, 1'b1, 1'b1, 13'b0};
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h2800; req.dataQ[0]==data_t;})
  endtask
endclass
