module memory_interface_tb();
    
    reg clk,rst, rd_wrt_mem, enable;
    reg [13:0] addr_mem;
    reg [63:0] data_to_mem;
    wire [63:0] data_from_mem;
    wire done_mem;
    wire [1:0] state;
    
       memory_interface mem(.rst(rst), .clk(clk), .addr_mem(addr_mem), 
       .rd_wrt_mem(rd_wrt_mem), .enable(enable), 
       .data_mem_in(data_to_mem), 
    .data_mem_out(data_from_mem),.done(done_mem));
    
    
    assign state=mem.state;
    
    initial begin
        clk = 0;
        forever
        #1 clk = ~clk;
end

initial begin
    rst=0;
    @(negedge clk);
    rst=1;
    enable=0;
    rd_wrt_mem=1;
    addr_mem=0;
    data_to_mem=64'h0123456789abcdef;
    @(negedge clk);
    enable=1;
    @(negedge clk);
    #1 enable=0;
    @(posedge done_mem);
    #2 rd_wrt_mem=0;
    enable=1;
    #2 enable=0;
    @(posedge done_mem);
    #2 enable=1;
    rd_wrt_mem=1;
    #20 $stop;
end

endmodule
