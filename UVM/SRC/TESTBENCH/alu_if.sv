`include"defines.sv"
interface alu_if( input bit CLK, RST);
  logic [`WIDTH-1:0] OPA, OPB;
  logic [`CMD_WIDTH-1:0] CMD;
  logic [1:0] INP_VALID;
  logic CE;
  logic CIN;
  logic MODE;
  logic [`WIDTH:0] RES;
  logic COUT;
  logic OFLOW;
  logic E, G, L;
  logic ERR;


  clocking drv_cb @(posedge CLK);
    default input #0 output #0;
    output OPA, OPB, CMD, INP_VALID, CE, CIN, MODE;
    input  RST;
  endclocking


  clocking mon_cb @(posedge CLK);
    default input #0 output #0;
    input  RES, COUT, OFLOW, E, G, L, ERR, RST, CMD, MODE, CE, INP_VALID, OPA, OPB, CIN;
endclocking


 /* clocking ref_cb @(posedge CLK);
    default input #0 output #0;
input OPA, OPB, CMD, INP_VALID, MODE, CE, CIN;
    input RES, COUT, OFLOW, E, G, L, ERR;
endclocking*/

  // Modport for driver
  modport DRV(clocking drv_cb);

  // Modport for monitor
  modport MON(
        clocking mon_cb,
        input CLK, RST);

  // Modport for reference model
 /* modport REF_SB( input CLK, RST,
    input OPA, OPB, CMD, INP_VALID, MODE, CE, CIN,
    input RES, COUT, E, G, L, OFLOW, ERR);
*/
endinterface
