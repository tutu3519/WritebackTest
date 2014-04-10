module store_queue(fnsh_unrll, loop_strt, clk,rst, mis_pred_str_ptr, cmmt_str, flsh, addr_fwd, indx_fwd, indx_str_al,ld_grnt,
                     mem_wrt, data_str, indx_ls, addr_ls, str_grnt, done, str_req,
                     str_iss, stll, fwd, fwd_rdy, addr, data_ca, data_fwd);
                     
// input and output ports declarations
input rst, mem_wrt, flsh, clk, cmmt_str, done, str_grnt, ld_grnt, fnsh_unrll, loop_strt;
input [31:0] indx_str_al;
input [3:0] mis_pred_str_ptr;
input [15:0] data_str, addr_ls, addr_fwd;
input [5:0] indx_ls;
input [6:0] indx_fwd;
output str_req, str_iss, fwd, fwd_rdy, stll;
output  [15:0] data_ca, addr, data_fwd;

reg str_req, str_iss, finished, loop_mode, pre_loop_strt;
reg [40:0] str_entry [0:15]; // store queue entries
reg [15:0] indx_comp, // used to tell whether the corresponding store occurs before the load being executed
            update, // indicate whether there is an index match for address and data update in the store queue entry
            ready, // indicate whether all stores occurring before the load being executed have memory addresses updated
            addr_comp, // indicate whether an address match occurs between the store and load to trigger data forwarding
            match, // indicate whether the corresponding store is a candidate for data forwarding
            shifted_match, // reordered match start from head
            first,
            second,
            third,
            fourth, 
            commit,
            loop_body,
            pre_loop_body, 
            flush_body,
            pre_flush_body;
reg [3:0] head, tail,  nxt_tail, indx_to_fwd, loop_start, loop_end;
wire [4:0] loop_body_diff, flush_body_diff;
wire [3:0] vld;
integer i;
reg [1:0] state,nxt_state; // state registers
wire [15:0] data_to_fwd; 
wire [6:0] first_indx, second_indx, third_indx, fourth_indx;
wire [15:0] pre_first, pre_second, pre_third, pre_fourth, insert;
wire no_wait, loop_round_up, loop_back, flush_round_up;
wire [4:0] added_loop_end, added_tail;

localparam IDLE=2'b00;
localparam WAIT_TWO=2'b01; // wait for the grant signal
localparam ISSUED=2'b10;
localparam WAIT_ONE=2'b11; // wait for the store to be ready

assign first_indx=indx_str_al[6:0];
assign second_indx=indx_str_al[14:8];
assign third_indx=indx_str_al[22:16];
assign fourth_indx=indx_str_al[30:24];


always@(posedge clk, negedge rst)
if (!rst)
   loop_start <= 0;
else if (loop_strt)
  loop_start <= tail;
else
  loop_start <= loop_start;
  
  
always@(posedge clk, negedge rst)
if (!rst)
   loop_end <= 0;
else if (fnsh_unrll)
    loop_end <= nxt_tail-1;
else
   loop_end <= loop_end;
   
// tail pointer update
always@(posedge clk,negedge rst)
if (!rst)
   tail <= 0;
else if (flsh)
   tail <= mis_pred_str_ptr;
else
   tail <= nxt_tail;
   
   
always@(posedge clk, negedge rst)
if (!rst)
   pre_loop_strt <= 0;
else
   pre_loop_strt <= loop_strt;
   
assign strt_rise=(!pre_loop_strt) & loop_strt;
always@(posedge clk, negedge rst)
if (!rst)
   loop_mode <= 0;
else if (strt_rise)
   loop_mode <= 1;
else if (flsh)
   loop_mode <= 0;
else
   loop_mode <= loop_mode;
   
assign vld={indx_str_al[31], indx_str_al[23], indx_str_al[15], indx_str_al[7]};
always@(vld, tail)
   case (vld)
       4'b0000: nxt_tail = tail;
       4'b0001: nxt_tail = tail+1;
       4'b0011: nxt_tail = tail+2;
       4'b0111: nxt_tail = tail+3;
       4'b1111: nxt_tail = tail+4;
       default: nxt_tail = tail;
   endcase
   
assign stll= (!str_entry[tail][40]); 


always@(posedge clk,negedge rst)
if (!rst)
   head <= 0;
else if (loop_back)
   head <= loop_start;
else if (finished)
   head <= head+1;
else
   head <= head;
   
assign loop_back= loop_mode & (head+1 > loop_end) & finished;   
assign no_wait=str_entry[head][39];

always@(head)
case(head)
    4'h0: commit = 16'h0001;
    4'h1: commit = 16'h0002;
    4'h2: commit = 16'h0004;
    4'h3: commit = 16'h0008;
    4'h4: commit = 16'h0010;
    4'h5: commit = 16'h0020;
    4'h6: commit = 16'h0040;
    4'h7: commit = 16'h0080;
    4'h8: commit = 16'h0100;
    4'h9: commit = 16'h0200;
    4'ha: commit = 16'h0400;
    4'hb: commit = 16'h0800;
    4'hc: commit = 16'h1000;
    4'hd: commit = 16'h2000;
    4'he: commit = 16'h4000;
    4'hf: commit = 16'h8000;
    default: commit=0;
endcase


assign loop_round_up=loop_end < loop_start;

assign added_loop_end=loop_end+24;

assign loop_body_diff= (loop_round_up) ? (added_loop_end-loop_start+1) : (loop_end - loop_start+1);

assign flush_round_up=tail < mis_pred_str_ptr;
assign added_tail=tail+24;
assign flush_body_diff= (flush_round_up) ? (added_tail-mis_pred_str_ptr) : (tail-mis_pred_str_ptr);
 
always@(loop_body_diff)
case(loop_body_diff)
    5'd0: pre_loop_body=0;
    5'd1: pre_loop_body=16'h0001;
    5'd2: pre_loop_body=16'h0003;
    5'd3: pre_loop_body=16'h0007;
    5'd4: pre_loop_body=16'h000f;
    5'd5: pre_loop_body=16'h001f;
    5'd6: pre_loop_body=16'h003f;
    5'd7: pre_loop_body=16'h007f;
    5'd8: pre_loop_body=16'h00ff;
    5'd9: pre_loop_body=16'h01ff;
    5'd10: pre_loop_body=16'h03ff;
    5'd11: pre_loop_body=16'h07ff;
    5'd12: pre_loop_body=16'h0fff;
    5'd13: pre_loop_body=16'h1fff;
    5'd14: pre_loop_body=16'h3fff;
    5'd15: pre_loop_body=16'h7fff;
    5'd16: pre_loop_body=16'hffff;
    default: pre_loop_body=0;
endcase





always@(*) 
case(loop_start)
    4'd0: loop_body = pre_loop_body;
    4'd1: loop_body={pre_loop_body[14:0],pre_loop_body[15]};
    4'd2: loop_body={pre_loop_body[13:0],pre_loop_body[15:14]};
    4'd3: loop_body={pre_loop_body[12:0],pre_loop_body[15:13]};
    4'd4: loop_body={pre_loop_body[11:0],pre_loop_body[15:12]};
    4'd5: loop_body={pre_loop_body[10:0],pre_loop_body[15:11]};
    4'd6: loop_body={pre_loop_body[9:0],pre_loop_body[15:10]};
    4'd7: loop_body={pre_loop_body[8:0],pre_loop_body[15:9]};
    4'd8: loop_body={pre_loop_body[7:0],pre_loop_body[15:8]};
    4'd9: loop_body={pre_loop_body[6:0],pre_loop_body[15:7]};
    4'd10: loop_body={pre_loop_body[5:0],pre_loop_body[15:6]};
    4'd11: loop_body={pre_loop_body[4:0],pre_loop_body[15:5]};
    4'd12: loop_body={pre_loop_body[3:0],pre_loop_body[15:4]};
    4'd13: loop_body={pre_loop_body[2:0],pre_loop_body[15:3]};
    4'd14: loop_body={pre_loop_body[1:0],pre_loop_body[15:2]};
    4'd15: loop_body={pre_loop_body[0],pre_loop_body[15:1]};
    default: loop_body = 0;
endcase
always@(flush_body_diff)
case(flush_body_diff)
    5'd0: pre_flush_body=0;
    5'd1: pre_flush_body=16'h0001;
    5'd2: pre_flush_body=16'h0003;
    5'd3: pre_flush_body=16'h0007;
    5'd4: pre_flush_body=16'h000f;
    5'd5: pre_flush_body=16'h001f;
    5'd6: pre_flush_body=16'h003f;
    5'd7: pre_flush_body=16'h007f;
    5'd8: pre_flush_body=16'h00ff;
    5'd9: pre_flush_body=16'h01ff;
    5'd10: pre_flush_body=16'h03ff;
    5'd11: pre_flush_body=16'h07ff;
    5'd12: pre_flush_body=16'h0fff;
    5'd13: pre_flush_body=16'h1fff;
    5'd14: pre_flush_body=16'h3fff;
    5'd15: pre_flush_body=16'h7fff;
    5'd16: pre_flush_body=16'hffff;
    default: pre_flush_body=0;
endcase





always@(*) 
case(mis_pred_str_ptr)
    4'd0: flush_body = pre_flush_body;
    4'd1: flush_body={pre_flush_body[14:0],pre_flush_body[15]};
    4'd2: flush_body={pre_flush_body[13:0],pre_flush_body[15:14]};
    4'd3: flush_body={pre_flush_body[12:0],pre_flush_body[15:13]};
    4'd4: flush_body={pre_flush_body[11:0],pre_flush_body[15:12]};
    4'd5: flush_body={pre_flush_body[10:0],pre_flush_body[15:11]};
    4'd6: flush_body={pre_flush_body[9:0],pre_flush_body[15:10]};
    4'd7: flush_body={pre_flush_body[8:0],pre_flush_body[15:9]};
    4'd8: flush_body={pre_flush_body[7:0],pre_flush_body[15:8]};
    4'd9: flush_body={pre_flush_body[6:0],pre_flush_body[15:7]};
    4'd10: flush_body={pre_flush_body[5:0],pre_flush_body[15:6]};
    4'd11: flush_body={pre_flush_body[4:0],pre_flush_body[15:5]};
    4'd12: flush_body={pre_flush_body[3:0],pre_flush_body[15:4]};
    4'd13: flush_body={pre_flush_body[2:0],pre_flush_body[15:3]};
    4'd14: flush_body={pre_flush_body[1:0],pre_flush_body[15:2]};
    4'd15: flush_body={pre_flush_body[0],pre_flush_body[15:1]};
    default: flush_body = 0;
endcase

assign pre_first={23'h000000, vld[0]};
assign pre_second={22'h000000, vld[1], 1'b0};
assign pre_third={21'h000000, vld[2], 2'b00};
assign pre_fourth={20'h00000, vld[3], 3'b000};

always@(*)
case(tail)
    4'd0: first = pre_first;
    4'd1: first={pre_first[14:0],pre_first[15]};
    4'd2: first={pre_first[13:0],pre_first[15:14]};
    4'd3: first={pre_first[12:0],pre_first[15:13]};
    4'd4: first={pre_first[11:0],pre_first[15:12]};
    4'd5: first={pre_first[10:0],pre_first[15:11]};
    4'd6: first={pre_first[9:0],pre_first[15:10]};
    4'd7: first={pre_first[8:0],pre_first[15:9]};
    4'd8: first={pre_first[7:0],pre_first[15:8]};
    4'd9: first={pre_first[6:0],pre_first[15:7]};
    4'd10: first={pre_first[5:0],pre_first[15:6]};
    4'd11: first={pre_first[4:0],pre_first[15:5]};
    4'd12: first={pre_first[3:0],pre_first[15:4]};
    4'd13: first={pre_first[2:0],pre_first[15:3]};
    4'd14: first={pre_first[1:0],pre_first[15:2]};
    4'd15: first={pre_first[0],pre_first[15:1]};
    default: first = 0;
endcase

always@(*)
case(tail)
    4'd0: second = pre_second;
    4'd1: second={pre_second[14:0],pre_second[15]};
    4'd2: second={pre_second[13:0],pre_second[15:14]};
    4'd3: second={pre_second[12:0],pre_second[15:13]};
    4'd4: second={pre_second[11:0],pre_second[15:12]};
    4'd5: second={pre_second[10:0],pre_second[15:11]};
    4'd6: second={pre_second[9:0],pre_second[15:10]};
    4'd7: second={pre_second[8:0],pre_second[15:9]};
    4'd8: second={pre_second[7:0],pre_second[15:8]};
    4'd9: second={pre_second[6:0],pre_second[15:7]};
    4'd10: second={pre_second[5:0],pre_second[15:6]};
    4'd11: second={pre_second[4:0],pre_second[15:5]};
    4'd12: second={pre_second[3:0],pre_second[15:4]};
    4'd13: second={pre_second[2:0],pre_second[15:3]};
    4'd14: second={pre_second[1:0],pre_second[15:2]};
    4'd15: second={pre_second[0],pre_second[15:1]};
    default: second = 0;
endcase

always@(*)
case(tail)
    4'd0: third = pre_third;
    4'd1: third={pre_third[14:0],pre_third[15]};
    4'd2: third={pre_third[13:0],pre_third[15:14]};
    4'd3: third={pre_third[12:0],pre_third[15:13]};
    4'd4: third={pre_third[11:0],pre_third[15:12]};
    4'd5: third={pre_third[10:0],pre_third[15:11]};
    4'd6: third={pre_third[9:0],pre_third[15:10]};
    4'd7: third={pre_third[8:0],pre_third[15:9]};
    4'd8: third={pre_third[7:0],pre_third[15:8]};
    4'd9: third={pre_third[6:0],pre_third[15:7]};
    4'd10: third={pre_third[5:0],pre_third[15:6]};
    4'd11: third={pre_third[4:0],pre_third[15:5]};
    4'd12: third={pre_third[3:0],pre_third[15:4]};
    4'd13: third={pre_third[2:0],pre_third[15:3]};
    4'd14: third={pre_third[1:0],pre_third[15:2]};
    4'd15: third={pre_third[0],pre_third[15:1]};
    default: third = 0;
endcase


always@(*)
case(tail)
    4'd0: fourth = pre_fourth;
    4'd1: fourth={pre_fourth[14:0],pre_fourth[15]};
    4'd2: fourth={pre_fourth[13:0],pre_fourth[15:14]};
    4'd3: fourth={pre_fourth[12:0],pre_fourth[15:13]};
    4'd4: fourth={pre_fourth[11:0],pre_fourth[15:12]};
    4'd5: fourth={pre_fourth[10:0],pre_fourth[15:11]};
    4'd6: fourth={pre_fourth[9:0],pre_fourth[15:10]};
    4'd7: fourth={pre_fourth[8:0],pre_fourth[15:9]};
    4'd8: fourth={pre_fourth[7:0],pre_fourth[15:8]};
    4'd9: fourth={pre_fourth[6:0],pre_fourth[15:7]};
    4'd10: fourth={pre_fourth[5:0],pre_fourth[15:6]};
    4'd11: fourth={pre_fourth[4:0],pre_fourth[15:5]};
    4'd12: fourth={pre_fourth[3:0],pre_fourth[15:4]};
    4'd13: fourth={pre_fourth[2:0],pre_fourth[15:3]};
    4'd14: fourth={pre_fourth[1:0],pre_fourth[15:2]};
    4'd15: fourth={pre_fourth[0],pre_fourth[15:1]};
    default: fourth = 0;
endcase

assign insert = first | second | third | fourth;

// entry update with physical register address and memory address
always@(*)
   for (i=0;i<16;i=i+1) 
      update[i]=mem_wrt & (str_entry[i][37:32] == indx_ls) & (!str_entry[i][40]);


always@(posedge clk, negedge rst)
for (i=0;i<16;i=i+1) begin
    if (!rst)
      str_entry[i][40:0] <= 41'h10000000000;
    else begin
       if (update[i]) begin
              str_entry[i][15:0] <= data_str; // update data to be stored into memory
              str_entry[i][31:16] <= addr_ls; // update memory address field
           end
           
           else begin
              str_entry[i][15:0] <= str_entry[i][15:0]; // 
              str_entry[i][31:16] <= str_entry[i][31:16]; // 
           end
           
           if (first[i])
              str_entry[i][38:32] <= first_indx;
           else if (second[i])
              str_entry[i][38:32] <= second_indx;
           else if (third[i])
              str_entry[i][38:32] <= third_indx;
           else if (fourth[i])
              str_entry[i][38:32] <= fourth_indx;
           else
              str_entry[i][38:32] <= str_entry[i][38:32];
                   
           // state bits
           if (flush_body[i] & flsh)
              str_entry[i][40] <= 1;
           else if (loop_body[i] & loop_back)
              str_entry[i][40] <= 0;
           else if (commit[i] & finished)
              str_entry[i][40] <= 1;
            else if (insert[i])
               str_entry[i][40] <= 0;
            else
               str_entry[i][40] <= str_entry[i][40];
               
            if (commit[i] & finished)
               str_entry[i][39] <= 0;
            else if (update[i])
               str_entry[i][39] <= 1;
            else
               str_entry[i][39] <= str_entry[i][39];
            
               
               
               
       end
   end
  
// execute upon commitment
always@(posedge clk, negedge rst)
if (!rst)
   state <= IDLE;
else
   state <= nxt_state;
   


   
assign addr=str_entry[head][31:16];
assign data_ca=str_entry[head][15:0];

always@(state, str_grnt, cmmt_str, done, no_wait)
begin
   str_req=0;
   str_iss=0;
   finished=0;
   case (state)
   IDLE:
   if (cmmt_str & no_wait) begin
       //str_req = 1;      
       nxt_state = WAIT_TWO;
   end
   else if (cmmt_str & (~no_wait)) begin
       nxt_state=WAIT_ONE;
   end
   else 
       nxt_state=IDLE;
       
   WAIT_ONE:
   if (no_wait)
      nxt_state=WAIT_TWO;
   else
      nxt_state=WAIT_ONE;
    
    WAIT_TWO:
    if (str_grnt) begin
       nxt_state= ISSUED;
       str_iss=1;
    end
    else begin
       str_req=1;
       nxt_state = WAIT_TWO;
    end
     
    ISSUED:
    if (done) begin
         finished=1;
         nxt_state = IDLE;
    end
    else 
        nxt_state=ISSUED;
 endcase
 end
       

assign signed_comp=str_entry[head][38]; // whether to compard the indexes in a signed manner
always@(*)
   for (i=0;i<16;i=i+1)
   if (signed_comp)
      indx_comp[i]=($signed(indx_fwd) > $signed(str_entry[i][38:32])) ? 1:0; 
   else
      indx_comp[i]= (indx_fwd > str_entry[i][38:32])? 1 : 0; 
      
      
always@(*)
   for (i=0;i<16;i=i+1)
      addr_comp[i]= (addr_fwd == str_entry[i][31:16]);
            
      
always@(*)
   for (i=0;i<16;i=i+1)
      ready[i]= str_entry[i][40] | (str_entry[i][39] & indx_comp[i]) | (~indx_comp[i]);
      

assign fwd_rdy=&ready;

always@(*)
   for (i=0;i<16;i=i+1)
      match[i]= (~str_entry[i][40]) & addr_comp[i] & indx_comp[i];
      
always@(match)
   case(head)
       4'h0:shifted_match=match;
       4'h1:shifted_match={match[0],match[15:1]};
       4'h2:shifted_match={match[1:0],match[15:2]};
       4'h3:shifted_match={match[2:0],match[15:3]};
       4'h4:shifted_match={match[3:0],match[15:4]};
       4'h5:shifted_match={match[4:0],match[15:5]};
       4'h6:shifted_match={match[5:0],match[15:6]};
       4'h7:shifted_match={match[6:0],match[15:7]};
       4'h8:shifted_match={match[7:0],match[15:8]};
       4'h9:shifted_match={match[8:0],match[15:9]};
       4'ha:shifted_match={match[9:0],match[15:10]};
       4'hb:shifted_match={match[10:0],match[15:11]};
       4'hc:shifted_match={match[11:0],match[15:12]};
       4'hd:shifted_match={match[12:0],match[15:13]};
       4'he:shifted_match={match[13:0],match[15:14]};
       4'hf:shifted_match={match[14:0],match[15]};
       default: shifted_match=match;
   endcase
   
// find the closest match for data forwarding     
always@(shifted_match)
   casex(shifted_match)
       16'h0: indx_to_fwd=0;
       16'b1???????????????: indx_to_fwd=head+15;
       16'b01??????????????: indx_to_fwd=head+14;
       16'b001?????????????: indx_to_fwd=head+13;
       16'b0001????????????: indx_to_fwd=head+12;
       16'b00001???????????: indx_to_fwd=head+11;
       16'b000001??????????: indx_to_fwd=head+10;
       16'b0000001?????????: indx_to_fwd=head+9;
       16'b00000001????????: indx_to_fwd=head+8;
       16'b000000001???????: indx_to_fwd=head+7;
       16'b0000000001??????: indx_to_fwd=head+6;
       16'b00000000001?????: indx_to_fwd=head+5;
       16'b000000000001????: indx_to_fwd=head+4;
       16'b0000000000001???: indx_to_fwd=head+3;
       16'b00000000000001??: indx_to_fwd=head+2;
       16'b000000000000001?: indx_to_fwd=head+1;
       16'h0001: indx_to_fwd=head;
     endcase
      
assign fwd=|match;
assign data_to_fwd = str_entry[indx_to_fwd][15:0];
assign data_fwd= fwd? data_to_fwd:16'h0000;   

endmodule    
 
                    
