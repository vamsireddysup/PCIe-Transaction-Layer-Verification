# M1/CLASS/

My plain SystemVerilog testbench from Week 1. No UVM.

See [M1/README.md](../README.md) for what I was trying to verify and the AXI timing diagrams.

## Files I created here

- `axi_intf.sv`
- `tl_dll_intf.sv`
- `pcie_tl_drv.sv`
- `top_tb.sv`

## How to run

```bash
vlog -sv +incdir+. axi_intf.sv tl_dll_intf.sv ../../design/pcie_tl.sv top_tb.sv
vsim -c top_tb -do "run -all; quit"
```
