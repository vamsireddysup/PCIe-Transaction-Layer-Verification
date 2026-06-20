# sim

Run logs and the debug record. Logs are gitignored (*.log), errors.md is tracked.

## errors.md

The full debug log for the bring-up. Every bug gets symptom, root cause, and the
fix, numbered 1 through 10, plus section 11 (current state) and section 12 (the
scoreboard analysis). This is the real record. The root README summarizes it.

## reproducing

See the root README for the vlog/vsim commands. For looking at DUT internals, the
signals get optimized away by default, so load with:

    vsim -c -voptargs=+acc -suppress 3839 work.top_tb +UVM_TESTNAME=pcie_wr_rd_test ...

The -suppress 3839 demotes the multiply-driven errors (an artifact of the AXI
interface having both master and slave clocking blocks) so the design loads with
full signal visibility. Always wrap long runs in a timeout so a hang gets killed
instead of spinning: timeout 120 vsim ... and check the exit code (143 = killed by
timeout = real hang, 0 = completed).
