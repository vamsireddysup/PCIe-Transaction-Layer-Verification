class pcie_tl_base_test extends uvm_test;
`uvm_component_utils(pcie_tl_base_test);
function new(string name, uvm_component parent);
	super.new(name, parent);
endfunction

task run_phase(uvm_phase phase);
	phase.raise_objection(this);
	#1000;
	phase.drop_objection(this);
endtask
endclass
