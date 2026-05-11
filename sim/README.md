# sim — Simulation Scripts

---

## Questa/ModelSim

```bash
make questa                    # compile + simulate pcie_wr_rd_test
make questa TEST=pcie_tl_base_test  # run a specific test
make wave                      # open waveform after simulation
make clean                     # remove work library and logs
```

## VCS (Synopsys)

```bash
make vcs
```

## Xcelium (Cadence)

```bash
make xcelium
```

---

## Log Files

| File | Description |
|------|-------------|
| `transcript` | Full Questa simulation log |
| `dump.vcd`   | VCD waveform (open with GTKWave or Questa) |
| `*.log`      | Named test logs |
