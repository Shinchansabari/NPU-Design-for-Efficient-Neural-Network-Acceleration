`timescale 1ns / 1ps

module tb_cnn;


    parameter DATA_WIDTH = 8;
    parameter IMG_H = 28;
    parameter IMG_W = 28;
    parameter K_H = 4;
    parameter K_W = 4;
    parameter STRIDE_H = 4;
    parameter STRIDE_W = 4;
    parameter POOL_SIZE = 2;
    parameter NUM_KERNELS = 6;
    localparam MAP_HEIGHT = (IMG_H - K_H) / STRIDE_H + 1;
    localparam MAP_WIDTH = (IMG_W - K_W) / STRIDE_W + 1;
    localparam NUM_WINDOWS = MAP_HEIGHT*MAP_WIDTH;

    reg clk;
    reg rst;
    reg start;
    reg input_taken;
    
    reg [DATA_WIDTH-1:0] image_mem [0:IMG_H*IMG_W-1];
    /*
    reg [DATA_WIDTH-1:0] weight_mem_1 [0:K_H-1][0:K_W-1];
    reg [DATA_WIDTH-1:0] weight_mem_2 [0:K_H-1][0:K_W-1];
    reg [DATA_WIDTH-1:0] weight_mem_3 [0:K_H-1][0:K_W-1];
    */
    reg [DATA_WIDTH-1:0] weight_mem_1 [0:K_W*K_H-1];
    reg [DATA_WIDTH-1:0] weight_mem_2 [0:K_W*K_H-1];
    reg [DATA_WIDTH-1:0] weight_mem_3 [0:K_W*K_H-1];
    reg [DATA_WIDTH-1:0] weight_mem_4 [0:K_W*K_H-1];
    reg [DATA_WIDTH-1:0] weight_mem_5 [0:K_W*K_H-1];
    reg [DATA_WIDTH-1:0] weight_mem_6 [0:K_W*K_H-1];
    
    reg [DATA_WIDTH*IMG_H*IMG_W-1:0] in_image;
    reg [DATA_WIDTH*K_H*K_W*NUM_KERNELS-1:0] in_kernel;
    reg pool_type;
    reg [1:0] act_type;

    // CNN outputs
    wire [(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS)-1:0] out_value;
    wire valid_out;

    // Intermediate outputs
    wire window_valid, windows_done, kernel_valid, kernels_done;
    wire mac_fed_left, mac_fed_top, mac_left_ready, mac_top_ready;
    wire mac_left_valid, mac_top_valid, mac_letting, mac_done;
    wire activation_ready, activation_done;
    wire transposed_out_valid, pooled_out_valid;

    wire [DATA_WIDTH*K_H*K_W-1:0] window_flat, kernel_flat;
    wire [DATA_WIDTH*(K_H*K_W + (NUM_WINDOWS>NUM_KERNELS?NUM_WINDOWS:NUM_KERNELS) -1)-1:0] mac_feed_left;
    wire [DATA_WIDTH*(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS?NUM_KERNELS:NUM_WINDOWS) -1)-1:0] mac_feed_top;
    wire [(DATA_WIDTH*4)*(NUM_KERNELS+NUM_WINDOWS-1)-1:0] mac_out;
    wire [DATA_WIDTH*NUM_KERNELS*NUM_WINDOWS-1:0] activation_out;
    wire [DATA_WIDTH*NUM_KERNELS*NUM_WINDOWS-1:0] transposed_out;
    wire [(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS)-1:0] pooled_out;
    
    wire [(K_H*K_W + (NUM_KERNELS>NUM_WINDOWS? NUM_KERNELS:NUM_WINDOWS) -1) -1:0] cycle_count;
    wire [7:0] diag;

    // ============================================================
    // Instantiate DUT
    // ============================================================
    integer i=0,j=0,k=0;
    initial begin
        $readmemh("9_0.mem", image_mem);
        
        $readmemh("conv1_weight_1.mem", weight_mem_1);
        $readmemh("conv1_weight_2.mem", weight_mem_2);
        $readmemh("conv1_weight_3.mem", weight_mem_3);
        $readmemh("conv1_weight_4.mem", weight_mem_4);
        $readmemh("conv1_weight_5.mem", weight_mem_5);
        $readmemh("conv1_weight_6.mem", weight_mem_6);
        
        
        for(i=0; i<IMG_H; i=i+1) begin
            for(j=0; j<IMG_W; j=j+1) begin
                in_image[(i*IMG_W + j)*DATA_WIDTH +: DATA_WIDTH] = image_mem[i*IMG_W + j];
            end
        end

        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[i*DATA_WIDTH +: DATA_WIDTH] = weight_mem_1[i];
        end
        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[(K_H*K_W+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_2[i];
        end
        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[(2*K_H*K_W+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_3[i];
        end 
        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[(3*K_H*K_W+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_4[i];
        end
        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[(4*K_H*K_W+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_5[i];
        end
        for(i=0; i<K_H*K_W; i=i+1) begin
            in_kernel[(5*K_H*K_W+i)*DATA_WIDTH +: DATA_WIDTH] = weight_mem_6[i];
        end    
             
    end
    
    cnn #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_H(IMG_H),
        .IMG_W(IMG_W),
        .K_H(K_H),
        .K_W(K_W),
        .STRIDE_H(STRIDE_H),
        .STRIDE_W(STRIDE_W),
        .POOL_SIZE(POOL_SIZE),
        .NUM_KERNELS(NUM_KERNELS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_taken(input_taken),
        .in_image(in_image),
        .in_kernel(in_kernel),
        .pool_type(pool_type),
        .act_type(act_type),

        .out_value(out_value),
        .valid_out(valid_out),

        .window_valid(window_valid),
        .windows_done(windows_done),
        .kernel_valid(kernel_valid),
        .kernels_done(kernels_done),
        .mac_fed_left(mac_fed_left),
        .mac_fed_top(mac_fed_top),
        .mac_left_ready(mac_left_ready),
        .mac_top_ready(mac_top_ready),
        .mac_left_valid(mac_left_valid),
        .mac_top_valid(mac_top_valid),
        .mac_letting(mac_letting),
        .mac_done(mac_done),
        .activation_ready(activation_ready),
        .activation_done(activation_done),
        .transposed_out_valid(transposed_out_valid),
        .pooled_out_valid(pooled_out_valid),

        .window_flat(window_flat),
        .kernel_flat(kernel_flat),
        .mac_feed_left(mac_feed_left),
        .mac_feed_top(mac_feed_top),
        .mac_out(mac_out),
        .activation_out(activation_out),
        .transposed_out(transposed_out),
        .pooled_out(pooled_out),
        
        .cycle_count(cycle_count),
        .diag(diag)
    );

    // ============================================================
    // Clock Generation
    // ============================================================
    initial clk = 0;
    always #1.25 clk = ~clk;

    // ============================================================
    // Stimulus
    // ============================================================
    initial begin
        rst = 1; start = 0; input_taken = 0; pool_type = 0; act_type = 2'b00;
        #20;
        rst = 0;
        #10;

       

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(valid_out);
        $display("Final output ready at time %0t", $time);

        #100 $finish;
    end



endmodule
