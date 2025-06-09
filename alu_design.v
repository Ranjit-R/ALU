module alu_design#(parameter WIDTH = 8, parameter CMD_WIDTH = 4)(OPA,OPB,CLK,RST,CE,MODE,CIN,CMD,IN_VALID,RES,COUT,OFLOW,G,E,L,ERR);
  input [WIDTH-1:0] OPA;
  input [WIDTH-1:0] OPB;
  input CLK,RST,CE,MODE,CIN;
  input [CMD_WIDTH-1:0] CMD;
  input [1:0] IN_VALID;
  output reg [2*WIDTH-1:0] RES ;
  output reg COUT;
  output reg OFLOW;
  output reg G;
  output reg E;
  output reg L;
  output reg ERR;

  localparam shift_bits = $clog2(WIDTH);
  reg [shift_bits-1:0]shift_val;

  reg[WIDTH-1:0] OPA_1;
  reg[WIDTH-1:0] OPB_1;
  reg MODE_1,CIN_1;
  reg[1:0]IN_VALID_1;
  reg[3:0]CMD_1;
  reg [2*WIDTH-1:0] mul_result = 0;
  reg [WIDTH:0] sum,sub,sum_in,sub_in;
  reg signed[WIDTH:0] signed_sum,signed_sub;

function [2*WIDTH-1:0] pad_result;
  input [WIDTH:0] data;
  begin
    pad_result = {{(2*WIDTH - (WIDTH+1)){1'b0}}, data};
  end
endfunction



always@(posedge CLK)begin
if( CE )begin
    RES <={2*WIDTH{1'b0}};
         COUT <=1'b0;
         OFLOW <=1'b0;
         G <=1'b0;
         E <=1'b0;
         L <=1'b0;
         ERR <=1'b0;
         OPA_1 <= OPA;
         OPB_1 <= OPB;
         MODE_1 <= MODE;
         CIN_1 <= CIN;
         IN_VALID_1 = IN_VALID;
         CMD_1 <= CMD;
         end
    end

always@(posedge CLK, posedge RST)begin
    if( RST )begin
        RES <={2*WIDTH{1'b0}};
        COUT <=1'b0;
        OFLOW <=1'b0;
        G <=1'b0;
        E <=1'b0;
        L <=1'b0;
        ERR <=1'b0;
    end

    else if( CE && MODE_1 && (IN_VALID_1 == 2'b11))begin
        RES <={2*WIDTH{1'b0}};
        COUT <=1'b0;
        OFLOW <=1'b0;
        G <=1'b0;
        E <=1'b0;
        L <=1'b0;
        ERR <=1'b0;

        case( CMD_1 )
        4'b0000:
                     begin
                    sum = OPA_1 + OPB_1;
                    RES <= pad_result(sum);
                    COUT <= sum[WIDTH];
                    end
        4'b0001:
                     begin
                     sub = OPA_1 - OPB_1;
                     RES <= pad_result( sub );
                     OFLOW <=(OPA_1 < OPB_1)?1:0;
                     end
        4'b0010:
                     begin
                     sum_in = OPA_1+OPB_1+CIN_1;
                     RES <= pad_result(sum_in);
                     COUT <= (sum_in[WIDTH] == 'b1 ) ?1:0;
                     end
                4'b0011:
                    begin
                    sub_in = OPA_1-OPB_1-CIN_1;
                    RES <= pad_result ( sub_in );
                    OFLOW<=(OPA_1<OPB_1) || ((OPA_1 - OPB_1)< CIN)?1:0;
                    end

        4'b1000:
                    begin
                    RES <= {WIDTH{1'b0}};
                    if(OPA_1 == OPB_1)
                     begin
                       E <= 1'b1;
                       G <= 1'b0;
                       L <= 1'b0;
                       end
                    else if(OPA_1 > OPB_1)
                     begin
                       E <=1'b0;
                       G <= 1'b1;
                       L <= 1'b0;
                     end
                    else
                     begin
                       E <= 1'b0;
                       G <= 1'b0;
                       L <= 1'b1;
                     end
                   end
         4'b1001:
                    begin
                        mul_result <= (OPA_1 + 1) * ( OPB_1 + 1);
                        RES <= mul_result[WIDTH-1:0];
                    end

         4'b1010:
                    begin
                        mul_result <= (OPA_1 << 1) * ( OPB_1);
                        RES <= mul_result;
                    end
          4'b1011: begin

                        signed_sum = $signed(OPA_1) + $signed(OPB_1);
                    RES <= signed_sum[WIDTH-1:0];


                    if (!OPA_1[WIDTH-1] && !OPB_1[WIDTH-1]) begin
                        COUT <= signed_sum[WIDTH];
                    end else begin
                        COUT <= 1'b0;
                    end


                    if (OPA_1[WIDTH-1] == OPB_1[WIDTH-1]) begin
                        OFLOW <= (signed_sum[WIDTH-1] != OPA_1[WIDTH-1]) ? 1'b1 : 1'b0;
                    end else begin
                        OFLOW <= 1'b0;
                    end
                end

          4'b1100: begin
                        signed_sub = $signed(OPA_1) - $signed(OPB_1);
                        RES <= signed_sub[WIDTH-1:0];

                        if ((OPA_1[WIDTH-1] == 0 && OPB_1[WIDTH-1] == 1 && signed_sub[WIDTH-1] == 1) ||
                            (OPA_1[WIDTH-1] == 1 && OPB_1[WIDTH-1] == 0 && signed_sub[WIDTH-1] == 0)) begin
                            OFLOW <= 1'b1;
                        end else begin
                            OFLOW <= 1'b0;
                        end

                        COUT <= 1'b0;
                    end
         default:
                    begin
                    RES<={WIDTH{1'b0}};
                    COUT<=1'b0;
                    OFLOW<=1'b0;
                                             G<=1'b0;
                    E<=1'b0;
                    L<=1'b0;
                    ERR<=1'b1;
                    end
        endcase
        end
        else if(CE && MODE_1 && (IN_VALID_1 == 2'b01))begin
            RES<={2*WIDTH{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
        case (CMD_1)
        4'b0100:   RES<=OPA_1+1;
        4'b0101:   RES<=OPA_1-1;
        default:
                   begin
                   RES<='b0;
                   COUT<=1'b0;
                   OFLOW<=1'b0;
                   G<=1'b0;
                   E<=1'b0;
                   L<=1'b0;
                   ERR<=1'b1;
                   end
        endcase
        end

        else if(CE && MODE_1 && (IN_VALID_1 == 2'b10))begin
            RES<={2*WIDTH{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
        case (CMD_1)
        4'b0110:   RES<=OPB_1+1;
        4'b0111:   RES<=OPB_1-1;

        default:
                   begin
                   RES<='b0;
                   COUT<=1'b0;
                   OFLOW<=1'b0;
                   G<=1'b0;
                   E<=1'b0;
                   L<=1'b0;
                   ERR<=1'b1;
                   end
        endcase

    end

    else if(CE && !MODE_1 && (IN_VALID_1 == 2'b11))begin
        RES<={2*WIDTH{1'b0}};
           COUT<=1'b0;
           OFLOW<=1'b0;
           G<=1'b0;
           E<=1'b0;
           L<=1'b0;
           ERR<=1'b0;
           case(CMD_1)
        4'b0000:  RES<=pad_result ({1'b0, OPA_1 & OPB_1});
        4'b0001:  RES<=pad_result ({1'b0,~(OPA_1&OPB_1)});
        4'b0010:  RES<=pad_result ({1'b0,OPA_1|OPB_1});
        4'b0011:  RES<=pad_result ({1'b0,~(OPA_1|OPB_1)});
        4'b0100:  RES<=pad_result ({1'b0,OPA_1^OPB_1});
        4'b0101:  RES<=pad_result ({1'b0,~(OPA_1^OPB_1)});
        4'b1100:
                  begin
                  shift_val = OPB[shift_bits-1:0];
                  RES <= pad_result ({1'b0 , OPA_1 << shift_val | OPA_1 >> ( (WIDTH-1) - shift_val)});
                  ERR = (OPB_1 > WIDTH - 1)?1:0;
                  end

        4'b1101:
                  begin
                  shift_val = OPB[shift_bits-1:0];
                  RES <= pad_result ({1'b0 , OPA_1 >> shift_val | OPA_1 << ( (WIDTH-1) - shift_val)});
                  ERR = (OPB_1 > WIDTH - 1)?1:0;
                  end

        default:
                   begin
                   RES<='b0;
                   COUT<=1'b0;
                   OFLOW<=1'b0;
                   G<=1'b0;
                   E<=1'b0;
                   L<=1'b0;
                   ERR<=1'b1;
                   end
        endcase
        end
        else if(CE && !MODE_1 && (IN_VALID_1 == 2'b01))begin
            RES<={2*WIDTH{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
        case (CMD_1)
        4'b0110:  RES<=pad_result ({1'b0,~OPA_1});
        4'b1000:  RES<=pad_result ({1'b0,OPA_1>>1});
        4'b1001:  RES<=pad_result ({1'b0,OPA_1<<1});
                default:
                   begin
                   RES<='b0;
                   COUT<=1'b0;
                   OFLOW<=1'b0;
                   G<=1'b0;
                   E<=1'b0;
                   L<=1'b0;
                   ERR<=1'b1;
                   end

         endcase
        end

        else if(CE && !MODE && (IN_VALID_1 == 2'b10))begin
            RES<={2*WIDTH{1'b0}};
            COUT<=1'b0;
            OFLOW<=1'b0;
            G<=1'b0;
            E<=1'b0;
            L<=1'b0;
            ERR<=1'b0;
        case (CMD_1)
        4'b0110:  RES<=pad_result ({1'b0,~OPB_1});
        4'b1000:  RES<=pad_result ({1'b0,OPB_1>>1});
        4'b1001:  RES<=pad_result ({1'b0,OPB_1<<1});
        default:
                   begin
                   RES<='b0;
                   COUT<=1'b0;
                   OFLOW<=1'b0;
                   G<=1'b0;
                   E<=1'b0;
                   L<=1'b0;
                   ERR<=1'b1;
                   end

         endcase
        end

    end
endmodule
