module top_level_forwarding_tb();
    
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
wire fwd, fwd_rdy;
wire [4:0] current;
wire [23:0] bid;
    
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
assign bid=top_level.lq.bid;
assign current=top_level.lq.current;





    initial begin
    clk=0;
    forever
    #1 clk = ~clk;
end
    
initial begin
rst=0;
loop_strt=0;
@(negedge clk);
rst=1;
flsh=0;
fnsh_unrll=0;
mis_pred_ld_ptr=0;
mis_pred_str_ptr=0;
cmmt_ld_ptr=0;

cmmt_str=0;
data_str=0;
indx_str_al=32'b00000000_00000000_10000100_10000010;
indx_ld_al=0;
mem_wrt=0;
mem_rd=0;
indx_ls=0;
addr_ls=0;
phy_addr_ld_in=0;
@(negedge clk);
indx_str_al=0;
indx_ld_al=32'b00000000_00000000_10000111_10000101;
@(negedge clk);
mem_rd=1;
addr_ls=1;
indx_ls=5;
phy_addr_ld_in=14;
indx_ld_al=0;
@(negedge clk);
mem_wrt=1;
indx_ls=2;
addr_ls=16'h0000;
data_str=16'haaaa;
mem_rd=0;
@(negedge clk);
mem_wrt=0;
mem_rd=1;
indx_ls=7;
addr_ls=0;
phy_addr_ld_in=18;
@(negedge clk);
mem_rd=0;
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
@(negedge clk);
mem_wrt=1;
indx_ls=4;
addr_ls=1;
data_str=16'hbbbb;
@(negedge clk);
mem_wrt=0;

#100 $stop;
end


endmodule

