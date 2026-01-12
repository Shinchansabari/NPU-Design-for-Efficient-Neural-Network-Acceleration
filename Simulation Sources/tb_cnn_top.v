`timescale 1ns / 1ps

module tb_cnn_top;
    localparam DATA_WIDTH = 8;
    localparam IMG_W = 28;
    localparam IMG_H = 28;
    localparam K_H_1 = 4;
    localparam K_W_1 = 4;
    localparam K_H_2 = 2;
    localparam K_W_2 = 2;
    localparam NUM_KERNELS_1 = 6;
    localparam NUM_KERNELS_2 = 2;

    reg clk;
    reg rst;
    reg start;
    wire input_taken;
    
    reg [8 -1:0] image_mem [0: 28*28 -1];

    //conv1 weights
    reg [8 -1:0] weight_mem_1_1 [0: K_H_1*K_W_1 -1];
    reg [8 -1:0] weight_mem_1_2 [0: K_H_1*K_W_1 -1];
    reg [8 -1:0] weight_mem_1_3 [0: K_H_1*K_W_1 -1];
    reg [8 -1:0] weight_mem_1_4 [0: K_H_1*K_W_1 -1];
    reg [8 -1:0] weight_mem_1_5 [0: K_H_1*K_W_1 -1];
    reg [8 -1:0] weight_mem_1_6 [0: K_H_1*K_W_1 -1];
    
    //conv2 weights
    reg [8 -1:0] weight_mem_2_1_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_1_2 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_2_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_2_2 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_3_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_3_2 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_4_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_4_2 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_5_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_5_2 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_6_1 [0: K_H_2*K_W_2 -1];
    reg [8 -1:0] weight_mem_2_6_2 [0: K_H_2*K_W_2 -1];
    
    
    reg [DATA_WIDTH* IMG_H*IMG_W -1:0] in_image;
    
    reg [DATA_WIDTH* K_H_1*K_W_1 *NUM_KERNELS_1 -1:0] in_kernel_1;
    
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_1;
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_2;
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_3;
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_4;
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_5;
    reg [DATA_WIDTH* K_H_2*K_W_2 *NUM_KERNELS_2 -1:0] in_kernel_2_6;


    wire [768-1:0] out_value_conv1;
    
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_1;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_2;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_3;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_4;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_5;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 -1:0] out_value_conv2_6;
    wire [DATA_WIDTH* NUM_KERNELS_2* 2*2 *6-1:0] out_value_conv2;
    
    wire valid_out_conv1;
    wire valid_out_conv2_1;
    wire valid_out_conv2_2;
    wire valid_out_conv2_3;
    wire valid_out_conv2_4;
    wire valid_out_conv2_5;
    wire valid_out_conv2_6;
    wire valid_out_conv2;
    
    
    wire [(DATA_WIDTH*4)*(6+49-1)-1:0] mac_out;
    wire [DATA_WIDTH*6*49-1:0] activation_out;
    wire [DATA_WIDTH*6*49-1:0] transposed_out;
    wire [DATA_WIDTH*6*16 -1:0] pooled_out;
    wire [DATA_WIDTH*16-1:0] window_flat, kernel_flat;
    wire window_valid, windows_done, kernel_valid, kernels_done, mac_letting, mac_done, activation_ready, activation_done, activation_complete, transposed_out_valid, pooled_out_valid, pooling_done;
    

    integer i=0,j=0,k=0;
    initial begin
        $readmemh("9_0.mem", image_mem);
        
        $readmemh("conv1_weight_1.mem", weight_mem_1_1);
        $readmemh("conv1_weight_2.mem", weight_mem_1_2);
        $readmemh("conv1_weight_3.mem", weight_mem_1_3);
        $readmemh("conv1_weight_4.mem", weight_mem_1_4);
        $readmemh("conv1_weight_5.mem", weight_mem_1_5);
        $readmemh("conv1_weight_6.mem", weight_mem_1_6);
        
        $readmemh("conv2_weight_1_1.mem", weight_mem_2_1_1);
        $readmemh("conv2_weight_1_2.mem", weight_mem_2_1_2);
        $readmemh("conv2_weight_2_1.mem", weight_mem_2_2_1);
        $readmemh("conv2_weight_2_2.mem", weight_mem_2_2_2);
        $readmemh("conv2_weight_3_1.mem", weight_mem_2_3_1);
        $readmemh("conv2_weight_3_1.mem", weight_mem_2_3_2);
        $readmemh("conv2_weight_4_1.mem", weight_mem_2_4_1);
        $readmemh("conv2_weight_4_2.mem", weight_mem_2_4_2);
        $readmemh("conv2_weight_5_1.mem", weight_mem_2_5_1);
        $readmemh("conv2_weight_5_2.mem", weight_mem_2_5_2);
        $readmemh("conv2_weight_6_1.mem", weight_mem_2_6_1);
        $readmemh("conv2_weight_6_2.mem", weight_mem_2_6_2);
        
        //loading image mem data to image reg
        for(i=0; i<IMG_H; i=i+1) begin
            for(j=0; j<IMG_W; j=j+1) begin
                in_image[(i*IMG_W + j)*DATA_WIDTH +: DATA_WIDTH] = image_mem[i*IMG_W + j];
            end
        end

        //loading weight mem data to kernels reg
        //conv1
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(0*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_1[i];
        end
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(1*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_2[i];
        end
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(2*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_3[i];
        end        
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(3*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_4[i];
        end
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(4*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_5[i];
        end
        for(i=0; i<K_H_1*K_W_1; i=i+1) begin
            in_kernel_1[(5*K_H_1*K_W_1+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1_6[i];
        end 
        
        //conv2
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_1[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_1_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_1[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_1_2[i];
        end 
        
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_2[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_2_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_2[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_2_2[i];
        end 
        
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_3[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_3_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_3[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_3_2[i];
        end 
        
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_4[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_4_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_4[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_4_2[i];
        end 
        
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_5[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_5_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_5[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_5_2[i];
        end 
        
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_6[(0*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_6_1[i];
        end     
        for(i=0; i<K_H_2*K_W_2; i=i+1) begin
            in_kernel_2_6[(1*K_H_2*K_W_2+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2_6_2[i];
        end 

         
    end
    
    cnn_top convolution(
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
        
        .pool_type(1'b0),
        .act_type(2'b00),
        
        .out_value_conv1(out_value_conv1),
        .valid_out_conv1(valid_out_conv1),
        .out_value_conv2(out_value_conv2),
        .valid_out_conv2(valid_out_conv2),
        
        .out_value_conv2_1(out_value_conv2_1),
        .out_value_conv2_2(out_value_conv2_2),
        .out_value_conv2_3(out_value_conv2_3),
        .out_value_conv2_4(out_value_conv2_4),
        .out_value_conv2_5(out_value_conv2_5),
        .out_value_conv2_6(out_value_conv2_6),
        .valid_out_conv2_1(valid_out_conv2_1),
        .valid_out_conv2_2(valid_out_conv2_2),
        .valid_out_conv2_3(valid_out_conv2_3),
        .valid_out_conv2_4(valid_out_conv2_4),
        .valid_out_conv2_5(valid_out_conv2_5),
        .valid_out_conv2_6(valid_out_conv2_6),
        
        .mac_out(mac_out),
        .activation_out(activation_out),
        .transposed_out(transposed_out),
        .pooled_out(pooled_out),
        .window_valid(window_valid),
        .window_flat(window_flat),
        .windows_done(windows_done),
        .kernels_done(kernels_done),
        .kernel_valid(kernel_valid),
        .kernel_flat(kernel_flat),
        .mac_letting(mac_letting), 
        .mac_done(mac_done), 
        .activation_ready(activation_ready), 
        .activation_done(activation_done) ,
        .activation_complete(activation_complete), 
        .transposed_out_valid(transposed_out_valid),
        .pooled_out_valid(pooled_out_valid), 
        .pooling_done(pooling_done)
    );


    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1; start = 0;
        #20;
        rst = 0;
        #10;

       

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(valid_out_conv2);
        $display("Final output ready at time %0t", $time);

        #100 $finish;
    end



endmodule
