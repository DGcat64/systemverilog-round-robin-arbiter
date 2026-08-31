`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: N/A
// Engineer: DGcat64
// 
// Create Date: 03/22/2026 06:11:50 PM
// Design Name: Round-Robin Arbiter Verification Environment
// Module Name: rr_arbiter_tb
// Project Name: 4-Requester Round-Robin Arbiter Design & Verification
// Target Devices: Simulation only
// Tool Versions: Vivado 2025.2
// Description: 
// 
// Dependencies: rr_arbiter.sv
// 
// Revision:
// Revision 0.01 - Initial verification environment
// Additional Comments:
//   Verification includes 100 randomized request sequences and functional
//   coverage of request patterns, grant outcomes, and round-robin grant
//   transitions.



module rr_arbiter_tb;

    localparam int N = 4;

    logic clk;
    logic rst_n;
    logic [N-1:0] req;
    logic [N-1:0] grant;
    

// ASSertion 1: Grant must be one hot or zero


assert_onehot_grant:
    assert property (@(posedge clk)
        disable iff (!rst_n)
        $onehot0(grant)
    )
    else
        $error("ASSERTION FAILED: Multiple grants active! grant=%b", grant); // added after 100 random
        

// Assertion 2: Never grant a non-requesting client


assert_grant_requires_request:
    assert property (@(posedge clk)
        disable iff (!rst_n)
        ((grant & ~req) == '0)
    )
    else
        $error(
            "ASSERTION FAILED: Grant issued without request! req=%b grant=%b",
            req,
            grant
        );



// Assertion 3: No requests means no grants


assert_no_request_no_grant:
    assert property (@(posedge clk)
        disable iff (!rst_n)
        (req == '0) |-> (grant == '0)
    )
    else
        $error(
            "ASSERTION FAILED: Grant active with no requests! req=%b grant=%b",
            req,
            grant
        );
        

// Functional Coverage


covergroup arbiter_cg @(posedge clk); 

    // Only sample while not in reset
    cp_req: coverpoint req iff (rst_n) {
        bins all_request_patterns[] = {[4'b0000:4'b1111]};
    }

    cp_grant: coverpoint grant iff (rst_n) {
        bins no_grant   = {4'b0000};
        bins requester0 = {4'b0001};
        bins requester1 = {4'b0010};
        bins requester2 = {4'b0100};
        bins requester3 = {4'b1000};
    }

    cp_grant_rotation: coverpoint grant iff (rst_n) {
        bins r0_to_r1 = (4'b0001 => 4'b0010);
        bins r1_to_r2 = (4'b0010 => 4'b0100);
        bins r2_to_r3 = (4'b0100 => 4'b1000);
        bins r3_to_r0 = (4'b1000 => 4'b0001);
    }

endgroup

// commands for tlc : write_xsim_coverage -cov_db_dir cRun1 -cov_db_name ArbiterCoverage
//  after frist cmd : export_xsim_coverage -cov_db_name ArbiterCoverage -cov_db_dir cRun1 -output_dir cReport -open_html true

arbiter_cg arbiter_cov = new();        
    
    // Reference model signals (added after doing waveform verification, aka hard programmed tests 1-6) 
    logic [N-1:0] expected_grant; // what the testbench thinks the correct answer should be
    int model_ptr; // model_ptr is the testbench's independent version of  dut's ptr_q 
    // , otherwise the reference model would read dut.ptr_q .ie it would be asking DUT if DUT is correct
        
    rr_arbiter #(
    .N(N)
) dut ( // dut means Device Under Test
    .clk   (clk),
    .rst_n (rst_n),
    .req   (req),
    .grant (grant)
);

task automatic calculate_expected_grant; // does not look at ptr_q or grant inside the DUT. 
                                         // It idependently knows what thee answer should be
    int model_idx;
    logic model_found;

    begin
        expected_grant = '0;
        model_found = 1'b0;

        for (int offset = 0; offset < N; offset++) begin

            model_idx = model_ptr + offset;

            if (model_idx >= N)
                model_idx = model_idx - N;

            if (!model_found && req[model_idx]) begin
                expected_grant[model_idx] = 1'b1;
                model_found = 1'b1;
            end
        end
    end

endtask

task automatic check_result; //calculate_expected_grant(), figure out what grant should be
                             //, check_result(), compares DUT grant vs expected_grant
                         
    begin
        calculate_expected_grant();

        #1;

        if (grant !== expected_grant) begin
            $display(
                "ERROR: time=%0t req=%b grant=%b expected=%b model_ptr=%0d",
                $time,
                req,
                grant,
                expected_grant,
                model_ptr
            );

            $fatal;
        end
        else begin
            $display(
                "PASS: time=%0t req=%b grant=%b",
                $time,
                req,
                grant
            );
        end
    end

endtask

task automatic update_model_ptr;

    begin
        for (int i = 0; i < N; i++) begin
            if (expected_grant[i]) begin // bug encounter. Used grant instead of expected_grant

                if (i == N-1)
                    model_ptr = 0;
                else
                    model_ptr = i + 1;

            end
        end
    end

endtask


initial begin // 100MHz clock cause 5ns for full cycle (#5)
    clk = 1'b0;

    forever #5 clk = ~clk;
end

initial begin
    req   = 4'b0000;
    rst_n = 1'b0; // reset is active 
    
    model_ptr = 0; // added on They both begin with requester 0 as the highest-priority requester
                   // , but importantly they maintain their state independently.

    
    repeat (2)
        @(posedge clk);

    rst_n = 1'b1; // normal opperation
    
    // Test 1: No requests
req = 4'b0000;

#1;

if (grant !== 4'b0000) begin // use !== to generate unknown values
    $display("TEST 1 FAILED: grant = %b", grant);
end
else begin
    $display("TEST 1 PASSED: no requests -> no grants");
end
    
    
    // Test 2: Requester 0 only
req = 4'b0001;

#1;

if (grant !== 4'b0001) begin
    $display("TEST 2 FAILED: req = %b, grant = %b", req, grant);
end
else begin
    $display("TEST 2 PASSED: requester 0 granted");
end

@(posedge clk); // important that It lets that grant reach a rising clock edge so the arbiter updates its priority pointer
    
  // Test 3: All requesters active
req = 4'b1111;

#1;

if (grant !== 4'b0010) begin
    $display("TEST 3 FAILED: req = %b, grant = %b, expected = 0010",
             req, grant);
end
else begin
    $display("TEST 3 PASSED: requester 1 granted");
end

@(posedge clk);

// Test 4: All requesters still active
#1;

if (grant !== 4'b0100) begin
    $display("TEST 4 FAILED: req = %b, grant = %b, expected = 0100",
             req, grant);
end
else begin
    $display("TEST 4 PASSED: requester 2 granted");
end

@(posedge clk);

// Test 5: All requesters still active
#1;

if (grant !== 4'b1000) begin
    $display("TEST 5 FAILED: req = %b, grant = %b, expected = 1000",
             req, grant);
end
else begin
    $display("TEST 5 PASSED: requester 3 granted");
end

@(posedge clk);

// Test 6: Wrap back to requester 0
#1;

if (grant !== 4'b0001) begin
    $display("TEST 6 FAILED: req = %b, grant = %b, expected = 0001",
             req, grant);
end
else begin
    $display("TEST 6 PASSED: wrapped back to requester 0");
end

@(posedge clk); 

req = 4'b0000;

$display("------------------------------");
$display("ALL DIRECTED TESTS COMPLETED");
$display("------------------------------");

@(posedge clk);


// Reference model verification


$display("------------------------------");
$display("STARTING REFERENCE MODEL TESTS");
$display("------------------------------");

// Reset DUT and reference model back to requester 0
req       = 4'b0000;
rst_n     = 1'b0;
model_ptr = 0;

repeat (2)
    @(posedge clk);

rst_n = 1'b1;
    
    // Reference Test 1
req = 4'b1010;

check_result();

@(posedge clk);
update_model_ptr();

// Reference Test 2
req = 4'b1111;

check_result();

@(posedge clk);
update_model_ptr();


// Reference Test 3
req = 4'b0011;

check_result();

@(posedge clk);
update_model_ptr();


// Reference Test 4
req = 4'b1100;

check_result();

@(posedge clk);
update_model_ptr(); // expected grants are not specified in these tests. model figures it out based on model_ptr


$display("------------------------------");
$display("REFERENCE MODEL TESTS PASSED");
$display("------------------------------");


// Randomized verification


$display("------------------------------");
$display("STARTING RANDOMIZED TESTS");
$display("------------------------------");

// Reset DUT and reference model
req       = 4'b0000;
rst_n     = 1'b0;
model_ptr = 0;

repeat (2)
    @(posedge clk);

rst_n = 1'b1;

// Run 100 random request patterns
for (int test = 0; test < 100; test++) begin

    req = $urandom_range((1 << N) - 1, 0);

    check_result();

    @(posedge clk);
    update_model_ptr();

end

$display("------------------------------");
$display("100 RANDOMIZED TESTS PASSED");
$display("------------------------------");

$finish;



end

endmodule
