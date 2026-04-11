// -----------------------------------------------------------------------------
// Formal Verification Wrapper: macPipe
// -----------------------------------------------------------------------------
// Proves correctness of the pipelined multiply-accumulate unit (macPipe.sv)
// using SymbiYosys with k-induction.
//
// Properties verified:
//   1. Reset safety       - rst suppresses valid_out the following cycle
//   2. Safety contract    - valid_out never asserts without prior valid_in
//   3. Liveness contract  - valid_in always produces valid_out 2 cycles later
//                           absent reset (no silent data dropping)
//   4. Moving target      - rst kills mid-flight transactions
//   5. Datapath (no acc)  - result equals A*B from 2 cycles ago
//   6. Datapath (acc)     - result equals correct running accumulation
//
// Tools: SymbiYosys, Yices solver
// Mode:  prove k-induction, depth 50 and bmc, depth 50
// -----------------------------------------------------------------------------

module macPipe_formal #(
    parameter int DATA_W = 8,
	parameter int RESULT_W = 32
)(
    input logic clk,
    input logic rst,
    input logic valid_in,
    input logic acc,
    input logic [DATA_W-1:0] A, B
);

	logic [DATA_W*2-1:0] mul_reg;
    logic [RESULT_W-1:0] result;
	logic [RESULT_W-1:0] res_reg;
	logic acc_ref;
    logic valid_out;
	logic val_reg;

    macPipe #(.DATA_W(DATA_W), .RESULT_W(RESULT_W)) dut (
        .clk(clk),
        .rst(rst),
        .acc(acc),
        .valid_in(valid_in),
        .A(A),
        .B(B),
        .result(result),
        .valid_out(valid_out)
    );

	always_ff @(posedge clk) begin
		if(rst) begin
			mul_reg <= 0;
			res_reg <= 0;
			val_reg <= 0;
			acc_ref <= 0;
		end else begin
			val_reg <= valid_in;
			acc_ref <= acc;
			if (valid_in)
				mul_reg <= A * B;
			if (val_reg) begin
				if(acc_ref)
					res_reg <= res_reg + {{(RESULT_W - 2*DATA_W){1'b0}}, mul_reg};
				else
					res_reg <= {{(RESULT_W - 2*DATA_W){1'b0}}, mul_reg};
			end
		end
	end


    reg [3:0] cycle_count;
    initial cycle_count = 0;
	initial assume(rst);
    always @(posedge clk)
        if (cycle_count < 15) cycle_count <= cycle_count + 1;

    // Property 1: rst high means valid_out low next cycle. Reset must full
    // reset the device. Otherwise, we could push garbage values through to
    // the next stage
    always @(posedge clk) begin
        if (cycle_count > 1 && $past(rst)) begin
            assert(!valid_out);
            assert(result == 0);
		end
    end

    // Property 2: Latency contract: valid_out implies valid_in 2 cycles ago.
    // If valid_out is triggering without a corresponding valid_in, we run
    // into the same issue as below except worse because we could be telling
    // devices down the line they CAN trust the data with bad data
    // k-induction proven to depth 50
    always @(posedge clk) begin
        if (cycle_count >= 3)
            if (valid_out)
                assert($past(valid_in, 2));
    end

	// Property 3: Liveness: valid_in implies valid_out in 2 cycles assuming
	// no resets trigger. If valid_in didn't imply valid_out propagation,
	// devices down the line wouldn't be able to trust the data from the MAC
	// k-induction proven depth 50
	always @(posedge clk) begin
		if (cycle_count >= 3)
			if ($past(valid_in, 2) && !$past(rst, 2) && !$past(rst, 1))
				assert(valid_out);
	end
	// Property 4: Moving target: reset during a valid transaction kills the
	// valid transaction. If reset can't stop valid transactions, what is the
	// point of reset? It's purpose is to fully reset the device
	// k-induction proven to depth 50
	always @(posedge clk) begin
		if (cycle_count >= 3)
			if ($past(valid_in, 2) && ($past(rst, 2) || $past(rst, 1)))
				assert(valid_out == 0);
	end

	// Property 5: valid_out and acc 2 cycles ago implies result is equal to
	// A * B two cycles ago. In our accumulator, setting acc low doesn't stop
	// result from changing. It only stops the addition of result to A * B.
	// k-induction proven depth 50
	always @(posedge clk) begin
		if (cycle_count >= 3)
			if (valid_out && !$past(acc,2))
				assert(result == (RESULT_W)'($past(A,2))*(RESULT_W)'($past(B,2)));
	end
	
	// Property 6: valid_out and acc implies result equals result + (A * B).
	// As mentioned above, acc low stops accumulation but doesn't stop
	// changing result. acc high just allows accumulation, the expected
	// behavior of the device. BMC pass to depth 50, k-induction fails to
	// prove the behavior but doesn't fail
	always @(posedge clk) begin
	if (cycle_count >= 3)
		if (valid_out && $past(acc,2))
			assert(result == res_reg);
	end


endmodule
