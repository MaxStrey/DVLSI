// reg_en_reset.v
// Parameterized register with synchronous reset and enable.
// This is the "bus version" of your ff_reset_en.

module reg_en_reset #(parameter W=32) (
    input  wire         clk,
    input  wire         reset,   // synchronous reset
    input  wire         en,      // enable
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    always @(posedge clk) begin
        if (reset)
            q <= {W{1'b0}};
        else if (en)
            q <= d;
        // else: hold
    end
endmodule