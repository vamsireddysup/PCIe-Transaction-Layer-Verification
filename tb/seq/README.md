# tb/seq

The sequences. AXI-side ones run on the axi sequencer in order (each depends on
the last finishing). The dll-side ones run on the dll_rx sequencer.

## axi side

- axi_base_seq : base class the others extend.
- axi_config_seq : initial config-register writes (tc_vc mapping, link control,
  bar0, max payload).
- axi_dma_descr_load_seq : loads one tx descriptor and one rx descriptor into the
  DUT's descriptor ram. Descriptor is dw0 = addr, dw1 = {length, flags}.
- axi_mem_wr_cfg_seq : the one that kicks off the actual transfers. Waits for
  enumeration to finish (waits on pcie_common::pcie_tl_dll_state == 0x14), then
  writes tlp_transfer_config_reg = MEM_WR and pulses dma_configure_reg[0], then
  does the same for MEM_RD. This sequence is why the dll-state mirror has to work:
  if the mirror is never driven, this wait blocks forever and nothing transfers.

## dll side

- dll_rx_base_seq : base class.
- dll_linkup_indicate_seq : tells the DUT the link is up (drives linkup).
- dll_vc_up_indicate_seq : tells the DUT the virtual channels are up.
- dll_cpl_seq : drives completions back during enumeration and after mem_rd.

These three dll sequences are started together with fork join_none in the test so
they run as responders across the whole sim.
