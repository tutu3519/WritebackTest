module load_queue(fnsh_unrll, clk,rst, mis_pred_ld_ptr, loop_strt, flsh, indx_ld_al, mem_rd, phy_addr_ld_in, indx_ls, addr_ls,
ld_grnt, done, data_sq, data_ca, fwd, fwd_rdy, ld_req, addr, reg_wrt_ld, phy_addr_ld,
data_ld, vld_ld, indx_ld,stll, indx_fwd, cmmt_ld_ptr);

// input and output ports declarations
input rst, clk, flsh, mem_rd, ld_grnt, done, fwd, fwd_rdy, fnsh_unrll,  loop_strt;
input [31:0] indx_ld_al;
input [4:0] mis_pred_ld_ptr, cmmt_ld_ptr;
input [5:0] phy_addr_ld_in, indx_ls;
input [15:0] addr_ls, data_ca, data_sq;
output vld_ld, reg_wrt_ld, stll, ld_req;
output [5:0] indx_ld, phy_addr_ld;
output [6:0] indx_fwd;
output [15:0] data_ld, addr;
wire [3:0] vld;
wire ld_rdy, loop_back; // indicate whether a load instruction is ready to execute
wire [4:0] nxt_head, nxt_tail, pre_head, cmmt_diff, loop_body_diff, flush_body_diff;
reg [41:0] ld_entry [0:23]; // load queue entries
reg [4:0] head, tail, current, pre_tail, pre_current, loop_end, loop_start;
reg busy, finished, loop_mode, pre_loop_strt;
integer i;
reg [23:0] update, // whether the corresponding entry needs update
            bid, // whether the corresponding load instruction is ready to execute
            shifted_bid, // shifted version of bid for priority decoding
            execute, // whether the corresponding entry 
            pre_commit,
            commit,
            loop_body,
            pre_loop_body,
            flush_body,
            pre_flush_body,
            first,
            second,
            third, 
            fourth;
wire [23:0] insert, pre_first, pre_second, pre_third, pre_fourth;
reg vld_ld, reg_wrt_ld, stored_fwd, ld_req ;
reg [15:0] stored_data_sq, stored_data_ca; // used to store data received from store queue and cache
reg [2:0] state, nxt_state; // state registers
wire [6:0] first_indx, second_indx, third_indx, fourth_indx;
wire [5:0] added_cmmt_ld_ptr, added_loop_end, added_tail;
wire cmmt_round_up, loop_round_up, flush_round_up, cmmt;

assign first_indx=indx_ld_al[6:0];
assign second_indx=indx_ld_al[14:8];
assign third_indx=indx_ld_al[22:16];
assign fourth_indx=indx_ld_al[30:24];
assign cmmt= (cmmt_ld_ptr != head);
localparam IDLE=3'b000; // Idle state
localparam WAIT=3'b001; // Send request to load store arbitrator and wait
localparam ISSUED=3'b010; // Receive the grant signal and wait for incoming data
localparam MEM_RDY=3'b011; // Receive data from cache but pending data from store queue
localparam FWD_RDY=3'b100;  // Receive data and forwarding signal from store queue but pending data from cache
localparam BOTH_RDY=3'b101;
localparam WRITEBACK=3'b110; // Write loaded data back to physical register file

always@(posedge clk, negedge rst)
if (!rst)
   loop_start <= 0;
else if (loop_strt)
  loop_start <= tail;
else
  loop_start <= loop_start;

assign loop_back=loop_mode & cmmt & (cmmt_ld_ptr == loop_start);
  
always@(posedge clk, negedge rst)
if (!rst)
   loop_end <= 0;
else if (fnsh_unrll)
    loop_end <= nxt_tail-1;
else
   loop_end <= loop_end;
  
// tail pointer update
always@(posedge clk, negedge rst)
if (!rst)
   tail <= 0;
else if (flsh)
   tail <= mis_pred_ld_ptr;
else
   tail <= nxt_tail;
   
   
// head pointer udpate
always@(posedge clk, negedge rst)
if (!rst)
   head <= 0;
else
   head <= cmmt_ld_ptr;

   
   
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

//assign pre_head = head + cmmt_ld;
//assign nxt_head =  (pre_head > 23)? (pre_head-24) : pre_head; // need modification in loop-mode
assign cmmt_round_up=cmmt_ld_ptr < head;
assign loop_round_up=loop_end < loop_start;
assign added_cmmt_ld_ptr=cmmt_ld_ptr+24;
assign added_loop_end=loop_end+24;
assign cmmt_diff=(cmmt_round_up) ? (added_cmmt_ld_ptr - head) : (cmmt_ld_ptr - head); // round up
assign loop_body_diff= (loop_round_up) ? (added_loop_end-loop_start+1) : (loop_end - loop_start+1);
assign flush_round_up=tail < mis_pred_ld_ptr;
assign added_tail=tail+24;
assign flush_body_diff=(flush_round_up) ? (added_tail-mis_pred_ld_ptr) : (tail-mis_pred_ld_ptr);
always@(cmmt_diff)
case(cmmt_diff)
    5'd0: pre_commit=0;
    5'd1: pre_commit=24'h000001;
    5'd2: pre_commit=24'h000003;
    5'd3: pre_commit=24'h000007;
    5'd4: pre_commit=24'h00000f;
    5'd5: pre_commit=24'h00001f;
    5'd6: pre_commit=24'h00003f;
    5'd7: pre_commit=24'h00007f;
    5'd8: pre_commit=24'h0000ff;
    5'd9: pre_commit=24'h0001ff;
    5'd10: pre_commit=24'h0003ff;
    5'd11: pre_commit=24'h0007ff;
    5'd12: pre_commit=24'h000fff;
    5'd13: pre_commit=24'h001fff;
    5'd14: pre_commit=24'h003fff;
    5'd15: pre_commit=24'h007fff;
    5'd16: pre_commit=24'h00ffff;
    5'd17: pre_commit=24'h01ffff;
    5'd18: pre_commit=24'h03ffff;
    5'd19: pre_commit=24'h07ffff;
    5'd20: pre_commit=24'h0fffff;
    5'd21: pre_commit=24'h1fffff;
    5'd22: pre_commit=24'h3fffff;
    5'd23: pre_commit=24'h7fffff;
    5'd24: pre_commit=24'hffffff;
    default: pre_commit=0;
endcase



always@(*)
case(head)
    5'd0: commit = pre_commit;
    5'd1: commit={pre_commit[22:0],pre_commit[23]};
    5'd2: commit={pre_commit[21:0],pre_commit[23:22]};
    5'd3: commit={pre_commit[20:0],pre_commit[23:21]};
    5'd4: commit={pre_commit[19:0],pre_commit[23:20]};
    5'd5: commit={pre_commit[18:0],pre_commit[23:19]};
    5'd6: commit={pre_commit[17:0],pre_commit[23:18]};
    5'd7: commit={pre_commit[16:0],pre_commit[23:17]};
    5'd8: commit={pre_commit[15:0],pre_commit[23:16]};
    5'd9: commit={pre_commit[14:0],pre_commit[23:15]};
    5'd10: commit={pre_commit[13:0],pre_commit[23:14]};
    5'd11: commit={pre_commit[12:0],pre_commit[23:13]};
    5'd12: commit={pre_commit[11:0],pre_commit[23:12]};
    5'd13: commit={pre_commit[10:0],pre_commit[23:11]};
    5'd14: commit={pre_commit[9:0],pre_commit[23:10]};
    5'd15: commit={pre_commit[8:0],pre_commit[23:9]};
    5'd16: commit={pre_commit[7:0],pre_commit[23:8]};
    5'd17: commit={pre_commit[6:0],pre_commit[23:7]};
    5'd18: commit={pre_commit[5:0],pre_commit[23:6]};
    5'd19: commit={pre_commit[4:0],pre_commit[23:5]};
    5'd20: commit={pre_commit[3:0],pre_commit[23:4]};
    5'd21: commit={pre_commit[2:0],pre_commit[23:3]};
    5'd22: commit={pre_commit[1:0],pre_commit[23:2]};
    5'd23: commit={pre_commit[0],pre_commit[23:1]};
    default: commit = 0;
endcase


always@(loop_body_diff)
case(loop_body_diff)
    5'd0: pre_loop_body=0;
    5'd1: pre_loop_body=24'h000001;
    5'd2: pre_loop_body=24'h000003;
    5'd3: pre_loop_body=24'h000007;
    5'd4: pre_loop_body=24'h00000f;
    5'd5: pre_loop_body=24'h00001f;
    5'd6: pre_loop_body=24'h00003f;
    5'd7: pre_loop_body=24'h00007f;
    5'd8: pre_loop_body=24'h0000ff;
    5'd9: pre_loop_body=24'h0001ff;
    5'd10: pre_loop_body=24'h0003ff;
    5'd11: pre_loop_body=24'h0007ff;
    5'd12: pre_loop_body=24'h000fff;
    5'd13: pre_loop_body=24'h001fff;
    5'd14: pre_loop_body=24'h003fff;
    5'd15: pre_loop_body=24'h007fff;
    5'd16: pre_loop_body=24'h00ffff;
    5'd17: pre_loop_body=24'h01ffff;
    5'd18: pre_loop_body=24'h03ffff;
    5'd19: pre_loop_body=24'h07ffff;
    5'd20: pre_loop_body=24'h0fffff;
    5'd21: pre_loop_body=24'h1fffff;
    5'd22: pre_loop_body=24'h3fffff;
    5'd23: pre_loop_body=24'h7fffff;
    5'd24: pre_loop_body=24'hffffff;
    default: pre_loop_body=0;
endcase





always@(*) 
case(loop_start)
    5'd0: loop_body = pre_loop_body;
    5'd1: loop_body={pre_loop_body[22:0],pre_loop_body[23]};
    5'd2: loop_body={pre_loop_body[21:0],pre_loop_body[23:22]};
    5'd3: loop_body={pre_loop_body[20:0],pre_loop_body[23:21]};
    5'd4: loop_body={pre_loop_body[19:0],pre_loop_body[23:20]};
    5'd5: loop_body={pre_loop_body[18:0],pre_loop_body[23:19]};
    5'd6: loop_body={pre_loop_body[17:0],pre_loop_body[23:18]};
    5'd7: loop_body={pre_loop_body[16:0],pre_loop_body[23:17]};
    5'd8: loop_body={pre_loop_body[15:0],pre_loop_body[23:16]};
    5'd9: loop_body={pre_loop_body[14:0],pre_loop_body[23:15]};
    5'd10: loop_body={pre_loop_body[13:0],pre_loop_body[23:14]};
    5'd11: loop_body={pre_loop_body[12:0],pre_loop_body[23:13]};
    5'd12: loop_body={pre_loop_body[11:0],pre_loop_body[23:12]};
    5'd13: loop_body={pre_loop_body[10:0],pre_loop_body[23:11]};
    5'd14: loop_body={pre_loop_body[9:0],pre_loop_body[23:10]};
    5'd15: loop_body={pre_loop_body[8:0],pre_loop_body[23:9]};
    5'd16: loop_body={pre_loop_body[7:0],pre_loop_body[23:8]};
    5'd17: loop_body={pre_loop_body[6:0],pre_loop_body[23:7]};
    5'd18: loop_body={pre_loop_body[5:0],pre_loop_body[23:6]};
    5'd19: loop_body={pre_loop_body[4:0],pre_loop_body[23:5]};
    5'd20: loop_body={pre_loop_body[3:0],pre_loop_body[23:4]};
    5'd21: loop_body={pre_loop_body[2:0],pre_loop_body[23:3]};
    5'd22: loop_body={pre_loop_body[1:0],pre_loop_body[23:2]};
    5'd23: loop_body={pre_loop_body[0],pre_loop_body[23:1]};
    default: loop_body = 0;
endcase
always@(flush_body_diff)
case(flush_body_diff)
    5'd0: pre_flush_body=0;
    5'd1: pre_flush_body=24'h000001;
    5'd2: pre_flush_body=24'h000003;
    5'd3: pre_flush_body=24'h000007;
    5'd4: pre_flush_body=24'h00000f;
    5'd5: pre_flush_body=24'h00001f;
    5'd6: pre_flush_body=24'h00003f;
    5'd7: pre_flush_body=24'h00007f;
    5'd8: pre_flush_body=24'h0000ff;
    5'd9: pre_flush_body=24'h0001ff;
    5'd10: pre_flush_body=24'h0003ff;
    5'd11: pre_flush_body=24'h0007ff;
    5'd12: pre_flush_body=24'h000fff;
    5'd13: pre_flush_body=24'h001fff;
    5'd14: pre_flush_body=24'h003fff;
    5'd15: pre_flush_body=24'h007fff;
    5'd16: pre_flush_body=24'h00ffff;
    5'd17: pre_flush_body=24'h01ffff;
    5'd18: pre_flush_body=24'h03ffff;
    5'd19: pre_flush_body=24'h07ffff;
    5'd20: pre_flush_body=24'h0fffff;
    5'd21: pre_flush_body=24'h1fffff;
    5'd22: pre_flush_body=24'h3fffff;
    5'd23: pre_flush_body=24'h7fffff;
    5'd24: pre_flush_body=24'hffffff;
    default: pre_flush_body=0;
endcase
always@(*) 
case(mis_pred_ld_ptr)
    5'd0: flush_body = pre_flush_body;
    5'd1: flush_body={pre_flush_body[22:0],pre_flush_body[23]};
    5'd2: flush_body={pre_flush_body[21:0],pre_flush_body[23:22]};
    5'd3: flush_body={pre_flush_body[20:0],pre_flush_body[23:21]};
    5'd4: flush_body={pre_flush_body[19:0],pre_flush_body[23:20]};
    5'd5: flush_body={pre_flush_body[18:0],pre_flush_body[23:19]};
    5'd6: flush_body={pre_flush_body[17:0],pre_flush_body[23:18]};
    5'd7: flush_body={pre_flush_body[16:0],pre_flush_body[23:17]};
    5'd8: flush_body={pre_flush_body[15:0],pre_flush_body[23:16]};
    5'd9: flush_body={pre_flush_body[14:0],pre_flush_body[23:15]};
    5'd10: flush_body={pre_flush_body[13:0],pre_flush_body[23:14]};
    5'd11: flush_body={pre_flush_body[12:0],pre_flush_body[23:13]};
    5'd12: flush_body={pre_flush_body[11:0],pre_flush_body[23:12]};
    5'd13: flush_body={pre_flush_body[10:0],pre_flush_body[23:11]};
    5'd14: flush_body={pre_flush_body[9:0],pre_flush_body[23:10]};
    5'd15: flush_body={pre_flush_body[8:0],pre_flush_body[23:9]};
    5'd16: flush_body={pre_flush_body[7:0],pre_flush_body[23:8]};
    5'd17: flush_body={pre_flush_body[6:0],pre_flush_body[23:7]};
    5'd18: flush_body={pre_flush_body[5:0],pre_flush_body[23:6]};
    5'd19: flush_body={pre_flush_body[4:0],pre_flush_body[23:5]};
    5'd20: flush_body={pre_flush_body[3:0],pre_flush_body[23:4]};
    5'd21: flush_body={pre_flush_body[2:0],pre_flush_body[23:3]};
    5'd22: flush_body={pre_flush_body[1:0],pre_flush_body[23:2]};
    5'd23: flush_body={pre_flush_body[0],pre_flush_body[23:1]};
    default: flush_body = 0;
endcase



 assign vld={indx_ld_al[31], indx_ld_al[23], indx_ld_al[15], indx_ld_al[7]};  
// Determine the next position for tail according to incoming valid load instruction count
always@(vld, tail)
   case (vld)
       4'b0000: pre_tail = tail;
       4'b0001: pre_tail = tail+1;
       4'b0011: pre_tail = tail+2;
       4'b0111: pre_tail = tail+3;
       4'b1111: pre_tail = tail+4;
       default: pre_tail = tail;
   endcase
   
assign nxt_tail=(pre_tail > 23)? (pre_tail-24) : pre_tail; // need modification in loop-mode  
  
assign stll= (!ld_entry[tail][41]); 




assign pre_first={23'h000000, indx_ld_al[7]};
assign pre_second={22'h000000, indx_ld_al[15], 1'b0};
assign pre_third={21'h000000, indx_ld_al[23], 2'b00};
assign pre_fourth={20'h00000, indx_ld_al[31], 3'b000};

always@(*)
case(tail)
    5'd0: first = pre_first;
    5'd1: first={pre_first[22:0],pre_first[23]};
    5'd2: first={pre_first[21:0],pre_first[23:22]};
    5'd3: first={pre_first[20:0],pre_first[23:21]};
    5'd4: first={pre_first[19:0],pre_first[23:20]};
    5'd5: first={pre_first[18:0],pre_first[23:19]};
    5'd6: first={pre_first[17:0],pre_first[23:18]};
    5'd7: first={pre_first[16:0],pre_first[23:17]};
    5'd8: first={pre_first[15:0],pre_first[23:16]};
    5'd9: first={pre_first[14:0],pre_first[23:15]};
    5'd10: first={pre_first[13:0],pre_first[23:14]};
    5'd11: first={pre_first[12:0],pre_first[23:13]};
    5'd12: first={pre_first[11:0],pre_first[23:12]};
    5'd13: first={pre_first[10:0],pre_first[23:11]};
    5'd14: first={pre_first[9:0],pre_first[23:10]};
    5'd15: first={pre_first[8:0],pre_first[23:9]};
    5'd16: first={pre_first[7:0],pre_first[23:8]};
    5'd17: first={pre_first[6:0],pre_first[23:7]};
    5'd18: first={pre_first[5:0],pre_first[23:6]};
    5'd19: first={pre_first[4:0],pre_first[23:5]};
    5'd20: first={pre_first[3:0],pre_first[23:4]};
    5'd21: first={pre_first[2:0],pre_first[23:3]};
    5'd22: first={pre_first[1:0],pre_first[23:2]};
    5'd23: first={pre_first[0],pre_first[23:1]};
    default: first = 0;
endcase

always@(*)
case(tail)
    5'd0: second = pre_second;
    5'd1: second={pre_second[22:0],pre_second[23]};
    5'd2: second={pre_second[21:0],pre_second[23:22]};
    5'd3: second={pre_second[20:0],pre_second[23:21]};
    5'd4: second={pre_second[19:0],pre_second[23:20]};
    5'd5: second={pre_second[18:0],pre_second[23:19]};
    5'd6: second={pre_second[17:0],pre_second[23:18]};
    5'd7: second={pre_second[16:0],pre_second[23:17]};
    5'd8: second={pre_second[15:0],pre_second[23:16]};
    5'd9: second={pre_second[14:0],pre_second[23:15]};
    5'd10: second={pre_second[13:0],pre_second[23:14]};
    5'd11: second={pre_second[12:0],pre_second[23:13]};
    5'd12: second={pre_second[11:0],pre_second[23:12]};
    5'd13: second={pre_second[10:0],pre_second[23:11]};
    5'd14: second={pre_second[9:0],pre_second[23:10]};
    5'd15: second={pre_second[8:0],pre_second[23:9]};
    5'd16: second={pre_second[7:0],pre_second[23:8]};
    5'd17: second={pre_second[6:0],pre_second[23:7]};
    5'd18: second={pre_second[5:0],pre_second[23:6]};
    5'd19: second={pre_second[4:0],pre_second[23:5]};
    5'd20: second={pre_second[3:0],pre_second[23:4]};
    5'd21: second={pre_second[2:0],pre_second[23:3]};
    5'd22: second={pre_second[1:0],pre_second[23:2]};
    5'd23: second={pre_second[0],pre_second[23:1]};
    default: second = 0;
endcase


always@(*)
case(tail)
    5'd0: third = pre_third;
    5'd1: third={pre_third[22:0],pre_third[23]};
    5'd2: third={pre_third[21:0],pre_third[23:22]};
    5'd3: third={pre_third[20:0],pre_third[23:21]};
    5'd4: third={pre_third[19:0],pre_third[23:20]};
    5'd5: third={pre_third[18:0],pre_third[23:19]};
    5'd6: third={pre_third[17:0],pre_third[23:18]};
    5'd7: third={pre_third[16:0],pre_third[23:17]};
    5'd8: third={pre_third[15:0],pre_third[23:16]};
    5'd9: third={pre_third[14:0],pre_third[23:15]};
    5'd10: third={pre_third[13:0],pre_third[23:14]};
    5'd11: third={pre_third[12:0],pre_third[23:13]};
    5'd12: third={pre_third[11:0],pre_third[23:12]};
    5'd13: third={pre_third[10:0],pre_third[23:11]};
    5'd14: third={pre_third[9:0],pre_third[23:10]};
    5'd15: third={pre_third[8:0],pre_third[23:9]};
    5'd16: third={pre_third[7:0],pre_third[23:8]};
    5'd17: third={pre_third[6:0],pre_third[23:7]};
    5'd18: third={pre_third[5:0],pre_third[23:6]};
    5'd19: third={pre_third[4:0],pre_third[23:5]};
    5'd20: third={pre_third[3:0],pre_third[23:4]};
    5'd21: third={pre_third[2:0],pre_third[23:3]};
    5'd22: third={pre_third[1:0],pre_third[23:2]};
    5'd23: third={pre_third[0],pre_third[23:1]};
    default: third = 0;
endcase


always@(*)
case(tail)
    5'd0: fourth = pre_fourth;
    5'd1: fourth={pre_fourth[22:0],pre_fourth[23]};
    5'd2: fourth={pre_fourth[21:0],pre_fourth[23:22]};
    5'd3: fourth={pre_fourth[20:0],pre_fourth[23:21]};
    5'd4: fourth={pre_fourth[19:0],pre_fourth[23:20]};
    5'd5: fourth={pre_fourth[18:0],pre_fourth[23:19]};
    5'd6: fourth={pre_fourth[17:0],pre_fourth[23:18]};
    5'd7: fourth={pre_fourth[16:0],pre_fourth[23:17]};
    5'd8: fourth={pre_fourth[15:0],pre_fourth[23:16]};
    5'd9: fourth={pre_fourth[14:0],pre_fourth[23:15]};
    5'd10: fourth={pre_fourth[13:0],pre_fourth[23:14]};
    5'd11: fourth={pre_fourth[12:0],pre_fourth[23:13]};
    5'd12: fourth={pre_fourth[11:0],pre_fourth[23:12]};
    5'd13: fourth={pre_fourth[10:0],pre_fourth[23:11]};
    5'd14: fourth={pre_fourth[9:0],pre_fourth[23:10]};
    5'd15: fourth={pre_fourth[8:0],pre_fourth[23:9]};
    5'd16: fourth={pre_fourth[7:0],pre_fourth[23:8]};
    5'd17: fourth={pre_fourth[6:0],pre_fourth[23:7]};
    5'd18: fourth={pre_fourth[5:0],pre_fourth[23:6]};
    5'd19: fourth={pre_fourth[4:0],pre_fourth[23:5]};
    5'd20: fourth={pre_fourth[3:0],pre_fourth[23:4]};
    5'd21: fourth={pre_fourth[2:0],pre_fourth[23:3]};
    5'd22: fourth={pre_fourth[1:0],pre_fourth[23:2]};
    5'd23: fourth={pre_fourth[0],pre_fourth[23:1]};
    default: fourth = 0;
endcase

always@(*)
for (i=0;i<24;i=i+1)
   update[i]= mem_rd & (!ld_entry[i][41]) & (indx_ls == ld_entry[i][37:32]);
   
   
assign insert = first | second | third | fourth;

always@(posedge clk, negedge rst)
   for (i=0;i<24;i=i+1) begin
       if (!rst)
          ld_entry[i][41:0] <= 42'h20000000000;
       else begin
          if (update[i]) begin
              ld_entry[i][15:0] <= phy_addr_ld_in; // update physical register address field
              ld_entry[i][31:16] <= addr_ls; // update memory address field
           end
           
           else begin
              ld_entry[i][15:0] <= ld_entry[i][15:0]; 
              ld_entry[i][31:16] <= ld_entry[i][31:16]; 
           end
           
           if (first[i])
              ld_entry[i][38:32] <= first_indx;
           else if (second[i])
              ld_entry[i][38:32] <= second_indx;
           else if (third[i])
              ld_entry[i][38:32] <= third_indx;
           else if (fourth[i])
              ld_entry[i][38:32] <= fourth_indx;
           else
              ld_entry[i][38:32] <= ld_entry[i][38:32];
                   
           // state bits
           if (flush_body[i] & flsh)
              ld_entry[i][41] <= 1;
           else if (loop_body[i] & loop_back)
              ld_entry[i][41] <= 0;
           else if (commit[i] & cmmt)
              ld_entry[i][41] <= 1;
            else if (insert[i])
               ld_entry[i][41] <= 0;
            else
               ld_entry[i][41] <= ld_entry[i][41];
               
            if (commit[i] & cmmt)
               ld_entry[i][40] <= 0;
            else if (update[i])
               ld_entry[i][40] <= 1;
            else
               ld_entry[i][40] <= ld_entry[i][40];
               
            if (commit[i] & cmmt)
               ld_entry[i][39] <= 0;
            else if (finished & execute[i])
               ld_entry[i][39] <= 1;
            else
               ld_entry[i][39] <= ld_entry[i][39];
               
               
               
       end
   end
      
    
// execute load
always@(*)
   for (i=0;i<24;i=i+1)
      bid[i]= (~busy) & (~ld_entry[i][41]) & (~ld_entry[i][39]) & (ld_entry[i][40]); // find ready load that has not been done
 
assign ld_rdy= |bid ;      

// Order the bids from head
always@(bid, head)
   case(head)
       5'h0:shifted_bid=bid;
       5'h01:shifted_bid={bid[0],bid[23:1]};
       5'h02:shifted_bid={bid[1:0],bid[23:2]};
       5'h03:shifted_bid={bid[2:0],bid[23:3]};
       5'h04:shifted_bid={bid[3:0],bid[23:4]};
       5'h05:shifted_bid={bid[4:0],bid[23:5]};
       5'h06:shifted_bid={bid[5:0],bid[23:6]};
       5'h07:shifted_bid={bid[6:0],bid[23:7]};
       5'h08:shifted_bid={bid[7:0],bid[23:8]};
       5'h09:shifted_bid={bid[8:0],bid[23:9]};
       5'h0a:shifted_bid={bid[9:0],bid[23:10]};
       5'h0b:shifted_bid={bid[10:0],bid[23:11]};
       5'h0c:shifted_bid={bid[11:0],bid[23:12]};
       5'h0d:shifted_bid={bid[12:0],bid[23:13]};
       5'h0e:shifted_bid={bid[13:0],bid[23:14]};
       5'h0f:shifted_bid={bid[14:0],bid[23:15]};
       5'h10:shifted_bid={bid[15:0],bid[23:16]};
       5'h11:shifted_bid={bid[16:0],bid[23:17]};
       5'h12:shifted_bid={bid[17:0],bid[23:18]};
       5'h13:shifted_bid={bid[18:0],bid[23:19]};
       5'h14:shifted_bid={bid[19:0],bid[23:20]};
       5'h15:shifted_bid={bid[20:0],bid[23:21]};
       5'h16:shifted_bid={bid[21:0],bid[23:22]};
       5'h17:shifted_bid={bid[22:0],bid[23]};
       default: shifted_bid=bid;
   endcase

// Priority decoding to find the oldest ready load for execution   
always@(shifted_bid)
   casex(shifted_bid)
       24'h0: pre_current = head;
       24'b???????????????????????1: pre_current=head; // 
       24'b??????????????????????10: pre_current=head+1; // 
       24'b?????????????????????100: pre_current=head+2; // 
       24'b????????????????????1000: pre_current=head+3; // 
       24'b???????????????????10000: pre_current=head+4; //
       24'b??????????????????100000: pre_current=head+5; // 
       24'b?????????????????1000000: pre_current=head+6; // 
       24'b????????????????10000000: pre_current=head+7; // 
       24'b???????????????100000000: pre_current=head+8; // 
       24'b??????????????1000000000: pre_current=head+9; // 
       24'b?????????????10000000000: pre_current=head+10; // 
       24'b????????????100000000000: pre_current=head+11; // 
       24'b???????????1000000000000: pre_current=head+12; // 
       24'b??????????10000000000000: pre_current=head+13; // 
       24'b?????????100000000000000: pre_current=head+14; // 
       24'b????????1000000000000000: pre_current=head+15; // 
       24'b???????10000000000000000: pre_current=head+16; // 
       24'b??????100000000000000000: pre_current=head+17; // 
       24'b?????1000000000000000000: pre_current=head+18; // 
       24'b????10000000000000000000: pre_current=head+19; // 
       24'b???100000000000000000000: pre_current=head+20; // 
       24'b??1000000000000000000000: pre_current=head+21; // 
       24'b?10000000000000000000000: pre_current=head+22; // 
       24'b100000000000000000000000: pre_current=head+23; //
       default: pre_current = head;
endcase

// Round-up update of current pointer
always@(posedge clk, negedge rst)
if (!rst)
  current <= 0;
 else if (busy)
    current <= current;
else if (pre_current > 23)
      current <= pre_current-24;
else 
      current <= pre_current;
      
always@(current)
case(current)
    5'd0: execute = 24'h000001;
    5'd1: execute = 24'h000002;
    5'd2: execute = 24'h000004;
    5'd3: execute = 24'h000008;
    5'd4: execute = 24'h000010;
    5'd5: execute = 24'h000020;
    5'd6: execute = 24'h000040;
    5'd7: execute = 24'h000080;
    5'd8: execute = 24'h000100;
    5'd9: execute = 24'h000200;
    5'd10: execute = 24'h000400;
    5'd11: execute = 24'h000800;
    5'd12: execute = 24'h001000;
    5'd13: execute = 24'h002000;
    5'd14: execute = 24'h004000;
    5'd15: execute = 24'h008000;
    5'd16: execute = 24'h010000;
    5'd17: execute = 24'h020000;
    5'd18: execute = 24'h040000;
    5'd19: execute = 24'h080000;
    5'd20: execute = 24'h100000;
    5'd21: execute = 24'h200000;
    5'd22: execute = 24'h400000;
    5'd23: execute = 24'h800000;
    default: execute = 0;
endcase

always@(posedge clk, negedge rst)
if (!rst)
   stored_fwd <= 0;
else if (fwd_rdy)
  stored_fwd <= fwd;
else
   stored_fwd <= stored_fwd;
   
always@(posedge clk, negedge rst)
if (!rst)
   stored_data_sq <= 0;
 else if (fwd_rdy)
   stored_data_sq <= data_sq;
else
   stored_data_sq <= stored_data_sq;
 
always@(posedge clk, negedge rst)
if (!rst)
   stored_data_ca <= 0;
 else if (done)
   stored_data_ca <= data_ca;
else
   stored_data_ca <= stored_data_ca;

    
assign addr=ld_entry[current][31:16];
assign data_ld = stored_fwd? stored_data_sq: stored_data_ca;
assign phy_addr_ld=ld_entry[current][15:0];
assign indx_ld=ld_entry[current][37:32];
assign indx_fwd=ld_entry[current][38:32];

// State transition
always@(posedge clk, negedge rst)
if (!rst)
   state <= IDLE;
else
   state <= nxt_state;
   
// Control signals generation   
always@(ld_rdy, done, fwd_rdy, ld_grnt, state) begin
   ld_req=0;
   busy=0;
   reg_wrt_ld=0;
   vld_ld=0;
   finished=0;
   case(state)
       IDLE:
       if (ld_rdy) begin
            nxt_state=WAIT;
       end
       else
             nxt_state=IDLE;
    
       WAIT: begin
       ld_req=1; // Keep requesting
       if (ld_grnt) begin
           nxt_state=ISSUED;
       end
       else 
          nxt_state=WAIT;
       end
   
       ISSUED: begin
       busy=1;
       if (done & !fwd_rdy)
        nxt_state=MEM_RDY;
       else if (!done & fwd_rdy)
        nxt_state=FWD_RDY;
       else if (done & fwd_rdy)
        nxt_state=BOTH_RDY;
       else
        nxt_state=ISSUED;
       end
   
        FWD_RDY: begin
        busy=1;
        if (done)
          nxt_state=WRITEBACK;
        else
          nxt_state=FWD_RDY;
        end
      
        MEM_RDY: begin
        busy=1;
        if (fwd_rdy)
          nxt_state=WRITEBACK;
        else
          nxt_state=MEM_RDY; 
        end   
        
        BOTH_RDY: begin
           nxt_state=WRITEBACK;
           busy=1;
    end
    
        WRITEBACK: begin
        reg_wrt_ld=1;
        vld_ld=1;
        busy=1;
        finished=1;
        if (ld_rdy)
           nxt_state=WAIT;
        else
           nxt_state=IDLE;
        end
endcase
end

endmodule

