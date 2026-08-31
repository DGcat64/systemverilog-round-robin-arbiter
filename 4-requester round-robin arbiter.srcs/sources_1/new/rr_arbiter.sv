`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: DGcat64 
// 
// Create Date: 03/12/2026 05:45:24 PM
// Design Name:  4-Requester Round-Robin Arbiter
// Module Name: rr_arbiter
// Project Name: Round-Robin Arbiter Design & Verification
// Target Devices: Nexys A7-100T
// Tool Versions: Vivado 2026.1
// Description: 
//   Parameterized round-robin arbiter that accepts requests from multiple
//   requesters and grants access to one requester per arbitration cycle.
//   Priority rotates after each successful grant to provide fair access.
// Dependencies: zero
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Initial implementation configured for four requesters.
// 
//////////////////////////////////////////////////////////////////////////////////


module rr_arbiter #(
    parameter int N = 4
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] req,
    output logic [N-1:0] grant
);
// priority pointerr
localparam int PTR_W = (N <= 1) ? 1 : $clog2(N);

    logic [PTR_W-1:0] ptr_q; // current priorty (saved)
    logic [PTR_W-1:0] ptr_d; // priority to be used next
    
    logic found; // created after always_ff. 
    integer idx;
    
    always_comb begin
    grant = '0;
    found = 1'b0;

    for (int offset = 0; offset < N; offset++) begin
        idx = ptr_q + offset;

        if (idx >= N)
            idx = idx - N;

        if (!found && req[idx]) begin
            grant[idx] = 1'b1;
            found = 1'b1;
        end
    end
end
    
    always_comb begin // define  ptr_d so the priority rotates
    ptr_d = ptr_q;

    for (int i = 0; i < N; i++) begin
        if (grant[i]) begin
            if (i == N-1)
                ptr_d = '0;
            else
                ptr_d = i + 1;
        end
    end
end
    
    always_ff @(posedge clk or negedge rst_n) begin // stores current PRIORITY pointer
    if (!rst_n)
        ptr_q <= '0;
    else
        ptr_q <= ptr_d;
end

endmodule


