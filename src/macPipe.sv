module macPipe #(
	parameter int WIDTH = 8
)(
	input logic [WIDTH-1:0] A, B, 
	input logic rst, acc, valid_in, clk,
	output logic [WIDTH*3-1:0] result, 
	output logic valid_out
);
	reg [WIDTH*2-1:0] mul_reg;
	reg acc_reg;
	reg valid;

	always_ff @(posedge clk) begin
		acc_reg <= acc;
		valid <= valid_in;

		case ({rst, valid_in})
			2'b10: begin
				mul_reg <= 0;
				valid <= 0;
				acc_reg <= 0;
			end
			2'b11: begin
				mul_reg <= 0;
				valid <= 0;
				acc_reg <= 0;
			end
			2'b00: mul_reg <= mul_reg;
			2'b01: mul_reg <= (WIDTH*2)'(A) * (WIDTH*2)'(B);
		endcase
	end

	always_ff @(posedge clk) begin
		valid_out <= valid;

		case ({rst, valid, acc_reg})
			3'b101: begin
				result <= 0;
				valid_out <= 0;
			end
			3'b111: begin
				result <= 0;
				valid_out <= 0;
			end
			3'b100: begin
				result <= 0;
				valid_out <= 0;
			end
			3'b110: begin
				result <= 0;
				valid_out <= 0;
			end
			3'b000: result <= result;
			3'b001: result <= result;
			3'b010: result <= {{(WIDTH){1'b0}}, mul_reg};
			3'b011: result <= result + {{(WIDTH){1'b0}}, mul_reg};
		endcase		
	end
endmodule
