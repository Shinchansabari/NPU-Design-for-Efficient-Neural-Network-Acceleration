`timescale 1ns/1ps

module tb_npu_top #(
    parameter DATA_WIDTH = 8,
    parameter IMG_W = 28,
    parameter IMG_H = 28,
    parameter K_H_1 = 4,
    parameter K_W_1 = 4,
    parameter K_H_2 = 2,
    parameter K_W_2 = 2,
    parameter NUM_KERNELS_1 = 6,
    parameter NUM_KERNELS_2 = 2
);
    reg clk=1'b0, rst=1'b0, start=1'b0;
    
    
    
    wire [DATA_WIDTH* IMG_H*IMG_W -1:0] in_image;
    
    wire [DATA_WIDTH* K_H_1*K_W_1 *NUM_KERNELS_1 -1:0] in_kernel_1;

    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_1;
    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_2;
    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_3;
    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_4;
    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_5;
    wire  [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_6;
    
    wire input_taken;
    
        wire [DATA_WIDTH*16-1:0] window_flat;
        wire [DATA_WIDTH*16-1:0] kernel_flat;
    wire [(DATA_WIDTH*4)*(2+9-1)-1:0] mac_out;
     wire [DATA_WIDTH*2*9-1:0] activation_out;
         wire [DATA_WIDTH*2*9-1:0] transposed_out;
         wire [DATA_WIDTH*2*4 -1:0] pooled_out;
         
    wire  [DATA_WIDTH* NUM_KERNELS_1* 4*4 *1 -1:0] out_value_conv1;
    wire  [DATA_WIDTH* NUM_KERNELS_2* 2*2 *NUM_KERNELS_1 -1:0] out_value_conv2;
    
    wire valid_out_conv1;
    wire valid_out_conv2;
    
    wire  [DATA_WIDTH *NUM_KERNELS_2 *2*2 *NUM_KERNELS_1 *10 -1:0] fc_weight;
    wire  [8 *10 -1:0] fc_bias;
    
    wire [32 *10 -1:0] fc_output;
    wire fc_done;
    
    wire [3:0] out_value;
    wire valid_out;
    

         
    
    
    npu_top NPU (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_taken(input_taken),
        .in_image(in_image),
        .in_kernel_1(in_kernel_1),
        .in_kernel_2_1(in_kernel_2_1),
        .in_kernel_2_2(in_kernel_2_2),
        .in_kernel_2_3(in_kernel_2_3),
        .in_kernel_2_4(in_kernel_2_4),
        .in_kernel_2_5(in_kernel_2_5),
        .in_kernel_2_6(in_kernel_2_6),
        .out_value_conv1(out_value_conv1),
        .out_value_conv2(out_value_conv2),
        .valid_out_conv1(valid_out_conv1),
        .valid_out_conv2(valid_out_conv2),
        .fc_weight(fc_weight),
        .fc_bias(fc_bias),
        .fc_output(fc_output),
        .fc_done(fc_done),
        .out_value(out_value),
        .valid_out(valid_out),
        
        .window_flat(window_flat),
        .kernel_flat(kernel_flat),
        .mac_out(mac_out),
        .activation_out(activation_out),
        .transposed_out(transposed_out),
        .pooled_out(pooled_out)
        
        
    );
        
        

    
    always #10 clk = ~clk;
    initial begin
        rst=1'b1;
        @(posedge clk);
        @(posedge clk);
        rst=1'b0;
        @(posedge clk);
        @(posedge clk);
        start=1'b1;
        @(posedge clk);
        start=1'b0;
    end
    
endmodule
