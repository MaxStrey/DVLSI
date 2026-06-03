# DVLSI
Uploading the code from the final project of DVLSI

# RISC-V Multicycle Processor

A 32-bit RISC-V processor implementation in Verilog with a multicycle datapath architecture. This project implements essential RISC-V instructions (ADD, SUB, AND, OR, SLT, ADDI, LW, SW, BEQ, JAL) and verifies functionality by writing a computed value to memory.

## File Descriptions

### Core Components
- **controller.v** - Finite state machine (11 states) that orchestrates instruction execution cycles
- **datapath.v** - Main datapath containing registers, multiplexers, and pipeline stages
- **alu.v** - 32-bit ALU supporting arithmetic, bitwise, and comparison operations with signed overflow detection

### Support Modules
- **regfile.v** - 32×32-bit register file (2 read ports, 1 write port)
- **extend.v** - Immediate value sign-extender for I/S/B/J-type instructions
- **instr_data_mem.v** - 64-word unified instruction and data memory
- **reg_en_reset.v** - Parameterized register with enable and synchronous reset
- **mux2.v / mux3.v** - 2-to-1 and 3-to-1 multiplexers with parameterized width

### Test & Documentation
- **riscvtest.s** - RISC-V assembly test program that verifies all instruction types
- **riscvtest.txt** - Machine code for test program (hex format)
- **Final_Project.pdf** - Detailed project specification and design documentation
- **Screenshot.png** - Simulation verification

## Test Program Result

The test program executes a series of instructions and writes the computed value **25** to memory address 100, confirming correct processor operation across all instruction types.
