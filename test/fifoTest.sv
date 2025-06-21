`timescale 1ns / 1ps

/*
// Testbench for FIFO in SPI module.
// It's a pretty cruicial component that will get reused, so we will test it separately.
*/

module FIFO_tb;

	logic clk;
	logic rst_n;
    logic writeEn;
    logic readEn;
    logic [7:0] dataIn;
    wire  [7:0] dataOut;
	wire full;
	wire empty;

	FIFO #(
		.WIDTH(8),
		.DEPTH(8)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.writeData(dataIn),
		.writeEn(writeEn),
		.readData(dataOut),
		.readEn(readEn),
		.full(full),
		.empty(empty)
	);

	parameter CLK_PERIOD = 10; // 100 MHz clock
	initial begin
		clk = 1; // Allign everything w/ rising edge
		forever #(CLK_PERIOD / 2) clk = ~clk;
	end

	logic [7:0] testMem [7:0];

	initial begin
		#500;
		rst_n = 0;
		writeEn = 0;
		readEn = 0;
		dataIn = 0;
		#(CLK_PERIOD * 5);
		rst_n = 1;
		#(CLK_PERIOD * 5 + 1);


		// First, a simple write then read
		dataIn = 8'h01;
		testMem[0] = dataIn;
		writeEn = 1;
		#CLK_PERIOD;
		writeEn = 0;
		readEn = 1;
		#CLK_PERIOD;
		readEn = 0;

		if (dataOut == testMem[0]) begin
			$display("TESTBENCH: PASS! Received %h as expected.", dataOut);
		end else begin
			$error("TESTBENCH: FAIL! Received %h, but expected %h.", dataOut, testMem[0]);
		end
		#CLK_PERIOD;


		// Full flag test
		for (int i = 0; i < 8; i++) begin
			testMem[i] = i + 1;
			dataIn = testMem[i];
			writeEn = 1;
			#CLK_PERIOD;
		end

		writeEn = 0;

		if (full == 1) begin
			$display("TESTBENCH: PASS! Full as expected.");
		end else begin
			$error("TESTBENCH: FAIL! Full is zero");
		end

		if (empty == 0) begin
			$display("TESTBENCH: PASS! Empty as expected.");
		end else begin
			$error("TESTBENCH: FAIL! Empty is zero");
		end

		for (int i = 0; i < 8; i++) begin
			readEn = 1;
			if (dataOut == testMem[i]) begin
				$display("TESTBENCH: PASS! Received %h as expected.", dataOut);
			end else begin
				$error("TESTBENCH: FAIL! Received %h, but expected %h.", dataOut, testMem[i]);
			end
			#CLK_PERIOD;
		end
		readEn = 0;

		if (empty == 1) begin
			$display("TESTBENCH: PASS! Empty as expected.");
		end else begin
			$error("TESTBENCH: FAIL! Empty is zero");
		end

		$finish;
	end

endmodule
