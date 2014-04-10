module cache_controller(rst, clk, enable_cache, done_mem, miss_hit, wrt_bck, rd_wrt_mem,
    mem_enable, idle, mem_rdy);
    
    // input and output ports declarations
    input rst, clk, miss_hit, wrt_bck, enable_cache, done_mem;
    output reg rd_wrt_mem, mem_enable, idle, mem_rdy;
    
    localparam IDLE=2'b00; // idle state
    localparam CACHE=2'b01; // handle cache operation (busy)
    localparam MISS =2'b10; // handle cache miss (busy)
    localparam WRITEBACK=2'b11; // handle memory writeback (busy)
    
    reg [1:0] state, nxt_state; // state registers
    
    // state transition
    always@(posedge clk, negedge rst)
    if (!rst)
       state <= IDLE;
    else
       state <= nxt_state;
    
    // output generation logic   
    always@(miss_hit, wrt_bck, enable_cache, done_mem, state) 
    begin
       rd_wrt_mem=0;
       mem_enable=0;
       idle=1;
       mem_rdy=0;
       case (state)
           IDLE:
           if (enable_cache && !(miss_hit)) begin
              nxt_state=MISS;
              // Enable memory read
              mem_enable=1;
              rd_wrt_mem=1;
              // Memory system is busy now
              idle=0;
           end
         else if (enable_cache && miss_hit) begin
              nxt_state=CACHE;
              idle=0;
           end
           else
              nxt_state=IDLE;
                 
           CACHE: 
             nxt_state=IDLE;
          
           
           MISS: begin
           idle=0;
           if (done_mem && !(wrt_bck)) begin
                mem_rdy=1;
                nxt_state=IDLE;
            end
            else if (done_mem && wrt_bck) begin
                mem_rdy=1;
                nxt_state=WRITEBACK;
                rd_wrt_mem=0;
                 mem_enable=1;
            end
            else
                nxt_state=MISS;
            end
                    
            WRITEBACK:
            if (done_mem) begin
                idle = 0;
                nxt_state = IDLE;
        end
            else begin
                 nxt_state=WRITEBACK;
                 mem_enable=1;
                 idle=0;
            end
                 
         endcase
         
                
    end               
             
    
    
endmodule
