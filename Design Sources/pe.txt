`timescale 1ns / 1ps

module pe #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input wire in_valid,
    input wire w_valid,

    input  wire [DATA_WIDTH-1:0]     input_data,  
    input  wire [DATA_WIDTH-1:0]     weight_data, 
    input  wire [(DATA_WIDTH*4)-1:0] input_psum,  

    output reg [(DATA_WIDTH*4)-1:0] output_psum = {DATA_WIDTH*4 {1'b0}},  
    output reg [DATA_WIDTH-1:0]     act_out = {DATA_WIDTH {1'b0}},     
    output reg [DATA_WIDTH-1:0]     wt_out = {DATA_WIDTH {1'b0}}
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_psum <= 0;
            act_out     <= 0;
            wt_out      <= 0;
        end else if (start && in_valid && w_valid) begin
            output_psum <= input_psum + (input_data * weight_data);
            act_out <= input_data;
            wt_out  <= weight_data;
        end
        
    end

endmodule
