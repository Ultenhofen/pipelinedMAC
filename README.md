# Multiply Accumulator with 2 stage pipeline

A parameterized and pipelined multiply accumulator (MAC) unit written in SystemVerilog. Includes valid signal propagation. Inputs are treated as unsigned

## Overview

Computes the equation `result = result + (A x B)` across a 2 stage pipeline. The accumulate signal controls whether the running total is held or reset before the next addition. Designed for throughput, one new operand is accepted per clock cycle.

## Architecture

| Stage | Operation          |
|-------|--------------------|
| 1     | Multiply           |
| 2     | Accumulate         |

**Parameters**
- `WIDTH` - input operand width (default: 8) Output is scaled to 3x input width for accumulate headroom for 256 max value accumulates

**Interface**

| Signal       | Dir | Width      | Description                        |
|--------------|-----|------------|------------------------------------|
| `clk`        | in  | 1          | Clock                              |
| `rst`        | in  | 1          | Active-high synchronous reset      |
| `valid_in`   | in  | 1          | Input operands are valid           |
| `accumulate` | in  | 1          | Hold running total when asserted   |
| `A`, `B`     | in  | WIDTH      | Multiplicand and multiplier        |
| `result`     | out | 3*WIDTH    | Accumulated output                 |
| `valid_out`  | out | 1          | Output is valid                    |

## Running Simulations

Verilator: 
```
verilator --cc --exe --build --trace macPipe.sv macPipe.cpp -o simMacPipe ./obj_dir/simMacPipe
```
Trace files are dumped for waveform viewing

Symbiyosys:
```
sby -f macPipe.sby
```
k-induction proof to depth 50, last property bmc proven to depth 50

## Formal Verification Properties

1. Reset safety       - rst suppresses valid_out the following cycle
2. Safety contract    - valid_out never asserts without prior valid_in
3. Liveness contract  - valid_in always produces valid_out 2 cycles later
                         absent reset (no silent data dropping)
4. Moving target      - rst kills mid-flight transactions
5. Datapath (no acc)  - result equals A*B from 2 cycles ago
6. Datapath (acc)     - result equals correct running accumulation

## Potential improvements

1. Do the multiply by hand instead of using the `*` operator. This will give me greater control and intent in what is actually synthesized. Potential performance improvements can arise from this as shrinking the volume of combinational logic would increase the theoretical clock speed the MAC could be run at
2. Building a UVM testbench. Proper coverage for my code is always appreciated although UVM may be a bit overkill for such a small project. Skills development is always appreciated!
3. Properly defined overflow handling. As of the moment, overflow resets to zero! Implement a saturation handler and have it be selectable at instantiation which handler you want to use, overflow or saturate
