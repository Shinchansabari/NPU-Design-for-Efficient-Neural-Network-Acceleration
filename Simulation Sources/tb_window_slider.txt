`timescale 1ns / 1ps

module tb_window_slider();

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam IMG_H = 4;
    localparam IMG_W = 4;
    localparam K_H = 2;
    localparam K_W = 2;
    localparam STRIDE_H = 1;
    localparam STRIDE_W = 1;

    // DUT signals
    reg clk;
    reg rst;
    reg start;
    reg next_window;
    wire [DATA_WIDTH*K_H*K_W-1:0] window_flat;
    wire window_valid;
    wire all_done;

    // Flattened 4x4 image: values from 1 to 16
    reg [DATA_WIDTH*IMG_H*IMG_W-1:0] image_flat;

    // Instantiate DUT
    window_slider #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_H(IMG_H),
        .IMG_W(IMG_W),
        .K_H(K_H),
        .K_W(K_W),
        .STRIDE_H(STRIDE_H),
        .STRIDE_W(STRIDE_W)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .next_window(next_window),
        .image_flat(image_flat),
        .window_flat(window_flat),
        .window_valid(window_valid),
        .all_done(all_done)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i, j;

    // Task to display 2x2 window
    task print_window;
        input [DATA_WIDTH*K_H*K_W-1:0] flat;
        integer r, c;
        reg [DATA_WIDTH-1:0] val;
        begin
            $display("Window:");
            for (r = 0; r < K_H; r = r + 1) begin
                for (c = 0; c < K_W; c = c + 1) begin
                    val = flat[(r*K_W + c)*DATA_WIDTH +: DATA_WIDTH];
                    $write("%0d ", val);
                end
                $write("\n");
            end
            $write("\n");
        end
    endtask

    // Test procedure
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        next_window = 0;

        // Initialize image (1 to 16)
        for (i = 0; i < IMG_H*IMG_W; i = i + 1)
            image_flat[i*DATA_WIDTH +: DATA_WIDTH] = i + 1;

        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;

        // Wait a bit and begin scanning
        @(negedge clk);

        while (!all_done) begin
            next_window = 1;
            @(negedge clk);
            next_window = 0;
            @(posedge clk);
            if (window_valid)
                print_window(window_flat);
            #10;
        end

        $display("? All windows processed!");
        $finish;
    end

endmodule
