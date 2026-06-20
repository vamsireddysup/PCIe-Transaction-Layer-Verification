// axi_mem_wr_cfg_seq.sv
// once enumeration is done, kicks off a mem_wr then a mem_rd by writing
// tlp_transfer_config_reg and pulsing dma_configure_reg[0].

class axi_mem_wr_cfg_seq extends axi_base_seq;
  `uvm_object_utils(axi_mem_wr_cfg_seq)
  `NEW_OBJ

  task body();
    wait (pcie_common::pcie_tl_dll_state == 5'h14); // wait for enumeration to finish
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1014; req.dataQ[0][4:0]==`MEM_WR;})
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1010; req.dataQ[0]==32'b1;})

    wait (pcie_common::pcie_tl_dll_state == 5'h14); // wait for mem_wr to complete, dll back to idle
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1014; req.dataQ[0][4:0]==`MEM_RD;})
    `uvm_do_with(req, {req.wr_rd==1; req.burst_len == 0; req.addr == 32'h1010; req.dataQ[0]==32'b1;})
  endtask
endclass
