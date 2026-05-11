# sim/ — Simulation Scripts

Run everything from this directory.

---

## Questa / ModelSim

```bash
make questa                               # compile + run pcie_wr_rd_test
make questa TEST=pcie_tl_base_test        # run a different test
make wave                                 # open waveform after run
make clean                                # delete work lib and logs
```

## VCS

```bash
make vcs
make vcs TEST=pcie_tl_base_test
```

## Xcelium

```bash
make xcelium
```

---

## Log files

| File | What it is |
|------|-----------|
| `transcript` | Questa full log |
| `dump.vcd` | Waveform (open with GTKWave or Questa) |
| `*.log` | Named per-test logs with timestamp |
