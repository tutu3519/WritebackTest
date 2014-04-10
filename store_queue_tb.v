module store_queue_tb();
    
    reg fnsh_unrll, rst, clk, flsh, ld_grnt, mem_wrt, str_grnt, done, cmmt_str;
    reg [1:0] lbd_state;
    reg [23:0] indx_str_al;
    reg [5:0] indx_fwd, indx_ls;
    reg [15:0] addr_ld, data_str,addr_ls;
    reg [3:0] vld_str, mis_pred_str_ptr;
    wire str_iss, stll_str, fwd, fwd_rdy, str_req;
    wire [15:0] data_ca_in, data_fwd, addr_str;
    wire [15:0] update, insert, commit, indx_comp, addr_comp, match, shifted_match, ready;
    wire [3:0] head, tail;
    
    
    
    store_queue sq(.fnsh_unrll(fnsh_unrll), .lbd_state(lbd_state), .rst(rst), .clk(clk),
                .addr_fwd(addr_ld),.indx_fwd(indx_fwd), .flsh(flsh), .indx_str_al(indx_str_al), .ld_grnt(ld_grnt),
               .vld_str(vld_str), .mem_wrt(mem_wrt), .data_str(data_str), .indx_ls(indx_ls), 
                .addr_ls(addr_ls), .str_grnt(str_grnt), .done(done), .str_req(str_req), 
                .str_iss(str_iss), .stll(stll_str), .fwd(fwd), .fwd_rdy(fwd_rdy), .addr(addr_str),
                .data_ca(data_ca_in), .data_fwd(data_fwd), .mis_pred_str_ptr(mis_pred_str_ptr),
                .cmmt_str(cmmt_str));
        
    assign update=sq.update;
    assign commit=sq.commit;
    assign insert=sq.insert;        
    assign head=sq.head;
    assign tail=sq.tail;
    assign indx_comp=sq.indx_comp;
    assign addr_comp=sq.addr_comp;
    assign match=sq.match;
    assign shifted_match=sq.shifted_match;
    assign ready=sq.ready;
    assign added_cmp=sq.added_cmp;
    initial begin
        clk = 0;
        forever
        #1 clk = ~clk;
   end
   
   initial begin
       rst=0;
       @(negedge clk);
       rst=1;
       vld_str=4'b0011;
       indx_str_al=24'b000000_000000_000100_000010;
       fnsh_unrll=0;
       lbd_state=2'b00;
       addr_ld=16'h0000;
       indx_fwd=6'h0;
       flsh=0;
       ld_grnt=0;
       mem_wrt=0;
       data_str=16'h0;
       indx_ls=6'h0;
       addr_ls=16'h0;
       str_grnt=0;
       done=0;
       mis_pred_str_ptr=4'h0;
       cmmt_str=0;
       @(negedge clk);
       vld_str=4'b0000;
       mem_wrt=1;
       addr_ls=16'haaaa;
       indx_ls=6'b000100;
       data_str=16'hffff;
       @(negedge clk);
       mem_wrt=0;
       cmmt_str=1;
       @(negedge clk);
       vld_str=4'b1111;
       indx_str_al=24'b001001_001000_000111_000110;
       @(negedge clk);
       vld_str=4'b1111;
       indx_str_al=24'b010000_001110_001100_001010;
       @(negedge clk);
       mem_wrt=1;
       addr_ls=16'hbbbb;
       indx_ls=6'b000010;
       data_str=16'h1111;
       @(negedge clk);
       mem_wrt=0;
       ld_grnt=1;
       indx_fwd=6'b000111;
       addr_ld=16'haaaa;
       @(negedge clk);
       mem_wrt=1;
       addr_ls=16'haaaa;
       indx_ls=6'b000110;
       data_str=16'h1111;
       str_grnt=1;
       @(negedge clk);
       mem_wrt=0;
       done=1;
       @(negedge clk);
       done=0;
       #8 $stop;
   end
   
   
   endmodule
       
