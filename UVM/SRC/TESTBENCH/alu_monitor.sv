`include "defines.sv"
 
class alu_monitor extends uvm_monitor;
  virtual alu_if vif;
  uvm_analysis_port #(alu_sequence_item) item_collected_port;
  alu_sequence_item mon_item;
  `uvm_component_utils(alu_monitor)
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
    mon_item = new();
    item_collected_port = new("item_collected_port", this);
  endfunction
 
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction
 
  function automatic bit multiplication_check();
    return (vif.mon_cb.MODE == 1'b1) && (vif.mon_cb.CMD inside {4'd9, 4'd10});
  endfunction
 
  virtual task run_phase(uvm_phase phase);
    repeat(1) @(vif.mon_cb);
    forever begin
      
      do repeat(3)@(vif.mon_cb);
      while (!(vif.mon_cb.CE && (vif.mon_cb.INP_VALID == 2'b11 || vif.mon_cb.INP_VALID == 2'b01 || vif.mon_cb.INP_VALID == 2'b10)));

      if (multiplication_check())
        repeat(1) @(vif.mon_cb);
 
      // Capture all inputs and outputs from interface
      mon_item = alu_sequence_item::type_id::create("mon_item");
      // Inside your monitor's run_phase just before capturing if signal
 
      mon_item.OPA       = vif.mon_cb.OPA;
      mon_item.OPB       = vif.mon_cb.OPB;
      mon_item.CMD       = vif.mon_cb.CMD;
      mon_item.MODE      = vif.mon_cb.MODE;
      mon_item.CE        = vif.mon_cb.CE;
      mon_item.CIN       = vif.mon_cb.CIN;
      mon_item.INP_VALID = vif.mon_cb.INP_VALID;
      mon_item.RES       = vif.mon_cb.RES;
      mon_item.COUT      = vif.mon_cb.COUT;
      mon_item.E         = vif.mon_cb.E;
      mon_item.G         = vif.mon_cb.G;
      mon_item.L         = vif.mon_cb.L;
      mon_item.OFLOW     = vif.mon_cb.OFLOW;
      mon_item.ERR       = vif.mon_cb.ERR;
 
      `uvm_info("MON",
        $sformatf("time[%0t], MONITOR sampling interface: OPA=%0d, OPB=%0d, CMD=%0b, MODE=%0b, CE=%0b, CIN=%0b, INP_VALID=%0b | RES=%0d, COUT=%b, E=%b, G=%b, L=%b, OFLOW=%b, ERR=%b",
                  $time, mon_item.OPA, mon_item.OPB, mon_item.CMD, mon_item.MODE, mon_item.CE, mon_item.CIN, mon_item.INP_VALID,
                  mon_item.RES, mon_item.COUT, mon_item.E, mon_item.G, mon_item.L, mon_item.OFLOW, mon_item.ERR),
        UVM_LOW
      )
 @(vif.mon_cb);
      item_collected_port.write(mon_item);
    end
  endtask
endclass
