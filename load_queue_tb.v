
module load_queue_tb();
    reg fnsh_unrll, 
          rst, 
          clk, 
          flsh, 
          mem_rd, 
          ld_grnt,
          done,
          fwd,
          fwd_rdy;
    reg [1:0]   lbd_state;
    reg [23:0] indx_ld_al;
    reg [3:0] vld_ld_al, cmmt_ld;
    reg [15:0] addr_ls, data_fwd, data_ca_out;
    reg [5:0] indx_ls, phy_addr_ld_in;
    reg [4:0] mis_pred_ld_ptr;
    
    wire ld_req, reg_wrt_ld, vld_ld, stll_ld;
    wire [15:0] addr_ld, data_ld;
    wire [5:0] indx_ld, indx_fwd, phy_addr_ld;
    wire [2:0] state;
    wire [23:0] update, insert,bid, commit, first, second, third, fourth, execute;
    wire [4:0] head,tail, current;
    load_queue lq(.fnsh_unrll(fnsh_unrll), .lbd_state(lbd_state), .rst(rst), .clk(clk), .flsh(flsh), .indx_ld_al(indx_ld_al), .vld_ld_al(vld_ld_al), .mem_rd(mem_rd),
               .phy_addr_ld_in(phy_addr_ld_in), .indx_ls(indx_ls), .addr_ls(addr_ls),
               .ld_grnt(ld_grnt), .done(done), .data_sq(data_fwd), .data_ca(data_ca_out),
               .fwd(fwd), .fwd_rdy(fwd_rdy), .ld_req(ld_req), .addr(addr_ld), .reg_wrt_ld(reg_wrt_ld),
               .phy_addr_ld(phy_addr_ld), .data_ld(data_ld), .vld_ld(vld_ld), .indx_ld(indx_ld), .stll(stll_ld),
               .mis_pred_ld_ptr(mis_pred_ld_ptr), .cmmt_ld(cmmt_ld), .indx_fwd(indx_fwd));
  assign state = lq.state; 
  assign update=lq.update;
  assign insert=lq.insert;
  assign commit=lq.commit;
  assign bid=lq.bid;  
  assign first=lq.first;
  assign second=lq.second;
  assign third=lq.third;
  assign fourth=lq.fourth; 
  assign execute=lq.execute;    
   assign head=lq.head;
   assign tail=lq.tail; 
   assign finished=lq.finished; 
   assign current=lq.current;      
    initial begin
        clk = 0;
        forever
        #1 clk = ~clk;
    end
    
    /* normal operation
    initial begin
    rst=0;
    @(negedge clk);
    rst=1;
    fnsh_unrll=0;
    lbd_state=2'b00;
    flsh=0;
    insert two loads
    indx_ld_al=24'b000000_000000_000011_000001;
    vld_ld_al=4'b0011;
    mem_rd=0;
    phy_addr_ld_in=6'b000000;
    indx_ls=6'b000000;
    addr_ls=16'h0000;
    ld_grnt=0;
    done=0;
    data_fwd=16'h0001;
    data_ca_out=16'h0000;
    fwd=0;
    fwd_rdy=0;
    mis_pred_ld_ptr=5'b00000;
    cmmt_ld=0;
    @(negedge clk);
    vld_ld_al=4'b0011;
    mem_rd=1;
    indx_ls=6'b000011;
    addr_ls=16'habcd;
    indx_ld_al=24'b000000_000000_000111_000100;
    @(negedge clk);
    vld_ld_al=4'b1111;
    indx_ld_al=24'b100000_010000_01101_001010;
    mem_rd=1;
    indx_ls=6'b000001;
    addr_ls=16'h0001;  
    @(negedge clk);
    vld_ld_al=4'b0000;
    mem_rd=1;
    ld_grnt=1;
    indx_ls=6'b000100;
    addr_ls=16'h0a00; 
    @(negedge clk);
    fwd=0;
    fwd_rdy=1;
    data_fwd=16'h1111;
    mem_rd=1;
     indx_ls=6'b000111;
    addr_ls=16'haa00; 
    @(negedge clk);
    mem_rd=0;
    done=1;
    data_ca_out=16'hffff;
    ld_grnt=0;
    @(posedge ld_req);
    @(negedge clk);
    ld_grnt=1;
    @(negedge clk);
    fwd=1;
    fwd_rdy=1;
    data_fwd=16'h1111;
    @(negedge clk);
    done=1;
    data_ca_out=16'hffff;
    ld_grnt=0; 
    @(negedge clk);
    cmmt_ld=4'd2;
    @(negedge clk);
    cmmt_ld=0;
    #10 $stop;
end
*/
//overflow
initial begin
    rst=0;
    @(negedge clk)
    rst=1;
    fnsh_unrll=0;
    lbd_state=2'b00;
    flsh=0;
    indx_ld_al=24'b000000_000000_000011_000001;
    vld_ld_al=4'b1111;
    mem_rd=0;
    phy_addr_ld_in=6'b000000;
    indx_ls=6'b000000;
    addr_ls=16'h0000;
    ld_grnt=0;
    done=0;
    data_fwd=16'h0001;
    data_ca_out=16'h0000;
    fwd=0;
    fwd_rdy=0;
    mis_pred_ld_ptr=5'b00000;
    cmmt_ld=0;
    #20 $stop;
end
    

//loop-mode


//misprediction

endmodule
    
    
    
    