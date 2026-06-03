// mux4.v - 4:1 mux, parameterized width
module mux4 #(parameter W=32) (
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [W-1:0] d3,
    input  wire [1:0]   s,
    output reg  [W-1:0] y
);
    always @(*) begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            2'b11: y = d3;
        endcase
    end
endmodule