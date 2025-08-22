// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`include "uvm_pkg.sv"
`include "uvm_macros.svh"
`include "alu_pkg.sv"
`include "alu_if.sv"
`include "design.sv"
`include"defines.sv"

module top;
   import uvm_pkg::*;
  import alu_pkg::*;

  bit CLK;
  bit RST;

  always #5 CLK = ~CLK;

  initial begin
  RST = 1;
  RST =0;
  end
  alu_if vif(CLK, RST);

  ALU_DESIGN DUT(.OPA(vif.OPA),
            .OPB(vif.OPB),
            .CE(vif.CE),
            .CIN(vif.CIN),
            .MODE(vif.MODE),
            .INP_VALID(vif.INP_VALID),
            .CMD(vif.CMD),
            .RES(vif.RES),
            .COUT(vif.COUT),
            .E(vif.E),
            .G(vif.G),
            .L(vif.L),
            .OFLOW(vif.OFLOW),
            .ERR(vif.ERR),
            .CLK(vif.CLK),
            .RST(vif.RST)
           );

  initial begin
   uvm_config_db#(virtual alu_if)::set(uvm_root::get(),"*","vif",vif);
   // $dumpfile("dump.vcd");
        //$dumpvars;
  end

  initial begin
    run_test("alu_regression_test");
    #100 $finish;
  end
endmodule
