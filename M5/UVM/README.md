# M5/UVM — Scoreboard & Test Closure

Implement the scoreboard, fix all bugs, achieve TEST PASSED.

See [`M5/README.md`](../README.md) for the complete bug fix checklist and scoreboard spec.

## New files to create this week

- `tl_sbd.sv` — `tl_sbd extends uvm_scoreboard`

## Files to fix this week

| File | Bug |
|------|-----|
| `test_lib.sv` | PASS condition always false (num_tx_rx_matches vs num_tx_rx_mismatches) |
| `design/pcie_tl.sv` | requester_function_num used as device_num in CFG TLP header |
| `pcie_tl_env.sv` | mem_agent never instantiated |
| `dll_item.sv` | CplD payload hardcoded to 32'h1234_5678 |
| `dll_tx_responder.sv` | pop_front before push_back in S_TLP_PAYLOAD |
| `dll_tx_mon.sv` | First TLP DW silently dropped |

## Final run

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test -do "run -all; quit" -l final_run.log
grep "TEST PASSED\|UVM_ERROR\|UVM_FATAL" final_run.log
```
