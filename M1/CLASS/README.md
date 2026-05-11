# M1/CLASS — Class-Based Testbench

Write your **non-UVM** SystemVerilog testbench here.

See [`M1/README.md`](../README.md) for the full challenge spec and timing diagrams.

## Files to create

- `axi_intf.sv` — AXI4 interface
- `tl_dll_intf.sv` — DLL interface
- `pcie_tl_drv.sv` — Plain class with AXI write/read tasks
- `top_tb.sv` — Top module

## Run

```bash
vlog -sv +incdir+. axi_intf.sv tl_dll_intf.sv ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb -do "run -all; quit"
```
