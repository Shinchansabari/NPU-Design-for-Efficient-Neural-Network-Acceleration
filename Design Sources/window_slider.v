`timescale 1ns / 1ps

module window_slider #(
    parameter DATA_WIDTH = 8,
    parameter IMG_H = 8, 
    parameter IMG_W = 8, 
    parameter K_H = 3,  
    parameter K_W = 3,  
    parameter STRIDE_H = 1,  
    parameter STRIDE_W = 1  
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire next_window,
    input wire [DATA_WIDTH*IMG_H*IMG_W-1:0] image_flat,

    output reg [DATA_WIDTH*K_H*K_W-1:0] window_flat,
    output reg window_valid=1'b0,
    output reg all_done
);

    localparam OUT_H = (IMG_H - K_H) / STRIDE_H + 1;
    localparam OUT_W = (IMG_W - K_W) / STRIDE_W + 1;

    reg [$clog2(OUT_H)-1:0] win_row;
    reg [$clog2(OUT_W)-1:0] win_col;
    reg started=1'b0;
    reg scanning;
    reg next_window_d;
    integer i, j, img_r, img_c, flat_img_idx, flat_win_idx;

    // Core logic
    always @(posedge clk or posedge rst) begin
        if(start) started <= 1'b1;
        if (rst) begin
            win_row <= 0;
            win_col <= 0;
            scanning <= 1'b0;
            window_flat <= {DATA_WIDTH*K_H*K_W{1'b0}};
            started <= 1'b0;
            all_done <= 1'b0;
        end 
        else begin
            if (!scanning) begin
                scanning <= 1'b1;
                win_row <= 0;
                win_col <= 0;
            end 
            else if (scanning && next_window && ~window_valid && ~all_done && started) begin
                // Generate next window
                for (i = 0; i < K_H; i = i + 1) begin
                    for (j = 0; j < K_W; j = j + 1) begin
                        img_r = win_row * STRIDE_H + i;
                        img_c = win_col * STRIDE_W + j;
                        flat_img_idx = DATA_WIDTH * (img_r * IMG_W + img_c);
                        flat_win_idx = DATA_WIDTH * (i * K_W + j);
                        window_flat[flat_win_idx +: DATA_WIDTH] <= image_flat[flat_img_idx +: DATA_WIDTH];
                    end
                end
                window_valid <= 1'b1;

                // Advance indices
                if (win_col + 1 < OUT_W)
                    win_col <= win_col + 1;
                else begin
                    win_col <= 0;
                    if (win_row + 1 < OUT_H)
                        win_row <= win_row + 1;
                    else begin
                        scanning <= 1'b0;
                        all_done <= 1'b1;
                        started <= 1'b0;
                    end
                end
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            window_valid <= 1'b0;
            all_done <= 1'b0;
            started <= 1'b0;
        end
        else begin
            if(window_valid) begin
                if(all_done) begin
                    window_flat <= {DATA_WIDTH*K_H*K_W{1'b0}};
                    all_done <= 1'b0;
                end
                window_valid <= 1'b0;
             end 
        end
    end
endmodule
