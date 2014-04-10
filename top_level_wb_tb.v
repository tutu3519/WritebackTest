module top_level_wb_tb();
    
reg clk, rst, flsh, mem_rd, cmmt_str, mem_wrt, fnsh_unrll, loop_strt;
reg [31:0] indx_ld_al, indx_str_al;
reg [15:0] data_str, addr_ls;
reg [3:0] mis_pred_str_ptr;
reg [5:0] indx_ls, phy_addr_ld_in;
reg [4:0] mis_pred_ld_ptr, cmmt_ld_ptr;
wire stll, str_iss, vld_ld, reg_wrt_ld;
wire [5:0] indx_ld, phy_addr_ld;
wire [15:0] data_ld;
wire [2:0] lq_state;
wire [1:0] sq_state, arbi_state;
wire fwd, fwd_rdy, victim, str_finished;
wire [5:0] indx_fwd;
 wire [15:0] addr_fwd; 
 wire [15:0] match, indx_comp, addr_comp, str_update, str_insert, str_commit, str_pre_lb; 
   wire [3:0] sq_head, sq_tail; 
   wire [4:0] lq_loop_start, lq_loop_end;
   wire [3:0] sq_loop_start, sq_loop_end;
   wire [23:0] ld_pre_lb, ld_update;
    
    top_level_wb top_level( .clk(clk),
                     .rst(rst),
                     .flsh(flsh),
							.mis_pred_ld_ptr(mis_pred_ld_ptr) , 
							 
							.indx_ld_al(indx_ld_al), 
					
							.mem_rd(mem_rd), 
							.phy_addr_ld_in(phy_addr_ld_in), 
							.mis_pred_str_ptr(mis_pred_str_ptr), 
							.cmmt_str(cmmt_str), 
							.indx_str_al(indx_str_al), 
					
							.mem_wrt(mem_wrt), 
							.data_str(data_str), 
							.indx_ls(indx_ls),
							.addr_ls(addr_ls),
							.fnsh_unrll(fnsh_unrll),
							.stll(stll),
						   .indx_ld(indx_ld),
							.vld_ld(vld_ld),
							.data_ld(data_ld),
							.phy_addr_ld(phy_addr_ld),
							.reg_wrt_ld(reg_wrt_ld),
							.str_iss(str_iss),
							.loop_strt(loop_strt),
							.cmmt_ld_ptr(cmmt_ld_ptr)
    );
    
assign lq_state=top_level.lq.state;
assign sq_state=top_level.sq.state;
assign arbi_state=top_level.lsa.state;
assign fwd=top_level.sq.fwd;
assign fwd_rdy=top_level.sq.fwd_rdy;
assign indx_fwd=top_level.sq.indx_fwd;
assign addr_fwd=top_level.sq.addr_fwd;
assign indx_comp=top_level.sq.indx_comp;
assign addr_comp=top_level.sq.addr_comp;
assign match=top_level.sq.match;
assign str_update=top_level.sq.update;
assign str_insert=top_level.sq.insert;
assign sq_head=top_level.sq.head;
assign sq_tail=top_level.sq.tail;
assign str_finished=top_level.sq.finished;
assign str_commit=top_level.sq.commit;
assign victim=top_level.mem_sys.ca.victim;  
assign lq_loop_start=top_level.lq.loop_start;
assign sq_loop_start=top_level.sq.loop_start;
assign lq_loop_end=top_level.lq.loop_end;
assign sq_loop_end=top_level.sq.loop_end; 
assign ld_pre_lb=top_level.lq.pre_loop_body;
assign str_pre_lb=top_level.sq.pre_loop_body;
assign ld_update=top_level.lq.update;
    initial begin
    clk=0;
    forever
    #1 clk = ~clk;
end
    
initial begin
rst=0;
loop_strt=0;
@(negedge clk);
loop_strt=1;
rst=1;
flsh=0;
fnsh_unrll=0;
mis_pred_ld_ptr=0;
mis_pred_str_ptr=0;
cmmt_ld_ptr=0;

cmmt_str=0;
data_str=0;
indx_ld_al=32'b00000000_00000000_10000011_10000001;
indx_str_al=32'b00000000_00000000_00000000_10000010;
mem_wrt=0;
mem_rd=0;
indx_ls=0;
addr_ls=0;
phy_addr_ld_in=0;
@(negedge clk);
fnsh_unrll=1;
loop_strt=0;
indx_ld_al=0;
indx_str_al=32'b00000000_00000000_00000000_10000101;
mem_rd=1;
indx_ls=1;
phy_addr_ld_in=37;
addr_ls=0;
@(negedge clk);
fnsh_unrll=0;
indx_str_al=0;
mem_rd=0;
mem_wrt=1;
addr_ls=0;
indx_ls=2;
data_str=16'hffff;

@(negedge clk);

cmmt_str=1;
mem_rd=1;
mem_wrt=0;
addr_ls=0;
phy_addr_ld_in=28;
indx_ls=3;
@(negedge clk);
cmmt_str=0;
mem_wrt=1;
mem_rd=0;
addr_ls=16'h0000;
indx_ls=5;
data_str=16'h0101;
@(negedge clk);
mem_wrt=0;
#100 $stop;
end

  
    
    
    
    
endmodule
