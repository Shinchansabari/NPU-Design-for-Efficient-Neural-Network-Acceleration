`timescale 1ns / 1ps

module fc #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter NUM_INPUTS   = 48,   
    parameter NUM_OUTPUTS  = 10    
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire [NUM_INPUTS*DATA_WIDTH-1:0]   in_vec_flat,
    input  wire [NUM_INPUTS*NUM_OUTPUTS*DATA_WIDTH-1:0] w_mat_flat,
    input  wire [NUM_OUTPUTS*DATA_WIDTH-1:0]  bias_flat,
    output reg  [NUM_OUTPUTS*ACC_WIDTH-1:0]   out_vec_flat,
    output reg finish
    
);


    wire [NUM_OUTPUTS*ACC_WIDTH-1:0] systolic_out_vec_flat;
    wire systolic_finish;
    wire finished_sys;


    fc_mac_array #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .NUM_INPUTS  (NUM_INPUTS),
        .NUM_OUTPUTS  (NUM_OUTPUTS)
    ) fc_mac_array_inst (
        .clk          (clk),
        .rst          (rst),
        .valid_in       (start),
        .data_in_flat  (in_vec_flat),
        .weight_flat   (w_mat_flat),
        .data_out_flat (systolic_out_vec_flat),
        .finish_sys(finished_sys)
        
    );

    assign systolic_finish = finished_sys; 


    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_vec_flat <= 0;
            finish <= 0;
        end else if (systolic_finish) begin
            // Add bias to systolic outputs
            for (k = 0; k < NUM_OUTPUTS; k = k + 1) begin
                out_vec_flat[k*ACC_WIDTH +: ACC_WIDTH] <= systolic_out_vec_flat[k*ACC_WIDTH +: ACC_WIDTH] + (bias_flat[k*DATA_WIDTH +: DATA_WIDTH]*4);
            end
            finish <= 1'b1;  
        end else begin
            finish <= 1'b0;
        end
    end

endmodule
