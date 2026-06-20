# tb/env

The env, pcie_tl_env.sv.

Instantiates the four agents (axi, mem, dll_tx, dll_rx) and the scoreboard, and in
connect_phase wires each monitor's analysis port to the matching scoreboard imp:

    dll_tx mon -> imp_dll_tx
    dll_rx mon -> imp_dll_rx
    axi mon    -> imp_proc
    mem mon    -> imp_mem

All four connections are present and correct (verified while debugging the empty
scoreboard checks). The empty checks are a DUT data-path problem, not a missing
connection here.
