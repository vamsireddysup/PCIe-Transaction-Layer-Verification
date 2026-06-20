# tb

Testbench root. Holds the top module, the shared common file, and the subdirs
for interfaces, agents, sequences, scoreboard, env, and tests.

## top_tb.sv

The top module. Generates a single 10ns / 100MHz clock that drives both the AXI
clock and the dll clock, holds reset high for 5 cycles, instantiates the DUT and
the interfaces, and sets the virtual interfaces into the uvm_resource_db so the
agents can pull them. Also runs run_test().

It carries one important line: the mirror that publishes the DUT's dll fsm state
into pcie_common::pcie_tl_dll_state. This has to live here (not in the DUT)
because pcie_common is a class included by two separate compilation units, so the
DUT and the tb each get their own copy of the static. Driving the mirror from
top_tb keeps the write in the same unit as the copy the sequences read.

## pcie_common.sv

Shared between the design and tb sides. Holds the NEW_COMP / NEW_OBJ macros, the
burst-type and tlp enums, tlp fmt/type encodings, the ep config constants, and
the static vars the tb and DUT use to sync (pcie_tl_dll_state, transmit_tlp,
rcvd_tlp_count, and the scoreboard match/mismatch counters). Guarded with ifndef
so it is safe to include from both sides.
