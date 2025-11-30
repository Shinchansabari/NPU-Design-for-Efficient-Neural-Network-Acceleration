module comparator #(
  parameter DATA_WIDTH  = 8,
  parameter N           = 10,
  parameter INDEX_WIDTH = $clog2(N)
)(
  input  wire                      clk,
  input  wire                      rst,
  input  wire                      load,
  input  wire [N*DATA_WIDTH-1:0]   data_in,
  output reg  [INDEX_WIDTH-1:0]    decision,
  output reg                       valid_out,
  output reg  [DATA_WIDTH-1:0]     next_max_val
);

  // Internal combinational signals
  reg [DATA_WIDTH-1:0] comb_max_val;
  reg [INDEX_WIDTH-1:0] comb_decision;
  integer i;

  // --- Combinational block: find max and index from data_in directly ---
  always @(*) begin
    comb_max_val  = data_in[0 +: DATA_WIDTH];
    comb_decision = {INDEX_WIDTH{1'b0}};
    for (i = 1; i < N; i = i + 1) begin
      if (data_in[i*DATA_WIDTH +: DATA_WIDTH] > comb_max_val) begin
        comb_max_val  = data_in[i*DATA_WIDTH +: DATA_WIDTH];
        comb_decision = i;
      end
    end
  end

  // --- Sequential block: output registration and reset handling ---
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      decision      <= {INDEX_WIDTH{1'b0}};
      valid_out     <= 1'b0;
      next_max_val  <= {DATA_WIDTH{1'b0}};
    end else if (load) begin
      decision      <= comb_decision;
      next_max_val  <= comb_max_val;
      valid_out     <= 1'b1;
    end else begin
      valid_out <= 1'b0;
    end
  end

endmodule
