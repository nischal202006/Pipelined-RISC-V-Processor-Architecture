# RISC-V 64-bit Pipelined Processor
**Author**:G.Nischal,R.Kowshikh,B.V.Shashank.
A complete implementation of a 64-bit RISC-V (RV64I) processor architecture using Verilog HDL. This project demonstrates the design and simulation of both a Single-Cycle (Phase 1) and a 5-Stage Pipelined (Phase 2) processor, supporting a comprehensive subset of the RISC-V instruction set.

## Project Overview

This project is divided into two main phases, showcasing the evolution from a simple sequential datapath to a high-performance pipelined architecture.

### Phase 1: Single-Cycle Processor
*   **Sequential Datapath**: Executes one instruction per clock cycle.
*   **Modules**: Includes ALU, Register File, Instruction Memory, and Control Unit.
*   **Functionality**: Validates the basic logic and control flow for supported instructions.
*   **Key Files**: `seq.v` (Top Level), `Control_unit.v`, `ALU.v`.

### Phase 2: Pipelined Processor
*   **5-Stage Pipeline**: Implements the classic RISC pipeline stages to increase instruction throughput:
    1.  **IF** (Instruction Fetch)
    2.  **ID** (Instruction Decode)
    3.  **EX** (Execute)
    4.  **MEM** (Memory Access)
    5.  **WB** (Write Back)
*   **Hazard Handling**:
    *   **Data Hazards**: Resolved using a **Forwarding Unit** to bypass results from EX/MEM and MEM/WB stages to the ALU inputs.
    *   **Control Hazards**: Handled using a **Hazard Detection Unit** with stalling (inserting bubbles) and flushing mechanisms.
    *   **Branch Prediction**: Features static branch prediction logic.
*   **Key Files**: `pipe.v` (Top Level), `Data_Forwarding_unit.v`, `Hazard_detection_unit.v`, pipeline registers.

## Key Features

*   **Architecture**: 64-bit RISC-V (RV64I subset).
*   **Instruction Set Supported**:
    *   **Arithmetic (R-Type/I-Type)**: `add`, `sub`, `addi`
    *   **Logical**: `and`, `or`
    *   **Memory**: `ld` (Load Doubleword), `sd` (Store Doubleword)
    *   **Control Flow**: `beq` (Branch if Equal)
*   **Simulation**: Verified using Verilog testbenches with waveform analysis (`.vcd` files included).

## File Structure

### Phase-1 (Single-Cycle)
*   `seq.v`: Top-level module for the single-cycle processor.
*   `seq_tb.v`: Testbench for verification.
*   `ALU.v`: 64-bit Arithmetic Logic Unit.
*   `Control_unit.v`: Main control signal generator.
*   `RegMem.v`: Register File (32 x 64-bit registers).
*   `DataMem.v`: Data Memory.
*   `Instruction_mem.v`: Holds the machine code instructions.
*   `Immediate_gen.v`: Generates immediate values from instructions.

### Phase2 (Pipelined)
*   `pipe.v`: Top-level module for the pipelined processor.
*   `pipe_tb.v`: Testbench for the pipelined processor.
*   `ID_EX_Register.v`, `IF_ID_Register.v`, `EX_MEM_Register.v`, `MEM_WB_Register.v`: Pipeline registers holding state between stages.
*   `Data_Forwarding_unit.v`: Logic for data forwarding to resolve hazards.
*   `Hazard_detection_unit.v`: Logic for detecting hazards and inserting stalls.
*   `ALU_Forwarding_mux.v`: Multiplexers for selecting forwarded data.

## Getting Started

### Prerequisites
*   A Verilog simulator (e.g., Icarus Verilog, ModelSim, Vivado).
*   A waveform viewer (e.g., GTKWave) to view `.vcd` files.

### Running Simulations

1.  **Compile the modules**:
    You can compile the Verilog files using typically available commands. For example, with Icarus Verilog:
    
    **For Phase 1:**
    ```bash
    iverilog -o phase1_sim Phase-1/*.v
    ```
    
    **For Phase 2:**
    ```bash
    iverilog -o phase2_sim Phase2/*.v
    ```

2.  **Run the simulation**:
    ```bash
    vvp phase1_sim
    ```
    or
    ```bash
    vvp phase2_sim
    ```

3.  **View Waveforms**:
    After running the simulation, a `.vcd` file (e.g., `seq_tb.vcd` or `pipe_tb.vcd`) will be generated. Open this file in GTKWave to visualize the processor's signals and instruction execution flow.

## Instruction Memory
The instructions to be executed are loaded into `Instruction_mem.v`. You can modify `instructions.txt` (or the internal array initialization) to run different programs.
See `Phase-1/instructions_exp.txt` for an example assembly program and its corresponding machine code translation.
