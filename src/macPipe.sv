module macPipe #(
	parameter int DATA_W = 8,
	parameter int RESULT_W = 32
)(
	input logic [DATA_W-1:0] A, B, 
	input logic rst, acc, valid_in, clk,
	output logic [RESULT_W-1:0] result, 
	output logic valid_out
);
	logic [DATA_W*2-1:0] mul_reg;
	logic acc_reg;
	logic valid;

	always_ff @(posedge clk) begin
		if(rst) begin
			mul_reg <= 0;
			acc_reg <= 0;
			valid <= 0;
		end else begin
			acc_reg <= acc;
			valid <= valid_in;	

			if(valid_in)
				mul_reg <= (DATA_W*2)'(A) * (DATA_W*2)'(B);
		end
	end

	always_ff @(posedge clk) begin
		if(rst) begin
			result <= 0;
			valid_out <= 0;
		end else begin
			valid_out <= valid;
			
			if(valid) begin
				case (acc_reg)
					1'b0: result <= {{(RESULT_W - 2*DATA_W){1'b0}}, mul_reg};
					1'b1: result <= result + {{(RESULT_W - 2*DATA_W){1'b0}}, mul_reg};
				endcase		
			end
		end
	end
endmodule
