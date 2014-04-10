module load_store_arbi(clk, rst, ld_req, str_req, idle, done, ld_grnt, str_grnt, enable, addr_sel, rd_wrt_ca);
// input and output ports declarations
input clk, rst, ld_req, str_req, idle, done;
output reg ld_grnt, str_grnt, enable, addr_sel, rd_wrt_ca;

reg [1:0] state, nxt_state; // state registers
assign ld=ld_req && idle && (!str_req); // a store request masks a load request
assign str=str_req && idle; 

localparam IDLE=2'b00; // idle state, open to accept load/store request
localparam STORE=2'b01; // grant a store request
localparam LOAD=2'b10; // grant a load request

always@(posedge clk, negedge rst)
if (!rst)
   state <= IDLE;
else
   state <= nxt_state;

always@(state, done, ld, str)
begin
ld_grnt=0;
str_grnt=0;
enable=0;
addr_sel=0;
rd_wrt_ca=0;
case (state)
    IDLE:
    if (str) 
    begin
       nxt_state=STORE;
       //str_grnt=1;
       //enable=1; // enable memory operation
       //addr_sel=1; // select the address of store
    end
    else if (ld) 
    begin
       nxt_state=LOAD;
       //ld_grnt=1;
       //enable=1; // enable memory operation
       //rd_wrt_ca=1; // select read operation
    end
    else
       nxt_state=IDLE;
       
    STORE:
    begin

       if (done) begin // write operation is completed
          if (str) begin
             nxt_state=STORE;
             //str_grnt=1;
          end
          else if (ld) begin
              nxt_state=LOAD;
              //ld_grnt=1;
           end   
        else 
              nxt_state=IDLE;
   end
   else begin
                  enable=1;
       addr_sel=1; 
       str_grnt=1; 
          nxt_state=STORE;
        end
    end
    
    LOAD:
    begin
 
       if (done) begin // read operation is completed
         if (str) begin
            nxt_state=STORE;
            //str_grnt=1;
        end
            else if (ld) begin
            nxt_state=LOAD;
            //ld_grnt=1;
        end
            else
            nxt_state=IDLE;
       end      
       else begin
                  enable=1;
       rd_wrt_ca=1;
       ld_grnt=1;
          nxt_state=LOAD;
    end
    end
endcase
end
endmodule
