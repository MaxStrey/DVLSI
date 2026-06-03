module controller(
    input        clk,
    input        reset,
    input  [6:0] op,
    input  [2:0] funct3,
    input        funct7b5,
    input        Zero,
    output reg [1:0] ImmSrc,
    output reg [1:0] ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg [1:0] ResultSrc,
    output reg       AdrSrc,
    output reg [2:0] ALUControl,
    output reg       IRWrite,
    output reg       PCWrite,
    output reg       RegWrite,
    output reg       MemWrite
);

    // Opcodes
    localparam OP_RTYPE = 7'b0110011;
    localparam OP_ITYPE = 7'b0010011;
    localparam OP_LW    = 7'b0000011;
    localparam OP_SW    = 7'b0100011;
    localparam OP_BEQ   = 7'b1100011;
    localparam OP_JAL   = 7'b1101111;

    // States
    localparam S_FETCH    = 4'd0;
    localparam S_DECODE   = 4'd1;
    localparam S_MEMADR   = 4'd2;
    localparam S_MEMREAD  = 4'd3;
    localparam S_MEMWB    = 4'd4;
    localparam S_MEMWRITE = 4'd5;
    localparam S_EXECUTER = 4'd6;
    localparam S_ALUWB    = 4'd7;
    localparam S_EXECUTEI = 4'd8;
    localparam S_JAL      = 4'd9;
    localparam S_BEQ      = 4'd10;

    reg [3:0] state, nextstate;

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= S_FETCH;
        else
            state <= nextstate;
    end

    // Next state logic
    always @(*) begin
        case (state)
            S_FETCH:    nextstate = S_DECODE;
            S_DECODE: begin
                case (op)
                    OP_LW:     nextstate = S_MEMADR;
                    OP_SW:     nextstate = S_MEMADR;
                    OP_RTYPE:  nextstate = S_EXECUTER;
                    OP_ITYPE:  nextstate = S_EXECUTEI;
                    OP_JAL:    nextstate = S_JAL;
                    OP_BEQ:    nextstate = S_BEQ;
                    default:   nextstate = S_FETCH;
                endcase
            end
            S_MEMADR: begin
                case (op)
                    OP_LW:   nextstate = S_MEMREAD;
                    OP_SW:   nextstate = S_MEMWRITE;
                    default: nextstate = S_FETCH;
                endcase
            end
            S_MEMREAD:  nextstate = S_MEMWB;
            S_MEMWB:    nextstate = S_FETCH;
            S_MEMWRITE: nextstate = S_FETCH;
            S_EXECUTER: nextstate = S_ALUWB;
            S_ALUWB:    nextstate = S_FETCH;
            S_EXECUTEI: nextstate = S_ALUWB;
            S_JAL:      nextstate = S_FETCH;
            S_BEQ:      nextstate = S_FETCH;
            default:    nextstate = S_FETCH;
        endcase
    end

    // ALU Decoder
    reg [1:0] ALUOp;

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000;  // ADD
            2'b01: ALUControl = 3'b001;  // SUB
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7b5 && op == OP_RTYPE)
                            ALUControl = 3'b001;  // SUB
                        else
                            ALUControl = 3'b000;  // ADD
                    end
                    3'b010: ALUControl = 3'b101;  // SLT
                    3'b110: ALUControl = 3'b011;  // OR
                    3'b111: ALUControl = 3'b010;  // AND
                    default: ALUControl = 3'b000;
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end

    // Output logic
    reg Branch;

    always @(*) begin
        // Defaults
        IRWrite   = 1'b0;
        PCWrite   = 1'b0;
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;
        AdrSrc    = 1'b0;
        ResultSrc = 2'b00;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        ALUOp     = 2'b00;
        ImmSrc    = 2'b00;
        Branch    = 1'b0;

        case (state)
            S_FETCH: begin
                AdrSrc    = 1'b0;
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00;
                ALUSrcB   = 2'b10;
                ALUOp     = 2'b00;
                ResultSrc = 2'b10;
                PCWrite   = 1'b1;
            end

            S_DECODE: begin
                ALUSrcA = 2'b01;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                case (op)
                    OP_SW:   ImmSrc = 2'b01;
                    OP_BEQ:  ImmSrc = 2'b10;
                    OP_JAL:  ImmSrc = 2'b11;
                    default: ImmSrc = 2'b00;
                endcase
            end

            S_MEMADR: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                case (op)
                    OP_SW:   ImmSrc = 2'b01;
                    default: ImmSrc = 2'b00;
                endcase
            end

            S_MEMREAD: begin
                ResultSrc = 2'b00;
                AdrSrc    = 1'b1;
            end

            S_MEMWB: begin
                ResultSrc = 2'b01;
                RegWrite  = 1'b1;
            end

            S_MEMWRITE: begin
                AdrSrc   = 1'b1;
                MemWrite = 1'b1;
            end

            S_EXECUTER: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                ALUOp   = 2'b10;
            end

            S_ALUWB: begin
                ResultSrc = 2'b00;
                RegWrite  = 1'b1;
            end

            S_EXECUTEI: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b10;
                ImmSrc  = 2'b00;
            end

            S_JAL: begin
                ALUSrcA   = 2'b01;
                ALUSrcB   = 2'b10;
                ALUOp     = 2'b00;
                ResultSrc = 2'b11;
                PCWrite   = 1'b1;
                RegWrite  = 1'b1;
            end

            S_BEQ: begin
                ALUSrcA   = 2'b10;
                ALUSrcB   = 2'b00;
                ALUOp     = 2'b01;
                ResultSrc = 2'b00;
                Branch    = 1'b1;
            end

            default: begin
            end
        endcase

        if (Branch && Zero)
            PCWrite = 1'b1;
    end

endmodule