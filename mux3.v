// mux3.v
// 3:1 mux, parameterized width. Select is 2 bits (00,01,10 valid).

module mux3 #(parameter W=32) (
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [1:0]   s,
    output reg  [W-1:0] y
);
    always @(*) begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = {W{1'bx}};
        endcase
    end
endmodule