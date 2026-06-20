# tb/agents

The four UVM agents plus the memory slave model. Each agent is the standard
sequencer + driver + monitor (+ coverage where present), wrapped one-class-per-file.

## axi agent (proc side)

Drives CPU register reads/writes over proc_if. axi_tx is the transaction (addr,
dataQ, strbQ, wr_rd, burst fields). axi_drv follows AXI handshake timing, splitting
write (addr/data/resp) vs read (addr/data) on wr_rd. axi_mon samples the bus and
feeds the scoreboard. axi_sqr is the sequencer. axi_cov is the covergroup.

## mem agent (memory side)

Watches the memory-side AXI bus (mem_if). mem_mon builds axi_tx items the same way
axi_mon does and feeds them to the scoreboard so it can compare what landed in
memory against the tlp. memory.sv is the actual memory slave model, it responds to
the DUT's reads/writes through slv_cb.

mem_mon fix this session: it only creates a tx in the write-addr and read-addr
branches, so the data/resp branches were guarded with tx != null and the right
wr_rd direction to stop a null-handle SIGSEGV.

## dll_tx agent

Watches tlps the DUT sends out (the tx tlp stream) and also responds to them.
dll_tx_mon collects each outgoing tlp as a dll_item (header + payload). 
dll_tx_responder decodes fmt/type of each received tlp and decides whether a
completion is owed, setting transmit_tlp and bumping rcvd_tlp_count. This is the
piece that froze on cfg_wr0 (set rcvd_tlp but never advanced n_state) and hung the
sim until fixed.

## dll_rx agent

Drives tlps into the DUT (completions, link-up and vc-up indications). dll_rx_drv
sends the completion the responder queued. dll_rx_mon collects incoming tlps for
the scoreboard. dll_rx_sqr / dll_rx_cov are the sequencer and coverage.

## dll_item

The dll-side transaction: headerQ, payloadQ, ecrc, linkup_indicate,
vc_status_vector.
