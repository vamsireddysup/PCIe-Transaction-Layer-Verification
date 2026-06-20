# tb/intf

The interfaces.

## axi_intf.sv

The AXI bus, used for both the processor-side register interface (proc_if) and
the memory-side interface (mem_if). Carries the full AW/W/B/AR/R channel signals.
Has three clocking blocks:

- bfm_cb : master direction, used by the axi driver to drive the proc side.
- slv_cb : slave direction, added this session so the memory slave model can drive
  its responses (awready, rdata, rvalid, bvalid, etc) through a clocking block
  instead of poking raw signals.
- mon_cb : monitor direction, sampled by the monitors.

Also has SVA assertions on the handshakes. Because one interface type is used in
two roles with both master and slave clocking blocks, QuestaSim emits "multiply
driven" warnings under +acc. They are harmless in the default optimized run.

## tl_dll_intf.sv

The dll-side interface between the DUT and the dll tx/rx agents. Carries the tx
and rx tlp data/valid/ready, vc_num, linkup, and dll_vc_up.
