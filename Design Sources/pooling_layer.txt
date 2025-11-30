`timescale 1ns / 1ps

module pooling_layer #(
    parameter DATA_WIDTH = 8,
    parameter MAP_WIDTH = 32,
    parameter MAP_HEIGHT = 32,
    parameter MAP_SIZE = MAP_WIDTH*MAP_HEIGHT, //=NUM_WINDOWS
    parameter NUM_KERNELS = 3,
    parameter POOL_SIZE  = 2
    
)(
    input  wire                     clk,
    input  wire                     rst,
    input                            pool_type, //0=max,1=avg
    input  wire                     valid_in,
    input [DATA_WIDTH*NUM_KERNELS*MAP_SIZE-1:0] input_value,

    output reg                      valid_out=1'b0,
    output reg [NUM_KERNELS-1:0] num_kernels_complete = 0,
    output reg [(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS)-1:0] output_value = {(DATA_WIDTH* ((MAP_WIDTH/POOL_SIZE)+(MAP_WIDTH%POOL_SIZE>0?1:0)) * ((MAP_HEIGHT/POOL_SIZE)+(MAP_HEIGHT%POOL_SIZE>0?1:0)) *NUM_KERNELS) {1'b0}},
    output reg all_done=1'b0
);
    integer kernel_count=0, r=0, c=0, idx=0, i=0, j=0;
    integer num=0, out_idx;
    reg [DATA_WIDTH-1:0] temp = {DATA_WIDTH {1'b0}};
    reg started = 1'b0;
    
    localparam MAP_HEIGHT_OUT = MAP_HEIGHT / POOL_SIZE;
    localparam MAP_WIDTH_OUT  = MAP_WIDTH / POOL_SIZE;
    
    always @(posedge clk or posedge rst) begin
    if(valid_in) started = 1'b1;
    if(valid_out) begin
        valid_out = 1'b0;
    end
    if(all_done) begin
        all_done = 1'b0;
        started = 1'b0;
    end
        if(rst) begin
                valid_out <= 1'b0;
                started <= 1'b0;
                output_value <= {((DATA_WIDTH*MAP_SIZE)/(POOL_SIZE*POOL_SIZE)) {1'b0}};
                temp <= {DATA_WIDTH {1'b0}};
                out_idx=0;
            end
       
        else if(started && ~valid_out) begin
            if(kernel_count<NUM_KERNELS) begin
                if(r<MAP_HEIGHT-POOL_SIZE+1) begin
                    if(c<MAP_WIDTH-POOL_SIZE+1) begin
                        idx = kernel_count*MAP_SIZE + r*MAP_WIDTH + c;
                        c = c+POOL_SIZE;
                        temp = {DATA_WIDTH {1'b0}};
                        for(i=0; i<POOL_SIZE; i=i+1) begin
                            for(j=0; j<POOL_SIZE; j=j+1) begin
                                if(i<MAP_HEIGHT && j<MAP_WIDTH) num = input_value[(idx + i*MAP_WIDTH + j)*DATA_WIDTH +: DATA_WIDTH];
                                else num = {DATA_WIDTH {1'b0}};
                                case(pool_type)
                                    1'b0:
                                        if(num > temp) temp = num;
                                    1'b1:
                                        temp = temp + num;
                                endcase
                            end
                        end
                        case(pool_type)
                            1'b0: begin
                                output_value[out_idx*DATA_WIDTH +: DATA_WIDTH] <= temp;
                                out_idx = out_idx+1; 
                            end
                        endcase
                    end
                    else begin
                        c=0;
                        r=r+POOL_SIZE;
                    end
                end
                else begin
                    r=0;
                    c=0;
                    valid_out = 1'b1;
                    kernel_count=kernel_count+1;
                    num_kernels_complete = kernel_count;
                    if(num_kernels_complete == NUM_KERNELS) all_done <= 1'b1;
                end
            end
        end
    end


endmodule
