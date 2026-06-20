# tb/test

The tests.

## pcie_tl_base_test.sv

Base test. Builds the env, holds the handles the derived test uses (linkup_seq,
vc_up_seq, cpl_seq), and the report_phase scaffolding.

## pcie_wr_rd_test.sv

The actual test. In run_phase it:

1. starts the three dll responder sequences (linkup, vc_up, cpl) with fork
   join_none so they run across the whole sim.
2. runs config_seq (initial register config).
3. runs dma_descr_seq (load tx and rx descriptors).
4. runs mem_wr_cfg_seq (kick off mem_wr then mem_rd, this one waits internally for
   enumeration to finish before writing the dma enable).
5. waits, then drops the objection.

report_phase does the pass/fail. It checks all three scoreboard comparisons: each
needs at least one match and zero mismatches to pass. The original code had a
copy-paste typo that compared the match counter in all three conditions (so the
second condition was always false and PASSED could never print). That is fixed to
check the correct mismatch counter per comparison.
