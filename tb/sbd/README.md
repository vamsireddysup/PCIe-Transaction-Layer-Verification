# tb/sbd

The scoreboard, tl_sbd.sv.

## what it does

Four analysis imps, one per monitor: imp_dll_tx (outgoing tlps), imp_dll_rx
(incoming tlps), imp_proc (proc-side axi, currently collected but unused), imp_mem
(memory-side axi). Each write_* function breaks 32-bit words into 4 bytes and
pushes them into per-path queues, since axi data and tlp payload do not always
line up at word granularity.

Three compare loops run forever in parallel under a fork. Each waits until both
its queues have a byte, pops one from each side, and bumps a match or mismatch
counter:

- mem_rd vs tlp_tx : memory read data should match what went out as a tlp.
- mem_wr vs tlp_rx : memory write data should match the incoming completion tlp.
- tlp_tx vs tlp_rx : loopback sanity, the tx and rx payload should match.

## current state

All wiring verified correct. The failures are upstream in the DUT (see root README
and sim/errors.md section 12): two compares get no data because the DUT paths that
would feed them are stubbed or not firing, and the loopback compare runs but the
payload is byte-misaligned (255 of 256 mismatch).

The pass/fail decision is in the test's report_phase, not here. The scoreboard
only collects and counts.
