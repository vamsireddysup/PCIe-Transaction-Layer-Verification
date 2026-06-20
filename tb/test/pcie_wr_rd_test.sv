// pcie_wr_rd_test.sv
// the actual test : config the dut, load dma descriptors, kick off mem_wr then mem_rd.
// runs the sequences on the axi agent in order since each one depends on the last finishing.

class pcie_wr_rd_test extends pcie_tl_base_test;

  axi_config_seq config_seq;
  axi_dma_descr_load_seq dma_descr_seq;
  axi_mem_wr_cfg_seq mem_wr_cfg_seq;

  `uvm_component_utils(pcie_wr_rd_test)
  `NEW_COMP

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

    config_seq = axi_config_seq::type_id::create("config_seq");
    config_seq.start(env.axi_agent_i.sqr);

    dma_descr_seq = axi_dma_descr_load_seq::type_id::create("dma_descr_seq");
    dma_descr_seq.start(env.axi_agent_i.sqr);

    // wait for enumeration to finish before writing the dma enable / transfer-type regs.
    // the dut only services processor axi writes from its S_IDLE_AXI state, and during
    // enumeration (link train -> vc init -> 16x cfg_rd0 -> cfg_wr0, ~2000ns) the axi slave
    // side does not return to idle, so an earlier write to 0x1010/0x1014 would block the
    // sequence forever on awready. this mirrors real pcie : software programs device
    // config registers only after enumeration sets up the bars. see errors.md #8
    #2500;

    mem_wr_cfg_seq = axi_mem_wr_cfg_seq::type_id::create("mem_wr_cfg_seq");
    mem_wr_cfg_seq.start(env.axi_agent_i.sqr);

    #10000;
    phase.drop_objection(this);
  endtask

  // pass/fail summary. checks all 3 scoreboard comparisons : mem_rd vs tx, mem_wr vs rx,
  // tx vs rx loopback. each needs at least 1 match and 0 mismatches.
  // note : original code compared num_tx_matches==0 in all 3 checks, a copy-paste typo
  // that made the second condition always false (so PASSED could never print). fixed to
  // check the actual mismatch counter for each comparison.
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (pcie_common::num_tx_matches > 0 && pcie_common::num_tx_mismatches == 0) begin
      `uvm_info("SCOREBOARD", "MEM_RD vs TLP_TX check : PASSED", UVM_NONE)
    end else begin
      `uvm_error("SCOREBOARD", $sformatf("MEM_RD vs TLP_TX check : FAILED, matches=%0d mismatches=%0d",
                  pcie_common::num_tx_matches, pcie_common::num_tx_mismatches))
    end

    if (pcie_common::num_rx_matches > 0 && pcie_common::num_rx_mismatches == 0) begin
      `uvm_info("SCOREBOARD", "MEM_WR vs TLP_RX check : PASSED", UVM_NONE)
    end else begin
      `uvm_error("SCOREBOARD", $sformatf("MEM_WR vs TLP_RX check : FAILED, matches=%0d mismatches=%0d",
                  pcie_common::num_rx_matches, pcie_common::num_rx_mismatches))
    end

    if (pcie_common::num_tx_rx_matches > 0 && pcie_common::num_tx_rx_mismatches == 0) begin
      `uvm_info("SCOREBOARD", "TLP_TX vs TLP_RX loopback check : PASSED", UVM_NONE)
    end else begin
      `uvm_error("SCOREBOARD", $sformatf("TLP_TX vs TLP_RX loopback check : FAILED, matches=%0d mismatches=%0d",
                  pcie_common::num_tx_rx_matches, pcie_common::num_tx_rx_mismatches))
    end

  endfunction

endclass
