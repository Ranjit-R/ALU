
`timescale 1ns / 1ps

`include "alu_design.v"
`include "define.v"


`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 240


module test_bench_alu();
  localparam Width = 8;
  localparam cmd_len = 4;

localparam TEST_CASE_WIDTH = 8 + 2 + 2 + 2*Width + cmd_len + 1 + 1 + 1 + 2*Width + 1 + 3 + 1 + 1;
localparam RESPONSE_WIDTH = TEST_CASE_WIDTH + 2*Width + 6 + 1;
localparam RESULT_WIDTH = 2*Width + 6;
localparam SCB_WIDTH = 1 + 8 + 2*RESULT_WIDTH + 1 + 1;

        reg [TEST_CASE_WIDTH -1:0] curr_test_case = 'b0;
        reg [TEST_CASE_WIDTH-1:0] stimulus_mem [0:`no_of_testcase-1];
        reg [RESPONSE_WIDTH-1:0] response_packet;

        integer i,j;
        reg CLK,REST,CE;
        event fetch_stimulus;
        reg [Width-1:0]OPA,OPB;
        reg [cmd_len-1:0]CMD;
        reg [1:0] INP_VALID;
        reg MODE,CIN;
        reg [7:0] Feature_ID;
        reg [2:0] Comparison_EGL;
        reg [(2*Width)-1:0] Expected_RES;
        reg err,cout,ov;
        reg [1:0] res1;

        wire  [(2*Width)-1:0] RES;
        wire ERR,OFLOW,COUT;
        wire [2:0]EGL;
        wire [RESULT_WIDTH-1:0] expected_data;
        reg [RESULT_WIDTH-1:0]exact_data;

        task read_stimulus();
                begin
                #10 $readmemb ("stimulus.txt",stimulus_mem);
        end
    endtask

    alu_design #(.WIDTH(Width),.CMD_WIDTH(cmd_len)) inst_dut (.OPA(OPA),.OPB(OPB),.CIN(CIN),.CLK(CLK),.CMD(CMD),.IN_VALID(INP_VALID),.CE(CE),.MODE(MODE),.COUT(COUT),.OFLOW(OFLOW),.RES(RES),.G(EGL[1]),.E(EGL[2]),.L(EGL[0]),.ERR(ERR),.RST(REST));

        integer stim_mem_ptr = 0,stim_stimulus_mem_ptr = 0,fid =0 , pointer =0 ;

        always@(fetch_stimulus)
        begin
                curr_test_case=stimulus_mem[stim_mem_ptr];
                $display ("stimulus_mem data = %0b \n",stimulus_mem[stim_mem_ptr]);
                $display ("packet data = %0b \n",curr_test_case);
                stim_mem_ptr=stim_mem_ptr+1;
        end

        initial
        begin
                CLK=0;
                forever #60 CLK=~CLK;
        end

        task driver ();
        begin
                ->fetch_stimulus;
                @(posedge CLK);
                Feature_ID=curr_test_case[56:49];
                res1 =curr_test_case[48:47];
                INP_VALID=curr_test_case[46:45];
                OPA=curr_test_case[44:37];
                OPB=curr_test_case[36:29];
                CMD=curr_test_case[28:25];
                CIN=curr_test_case[24];
                CE= curr_test_case[23];
                MODE=curr_test_case[22];
                Expected_RES =curr_test_case[21:6];
                cout =curr_test_case[5];
                Comparison_EGL=curr_test_case[4:2];
                ov =curr_test_case[1];
                err=curr_test_case[0];
                $display("At time (%0t), Feature_ID = %8b, Reserved_bit = %2b, OPA = %8b, OPB = %8b, CMD = %4b, CIN = %1b, CE = %1b, MODE = %1b, expected_result = %9b, cout = %1b, Comparison_EGL = %3b, ov = %1b, err = %1b",$time,Feature_ID,res1,OPA,OPB,CMD,CIN,CE,MODE, Expected_RES,cout,Comparison_EGL,ov,err);
        end
        endtask

        task dut_reset ();
        begin
                CE=1;
        #10 REST=1;
                #20 REST=0;
        end
        endtask

        task global_init ();
        begin
                curr_test_case=57'b0;
                response_packet=80'b0;
                stim_mem_ptr=0;
        end
        endtask

        task monitor ();
        begin
                repeat(5)@(posedge CLK);
                #5 response_packet[56:0]=curr_test_case;
                response_packet[57]     =ERR;
                response_packet[58]     =OFLOW;
                response_packet[61:59]  ={EGL};
                response_packet[62]     =COUT;
                response_packet[78:63]  =RES;
                response_packet[79]     =0;
                $display("Monitor: At time (%0t), RES = %9b, COUT = %1b, EGL = %3b, OFLOW = %1b, ERR = %1b",$time,RES,COUT,{EGL},OFLOW,ERR);
                exact_data ={RES,COUT,{EGL},OFLOW,ERR};
        end
        endtask

        assign expected_data = {Expected_RES,cout,Comparison_EGL,ov,err};

        reg [SCB_WIDTH-1:0] scb_stimulus_mem [0:`no_of_testcase-1];

        task score_board();
        reg [RESULT_WIDTH-1:0] expected_res;
        reg [7:0] feature_id;
        reg [RESULT_WIDTH-1:0] response_data;
        begin
                #5;
                feature_id = curr_test_case[56:49];
                expected_res = curr_test_case[21:6];
                response_data = response_packet[79:57];
                $display("expected result = %15b ,response data = %15b",expected_data,exact_data);
                if(expected_data === exact_data)
                        scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
                else
                        scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
                       stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
        end
        endtask

        task gen_report;
        integer file_id,pointer;
        reg [SCB_WIDTH-1:0] status;
        begin
                file_id = $fopen("results.txt", "w");
                for(pointer = 0; pointer <= `no_of_testcase-1 ; pointer = pointer+1 )
                begin
                        status = scb_stimulus_mem[pointer];
                        if(status[0])
                                $fdisplay(file_id, "Feature ID %8b : PASS", status[53:46]);
                        else
                                $fdisplay(file_id, "Feature ID %8b : FAIL", status[53:46]);
                end
        end
        endtask

        initial
        begin
                #10;
                global_init();
                dut_reset();
                read_stimulus();
                for(j=0;j<=`no_of_testcase-1;j=j+1)
                begin
                        fork
                                driver();
                                monitor();
                        join
                        score_board();
                end
                gen_report();
                $fclose(fid);
                #300 $finish();
        end
initial begin
 $dumpfile("waveform.vcd");
$dumpvars(0,test_bench_alu);
end
endmodule
