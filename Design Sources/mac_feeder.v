`timescale 1ns / 1ps

module mac_feeder #(
    parameter DATA_WIDTH = 8,
    parameter IN_DIM = 3,
    parameter OUT_DIM = 8
)(
    input wire clk,
    input wire rst,
    input start,
    input wire vector_valid,
    input wire vectors_complete,
    input wire [IN_DIM*DATA_WIDTH -1:0] in_vector,

    output reg [OUT_DIM*DATA_WIDTH -1:0] out_vector,
    output reg ready=1'b1,
    output reg output_done,
    output reg all_done
);

    integer n=0;
    reg started = 1'b0;
    reg input_done = 1'b0;
    
    always @(posedge clk or posedge rst) begin
        if(start) started <= 1'b1;
        if (rst) begin
            n <= 0;
            out_vector <= {OUT_DIM*DATA_WIDTH{1'b0}};
        end 
        else if(started) begin
            
            if (vector_valid && ready) begin
                out_vector <= {OUT_DIM*DATA_WIDTH{1'b0}};
                out_vector[n*DATA_WIDTH +: IN_DIM*DATA_WIDTH] <= in_vector;
                output_done <= 1'b1;
                ready <= 1'b0;
                n <= n + 1;
            end
            if (vectors_complete) begin
                            n <= 0;
                            all_done <= 1'b1;
                            ready <= 1'b0;
                            started <= 1'b0;
                           
                        end 
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ready <= 1'b1;
            output_done <= 1'b0;
            all_done <= 1'b0;
            started <= 1'b0;
        end
        else if(output_done && ~all_done) begin
            ready <= 1'b1;
            output_done <= 1'b0;
        end
        else if(all_done) begin
            all_done <= 1'b0;
            out_vector <= {OUT_DIM*DATA_WIDTH{1'b0}};
        end
    end
endmodule
