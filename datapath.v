module datapath(
    input         clk,
    input         reset,
    input  [1:0]  ImmSrc,
    input  [1:0]  ALUSrcA,
    input  [1:0]  ALUSrcB,
    input  [1:0]  ResultSrc,
    input         AdrSrc,
    input         IRWrite,
    input         PCWrite,
    input         RegWrite,
    input         MemWrite,
    input  [2:0]  ALUControl,
    output [6:0]  op,
    output [2:0]  funct3,
    output        funct7b5,
    output        Zero,
    output [31:0] Adr,
    input  [31:0] ReadData,
    output [31:0] WriteData
);

    // Internal wires
    wire [31:0] PC, Instr, OldPC, A, B, Data, ALUOut;
    wire [31:0] RD1, RD2, ImmExt;
    wire [31:0] SrcA, SrcB, ALUResult, Result, PCNext;

    // Instruction fields
    assign op       = Instr[6:0];
    assign funct3   = Instr[14:12];
    assign funct7b5 = Instr[30];

    wire [4:0] Rs1 = Instr[19:15];
    wire [4:0] Rs2 = Instr[24:20];
    wire [4:0] Rd  = Instr[11:7];

    // PC register
    reg_en_reset #(32) pc_reg (
        .clk(clk),
        .reset(reset),
        .en(PCWrite),
        .d(PCNext),
        .q(PC)
    );

    // Instruction register
    reg_en_reset #(32) instr_reg (
        .clk(clk),
        .reset(reset),
        .en(IRWrite),
        .d(ReadData),
        .q(Instr)
    );

    // OldPC register
    reg_en_reset #(32) oldpc_reg (
        .clk(clk),
        .reset(reset),
        .en(IRWrite),
        .d(PC),
        .q(OldPC)
    );

    // A register (rs1 value)
    reg_en_reset #(32) a_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(RD1),
        .q(A)
    );

    // Data register (memory data)
    reg_en_reset #(32) data_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(ReadData),
        .q(Data)
    );

    // ALUOut register
    reg_en_reset #(32) aluout_reg (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .d(ALUResult),
        .q(ALUOut)
    );

    // Address mux
    mux2 #(32) adr_mux (
        .d0(PC),
        .d1(ALUOut),
        .s(AdrSrc),
        .y(Adr)
    );

    // Register file
    regfile rf (
        .clk(clk),
        .we3(RegWrite),
        .a1(Rs1),
        .a2(Rs2),
        .a3(Rd),
        .wd3(Result),
        .rd1(RD1),
        .rd2(RD2)
    );

    assign B = RD2;
    assign WriteData = B;

    // Extend unit
    extend ext (
        .instr(Instr[31:7]),
        .immsrc(ImmSrc),
        .immext(ImmExt)
    );

    // SrcA mux
    mux3 #(32) srca_mux (
        .d0(PC),
        .d1(OldPC),
        .d2(A),
        .s(ALUSrcA),
        .y(SrcA)
    );

    // SrcB mux
    mux3 #(32) srcb_mux (
        .d0(B),
        .d1(ImmExt),
        .d2(32'd4),
        .s(ALUSrcB),
        .y(SrcB)
    );

    // ALU
    alu alu_inst (
        .A(SrcA),
        .B(SrcB),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    // Result mux
    mux4 #(32) result_mux (
        .d0(ALUOut),
        .d1(Data),
        .d2(ALUResult),
        .d3(ALUResult),
        .s(ResultSrc),
        .y(Result)
    );

    // PCNext mux - selects ALUOut for JAL (ResultSrc=11), otherwise Result
    assign PCNext = (ResultSrc[1] & ResultSrc[0]) ? ALUOut : Result;

endmodule