`include "uvm_macros.svh"
`include "defines.sv"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_monitor) // keep your macro usage if used elsewhere

class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)

  // analysis imp from monitor -> scoreboard (you used a custom name)
  uvm_analysis_imp_monitor #(alu_sequence_item, alu_scoreboard) mon_imp;

  // single queue to hold monitor transactions
  alu_sequence_item mon_q[$];

  int MATCH = 0, MISMATCH = 0;
  virtual alu_if vif;

  function new (string name = "alu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // create analysis imp
    mon_imp = new("mon_imp", this);

    // get virtual interface
    if(!uvm_config_db#(virtual alu_if)::get(this,"","vif",vif)) begin
      `uvm_fatal("NOVIF","Virtual interface not found in alu_scoreboard")
    end
  endfunction

  // Single write function receiving all transactions from monitor (inputs + outputs)
  // If your analysis imp expects 'write' or 'write_monitor', keep consistent with your monitor connect
  function void write_monitor(alu_sequence_item t);
    if (t == null) begin
      `uvm_error("SCB_MON_WRITE","Received null transaction from monitor!")
      return;
    end

    `uvm_info("SCB_MON_WRITE",$sformatf(
      "Monitor Txn time[%0t] : OPA=%0d OPB=%0d CMD=%0b MODE=%0b CE=%0b CIN=%0b INP_VALID=%0b | RES=%0d, COUT=%0b, OFLOW=%0b, E=%0b, G=%0b, L=%0b, ERR=%0b",
      $time, t.OPA, t.OPB, t.CMD, t.MODE, t.CE, t.CIN, t.INP_VALID,
      t.RES, t.COUT, t.OFLOW, t.E, t.G, t.L, t.ERR), UVM_LOW);

    mon_q.push_back(t);
  endfunction

  virtual task run_phase(uvm_phase phase);
  alu_sequence_item mon_item;
  alu_sequence_item exp_item;

  forever begin
    wait(mon_q.size() > 0);

    mon_item = mon_q.pop_front();

    exp_item = alu_sequence_item::type_id::create("exp_item");
    if (exp_item == null) begin
      `uvm_fatal("SCB_EXP_NULL","Failed to create exp_item via factory in scoreboard")
    end

    exp_item.copy_inputs(mon_item);

    `uvm_info("SCB_DEBUG", $sformatf("Before ref model: OPA=%0d OPB=%0d CMD=%0b MODE=%0b",
       mon_item.OPA, mon_item.OPB, mon_item.CMD, mon_item.MODE), UVM_LOW);

    run_ref_model(mon_item, exp_item);

    compare_and_report(mon_item, exp_item);
    $display();
  end
endtask


  virtual task run_ref_model(input alu_sequence_item dut_item,
                             ref   alu_sequence_item exp_item);
    int shift;

    if (dut_item == null) begin
      `uvm_error("REF_MODEL", "Input transaction dut_item is null!")
      return;
    end

    if (exp_item == null) begin
      `uvm_fatal("REF_NULL", "exp_item is null inside run_ref_model")
    end

    if (vif == null) begin
      `uvm_fatal("NOVIF", "Virtual interface handle 'vif' is NULL in scoreboard.");
    end

   
    shift = dut_item.OPB[2:0];

    `uvm_info("SCB_REF_MODEL", $sformatf("Ref model start time[%0t] : CMD=%0b MODE=%0b INP_VALID=%0b",
                                   $time, dut_item.CMD, dut_item.MODE, dut_item.INP_VALID), UVM_LOW)

   
    zero_outputs(exp_item);

    if (dut_item.CE) begin
      case (dut_item.INP_VALID)
        2'b11: begin
          case (dut_item.MODE)
            1'b1: begin // Arithmetic
              case (dut_item.CMD)
                4'b0000: begin exp_item.RES = dut_item.OPA + dut_item.OPB; exp_item.COUT = exp_item.RES[`WIDTH]; end
                4'b0001: begin exp_item.RES = dut_item.OPA - dut_item.OPB; exp_item.OFLOW = (dut_item.OPA < dut_item.OPB); end
                4'b0010: begin exp_item.RES = dut_item.OPA + dut_item.OPB + dut_item.CIN; exp_item.COUT = exp_item.RES[`WIDTH]; end
                4'b0011: begin exp_item.RES = dut_item.OPA - dut_item.OPB - dut_item.CIN; exp_item.OFLOW = (dut_item.OPA < dut_item.OPB + dut_item.CIN); end
                4'b1001: exp_item.RES = (dut_item.OPA + 1) * (dut_item.OPB + 1);
                4'b1010: exp_item.RES = (dut_item.OPA << 1) * dut_item.OPB;
                4'b0100: exp_item.RES = dut_item.OPA + 1;
                4'b0101: exp_item.RES = dut_item.OPA - 1;
                4'b0110: exp_item.RES = dut_item.OPB + 1;
                4'b0111: exp_item.RES = dut_item.OPB - 1;
                4'b1000: begin
                  if (dut_item.OPA == dut_item.OPB) exp_item.E = 1;
                  else if (dut_item.OPA > dut_item.OPB) exp_item.G = 1;
                  else exp_item.L = 1;
                end
                default: zero_outputs(exp_item);
              endcase
            end

            1'b0: begin // Logical
              case (dut_item.CMD)
                4'b0000: exp_item.RES = {1'b0, dut_item.OPA & dut_item.OPB};
                4'b0001: exp_item.RES = {1'b0, ~(dut_item.OPA & dut_item.OPB)};
                4'b0010: exp_item.RES = {1'b0, dut_item.OPA | dut_item.OPB};
                4'b0011: exp_item.RES = {1'b0, ~(dut_item.OPA | dut_item.OPB)};
                4'b0100: exp_item.RES = {1'b0, dut_item.OPA ^ dut_item.OPB};
                4'b0101: exp_item.RES = {1'b0, ~(dut_item.OPA ^ dut_item.OPB)};
                4'b0110: exp_item.RES = {1'b0, ~dut_item.OPA};
                4'b0111: exp_item.RES = {1'b0, ~dut_item.OPB};
                4'b1000: exp_item.RES = {1'b0, dut_item.OPA >> 1};
                4'b1001: exp_item.RES = {1'b0, dut_item.OPA << 1};
                4'b1010: exp_item.RES = {1'b0, dut_item.OPB >> 1};
                4'b1011: exp_item.RES = {1'b0, dut_item.OPB << 1};
                4'b1100: begin
                  exp_item.RES = (shift==0) ? {1'b0,dut_item.OPA} :
                                 {1'b0,(dut_item.OPA<<shift)|(dut_item.OPA>>(`WIDTH-shift))};
                  exp_item.ERR = (`WIDTH > 3 && |dut_item.OPB[`WIDTH-1:4]);
                end
                4'b1101: begin
                  exp_item.RES = (shift==0) ? {1'b0,dut_item.OPA} :
                                 {1'b0,(dut_item.OPA>>shift)|(dut_item.OPA<<(`WIDTH-shift))};
                  exp_item.ERR = (`WIDTH > 3 && |dut_item.OPB[`WIDTH-1:4]);
                end
                default: zero_outputs(exp_item);
              endcase
            end
          endcase
        end

        2'b01: begin // Only OPA valid
          case (dut_item.MODE)
            1'b1: begin
              case (dut_item.CMD)
                4'b0100: exp_item.RES = dut_item.OPA + 1;
                4'b0101: exp_item.RES = dut_item.OPA - 1;
                default: zero_outputs(exp_item);
              endcase
            end
            1'b0: begin
              case (dut_item.CMD)
                4'b0110: exp_item.RES = {1'b0, ~dut_item.OPA};
                4'b1000: exp_item.RES = {1'b0, dut_item.OPA >> 1};
                4'b1001: exp_item.RES = {1'b0, dut_item.OPA << 1};
                default: zero_outputs(exp_item);
              endcase
            end
          endcase
        end

        2'b10: begin // Only OPB valid
          case (dut_item.MODE)
            1'b1: begin
              case (dut_item.CMD)
                4'b0110: exp_item.RES = dut_item.OPB + 1;
                4'b0111: exp_item.RES = dut_item.OPB - 1;
                default: zero_outputs(exp_item);
              endcase
            end
            1'b0: begin
              case (dut_item.CMD)
                4'b0111: exp_item.RES = {1'b0, ~dut_item.OPB};
                4'b1010: exp_item.RES = {1'b0, dut_item.OPB >> 1};
                4'b1011: exp_item.RES = {1'b0, dut_item.OPB << 1};
                default: zero_outputs(exp_item);
              endcase
            end
          endcase
        end

        default: zero_outputs(exp_item);
      endcase
    end else begin
      zero_outputs(exp_item);
    end
  endtask

  // helper to zero expected outputs
  function void zero_outputs(alu_sequence_item exp_item);
    exp_item.RES = 9'bzzzzzzzzz;
    exp_item.COUT = 'bz;    // Changed from 'z
    exp_item.OFLOW = 'bz;
    exp_item.E   = 'bz;
    exp_item.G = 'bz;
    exp_item.L = 'bz;
    exp_item.ERR = 'bz;
  endfunction

  // Enhanced comparison with detailed field-by-field checking
  function bit compare_fields(alu_sequence_item dut, alu_sequence_item exp_item);
    bit res_match, cout_match, oflow_match, e_match, g_match, l_match, err_match;
    
    // Use === for exact comparison including X/Z states
    res_match = (dut.RES === exp_item.RES);
    cout_match = (dut.COUT === exp_item.COUT);
    oflow_match = (dut.OFLOW === exp_item.OFLOW);
    e_match = (dut.E === exp_item.E);
    g_match = (dut.G === exp_item.G);
    l_match = (dut.L === exp_item.L);
    err_match = (dut.ERR === exp_item.ERR);
    
    // Debug individual field mismatches
    if (!res_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("RES mismatch: DUT=%b(%0d) EXP=%b(%0d)", dut.RES, dut.RES, exp_item.RES, exp_item.RES), UVM_LOW);
    if (!cout_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("COUT mismatch: DUT=%b EXP=%b", dut.COUT, exp_item.COUT), UVM_LOW);
    if (!oflow_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("OFLOW mismatch: DUT=%b EXP=%b", dut.OFLOW, exp_item.OFLOW), UVM_LOW);
    if (!e_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("E mismatch: DUT=%b EXP=%b", dut.E, exp_item.E), UVM_LOW);
    if (!g_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("G mismatch: DUT=%b EXP=%b", dut.G, exp_item.G), UVM_LOW);
    if (!l_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("L mismatch: DUT=%b EXP=%b", dut.L, exp_item.L), UVM_LOW);
    if (!err_match) `uvm_info("SCB_FIELD_DEBUG", $sformatf("ERR mismatch: DUT=%b EXP=%b", dut.ERR, exp_item.ERR), UVM_LOW);
    
    return (res_match && cout_match && oflow_match && e_match && g_match && l_match && err_match);
  endfunction

  // compare DUT outputs against expected and report
  task compare_and_report(alu_sequence_item dut, alu_sequence_item exp_item);
    
    if (compare_fields(dut, exp_item)) begin
      MATCH++;
      `uvm_info("MATCH", $sformatf(
        "DUT time[%0t]: RES=%0d, COUT=%0b, OFLOW=%0b, E=%0b, G=%0b, L=%0b, ERR=%0b | EXP: RES=%0d, COUT=%0b, OFLOW=%0b, E=%0b, G=%0b, L=%0b, ERR=%0b",
        $time,
        dut.RES, dut.COUT, dut.OFLOW, dut.E, dut.G, dut.L, dut.ERR,
        exp_item.RES, exp_item.COUT, exp_item.OFLOW, exp_item.E, exp_item.G, exp_item.L, exp_item.ERR
      ), UVM_LOW);
    end else begin
      MISMATCH++;
      `uvm_error("MISMATCH", $sformatf(
        "DUT time[%0t]: RES=%0d, COUT=%0b, OFLOW=%0b, E=%0b, G=%0b, L=%0b, ERR=%0b | EXP: RES=%0d, COUT=%0b, OFLOW=%0b, E=%0b, G=%0b, L=%0b, ERR=%0b",
        $time,
        dut.RES, dut.COUT, dut.OFLOW, dut.E, dut.G, dut.L, dut.ERR,
        exp_item.RES, exp_item.COUT, exp_item.OFLOW, exp_item.E, exp_item.G, exp_item.L, exp_item.ERR
      ));
      
      // Additional binary format debug info
      `uvm_info("MISMATCH_BINARY", $sformatf(
        "Binary comparison - RES: DUT=%b EXP=%b | COUT: DUT=%b EXP=%b | OFLOW: DUT=%b EXP=%b",
        dut.RES, exp_item.RES, dut.COUT, exp_item.COUT, dut.OFLOW, exp_item.OFLOW), UVM_LOW);
    end
  endtask

  // Final report of match/mismatch statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_FINAL_REPORT", $sformatf("Total MATCHES: %0d, Total MISMATCHES: %0d", MATCH, MISMATCH), UVM_LOW);
  endfunction

endclass
