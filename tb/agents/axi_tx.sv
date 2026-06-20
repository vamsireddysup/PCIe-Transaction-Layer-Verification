// axi_tx.sv
// the axi transaction item. one of these represents either a full write (addr+data+resp)
// or a full read (addr+data) on the axi bus.

class axi_tx extends uvm_sequence_item;
  rand bit [3:0] txid;
  rand bit [31:0] addr;
  rand bit [31:0] dataQ[$];
  rand bit [31:0] strbQ[$];
  rand bit wr_rd;
  rand bit [3:0] burst_len; // 0 -> 1 beat, 1 -> 2 beats, so on
  rand burst_type_t burst_type;
  rand bit [2:0] burst_size;
  rand bit [1:0] resp;
  // note : valid/ready handshake signals never go in the tx, those aren't randomized

  `uvm_object_utils_begin(axi_tx)
    `uvm_field_int(txid,UVM_ALL_ON)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_queue_int(dataQ,UVM_ALL_ON)
    `uvm_field_queue_int(strbQ,UVM_ALL_ON)
    `uvm_field_int(wr_rd,UVM_ALL_ON)
    `uvm_field_int(burst_len,UVM_ALL_ON)
    `uvm_field_enum(burst_type_t,burst_type,UVM_ALL_ON)
    `uvm_field_int(burst_size,UVM_ALL_ON)
    `uvm_field_int(resp,UVM_ALL_ON)
  `uvm_object_utils_end

  `NEW_OBJ

  // dataQ/strbQ size has to track burst_len, one entry per beat
  constraint dataQ_c {
    dataQ.size() == burst_len + 1;
    strbQ.size() == burst_len + 1;
  }

  constraint rsvd_c {
    burst_type != RSVD_BT;
  }

  // soft defaults, sequences override whatever fields they care about
  constraint soft_c {
    soft burst_type == INCR;
    soft burst_size == 2; // 4 bytes/beat
    soft burst_len == 1; // 1 beat default
    soft addr%4 == 0; // keep tx 32 bit aligned
    soft wr_rd == 1;
  }
endclass
