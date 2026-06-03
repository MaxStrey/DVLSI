module mem(
    input        clk,
    input        we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
);

    reg [31:0] RAM [0:63];   // 64 words, each 32-bit

`ifndef SYNTHESIS
    initial begin
        $readmemh("riscvtest.txt", RAM);
    end
`endif

//The LSB 2bits in address input "a" are dumped and not used. Explain why: Bonus points +5;
    assign rd = RAM[a[31:2]]; 

    always @(posedge clk) begin
        if (we)
            RAM[a[31:2]] <= wd;
    end

endmodule