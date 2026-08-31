## 4-Requester Round-Robin Arbiter

A 4-requester round-robin arbiter designed in SystemVerilog and verified with a self-checking testbench.

The arbiter grants access to one requester at a time while rotating priority between requesters to prevent starvation.

## Features

- 4 independent request inputs
- One-hot grant output
- Round-robin priority rotation
- Fair arbitration between requesters
- Synchronous reset
- Synthesizable SystemVerilog RTL

## Verification

The design was verified using a SystemVerilog testbench with:

- Directed test cases
- 100 randomized request tests
- Automatic result checking
- SystemVerilog assertions
- One-hot grant verification
- Checks for invalid grants
- Starvation/fairness verification

All test cases completed successfully.

## Project Structure

```text
systemverilog-round-robin-arbiter/
├── 4-requester round-robin arbiter.xpr
├── 4-requester round-robin arbiter.srcs/
│   ├── sources_1/
│   │   └── new/
│   │       └── rr_arbiter.sv
│   └── sim_1/
│       └── new/
│           └── rr_arbiter_tb.sv
├── README.md
└── .gitignore
```
