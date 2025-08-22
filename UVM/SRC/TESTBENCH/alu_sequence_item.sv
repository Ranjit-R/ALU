`include"defines.sv"
`include "uvm_macros.svh"
  import uvm_pkg::*;

class alu_sequence_item extends uvm_sequence_item;

rand bit [`WIDTH - 1:0] OPA;
rand bit [`WIDTH - 1:0] OPB;
rand bit CIN;
rand bit CE ;
rand bit MODE ;
rand bit [1:0] INP_VALID ;
rand bit [`CMD_WIDTH-1:0] CMD ;

logic [`WIDTH:0] RES;
bit OFLOW;
logic COUT;
bit G;
bit L;
bit E;
bit ERR;

 bit fix_ctrl_signals = 0;
 bit [`CMD_WIDTH-1:0] fixed_CMD;
 bit fixed_MODE;
 bit fixed_CE;


`uvm_object_utils_begin(alu_sequence_item)
`uvm_field_int(OPA, UVM_ALL_ON);
`uvm_field_int(OPB, UVM_ALL_ON);
`uvm_field_int(CIN, UVM_ALL_ON);
`uvm_field_int(CE, UVM_ALL_ON);
`uvm_field_int(MODE, UVM_ALL_ON);
`uvm_field_int(INP_VALID, UVM_ALL_ON);
`uvm_field_int(CMD, UVM_ALL_ON);
  
`uvm_object_utils_end

function new(string name = "alu_sequence_item");
super.new(name);
endfunction


      
  virtual function void copy_inputs(alu_sequence_item item);
    this.OPA = item.OPA;
    this.OPB = item.OPB;
    this.CIN = item.CIN;
    this.CE = item.CE;
    this.MODE = item.MODE;
    this.INP_VALID = item.INP_VALID;
    this.CMD = item.CMD;

    // reset outputs
    this.RES = 0;
    this.COUT = 'z;
    this.OFLOW = 0;
    this.G = 0;
    this.L = 0;
    this.E = 0;
    this.ERR = 0;
endfunction

endclass
