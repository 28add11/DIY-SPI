/** THANKS GEMINI!!!! YAY AI!!!! I LOVE NOT MAKING MY OWN TBs!!!
 *
 * @file spi_slave_tb.sv
 * @brief Testbench for an SPI Mode 0 Master
 * @details
 * This testbench instantiates an SPI master DUT (Design Under Test) and
 * acts as a passive SPI slave device to verify the master's functionality.
 * It operates in SPI Mode 0 (CPOL=0, CPHA=0).
 *
 * Test Sequence:
 * 1. The testbench initializes the DUT.
 * 2. It waits for the master to initiate a transaction by asserting chip select (cs).
 * 3. It then iterates through all possible 8-bit values (0 to 255).
 * 4. For each value, it waits for the master to send the data.
 * 5. The testbench samples the MOSI (Master Out Slave In) line on the rising
 * edge of the clock (sclk).
 * 6. Simultaneously, it drives the MISO (Master In Slave Out) line with the
 * same data on the falling edge of the clock.
 * 7. The testbench verifies that the master correctly sends all values from
 * 0 to 255 sequentially.
 */

`timescale 1ns/1ps

module spi_master_tb;

	//----------------------------------------------------------------
	// Testbench signals
	//----------------------------------------------------------------
	logic clk;
	logic rst;

	// SPI Interface Signals
	logic sclk; // Serial Clock
	logic cs;   // Chip Select
	logic mosi; // Master Out, Slave In
	logic miso; // Master In, Slave Out

	// Expected data from master
	logic [7:0] expected_data_from_master;

	//----------------------------------------------------------------
	// Instantiate the DUT (Design Under Test - Your SPI Master)
	//----------------------------------------------------------------
	// Note: The DUT is assumed to have this port mapping.
	// You should replace this with your actual module instantiation if different.
	masterTop dut (
		.clk(clk),
		.rst(rst),
		.SCLK(sclk),
		.CS_n(cs),
		.MOSI(mosi),
		.MISO(miso),
		.sw(16'h00FF)
		// Add any other necessary ports for your master, like a start trigger
		// or status flags, if they exist.
	);

	//----------------------------------------------------------------
	// Clock Generation
	//----------------------------------------------------------------
	parameter CLK_PERIOD = 10; // 10 ns -> 100 MHz clock
	initial begin
		clk = 0;
		forever #(CLK_PERIOD / 2) clk = ~clk;
	end

	//----------------------------------------------------------------
	// Main Test Logic
	//----------------------------------------------------------------
	initial begin
		$display("T=%0t: [TB] Simulation starting.", $time);

		// Wait for reset to be released
		rst = 1;
		$display("T=%0t: [TB] Applying reset.", $time);
		# (CLK_PERIOD * 5);
		rst = 0;
		$display("T=%0t: [TB] Releasing reset.", $time);

		#CLK_PERIOD;

		// Initialize slave MISO line to high-impedance or a known state
		miso = 1'bZ;

		// Loop through all 256 possible byte values (extra one because logic to start at 1 was easier and this isn't about the data sent)
		for (int i = 0; i < 257; i++) begin
			expected_data_from_master = i % 256;

			$display("T=%0t: [TB] Waiting for transaction %0d (expected data: 0x%0h)", $time, i, expected_data_from_master);

			// --- Wait for the transaction to start (CS goes low) ---
			wait(cs === 0);
			$display("T=%0t: [TB] Chip Select Asserted (low). Transaction started.", $time);

			// --- Perform the 8-bit SPI transaction ---
			receive_and_transmit_byte(expected_data_from_master);

			// --- Wait for the transaction to end (CS goes high) ---
			wait(cs === 1);
			$display("T=%0t: [TB] Chip Select De-asserted (high). Transaction finished.", $time);
			# (CLK_PERIOD); // Small delay between transactions
		end

		$display("T=%0t: [TB] All 256 transactions completed successfully.", $time);
		$finish;
	end

	//----------------------------------------------------------------
	// SPI Slave Task: Receive and Transmit one byte
	//----------------------------------------------------------------
	// This task models the behavior of an SPI slave for one 8-bit transfer.
	// In SPI Mode 0:
	// - CPOL = 0: Clock is idle low.
	// - CPHA = 0: Data is sampled on the rising edge and changed on the falling edge.
	task receive_and_transmit_byte(input logic [7:0] data_to_send);
    	logic [7:0] received_byte;

    	// For CPHA=0, the slave must output the MSB as soon as CS is asserted,
    	// before the first rising clock edge. The master samples on the rising edge.
    	miso <= data_to_send[7];

    	for (int bit_idx = 7; bit_idx >= 0; bit_idx--) begin
    		// Slave samples MOSI on the rising edge of the clock.
    		@(posedge sclk);
    		received_byte[bit_idx] = mosi;

    		// Slave changes MISO on the falling edge of the clock.
    		// It prepares the *next* bit for the master to sample on the *next* rising edge.
    		if (bit_idx > 0) begin
    		    @(negedge sclk);
    		    miso <= data_to_send[bit_idx - 1];
    		end else begin
    		    // After the last bit is sampled, wait for the final falling edge.
    		    // MISO will be set to Z after CS goes high in the main loop.
    		    @(negedge sclk);
    		end
    	end

    	// After the transaction, set MISO to high-Z. This is important
    	// to prevent bus contention with other potential slaves.
    	miso <= 1'bZ;

    	// --- Verification ---
    	$display("T=%0t: [SLAVE] Received byte: 0x%0h", $time, received_byte);
    	if (received_byte !== expected_data_from_master) begin
    	  $error("T=%0t: [SLAVE] DATA MISMATCH! Expected 0x%0h, but received 0x%0h", $time, expected_data_from_master, received_byte);
    	  $finish;
    	end else begin
    	  $display("T=%0t: [SLAVE] Data MATCH! Correctly received 0x%0h.", $time, received_byte);
    	end
	endtask

endmodule
