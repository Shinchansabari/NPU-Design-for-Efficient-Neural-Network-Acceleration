`timescale 1ns / 1ps

module cnn #(
    parameter DATA_WIDTH = 8,
    parameter IMG_H = 28,
    parameter IMG_W = 28,
    parameter K_H = 4,
    parameter K_W = 4,
    parameter STRIDE_H = 4,
    parameter STRIDE_W = 4,
    parameter POOL_SIZE = 2,
    parameter NUM_WINDOWS = (((IMG_H-K_H)/STRIDE_H + 1)*((IMG_W-K_W)/STRIDE_W + 1)), 
    parameter NUM_KERNELS = 6,
    
    localparam MAP_HEIGHT = ((IMG_H - K_H) / STRIDE_H) + 1,
    localparam MAP_WIDTH = ((IMG_W - K_W) / STRIDE_W) + 1
    
)(
    input clk,
    input rst,
    input wire start,
    output wire input_taken,
    input wire [DATA_WIDTH*IMG_H*IMG_W-1:0] in_image,
    input wire [DATA_WIDTH*K_H*K_W*NUM_KERNELS-1:0] in_kernel,
    input  wire pool_type,
    input  wire [1:0] act_type,

    output reg [(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS)-1:0] out_value = {(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS) {1'b0}},
    output reg valid_out = 1'b0,
  
    output wire window_valid, windows_done, kernel_valid, kernels_done, mac_fed_left, mac_fed_top, mac_left_ready, mac_top_ready, mac_left_valid, mac_top_valid, mac_letting, mac_done, activation_ready, activation_done, activation_complete, transposed_out_valid, pooled_out_valid, pooling_done,
    output wire [DATA_WIDTH*K_H*K_W-1:0] window_flat, kernel_flat,
    output wire [DATA_WIDTH*(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1) -1:0] mac_feed_left,
    output wire [DATA_WIDTH*(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1) -1:0] mac_feed_top,
    output wire [(DATA_WIDTH*4)*(NUM_KERNELS+NUM_WINDOWS-1)-1:0] mac_out,
    output wire [DATA_WIDTH*NUM_KERNELS*NUM_WINDOWS-1:0] activation_out,
    output wire [DATA_WIDTH*NUM_KERNELS*NUM_WINDOWS-1:0] transposed_out,
    output wire [(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS)-1:0] pooled_out, //
    
    output wire [(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1) -1:0] cycle_count,
    output wire [7:0] diag
    );

    assign input_taken = windows_done;
    

    window_slider #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_H(IMG_H),
        .IMG_W(IMG_W),
        .K_H(K_H),
        .K_W(K_W),
        .STRIDE_H(STRIDE_H),
        .STRIDE_W(STRIDE_W)
    ) image_slicer(
        .clk(clk),
        .rst(rst),
        .start(start),
        .next_window(mac_left_ready),
        .image_flat(in_image),
        
        .window_flat(window_flat),
        .window_valid(window_valid),
        .all_done(windows_done)
    );
    
    mac_feeder #(
        .DATA_WIDTH(DATA_WIDTH),
        .IN_DIM(K_H*K_W),
        .OUT_DIM(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1)
    ) image_feed(
        .clk(clk),
        .rst(rst),
        .start(start),
        .vector_valid(window_valid),
        .vectors_complete(windows_done),
        .in_vector(window_flat),
        
        .out_vector(mac_feed_left),
        .ready(mac_left_ready),
        .output_done(mac_left_valid),
        .all_done(mac_fed_left)
    );
    
    weight_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .K_H(K_H),
        .K_W(K_W),
        .NUM_KERNELS(NUM_KERNELS)
    ) weight(
        .clk(clk),
        .rst(rst),
        .start(start),
        .next_kernel(mac_top_ready),
        .input_value(in_kernel),
        
        .output_value(kernel_flat),
        .output_done(kernel_valid),
        .done(kernels_done)
    );
    
    mac_feeder #(
        .DATA_WIDTH(DATA_WIDTH),
        .IN_DIM(K_H*K_W),
        .OUT_DIM(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1)
    ) kernel_feed(
        .clk(clk),
        .rst(rst),
        .start(start),
        .vector_valid(kernel_valid),
        .vectors_complete(kernels_done),
        .in_vector(kernel_flat),
        
        .out_vector(mac_feed_top),
        .ready(mac_top_ready),
        .output_done(mac_top_valid),
        .all_done(mac_fed_top)
    );
    
    mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_LENGTH(K_H*K_W),
        .MAT_ROWS(NUM_WINDOWS),
        .MAT_COLS(NUM_KERNELS)
    ) mac(
        .clk(clk),
        .rst(rst),
        .start(activation_ready && ~activation_done && ~mac_letting),
        .in_valid(mac_left_valid),
        .w_valid(mac_top_valid),
        .in_done(mac_fed_left),
        .w_done(mac_fed_top),
        .a_vec_in(mac_feed_left),
        .b_vec_in(mac_feed_top),
        
        .c_vec_out(mac_out),
        .letting(mac_letting),
        .done(mac_done),
        
        .cycle_count(cycle_count)
    );
    
    activation_layer #(
        .DATA_WIDTH(DATA_WIDTH*4),
        .MAT_ROWS(NUM_WINDOWS),
        .MAT_COLS(NUM_KERNELS)
    ) activation(
        .clk(clk),
        .rst(rst),
        .start(mac_letting),
        .input_done(mac_done),
        .act_type(act_type),
        .in_value(mac_out),
        
        .out_value_flattened(activation_out),
        .ready(activation_ready),
        .output_done(activation_done),
        .output_complete(activation_complete),
        
        .diag(diag)
    );
    
    transpose_module #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAT_ROWS(NUM_WINDOWS),
        .MAT_COLS(NUM_KERNELS)
    ) transpose(
        .clk(clk),
        .rst(rst),
        .start(activation_complete),
        .input_value(activation_out),
        
        .output_value(transposed_out),
        .valid_out(transposed_out_valid)
    );
        
    pooling_layer #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAP_HEIGHT(((IMG_H - K_H) / STRIDE_H) + 1),
        .MAP_WIDTH(((IMG_W - K_W) / STRIDE_W) + 1),
        .NUM_KERNELS(NUM_KERNELS),
        .POOL_SIZE(POOL_SIZE)
    ) pooling(
        .clk(clk),
        .rst(rst),
        .pool_type(pool_type),
        .valid_in(transposed_out_valid),
        .input_value(transposed_out),
        
        .valid_out(pooled_out_valid),
        .output_value(pooled_out),
        .all_done(pooling_done)
    );
    
    always@(posedge clk) begin
    if(valid_out) valid_out <= 1'b0;
    if(pooled_out_valid) begin
        if(pooling_done) valid_out<=1'b1; 
        out_value<=pooled_out;
        $display("%0xh",pooled_out);
        end
    end    

endmodule
