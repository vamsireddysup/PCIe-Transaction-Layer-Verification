// axi_config_seq.sv
// writes the initial config regs (vc mapping, payload size), reads them back to check,
// then sets link_control_reg[0] to kick off link training in the dut.

class axi_config_seq extends axi_base_seq;
  axi_tx tx;
  axi_tx txQ[$];
  `uvm_object_utils(axi_config_seq)
  `NEW_OBJ

  task body();
    for (int i = 0; i < 2; i++) begin
      req = new();
      `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1000+4*i; req.dataQ[0][0]==1'b0;}) // wr tx
      txQ.push_back(req);
    end
    // 100c : ep_bar0_base_addr
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h100C; req.dataQ[0] ==32'hEC00_0000;})
    // 1018 : max_payload_size
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1018; req.dataQ[0] == `PAYLOAD_SIZE;})
    // reading back the same regs we just wrote, to check they stuck
    for (int i = 0; i < 2; i++) begin
      tx = txQ.pop_front();
      `uvm_do_with(req, {
              req.wr_rd==0;
              req.addr == tx.addr;
              req.burst_size == tx.burst_size;
              req.burst_type == tx.burst_type;}) // rd tx
    end
    `uvm_do_with(req, {req.wr_rd==1; req.addr == 32'h1004; req.dataQ[0][0]==1'b1;}) // done with cfg, kick off link training
  endtask
endclass
