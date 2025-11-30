`timescale 1ns / 1ps

module transpose_module #(
    parameter DATA_WIDTH = 8,
    parameter MAT_ROWS   = 4,
    parameter MAT_COLS   = 4
)(
    input  wire                          clk,
    input  wire                          rst,        // active-high reset
    input  wire                          start,      // start signal
    input  wire [DATA_WIDTH*MAT_ROWS*MAT_COLS-1:0] input_value,
    output reg [DATA_WIDTH*MAT_ROWS*MAT_COLS-1:0] output_value,
    output reg                           valid_out   // high when transpose complete
);

    // ------------------------------------------------------------------------
    // Local parameters and indices
    // ------------------------------------------------------------------------
    reg [MAT_ROWS-1:0] row_idx=0;
    reg [MAT_COLS-1:0] col_idx=0;
    reg busy, all_done;
    integer in_flat, out_flat;
    // ------------------------------------------------------------------------
    // Sequential transpose process
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if(valid_out) begin
            all_done <= 1'b1;
            valid_out <= 1'b0;
        end
        if (rst) begin
            output_value <= 0;
            row_idx      <= 0;
            col_idx      <= 0;
            valid_out    <= 0;
            busy         <= 0;
            all_done <= 1'b0;
        end else begin
            valid_out <= 0; // default

            if (start && !busy && ~valid_out) begin
                // Begin new transpose
                busy      <= 1'b1;
                row_idx   <= 0;
                col_idx   <= 0;
            end 
            else if (busy && ~all_done) begin
                // Compute input/output flat indices
                
                in_flat  = (row_idx * MAT_COLS + col_idx) * DATA_WIDTH;
                out_flat = (col_idx * MAT_ROWS + row_idx) * DATA_WIDTH;

                // Perform one element transpose per clock
                output_value[out_flat +: DATA_WIDTH] <= input_value[in_flat +: DATA_WIDTH];

                // Advance indices
                if (col_idx == MAT_COLS - 1) begin
                    col_idx <= 0;
                    if (row_idx == MAT_ROWS - 1) begin
                        row_idx <= 0;
                        busy <= 1'b0;
                        valid_out <= 1'b1; // transpose complete
                    end else begin
                        row_idx <= row_idx + 1;
                    end
                end else begin
                    col_idx <= col_idx + 1;
                end
            end
        end
    end
endmodule
