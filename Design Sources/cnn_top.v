`timescale 1ns / 1ps

module cnn_top #(
    parameter DATA_WIDTH = 8
    )(
    input clk,
    input rst,
    input wire start,
    output wire input_taken,
    input wire [DATA_WIDTH* 28*28 -1:0] in_image,
    input wire [DATA_WIDTH* 4*4 *6 -1:0] in_kernel_1,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_1,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_2,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_3,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_4,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_5,
    input wire [DATA_WIDTH* 2*2 *2 -1:0] in_kernel_2_6,
    input  wire pool_type,
    input  wire [1:0] act_type,
    
    output wire [768-1:0] out_value_conv1,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_1,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_2,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_3,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_4,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_5,
    output wire [DATA_WIDTH*8 -1:0] out_value_conv2_6,
    output reg [DATA_WIDTH*8 *6 -1:0] out_value_conv2 = {DATA_WIDTH*8 *6 {1'b0}},
    
    output wire valid_out_conv1,
    output wire valid_out_conv2_1,
    output wire valid_out_conv2_2,
    output wire valid_out_conv2_3,
    output wire valid_out_conv2_4,
    output wire valid_out_conv2_5,
    output wire valid_out_conv2_6,
    output reg valid_out_conv2 = 0,
    
    output wire [(DATA_WIDTH*4)*(6+49-1)-1:0] mac_out,
    output wire [DATA_WIDTH*6*49-1:0] activation_out,
    output wire [DATA_WIDTH*6*49-1:0] transposed_out,
    output wire [DATA_WIDTH*6*16 -1:0] pooled_out,
    output wire [DATA_WIDTH*16-1:0] window_flat,
    output wire [DATA_WIDTH*16-1:0] kernel_flat,
    output wire window_valid, windows_done, kernel_valid, kernels_done, mac_letting, mac_done, activation_ready, activation_done, activation_complete, transposed_out_valid, pooled_out_valid, pooling_done
);

    reg valid_out_conv1_reg, valid_out_conv2_1_reg, valid_out_conv2_2_reg, valid_out_conv2_3_reg, valid_out_conv2_4_reg, valid_out_conv2_5_reg, valid_out_conv2_6_reg;

    cnn #(
        .DATA_WIDTH(8),
        .IMG_H(28),
        .IMG_W(28),
        .K_H(4),
        .K_W(4),
        .STRIDE_H(4),
        .STRIDE_W(4),
        .POOL_SIZE(2),
        .NUM_KERNELS(6)
    ) conv1 (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_taken(input_taken),
        .in_image(in_image),
        .in_kernel(in_kernel_1),
        .pool_type(1'b0),
        .act_type(2'b00),
        
        .out_value(out_value_conv1),
        .valid_out(valid_out_conv1),
        
        
                                             .mac_out(mac_out),
.activation_out(activation_out),
.transposed_out(transposed_out),
.pooled_out(pooled_out),
.window_valid(window_valid), 
.window_flat(window_flat),
.windows_done(windows_done),
.kernel_valid(kernel_valid),
.kernel_flat(kernel_flat),
.kernels_done(kernels_done),
.mac_letting(mac_letting), 
.mac_done(mac_done), 
.activation_ready(activation_ready), 
.activation_done(activation_done) ,
.activation_complete(activation_complete), 
.transposed_out_valid(transposed_out_valid),
.pooled_out_valid(pooled_out_valid), 
.pooling_done(pooling_done)
        
                
    );
    
    cnn #(
        .DATA_WIDTH(8),
        .IMG_H(4),
        .IMG_W(4),
        .K_H(2),
        .K_W(2),
        .STRIDE_H(1),
        .STRIDE_W(1),
        .POOL_SIZE(2),
        .NUM_KERNELS(2)    
    ) conv2_1 (
        .clk(clk),
        .rst(rst),
        .start(valid_out_conv1),
        .in_image(out_value_conv1[8*16 -1:0]),
        .in_kernel(in_kernel_2_1),
        .pool_type(1'b0),
        .act_type(2'b00),
        
         .out_value(out_value_conv2_1),
         .valid_out(valid_out_conv2_1)
         
     );
   
     cnn #(
         .DATA_WIDTH(8),
         .IMG_H(4),
         .IMG_W(4),
         .K_H(2),
         .K_W(2),
         .STRIDE_H(1),
         .STRIDE_W(1),
         .POOL_SIZE(2),
         .NUM_KERNELS(2)    
     ) conv2_2 (
         .clk(clk),
         .rst(rst),
         .start(valid_out_conv1),
         .in_image(out_value_conv1[2 *8*16 -1 -: 8*16]),
         .in_kernel(in_kernel_2_2),
         .pool_type(1'b0),
         .act_type(2'b00),
         
          .out_value(out_value_conv2_2),
          .valid_out(valid_out_conv2_2)
          
          
 
          

      );   
     
     cnn #(
          .DATA_WIDTH(8),
          .IMG_H(4),
          .IMG_W(4),
          .K_H(2),
          .K_W(2),
          .STRIDE_H(1),
          .STRIDE_W(1),
          .POOL_SIZE(2),
          .NUM_KERNELS(2)    
      ) conv2_3 (
          .clk(clk),
          .rst(rst),
          .start(valid_out_conv1),
          .in_image(out_value_conv1[3 *8*16 -1 -: 8*16]),
          .in_kernel(in_kernel_2_3),
          .pool_type(1'b0),
          .act_type(2'b00),
          
           .out_value(out_value_conv2_3),
           .valid_out(valid_out_conv2_3)
       );   
       
     cnn #(
            .DATA_WIDTH(8),
            .IMG_H(4),
            .IMG_W(4),
            .K_H(2),
            .K_W(2),
            .STRIDE_H(1),
            .STRIDE_W(1),
            .POOL_SIZE(2),
            .NUM_KERNELS(2)    
        ) conv2_4 (
            .clk(clk),
            .rst(rst),
            .start(valid_out_conv1),
            .in_image(out_value_conv1[4 *8*16 -1 -: 8*16]),
            .in_kernel(in_kernel_2_4),
            .pool_type(1'b0),
            .act_type(2'b00),
            
             .out_value(out_value_conv2_4),
             .valid_out(valid_out_conv2_4)
         );     
         
         
     cnn #(
              .DATA_WIDTH(8),
              .IMG_H(4),
              .IMG_W(4),
              .K_H(2),
              .K_W(2),
              .STRIDE_H(1),
              .STRIDE_W(1),
              .POOL_SIZE(2),
              .NUM_KERNELS(2)    
          ) conv2_5 (
              .clk(clk),
              .rst(rst),
              .start(valid_out_conv1),
              .in_image(out_value_conv1[5 *8*16 -1 -: 8*16]),
              .in_kernel(in_kernel_2_5),
              .pool_type(1'b0),
              .act_type(2'b00),
              
               .out_value(out_value_conv2_5),
               .valid_out(valid_out_conv2_5)
           );  
           
     cnn #(
            .DATA_WIDTH(8),
            .IMG_H(4),
            .IMG_W(4),
            .K_H(2),
            .K_W(2),
            .STRIDE_H(1),
            .STRIDE_W(1),
            .POOL_SIZE(2),
            .NUM_KERNELS(2)    
          ) conv2_6 (
            .clk(clk),
            .rst(rst),
            .start(valid_out_conv1),
            .in_image(out_value_conv1[6 *8*16 -1 -: 8*16]),
            .in_kernel(in_kernel_2_6),
            .pool_type(1'b0),
            .act_type(2'b00),
                    
            .out_value(out_value_conv2_6),
            .valid_out(valid_out_conv2_6)
        );  
   
    always @(posedge clk or posedge rst) begin
        valid_out_conv1_reg <= valid_out_conv1;
        valid_out_conv2_1_reg <= valid_out_conv2_1;
        valid_out_conv2_2_reg <= valid_out_conv2_2;
        valid_out_conv2_3_reg <= valid_out_conv2_3;
        valid_out_conv2_4_reg <= valid_out_conv2_4;
        valid_out_conv2_5_reg <= valid_out_conv2_5;
        valid_out_conv2_6_reg <= valid_out_conv2_6;
        
        if(valid_out_conv2) valid_out_conv2 <= 1'b0;
        
        if(rst) begin
            
        end
        else if(valid_out_conv2_1_reg && valid_out_conv2_2_reg && valid_out_conv2_3_reg && valid_out_conv2_4_reg && valid_out_conv2_5_reg && valid_out_conv2_6_reg) begin
            valid_out_conv2 <= 1'b1;
            out_value_conv2 = {out_value_conv2_6, out_value_conv2_5, out_value_conv2_4, out_value_conv2_3, out_value_conv2_2, out_value_conv2_1};
            $display("%0xh",out_value_conv2);
        end
    end
       
endmodule
