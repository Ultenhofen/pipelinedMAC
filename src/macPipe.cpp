#include "VmacPipe.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdlib>
#include <ctime>
#include <iostream>

int main(int argc, char** argv) {
	srand(time(NULL));

	VerilatedContext* ctx = new VerilatedContext;
	ctx->commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	VmacPipe* dut = new VmacPipe{ctx};

	VerilatedVcdC* tfp = new VerilatedVcdC;
	dut->trace(tfp, 99);
	tfp->open("dump.vcd");

	dut->acc = 1; dut->rst = 1; dut->clk = 0; dut->eval();
	tfp->dump(ctx->time()); ctx->timeInc(10);
	dut->clk = 1;
	dut->eval();
	tfp->dump(ctx->time()); ctx->timeInc(10);

	dut->rst = 0; dut->valid_in = 1; dut->clk = 0;
	dut->eval();
	tfp->dump(ctx->time()); ctx->timeInc(10);

	for (int cycle = 0; cycle < 400; cycle++) {
		dut->clk = 1;
		dut->A = rand() % 256; dut->B = rand() % 256;
		dut->eval();
		std::cout << "count = " << (unsigned long long)dut->result << "\n";
		tfp->dump(ctx->time());
		ctx->timeInc(5);


		dut->clk = 0;
		dut->eval();
		tfp->dump(ctx->time());
		ctx->timeInc(5);
	}

	dut->final();

	std::cout << "closing trace\n";
	tfp->close();
	delete dut; delete ctx;
	return 0;
}
