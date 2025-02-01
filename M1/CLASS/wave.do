onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/aclk
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arst
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awvalid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wvalid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awready
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wready
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awaddr
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awlen
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/awburst
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wdata
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wstrb
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/wlast
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/bvalid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/bready
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/bid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/bresp
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arvalid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arready
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rvalid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rready
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/araddr
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arlen
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/arburst
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rdata
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rid
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rlast
add wave -noupdate -expand -group AXI_PROC_INTF /top_tb/axi_p_pif/rresp
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/aclk
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arst
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awvalid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wvalid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awready
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wready
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awaddr
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awlen
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/awburst
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wdata
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wstrb
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/wlast
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/bvalid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/bready
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/bid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/bresp
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arvalid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arready
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rvalid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rready
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/araddr
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arlen
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/arburst
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rdata
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rid
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rlast
add wave -noupdate -group AXI_MEM_INTF /top_tb/axi_m_pif/rresp
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/tl_dll_clk
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/arst
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/tx_data_o
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/tx_valid_o
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/tx_ready_i
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/rx_data_i
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/rx_valid_i
add wave -noupdate -group TL_DLL_INTF /top_tb/tl_dll_pif/rx_ready_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {840 ns}
