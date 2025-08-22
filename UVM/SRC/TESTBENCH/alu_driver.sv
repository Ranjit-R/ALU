`include "defines.sv"

class alu_driver extends uvm_driver #(alu_sequence_item);
  virtual alu_if vif;
  `uvm_component_utils(alu_driver)
  alu_sequence_item second_op;

  function new (string name = "alu_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(vif.drv_cb);
    forever begin
    //  repeat(3) @(vif.drv_cb);
      seq_item_port.get_next_item(req);
      drive();
     // repeat (2) @(vif.drv_cb);
      repeat(4) @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive();
    if (req.CE) begin
      if ((req.INP_VALID inside {2'b01, 2'b10}) &&
          ((req.MODE == 1'b1 && req.CMD inside {0, 1, 2, 3, 8, 9, 10}) ||
           (req.MODE == 1'b0 && req.CMD inside {0, 1, 2, 3, 4, 5, 12, 13}))) begin

        vif.drv_cb.INP_VALID <= req.INP_VALID;
        if (req.INP_VALID == 2'b01) begin
          vif.drv_cb.OPA <= req.OPA;
          vif.drv_cb.OPB <= '0;
        end else if (req.INP_VALID == 2'b10) begin
          vif.drv_cb.OPB <= req.OPB;
          vif.drv_cb.OPA <= '0;
        end
        vif.drv_cb.CMD  <= req.CMD;
        vif.drv_cb.MODE <= req.MODE;
        vif.drv_cb.CE   <= req.CE;
        vif.drv_cb.CIN  <= req.CIN;
        @(vif.drv_cb);

        // Wait for and send second operand within 16 cycles
        for (int j = 0; j < 16; j++) begin
          @(vif.drv_cb);
          second_op = alu_sequence_item::type_id::create("second_op");
          second_op.fix_ctrl_signals = 1;
          second_op.fixed_CMD = req.CMD;
          second_op.fixed_MODE = req.MODE;
          second_op.fixed_CE = req.CE;
          second_op.INP_VALID = 2'b11;
          if (!second_op.randomize()) begin
            `uvm_warning("DRV", $sformatf("time = [%0t] Randomization failed on 2nd operand attempt %0d, retrying...", $time, j))
            continue;
          end
          vif.drv_cb.INP_VALID <= 2'b11;
          vif.drv_cb.OPA <= second_op.OPA;
          vif.drv_cb.OPB <= second_op.OPB;
          vif.drv_cb.CMD <= second_op.CMD;
          vif.drv_cb.MODE <= second_op.MODE;
          vif.drv_cb.CE <= second_op.CE;
          vif.drv_cb.CIN <= second_op.CIN;
          `uvm_info("DRV",
            $sformatf("time [%0t] 2nd operand sent at attempt[%0d]: OPA=%0d OPB=%0d CMD=%0d MODE=%0d CE=%0d INP_VALID=%b", $time, j, second_op.OPA, second_op.OPB, second_op.CMD, second_op.MODE, second_op.CE, second_op.INP_VALID),
            UVM_LOW)
          break;
        end

      end else if (req.INP_VALID == 2'b11) begin
        // Direct full input
        vif.drv_cb.INP_VALID <= 2'b11;
        vif.drv_cb.OPA <= req.OPA;
        vif.drv_cb.OPB <= req.OPB;
        vif.drv_cb.CMD <= req.CMD;
        vif.drv_cb.MODE <= req.MODE;
        vif.drv_cb.CE <= req.CE;
        vif.drv_cb.CIN <= req.CIN;
       //  @(vif.drv_cb);
        `uvm_info("DRV",
          $sformatf(" time[%0t] , Driver sending full transaction: OPA=%0d OPB=%0d CMD=%0b MODE=%0b CE=%0b CIN=%0b INP_VALID=%0b",
                    $time, req.OPA, req.OPB, req.CMD, req.MODE, req.CE, req.CIN, req.INP_VALID),
          UVM_LOW)
      end else begin
        // INP_VALID = 00
        vif.drv_cb.INP_VALID <= 2'b00;
        vif.drv_cb.OPA       <= '0;
        vif.drv_cb.OPB       <= '0;
        vif.drv_cb.CMD       <= '0;
        vif.drv_cb.MODE      <= '0;
        vif.drv_cb.CE        <= 1'b0;
        vif.drv_cb.CIN       <= 1'b0;
       // @(vif.drv_cb);
      end

    end else begin
      // CE = 0
      vif.drv_cb.INP_VALID <= 2'b00;
      vif.drv_cb.OPA       <= '0;
      vif.drv_cb.OPB       <= '0;
      vif.drv_cb.CMD       <= '0;
      vif.drv_cb.MODE      <= '0;
      vif.drv_cb.CE        <= 1'b0;
      vif.drv_cb.CIN       <= 1'b0;
    //  @(vif.drv_cb);
    end
  endtask
endclass
