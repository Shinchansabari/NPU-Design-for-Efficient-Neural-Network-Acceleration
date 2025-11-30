`timescale 1ns / 1ps

module tb_mac_array;

    // --------------------------
    // Parameters
    // --------------------------
    parameter DATA_WIDTH = 8;
    parameter BASE_LENGTH = 2;
    parameter MAT_ROWS   = 2;
    parameter MAT_COLS   = 2;
    localparam LATENCY   = (MAT_ROWS >= MAT_COLS ? MAT_ROWS : MAT_COLS);
    localparam ARR_DIM   = (BASE_LENGTH + LATENCY -1);

    // --------------------------
    // Signals
    // --------------------------
    reg clk;
    reg rst;
    reg start;
    reg in_valid;
    reg w_valid;
    reg in_done;
    reg w_done;

    reg [(DATA_WIDTH*ARR_DIM)-1:0] a_vec_in;
    reg [(DATA_WIDTH*ARR_DIM)-1:0] b_vec_in;

    wire [(DATA_WIDTH*4)*(MAT_ROWS+MAT_COLS-1)-1:0] c_vec_out;
    wire letting;
    wire done;
    wire [ARR_DIM*ARR_DIM-1:0] cycle_count;

    // --------------------------
    // Instantiate DUT
    // --------------------------
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAT_ROWS(MAT_ROWS),
        .MAT_COLS(MAT_COLS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .in_valid(in_valid),
        .w_valid(w_valid),
        .in_done(in_done),
        .w_done(w_done),
        .a_vec_in(a_vec_in),
        .b_vec_in(b_vec_in),
        .c_vec_out(c_vec_out),
        .letting(letting),
        .done(done),
        .cycle_count(cycle_count)
    );

    // --------------------------
    // Clock generation
    // --------------------------
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // --------------------------
    // Test sequence
    // --------------------------
    initial begin
        // Reset
        rst = 1;
        start = 0;
        in_valid = 0;
        w_valid = 0;
        a_vec_in = 0;
        b_vec_in = 0;
        #20;
        rst = 0;
        
        @(posedge clk);
        a_vec_in = {8'd0, 8'd0, 8'd1};
        b_vec_in = {8'd0, 8'd3, 8'd1};
        start = 1;
        in_valid = 1;
        w_valid = 1;
        
        @(posedge clk);
        in_valid = 0;
        w_valid = 0;
        start = 0;
        
        @(posedge clk);
        a_vec_in = {8'd1, 8'd0, 8'd0};
        b_vec_in = {8'd4, 8'd2, 8'd0};
        in_done = 1;
        w_done = 1;
        start = 1;


        @(posedge clk);
        in_valid = 0;
        w_valid = 0;
        start = 0;
        
        @(posedge clk);
        a_vec_in = {8'd0, 8'd0, 8'd0};
        b_vec_in = {8'd0, 8'd0, 8'd0};
        start=1;
        
                @(posedge clk);
                start = 0;
        
                        @(posedge clk);
                start = 1;
                
                                @(posedge clk);
                start = 0;
                
                                @(posedge clk);
                start = 1;
        
        // Wait until done
        wait(done);
        #20;
        $stop;
    end

endmodule
