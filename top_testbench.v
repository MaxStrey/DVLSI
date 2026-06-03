`timescale 1ns/1ps

module testbench;

    reg         clk;
    reg         reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire        MemWrite;

    // instantiate top module(DUT)
    top dut(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    // initialize reset
    initial begin
        reset <= 1;
        #22;
        reset <= 0;
    end

    // generate clock: 10 ns period, 50% duty cycle
    always begin
        clk <= 1;
        #5;
        clk <= 0;
        #5;
    end

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("tb_riscvmulti.vcd");
        $dumpvars(0, testbench);
    end

    // check results on each negative edge of the clock
    always @(negedge clk) begin
        if (MemWrite) begin
            // NOTE: single '&' is bitwise, replicating original behavior:
            // (DataAdr === 100) & (WriteData === 25)
            if (DataAdr === 32'd100 & WriteData === 32'd25) begin
                $display("Simulation succeeded");
                $stop;
            end
            else if (DataAdr !== 32'd96) begin
                $display("Simulation failed");
                $stop;
            end
        end
    end

endmodule

module top(
    input        clk,
    input        reset,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output        MemWrite
);

    wire [31:0] ReadData;

    // instantiate processor and memory
    riscvmulti rvmulti(
        .clk(clk),
        .reset(reset),
        .MemWrite(MemWrite),
        .Adr(DataAdr),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

    mem mem(
        .clk(clk),
        .we(MemWrite),
        .a(DataAdr),
        .wd(WriteData),
        .rd(ReadData)
    );

endmodule

module riscvmulti(
    input        clk,
    input        reset,
    output       MemWrite,
    output [31:0] Adr,
    output [31:0] WriteData,
    input  [31:0] ReadData
);

    // Internal control/status signals
    wire        RegWrite;
    wire [1:0]  ResultSrc;
    wire [1:0]  ImmSrc;
    wire [2:0]  ALUControl;
    wire        PCWrite;
    wire        IRWrite;
    wire [1:0]  ALUSrcA;
    wire [1:0]  ALUSrcB;
    wire        AdrSrc;
    wire        Zero;
    wire [6:0]  op;
    wire [2:0]  funct3;
    wire        funct7b5;

    // Controller FSM
    controller top_fsm(
        .clk(clk),
        .reset(reset),
        .op(op),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .Zero(Zero),
        .ImmSrc(ImmSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .AdrSrc(AdrSrc),
        .ALUControl(ALUControl),
        .IRWrite(IRWrite),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite)
    );

    // Datapath
    datapath dp(
        .clk(clk),
        .reset(reset),
        .ImmSrc(ImmSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .AdrSrc(AdrSrc),
        .IRWrite(IRWrite),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .op(op),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .Zero(Zero),
        .Adr(Adr),
        .ReadData(ReadData),
        .WriteData(WriteData)
    );

endmodule

module regfile(
    input        clk,
    input        we3,
    input  [4:0] a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1,
    output [31:0] rd2
);

    reg [31:0] rf [0:31];   // 32 registers, 32-bit each

    // Write on rising clock edge
    always @(posedge clk) begin
        if (we3)
            rf[a3] <= wd3;
    end

    // Register x0 always reads as zero
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;

endmodule

module extend(
    input  [31:7] instr,
    input  [1:0]  immsrc,
    output reg [31:0] immext
);

    always @(*) begin
        case (immsrc)
            // I-type (e.g. load, addi, slti, jalr)
            2'b00: immext = {{20{instr[31]}}, instr[31:20]};

            // S-type (stores)
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type (branches)
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

            // J-type (jal)
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            default: immext = 32'bx;   // undefined
        endcase
    end

endmodule