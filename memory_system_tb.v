module memory_system_tb();
    
    reg rst, clk, rd_wrt_ca, enable;
    reg [15:0] addr_ca, data_ca_in;
    wire idle, done;
    wire [15:0] data_ca_out;
    wire [1:0] cc_state;
    wire ca_hit, ca_wb, mem_rdy, victim, hit_first, hit_second;
    wire [13:0] addr_mem;
    wire [63:0] data_to_mem, stored_data;
    memory_system mem_sys(.rst(rst), .clk(clk),.addr_ca(addr_ca), 
                         .data_ca_out(data_ca_out),.rd_wrt_ca(rd_wrt_ca), 
                           .data_ca_in(data_ca_in),.enable(enable), 
                           .idle(idle), .done(done));

assign cc_state=mem_sys.cc.state;
assign ca_hit=mem_sys.ca.miss_hit;
assign ca_wb=mem_sys.ca.wrt_bck;
assign addr_mem=mem_sys.ca.addr_mem;
assign data_to_mem=mem_sys.ca.data_to_mem;
assign mem_rdy=mem_sys.cc.mem_rdy;
assign victim=mem_sys.ca.victim;
assign hit_first=mem_sys.ca.hit_first;
assign hit_second=mem_sys.ca.hit_second;
assign stored_data=mem_sys.ca.mem[0][63:0];
initial begin
    clk =0;
    forever
    #1 clk = ~clk;
end

initial begin
    rst=0;
    @(negedge clk);
    rst=1;
    enable=1;
    addr_ca=0;
    rd_wrt_ca=0;
    data_ca_in=16'h2000;
    @(posedge done);
    #1 addr_ca=16'b1111111111100000;
    data_ca_in=16'h0f00;
    @(posedge done);
    #1 addr_ca=16'b1011111111100000;
   rd_wrt_ca=1;
    #40 $stop;
    
    
    
    
    
    
    
    
    
    
    
    
    
end

endmodule