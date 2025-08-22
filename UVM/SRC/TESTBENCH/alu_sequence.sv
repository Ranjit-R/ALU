`include"defines.sv"
class alu_sequence extends uvm_sequence#(alu_sequence_item);

  `uvm_object_utils(alu_sequence)
  function new(string name = "alu_sequence");
    super.new(name);
  endfunction


  virtual task body();
    for (int i = 0; i < `no_of_transactions; i++) begin
    //repeat(2)begin
    req = alu_sequence_item::type_id::create("req");
    wait_for_grant();
    req.randomize();
    send_request(req);
    wait_for_item_done();
        end
  endtask
endclass

class alu_sequence_1 extends uvm_sequence#(alu_sequence_item);

`uvm_object_utils(alu_sequence_1)
  function new(string name = "alu_sequence_1");
    super.new(name);
  endfunction

 virtual task body();
   `uvm_do_with(req,{req.MODE==0 && req.CMD inside {[6:11]} && req.INP_VALID == 2'b11;})
  endtask
endclass


class alu_sequence_2 extends uvm_sequence#(alu_sequence_item);

`uvm_object_utils(alu_sequence_2)
  function new(string name = "alu_sequence_2");
    super.new(name);
  endfunction

 virtual task body();
   `uvm_do_with(req,{req.MODE == 1 && req.CMD inside {[0:10]} && req.INP_VALID == 2'b11;})
  endtask
endclass


class alu_sequence_3 extends uvm_sequence#(alu_sequence_item);

`uvm_object_utils(alu_sequence_3)
  function new(string name = "alu_sequence_3");
    super.new(name);
  endfunction

 virtual task body();
    `uvm_do_with(req,{req.MODE==0 && req.CMD inside {[0:6], 12, 13} && req.INP_VALID == 2'b11;})
  endtask
endclass

class alu_sequence_4 extends uvm_sequence#(alu_sequence_item);

`uvm_object_utils(alu_sequence_4)
  function new(string name = "alu_sequence_4");
    super.new(name);
  endfunction

 virtual task body();
    `uvm_do_with(req,{req.MODE==1 && req.CMD inside {[0:3], 8, 9, 10} && req.INP_VALID == 2'b11;})
  endtask
endclass

class alu_sequence_5 extends uvm_sequence#(alu_sequence_item);

  `uvm_object_utils(alu_sequence_5)
  function new(string name = "alu_sequence_5");
    super.new(name);
  endfunction

 virtual task body();
   `uvm_do_with(req,{req.INP_VALID inside {1,2};})
  endtask
endclass

class alu_regression extends uvm_sequence#(alu_sequence_item);
  
  alu_sequence_1  logic_one_op;
  alu_sequence_2  arith_one_op;
  alu_sequence_3  logic_two_op;
  alu_sequence_4  arith_two_op;
  alu_sequence_5  cycle_16;
  
  `uvm_object_utils(alu_regression)
   
  function new(string name = "alu_regression");
    super.new(name);
  endfunction
  
  virtual task body();
//  repeat(`no_of_transactions) begin
//     `uvm_do(logic_one_op)
//  end
//  repeat(`no_of_transactions) begin
//     `uvm_do(arith_one_op)
//  end
//  repeat(`no_of_transactions) begin
//     `uvm_do(logic_two_op)
//  end
// repeat(`no_of_transactions) begin
//     `uvm_do(arith_two_op)
// end
    
repeat(`no_of_transactions) begin
    `uvm_do(cycle_16)
end
  endtask
endclass

