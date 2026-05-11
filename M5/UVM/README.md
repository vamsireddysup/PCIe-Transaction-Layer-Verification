# M5/UVM/

Week 5 — scoreboard, all bugs fixed, TEST PASSED.

See [M5/README.md](../README.md) for the full bug fix checklist and scoreboard spec.

## New files this week

- `tl_sbd.sv` — scoreboard extending `uvm_scoreboard`

## Bugs fixed this week

- [ ] `test_lib.sv:30` — impossible PASS condition
- [ ] `design/pcie_tl.sv:564` — wrong requester ID field
- [ ] `pcie_tl_env.sv` — mem_agent not instantiated
- [ ] `dll_item.sv:88` — hardcoded CplD payload
- [ ] `dll_tx_responder.sv` — pop before push
- [ ] `dll_tx_mon.sv:31` — first DW dropped
- [ ] All agents — wrong base class

## Final run

```bash
vsim -c top_tb +UVM_TESTNAME=pcie_wr_rd_test -do "run -all; quit" -l final_run.log
grep "TEST PASSED\|UVM_ERROR\|UVM_FATAL" final_run.log
```
