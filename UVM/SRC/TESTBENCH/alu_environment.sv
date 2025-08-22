`include"defines.sv"

class alu_environment extends uvm_env;
  alu_agent      agt;
  alu_scoreboard scb;
  alu_coverage cov;

  `uvm_component_utils(alu_environment)

  function new(string name = "alu_environment", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = alu_agent::type_id::create("agt", this);
    scb = alu_scoreboard::type_id::create("scb", this);
    cov = alu_coverage::type_id::create("cov", this);
  endfunction

 
  function void connect_phase(uvm_phase phase);
  agt.mon.item_collected_port.connect(scb.mon_imp);
  //agt.drv.item_collected_port.connect(scb.drv_imp);
  agt.mon.item_collected_port.connect(cov.aport_mon1);
  agt.mon.item_collected_port.connect(cov.aport_drv1);
endfunction

 

endclass
