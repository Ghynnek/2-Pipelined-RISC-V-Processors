# Software-scheduled pipeline demo

Prepared against GitHub main commit `dc5f7ab1068b80abed59b2c55c1468aca596e247`.
The supplied Part 2 handout defines the software-scheduled deliverables, but does
not define a separate midpoint-demo rubric. Confirm any Canvas-only checklist.

## Install and run

1. Back up your current `cpre3810-toolflow/proj/src` directory.
2. Extract this ZIP into your repository root, merging its `cpre3810-toolflow`
   directory with yours. Accept the replacement source files. The ZIP does not
   include or replace the course toolflow internals.
3. From `cpre3810-toolflow`, run the course toolflow with the scheduled tests:

```bash
bash 3810_tf.sh test proj/riscv/sw/proj1_base_test_sw.s
bash 3810_tf.sh test proj/riscv/sw/proj1_cf_test_sw.s
bash 3810_tf.sh test proj/riscv/sw/proj1_mergesort_sw.s
bash 3810_tf.sh test proj/riscv/sw/grendel_sw.s
```

Do not run the unscheduled Project 1 tests against this processor. Their adjacent
RAW dependencies are intentionally unsupported by a software-scheduled pipeline.
Compile `src` OR `src_sw`, never both: they contain the same entity names. `src`
is active for the toolflow; `src_sw` preserves the separate software design
required by the assignment. The old single-cycle `fetch_logic.vhd` is kept for
its existing unit tests; the processor instantiates `fetch_logic_sw` instead.

## Open the demo waveform in Questa

In the Questa Transcript, change directory to `cpre3810-toolflow/proj` and run:

```tcl
set program proj1_mergesort_sw
do test/demo_sw.do
```

Choose `proj1_base_test_sw`, `proj1_cf_test_sw`, `grendel_sw`, or
`proj1_extrasort_sw` for other tests. This compiles the complete processor,
loads the included RARS-generated memory images, groups the five stages, and
records `<program>.wlf`. The GUI script is provided for the lab setup; it has
not been run in Questa here. The checked-in hex files correspond exactly to the
included assembly. After changing assembly, regenerate the images or use the
course toolflow, which assembles them automatically.

## What changed

The repository already had pipeline registers, but the active top level was
single-cycle. The replacement connects IF/ID, ID/EX, EX/MEM and MEM/WB, while
retaining the existing control unit, ALU, register file, immediate generator,
writeback selector, and byte-enabled memories.

| Stage | Work and state |
|---|---|
| IF | PC and instruction-memory read; PC+4 |
| ID | Decode, asynchronous register reads, immediate generation, WFI decode |
| EX | ALU, AUIPC using the instruction's saved PC, branch comparison and branch/jump target |
| MEM | Store address/data/byte enables and memory reads from EX/MEM |
| WB | Register destination/value/control and final halt from MEM/WB |

| Boundary | Values that travel with the instruction |
|---|---|
| IF/ID | instruction, PC, PC+4 |
| ID/EX | PC, PC+4, rs1/rs2 values and indices, rd, immediate, funct3; RegWrite, ALUSrc, AUIPC, MemWrite, MemToReg, Branch, Jump, JumpReg, LUI, Halt, ALUControl |
| EX/MEM | ALU result, store operand, immediate, PC+4, funct3, rd; RegWrite, MemWrite, MemToReg, Jump, JumpReg, LUI, Halt |
| MEM/WB | memory read data, ALU result/address offset, immediate, PC+4, funct3, rd; RegWrite, MemToReg, Jump, JumpReg, LUI, Halt |

There is no bypass, forwarding, hazard detector, or automatic stall/flush.
Existing pipeline-register stall/flush inputs are tied to zero. Reset clears
pipeline controls and returns the PC to `0x00400000`; instruction loading holds
the processor in reset. `s_Halt` is only asserted at WB, so older instructions
complete before simulation stops. The required toolflow signal names and memory
instance names are preserved.

EX branch targets use `e_pc + e_imm`, not the current fetch PC. JALR clears bit 0.
AUIPC uses `e_pc`; link writeback uses the saved PC+4. Store data, funct3 and byte
offset all come from MEM. Load extension uses the WB address offset/funct3.

## Scheduling rules to explain at the demo

The register file still writes on the rising edge. ID/EX captures its read data
on that same edge, so a consumer cannot capture the value being written at that
edge. Put three other instructions between a producer and consumer. These may
be useful independent instructions, NOPs, or a combination. This applies to
ALU results, loads, store operands, branch operands, and JALR bases.

Control transfers resolve in EX. Two sequential instructions have already been
fetched, and this design does not squash them. Put two NOPs immediately after
every branch, JAL or JALR. A taken transfer reaches its target after these two
bubbles. A JAL link used immediately at the target still needs one additional
instruction of separation; the schedule accounts for this.

Three examples in `proj1_mergesort_sw.s`:

1. Before `jal ra, Merge`, `lw a1,8(sp)`, `lw a2,0(sp)`, and `lw a3,4(sp)`
   run consecutively. The jump and its two control NOPs allow these argument
   loads to finish before Merge consumes them, with no extra RAW NOPs there.
2. In `SortDone`, `addi sp,sp,4` does useful work between `lw ra,0(sp)` and
   `jalr x0,0(ra)`. Only two RAW NOPs are needed instead of three.
3. Every control transfer has two trailing NOPs, not four or five. This is safe
   because redirection is resolved in EX rather than a later pipeline stage.

`scripts/schedule_sw.py` expands `la`, large `li`, label loads and other used
pseudos before analyzing dependencies. It preserves operation order, follows
loops, calls, and conservatively modeled indirect targets, then removes redundant
RAW padding. It does not claim a globally optimal schedule: reordering independent
work can improve performance further. It is specific to the syntax used by these
tests and rejects unsupported operations. No blanket four/five-NOP padding is used.

The control test's original `JalrBase + 8` target was replaced by `JalrFunc + 0`,
because inserting NOPs changes the distance between labels. Grendel's ambiguous
`-1-1-1-1` initializer was written explicitly as four `-1` words.

## Verified results

The software-pipeline source compiled and elaborated as one processor with GHDL 5.0.1.
All five programs were assembled with RARS built from this repository's Java
source. Every nonzero-register write and every memory-write byte, in order,
matched the RARS execution reference:

| Program | Machine-code words | Clock cycles through WB halt | Result |
|---|---:|---:|---|
| Base instruction test | 155 | 159 | PASS |
| Control-flow/recursive-call test | 201 | 385 | PASS |
| Mergesort | 210 | 2991 | PASS |
| Existing extra sort | 91 | 1515 | PASS |
| Grendel | 717 | 5815 | PASS |

These cycle counts exclude instruction loading/reset and include pipeline fill
and control bubbles. They are not timing/frequency measurements. All programs fit
inside the 1024-word instruction memory.

The supplied 12-element array sorts to:
`[5, 7, 9, 10, 11, 12, 45, 65, 67, 70, 89, 90]`.
Grendel produces `[3, 0, 2, 1]`. The control test finishes with `s0 = 20` and
restores `sp`; the fail-path sentinel is not written.

`validation/` contains exact memory images, RARS and HDL traces, simulation logs,
and JSON test results. `waveforms/proj1_mergesort_sw.vcd.gz` contains the GHDL
waveform for the validated sort; decompress it to open in a VCD viewer. It is
not a Questa `.wlf` file.

To reproduce the checks with GHDL and Java installed:

```bash
# From cpre3810-toolflow/proj:
python3 scripts/schedule_sw.py
python3 scripts/verify_sw.py
```

`RARS_JAR` can select the course RARS JAR; `GHDL` can select the simulator binary.
The checker creates simulation-only copies in `build_sw`, adding a passive trace
monitor and initializing RAM from the assembled data image. It leaves the
submitted VHDL untouched. The RARS Java source in this repository omits printed
SB/SH write events, so the checker reconstructs expected store bytes from RARS's
executed store instruction and register trace. If the course comparator reports
extra SB/SH writes, check that you have the current instructor-supplied RARS JAR;
do not remove functioning byte stores to suppress a reference-trace issue.

## Still required on the lab machine

Run the course toolflow and the provided Questa demo script before presenting.
Generate the actual `.wlf` files and annotate at least two iterations/recursions
plus the scheduling examples above. Use Quartus to obtain Fmax and the critical
path; neither is measured here. The report and team contract are not completed
by this code package. There is no separate midpoint rubric in the supplied PDF.

If your team has three members, the handout asks for quicksort as well as
mergesort. Your existing `proj1_extrasort.s` is insertion sort, not quicksort;
its scheduled copy is included as an additional test, not a quicksort replacement.
The supplied-array runs do not establish correctness for every possible input
array or constitute FPGA synthesis verification.
