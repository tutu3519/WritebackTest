module memory_system(clk, rst, addr_ca, data_ca_in, rd_wrt_ca, enable, idle, done, data_ca_out);
    input rd_wrt_ca, enable, clk, rst;
    input [15:0] addr_ca, data_ca_in;
    output idle, done;
    output [15:0] data_ca_out;  
    
    wire miss_hit, wrt_bck,done_mem, rd_wrt_mem, mem_enable, mem_rdy, miss_handling;
    wire [63:0] data_to_mem, data_from_mem;  
    wire [13:0] addr_mem;
    
    cache ca(.rst(rst), .clk(clk), .addr_ca(addr_ca), .data_ca_in(data_ca_in), .rd_wrt_ca(rd_wrt_ca), .enable(enable),
    .data_ca_out(data_ca_out), .addr_mem(addr_mem),.mem_rdy(mem_rdy), 
    .data_to_mem(data_to_mem), .wrt_bck(wrt_bck), .miss_hit(miss_hit), .data_from_mem(data_from_mem),.done(done));
    
    cache_controller cc(.rst(rst), .clk(clk), .enable_cache(enable),.done_mem(done_mem), .miss_hit(miss_hit), .wrt_bck(wrt_bck), .rd_wrt_mem(rd_wrt_mem),
    .mem_enable(mem_enable), .idle(idle), .mem_rdy(mem_rdy));
    
    memory_interface mem(.rst(rst), .clk(clk), .addr_mem(addr_mem), .rd_wrt_mem(rd_wrt_mem), .enable(mem_enable), .data_mem_in(data_to_mem), 
    .data_mem_out(data_from_mem),.done(done_mem));
   
    
endmodule
