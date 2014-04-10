module load_store_arbi_tb();
    reg rst, clk, ld_req, str_req, ca_idle, done;
    wire ld_grnt, str_grnt, addr_sel, rd_wrt_ca, ca_enable;
    
    
    
    initial begin
        clk=0;
        forever 
        #1 clk = ~clk;
end


initial begin
    rst=0;
    #2 rst=1;
    #1 ca_idle=1;
    ld_req=1;
    str_req=0;
    done=0;
    #4 $stop;
end
    
    
    
    
    load_store_arbi lsa(.rst(rst), .clk(clk),.ld_req(ld_req), .str_req(str_req), .idle(ca_idle), .done(done),
                     .ld_grnt(ld_grnt), .str_grnt(str_grnt), .addr_sel(addr_sel),
                        .rd_wrt_ca(rd_wrt_ca), .enable(ca_enable));
endmodule
