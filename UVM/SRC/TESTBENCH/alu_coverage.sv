`include"defines.sv"
`uvm_analysis_imp_decl(_mon_cg)
`uvm_analysis_imp_decl(_drv_cg)

class alu_coverage extends uvm_component;

`uvm_component_utils(alu_coverage)


  uvm_analysis_imp_mon_cg #(alu_sequence_item, alu_coverage) aport_mon1;
  uvm_analysis_imp_drv_cg #(alu_sequence_item, alu_coverage) aport_drv1;

alu_sequence_item txn_mon1, txn_drv1;
real mon1_cov,drv1_cov;

covergroup driver_cov;

  option.per_instance = 1;
    OPA_COV: coverpoint txn_drv1.OPA { bins opa[] = {[0:255]}; }
    OPB_COV: coverpoint txn_drv1.OPB { bins opb[] = {[0:255]}; }
    CIN_COV: coverpoint txn_drv1.CIN { bins cin[] = {0, 1}; }
    CE_COV: coverpoint txn_drv1.CE { bins ce[] = {0, 1}; }
    MODE_COV: coverpoint txn_drv1.MODE { bins mode[] = {0, 1}; }
    INP_VALID_COV: coverpoint txn_drv1.INP_VALID { bins inp_valid[] = {[0:3]}; }
    CMD_COV: coverpoint txn_drv1.CMD { bins cmd[] = {[0:13]}; }
    CE_X_MODE: cross CE_COV, MODE_COV;
    CE_X_CMD: cross CE_COV, CMD_COV;
  //  CMD_X_INP_VALID: cross CMD_COV, INP_VALID_COV;
    CMD_X_MODE: cross CMD_COV, MODE_COV;
  endgroup



covergroup monitor_cov;
  option.per_instance = 1;
    RES_COV: coverpoint txn_mon1.RES{bins res[] = {[0:255]};}
    COUT_COV: coverpoint txn_mon1.COUT {bins cout[] = {[0:1]};}
    EQUAL_COV: coverpoint txn_mon1.E {bins equal[] = {[0:1]};}
    GREATER_COV: coverpoint txn_mon1.G {bins greater[] = {[0:1]};}
    LESS_COV: coverpoint txn_mon1.L {bins less[] = {[0:1]};}
    OFLOW_COV: coverpoint txn_mon1.OFLOW {bins oflow[] = {[0:1]};}
    ERR_COV: coverpoint txn_mon1.ERR {bins err[] = {[0:1]};}


endgroup

function new(string name = "alu_coverage", uvm_component parent);
 super.new(name, parent);
  monitor_cov = new;
  driver_cov = new;
  aport_drv1=new("aport_drv1", this);

  aport_mon1 = new("aport_mon1", this);

endfunction

function void write_drv_cg(alu_sequence_item t);
 txn_drv1 = t;
  driver_cov.sample();
  `uvm_info(get_type_name, $sformatf("[DRIVER] time[%0t], OPA=%0d OPB=%0d CIN=%0d CE=%0d MODE=%0d INP_VALID=%0d CMD=%0d", $time, txn_drv1.OPA, txn_drv1.OPB, txn_drv1.CIN, txn_drv1.CE, txn_drv1.MODE, txn_drv1.INP_VALID, txn_drv1.CMD), UVM_MEDIUM);
endfunction


function void write_mon_cg(alu_sequence_item t);
  txn_mon1 = t;
  monitor_cov.sample();
  `uvm_info(get_type_name, $sformatf("[MONITOR] time[%0t], RES=%d COUT=%d E=%d G=%d L=%d OFLOW=%d ERR=%d",$time, txn_mon1.RES, txn_mon1.COUT, txn_mon1.E, txn_mon1.G, txn_mon1.L, txn_mon1.OFLOW, txn_mon1.ERR ), UVM_MEDIUM);
endfunction


function void extract_phase(uvm_phase phase);
  super.extract_phase(phase);
  drv1_cov = driver_cov.get_coverage();
  mon1_cov = monitor_cov.get_coverage();
endfunction

function void report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name, $sformatf("[DRIVER] Coverage ------> %0.2f%%,", drv1_cov), UVM_MEDIUM);
  `uvm_info(get_type_name, $sformatf("[MONITOR] Coverage ------> %0.2f%%", mon1_cov), UVM_MEDIUM);
  endfunction

endclass
