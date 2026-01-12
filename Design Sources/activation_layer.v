`timescale 1ns / 1ps

module activation_layer #(
    parameter DATA_WIDTH = 32,
    parameter MAT_ROWS = 3,
    parameter MAT_COLS = 3,
    parameter NUM_VALUES = MAT_ROWS+MAT_COLS-1,
    parameter GREATER_DIM = (MAT_ROWS>=MAT_COLS?MAT_ROWS:MAT_COLS)
)(
    input wire                        clk,
    input wire                        rst,
    input wire                        start,
    input wire                        input_done,

    input       [1:0]                 act_type, // 00=ReLU, 01=Sigmoid, 10=Tanh, 11=Identity
    input wire [DATA_WIDTH*(MAT_ROWS+MAT_COLS-1)-1:0]     in_value,
    output reg [(DATA_WIDTH/4)*MAT_ROWS*MAT_COLS-1:0] out_value_flattened= {(DATA_WIDTH/4)*MAT_ROWS*MAT_COLS{1'b0}},
    output reg                        ready=1'b1,
    output reg output_done=1'b0,
    output reg output_complete=1'b0,
    output reg [7:0] diag = 8'b1
);

    localparam SCALE_SHIFT = 8;   // scale input down to approx. [-128,+127]
    localparam MAX = 32'sd128;  

    function [7:0] relu;
        input [31:0] x;
        begin
            /*if (x <= 0)
                relu = 8'd0;
            else begin*/
                if      (x < 32'd2)             relu = 8'd1;
                else if (x < 32'd4)             relu = 8'd2;
                else if (x < 32'd8)             relu = 8'd4;
                else if (x < 32'd16)            relu = 8'd8;
                else if (x < 32'd32)            relu = 8'd16;
                else if (x < 32'd64)            relu = 8'd24;
                else if (x < 32'd128)           relu = 8'd32;
                else if (x < 32'd256)           relu = 8'd40;
                else if (x < 32'd512)           relu = 8'd48;
                else if (x < 32'd1024)          relu = 8'd56;
                else if (x < 32'd2048)          relu = 8'd64;
                else if (x < 32'd4096)          relu = 8'd80;
                else if (x < 32'd8192)          relu = 8'd96;
                else if (x < 32'd16384)         relu = 8'd112;
                else if (x < 32'd32768)         relu = 8'd128;
                else if (x < 32'd65536)         relu = 8'd144;
                else if (x < 32'd131072)        relu = 8'd160;
                else if (x < 32'd262144)        relu = 8'd176;
                else if (x < 32'd524288)        relu = 8'd192;
                else if (x < 32'd1048576)       relu = 8'd208;
                else if (x < 32'd2097152)       relu = 8'd216;
                else if (x < 32'd4194304)       relu = 8'd224;
                else if (x < 32'd8388608)       relu = 8'd232;
                else if (x < 32'd16777216)      relu = 8'd240;
                else if (x < 32'd33554432)      relu = 8'd248;
                else                             relu = 8'd255; // Saturate
            //end
        end
    endfunction


    function [7:0] sigmoid;
        input [31:0] x;
        reg [31:0] scaled_x;
        begin
            scaled_x = x >>> SCALE_SHIFT;
            // Clip to saturation
            if (scaled_x > MAX) 
                sigmoid = 8'sd127;
            else if (scaled_x < -MAX)
                sigmoid = 8'sd0;
            // Linear approx. for [-MAX, MAX]
            else 
                sigmoid = scaled_x[11:4];
        end
    endfunction
    function [7:0] tanh;
        input [31:0] x;
        reg [31:0] scaled_x;
        begin
            scaled_x = x >>> SCALE_SHIFT;
            // Clip to saturation
            if (scaled_x > MAX) 
                tanh = 8'd127;
            else if (scaled_x < -MAX)
                tanh = -8'sd128;
            // Linear approx. for [-MAX, MAX]
            else 
                tanh = scaled_x[11:4];
        end
    endfunction

    reg [DATA_WIDTH*(MAT_ROWS+MAT_COLS-1)-1:0]     input_buffer;
    reg [(DATA_WIDTH/4)*GREATER_DIM*GREATER_DIM-1:0]     output_buffer;
    reg loop1_done = 1'b0,loop2_done = 1'b0;
    reg started = 1'b0;
    reg input_complete = 1'b0;
    

    integer i=0,j=0;
    integer diag = 0;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            input_complete <= 1'b0;
            output_complete <= 1'b0;
            started <= 1'b0;
            ready <= 1'b1;
        end
        
        else begin
            if(start) begin
                input_buffer <= in_value;
                started <= 1'b1;
                ready <= 1'b0;
            end
            if(input_done) begin
                input_complete <= 1'b1;
            end
            if(loop1_done && loop2_done) begin
                loop1_done <= 1'b0;
                loop2_done <= 1'b0;
                started <= 1'b0;
                output_done <= 1'b1;
                diag=diag+1;
                if(input_complete) begin
                    out_value_flattened <= output_buffer;
                    output_complete <= 1'b1;
                    diag=0;
                    $display(out_value_flattened);
                end
                i=0;j=0;
            end
            if(output_done) begin
                output_done <= 1'b0;
                if(~output_complete) ready <= 1'b1;
            end
        end
        
    end
    
    always @(posedge clk or posedge rst) begin
    
        if(rst) begin
            input_buffer <= {DATA_WIDTH*(MAT_ROWS+MAT_COLS-1) {1'b0}};
            out_value_flattened <= {(DATA_WIDTH/4)*MAT_ROWS*MAT_COLS {1'b0}};
            i=0;j=0;diag=0;
        end
        else begin
            if(started) begin
                if ((i < MAT_COLS-diag) && (diag<MAT_COLS)) begin
                    output_buffer[(DATA_WIDTH/4) *(diag*MAT_COLS+diag+i) +: (DATA_WIDTH/4)] <= relu(input_buffer[DATA_WIDTH*i +:DATA_WIDTH]);
                    i=i+1;
                end
                else loop1_done <= 1'b1;
                if ((j < MAT_ROWS-diag) && (diag<MAT_ROWS)) begin
                    output_buffer[(DATA_WIDTH/4) *(diag*MAT_COLS+diag+(j*MAT_COLS)) +: (DATA_WIDTH/4)] <= relu(input_buffer[DATA_WIDTH*(MAT_COLS+j) +:DATA_WIDTH]);
                    j=j+1;
                end   
                else loop2_done <= 1'b1;             
            end
        end
    
    end
        
endmodule


