// dll_item.sv
// represents a tlp, the unit of communication between tl and dll.
// also doubles as a "control" item for linkup/vc_up signaling, those don't carry a real tlp.

class dll_item extends uvm_sequence_item;
  rand tlp_type_t tlp_type;
  int header_size;
  rand bit [31:0] headerQ[$]; // 3dw or 4dw
  rand bit [31:0] payloadQ[$]; // 0dw or up to 1024dw
  rand bit [31:0] ecrc;
  rand bit linkup_indicate;
  rand bit [7:0] vc_status_vector;
  rand bit mem_data_f;

  // knobs : control how randomization behaves, not driven onto the dut interface directly

  `uvm_object_utils_begin(dll_item)
    `uvm_field_queue_int(headerQ,UVM_ALL_ON)
    `uvm_field_queue_int(payloadQ,UVM_ALL_ON)
    `uvm_field_int(ecrc,UVM_ALL_ON)
    `uvm_field_int(linkup_indicate,UVM_ALL_ON)
    `uvm_field_int(vc_status_vector,UVM_ALL_ON)
  `uvm_object_utils_end

  `NEW_OBJ

  // if this is a cpld responding to a cfg_rd, fill the payload from the ep config space
  // based on which register the dut asked for
  function void post_randomize();
    if (pcie_common::rcvd_tlp inside {CfgRd0,CfgRd1} && tlp_type == CplD) begin
      case (pcie_common::reg_num)
        0: payloadQ[0] = {dll_cfg_rx::device_id,dll_cfg_rx::vendor_id};
        1: payloadQ[0] = {dll_cfg_rx::status,dll_cfg_rx::command};
        2: payloadQ[0] = {dll_cfg_rx::class_code,dll_cfg_rx::revision_id};
        3: payloadQ[0] = {dll_cfg_rx::bist,dll_cfg_rx::vendor_id,dll_cfg_rx::latency_time,dll_cfg_rx::cache_line_size};
        4: payloadQ[0] = dll_cfg_rx::bar0;
        5: payloadQ[0] = dll_cfg_rx::bar1;
        6: payloadQ[0] = dll_cfg_rx::bar2;
        7: payloadQ[0] = dll_cfg_rx::bar3;
        8: payloadQ[0] = dll_cfg_rx::bar4;
        9: payloadQ[0] = dll_cfg_rx::bar5;
        10: payloadQ[0] = dll_cfg_rx::cardbus_cis_pointer;
        11: payloadQ[0] = {dll_cfg_rx::subsystem_id,dll_cfg_rx::subsystem_vendor_id};
        12: payloadQ[0] = dll_cfg_rx::expansion_rom_base_addr;
        13: payloadQ[0] = {24'h0,dll_cfg_rx::capability_pointer};
        14: payloadQ[0] = 32'h0;
        15: payloadQ[0] = {dll_cfg_rx::max_lat,dll_cfg_rx::min_gnt,dll_cfg_rx::interrupt_pin,dll_cfg_rx::interrupt_line};
      endcase
    end
  endfunction

  constraint soft_c {
    soft headerQ.size() == 3;
    soft payloadQ.size() == 1;
    soft linkup_indicate == 0;
    soft vc_status_vector == 0;
    soft mem_data_f == 0;
  }

  // builds a proper cpld header matching whatever the responder decoded off the tx side
  constraint header_c {
    (tlp_type == CplD) -> (
                              headerQ[0][31:29] == 3'b010 &&
                              headerQ[0][28:24] == 5'b01010 &&
                              headerQ[0][23] == pcie_common::tag[9] &&
                              headerQ[0][22:20] == pcie_common::tc &&
                              headerQ[0][19] == pcie_common::tag[8] &&
                              headerQ[0][18] == pcie_common::attr[2] &&
                              headerQ[0][17] == pcie_common::ln &&
                              headerQ[0][16] == pcie_common::th &&
                              headerQ[0][15] == pcie_common::td &&
                              headerQ[0][14] == pcie_common::ep &&
                              headerQ[0][13:12] == pcie_common::attr[1:0] &&
                              headerQ[0][11:10] == 2'b00 &&
                              headerQ[0][9:0] == 10'b1 &&

                              headerQ[1][31:16] == {pcie_common::target_bus_num,pcie_common::target_device_num,pcie_common::target_func_num} &&
                              headerQ[1][15:13] == 3'b000 &&
                              headerQ[1][12] == 0 &&
                              headerQ[1][11:0] == 0 &&

                              headerQ[2][31:16] == {pcie_common::requester_bus_num,pcie_common::requester_device_num,pcie_common::requester_func_num} &&
                              headerQ[2][15:8] == pcie_common::tag[7:0] &&
                              headerQ[2][7] == 0 &&
                              headerQ[2][6:0] == 0 &&

                              // payloadQ
                              payloadQ.size() == 1 &&
                              payloadQ[0] == 32'h1234_5678

                            );
  }

endclass


//////////////////////////////////////////////////

// state machine the responder uses to track which dw of an incoming tlp it's looking at
typedef enum {
  S_IDLE_DUMMY,
  S_IDLE,
  S_TLP_FIRST_DW,
  S_TLP_SECOND_DW,
  S_TLP_THIRD_DW,
  S_TLP_PAYLOAD
} state_t;
