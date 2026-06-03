//=============================================================================
// alu.v - Arithmetic Logic Unit for RISC-V Multicycle Processor
//=============================================================================
// This ALU supports all operations required
//
// RISC-V instructions use this ALU as follows:
//   - ADD/ADDI/LW/SW/JAL: ALUControl = 000 (addition for arithmetic or address calc)
//   - SUB/BEQ:            ALUControl = 001 (subtraction; BEQ checks Zero flag)
//   - AND:                ALUControl = 010 (bitwise AND)
//   - OR:                 ALUControl = 011 (bitwise OR)
//   - SLT/SLTI:           ALUControl = 101 (set less than, signed comparison)
//
// The Zero output is critical for BEQ: if A - B = 0, then A == B, so branch.
//=============================================================================

module alu (
    input  wire [31:0] A,           // First operand (from SrcA mux)
    input  wire [31:0] B,           // Second operand (from SrcB mux)
    input  wire [2:0]  ALUControl,  // Operation select (from controller)
    output reg  [31:0] Result,      // ALU output
    output wire        Zero         // 1 if Result == 0 (used for BEQ)
);

    //=========================================================================
    // Internal Signals
    //=========================================================================
    
    // For ADD/SUB: we use a single adder with conditional inversion of B.
    // SUB is implemented as A + (~B) + 1 = A - B (two's complement subtraction).
    //
    // ALUControl[0] determines add vs subtract:
    //   - ALUControl[0] = 0: ADD → B_mux = B,  carry_in = 0
    //   - ALUControl[0] = 1: SUB → B_mux = ~B, carry_in = 1
    
    wire [31:0] B_mux;              // B or ~B depending on operation
    wire [31:0] Sum;                // Output of the adder
    wire        Cout;               // Carry out (unused but computed)
    
    // Conditionally invert B for subtraction
    // XOR with all 1s inverts; XOR with all 0s passes through unchanged.
    assign B_mux = B ^ {32{ALUControl[0]}};
    
    // 32-bit adder with carry-in for subtraction
    // For SUB: A + ~B + 1 = A - B
    assign {Cout, Sum} = A + B_mux + {31'b0, ALUControl[0]};
    
    //=========================================================================
    // SLT (Set Less Than) - Signed Comparison
    //=========================================================================
    // SLT sets Result = 1 if A < B (signed), else Result = 0.
    //
    // For signed comparison, we compute A - B and look at the sign of the result,
    // but we must account for overflow. The key insight:
    //
    //   - If no overflow: A < B iff (A - B) is negative, i.e., Sum[31] = 1
    //   - If overflow occurred: the sign bit is wrong, so we invert our conclusion
    //
    // Overflow occurs when:
    //   - A is positive, B is negative, and Sum is negative (should be positive)
    //   - A is negative, B is positive, and Sum is positive (should be negative)
    //
    // This simplifies to: overflow = (A[31] != B[31]) && (Sum[31] != A[31])
    //=========================================================================
    
    wire        SLT_overflow;       // Signed overflow detection
    wire [31:0] SLT_result;         // Result for SLT operation
    
    // Detect signed overflow in subtraction
    assign SLT_overflow = (A[31] != B[31]) && (Sum[31] != A[31]);
    
    // SLT result: 1 if A < B (signed), 0 otherwise
    // If overflow occurred, the sign bit lies, so XOR to correct it.
    assign SLT_result = {31'b0, Sum[31] ^ SLT_overflow};
    
    //=========================================================================
    // Result Multiplexer
    //=========================================================================
    // Select the appropriate result based on ALUControl.
    //
    // ALUControl encoding (matches Harris & Harris RISC-V):
    //   000 - ADD
    //   001 - SUB
    //   010 - AND
    //   011 - OR
    //   100 - (unused)
    //   101 - SLT
    //   110 - (unused)
    //   111 - (unused)
    //=========================================================================
    
    always @(*) begin
        case (ALUControl)
            3'b000:  Result = Sum;          // ADD: A + B
            3'b001:  Result = Sum;          // SUB: A - B (B was inverted above)
            3'b010:  Result = A & B;        // AND: bitwise AND
            3'b011:  Result = A | B;        // OR:  bitwise OR
            3'b101:  Result = SLT_result;   // SLT: set if A < B (signed)
            default: Result = 32'b0;        // Unused opcodes default to 0
        endcase
    end
    
    //=========================================================================
    // Zero Flag
    //=========================================================================
    // Zero = 1 when Result is all zeros.
    // This is used by the BEQ instruction: if A - B = 0, then A == B.
    //=========================================================================
    
    assign Zero = (Result == 32'b0);

endmodule