


`include"defines.sv"

class alu_base extends uvm_test;

  `uvm_component_utils(alu_base)

 alu_environment env;
alu_sequence seq;

  function new(string name = "alu_base",uvm_component parent=null);
    super.new(name,parent);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = alu_environment::type_id::create("env", this);
    
  endfunction : build_phase

virtual function void end_of_elaboration();
 print();
endfunction
endclass 




class alu_regression_test extends alu_base;

  `uvm_component_utils(alu_regression_test)

  function new(string name = "alu_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_regression   seq;
    phase.raise_objection(this);
    repeat(10)begin
    seq =  alu_regression::type_id::create("seq");
    seq.start(env.agt.seqr);
    end
    phase.drop_objection(this);
  endtask
endclass
