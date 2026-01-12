`timescale 1ns / 1ps
module mac_array #(
    parameter DATA_WIDTH = 8,
    parameter BASE_LENGTH = 3,
    parameter MAT_ROWS = 3,
    parameter MAT_COLS = 3,
    parameter LATENCY = (MAT_ROWS >= MAT_COLS ? MAT_ROWS : MAT_COLS),
    parameter ARR_DIM = (BASE_LENGTH + LATENCY -1)
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire in_valid,
    input  wire w_valid,
    input wire in_done,
    input wire w_done,

    input  wire [(DATA_WIDTH*ARR_DIM)-1:0]    a_vec_in,
    input  wire [(DATA_WIDTH*ARR_DIM)-1:0] b_vec_in,

    // Feature map now collects only bottom row + rightmost column
    output wire [(DATA_WIDTH*4)*(MAT_ROWS+MAT_COLS-1)-1:0] c_vec_out,
    output reg letting,
    output reg done,
    output reg [ARR_DIM-1:0] cycle_count=0
);

    // Internal wires
    
    wire [(DATA_WIDTH)-1:0]        act_wire  [0:ARR_DIM-1][0:ARR_DIM];
    wire [(DATA_WIDTH)-1:0]        wt_wire   [0:ARR_DIM][0:ARR_DIM-1];
    wire [(DATA_WIDTH*4)-1:0]    psum_wire [0:ARR_DIM][0:ARR_DIM];
    
    // --------------------------
        // done signal with latency
        // --------------------------
        
    integer k;
    genvar r,c,i;
    reg in_input_complete=0, w_input_complete=0;

    // Instantiate PEs
    generate
        for (r = 0; r < ARR_DIM; r = r + 1) begin : ROW_GEN
            for (c = 0; c < ARR_DIM; c = c + 1) begin : COL_GEN
                pe #(.DATA_WIDTH(DATA_WIDTH)) u_pe (
                    .clk(clk),
                    .rst(rst),
                    .start(start),
                    .in_valid(in_valid || in_input_complete),
                    .w_valid(w_valid || w_input_complete),
                    .input_data (act_wire[r][c]),
                    .weight_data(wt_wire[r][c]),
                    .input_psum (psum_wire[r][c]),
                    .output_psum(psum_wire[r+1][c+1]),
                    .act_out    (act_wire[r][c+1]),
                    .wt_out     (wt_wire[r+1][c])
                );
            end
        end
    endgenerate
    
    
        // Initialize psum borders to zero
    generate
        for (r = 0; r < ARR_DIM+1; r = r + 1) begin : PSUM_ROW
            assign psum_wire[r][0] = 0;
        end
        for (c = 0; c < ARR_DIM+1; c = c + 1) begin : PSUM_COL
            assign psum_wire[0][c] = 0;
        end
    endgenerate
    

    // Feed input vectors
    generate
        for (r = 0; r < ARR_DIM; r = r + 1) begin : LEFT_ACT
            assign act_wire[r][0] = {a_vec_in[r*DATA_WIDTH +: DATA_WIDTH]};
        end
    endgenerate

    generate
        for (c = 0; c < ARR_DIM; c = c + 1) begin : TOP_WT
            assign wt_wire[0][c] = {b_vec_in[c*DATA_WIDTH +: DATA_WIDTH]};
        end
    endgenerate


    // --------------------------
    // Feature map assignment
    // --------------------------
    
    //RIGHT EDGE
    generate
        for (i = 0; i < MAT_COLS; i = i + 1) begin 
            assign c_vec_out[(i*DATA_WIDTH*4) +: (DATA_WIDTH*4)] = psum_wire[ARR_DIM-i][ARR_DIM];
        end
    endgenerate
    
    generate
            for (i = 1; i < MAT_ROWS; i = i + 1) begin 
               //BOTTOM EDGE
                assign c_vec_out[((MAT_COLS-1+i)*(DATA_WIDTH*4)) +: (DATA_WIDTH*4)] = psum_wire[ARR_DIM][ARR_DIM-i];
            end
    endgenerate
    

    always @(posedge clk or posedge rst) begin
        if(in_done) in_input_complete = 1'b1;
        if(w_done) w_input_complete = 1'b1;
        if(done) done <= 1'b0;
        if (rst) begin
            cycle_count <= 0;
            letting <= 0;
            done <= 0;
        end 
        else if (start && ~letting && (in_valid||in_input_complete) && (w_valid||w_input_complete)) begin
                cycle_count = cycle_count + 1;
                if (cycle_count >= ARR_DIM) begin
                    letting <= 1'b1;
                    if( (cycle_count >= (ARR_DIM+LATENCY-1))) begin
                        done <= 1'b1;
                        cycle_count <= 1'b0;
                    end
                end
        end
        else if(~start) letting <= 1'b0;
    end

endmodule
