`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Testbench for SPItop module
//
// Description:
// This testbench verifies the functionality of the SPItop SPI slave module.
// It acts as an SPI master, performing the following sequence:
// 1. Sends a byte (e.g., 0xA5) to the slave.
// 2. Sends a second byte (e.g., 0x5A) and verifies that the data received
//    from the slave during this transaction is the first byte (0xA5).
// 3. Continues this pattern to confirm the echo functionality.
//
// The master implementation follows SPI Mode 0 (CPOL=0, CPHA=0).
//
//////////////////////////////////////////////////////////////////////////////////

module SPItop_tb;

    // Testbench signals
    logic clk;
	logic rst;
    logic CS_n;
    logic SCLK;
    logic MOSI;
    wire  MISO;

	// Control signals
	logic [1:0] sw;

    // Instantiate the Device Under Test (DUT)
	// Ignoring outputs because we only really care about the SPI interface itself...
    slaveTop dut (
        .clk(clk),
		.rst(rst),
        .CS_n(CS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .sw(sw)
    );

    // System Clock Generation (100 MHz)
    parameter CLK_PERIOD = 10;
    initial begin
    	clk = 0;
    	forever #(CLK_PERIOD / 2) clk = ~clk;
	end
    // SPI Master Task for a single byte transfer
    // - Drives MOSI with tx_data
    // - Captures MISO into rx_data
    task automatic spi_transfer(input logic [7:0] tx_data, output logic [7:0] rx_data);
        // Start the transaction by asserting Chip Select
        CS_n = 0;
        
        // Small delay to allow slave to recognize CS_n
        #10; 

        // Loop 8 times for 8 bits of data
        for (int i = 7; i >= 0; i--) begin
            // CPHA=0: Data is valid on the rising edge of SCLK
            
            // Set MOSI just before the falling edge
            MOSI = tx_data[i];
            
            // Generate SCLK pulse (CPOL=0: idle low)
            SCLK = 0;
            #(CLK_PERIOD * 3); // Because of the synchronizers, we wait an extra clock cycle than what would normally be needed
            
            SCLK = 1;
            // The slave captures MOSI on this rising edge.
            // We sample MISO on this rising edge as well.
            rx_data[i] = MISO; 
            #(CLK_PERIOD * 3);
        end
        
        // Reset signals after the transfer
        SCLK = 0;
        MOSI = 0;

        // End the transaction by de-asserting Chip Select
        CS_n = 1;
        
        // Wait for a period between transactions
        #(CLK_PERIOD * 5);
    endtask


	// 2. Declare variables for test data
    logic [7:0] data_sent;
    logic [7:0] data_received;
    logic [7:0] expected_data;

    // Main Test Sequence
    initial begin
    	#500;
        // 1. Initialize all signals to a known state
        $display("TESTBENCH: Starting simulation.");
        clk = 0;
        CS_n = 1;  // Chip select is active low, so start high
        SCLK = 0;  // SPI Mode 0, clock idle is low
        MOSI = 0;
		sw = 2'b00;
		

		for (int i = 0; i < 2; i++) begin // Go once for no fifo, then again for fifo
		
		sw[0] = i; // Set switch to select FIFO or no FIFO
		$display("TESTBENCH: Running test with sw[0] = %b", sw[0]);

		rst = 1; // Reset after switches to ensure FIFOs aren't full of garbage
		#(CLK_PERIOD * 5);
		rst = 0;

		// Wait for a few clock cycles for stability
        #(CLK_PERIOD * 5);

        // --------------------------------------------------------------------
        // Transaction 1: Send the first byte (0xA5). We expect to receive
        // junk (0x00) since the slave has nothing to echo yet.
        // --------------------------------------------------------------------
        data_sent = 8'hA5;
        expected_data = 8'h??; // Expected from the first transaction
        
        $display("TESTBENCH: Tx -> %h, Expecting Rx -> %h", data_sent, expected_data);
        spi_transfer(data_sent, data_received);

        if (data_received == expected_data) begin
            $display("TESTBENCH: PASS! Received %h as expected.", data_received);
        end else begin
            $error("TESTBENCH: FAIL! Received %h, but expected %h.", data_received, expected_data);
        end

        // --------------------------------------------------------------------
        // Transaction 2: Send the second byte (0x5A). We expect to receive
        // the byte from the PREVIOUS transaction (0xA5).
        // --------------------------------------------------------------------
        expected_data = data_sent; // Expect to get back what we just sent
        data_sent = 8'h5A;
        
        $display("TESTBENCH: Tx -> %h, Expecting Rx -> %h (echo)", data_sent, expected_data);
        spi_transfer(data_sent, data_received);
        
        if (data_received == expected_data) begin
            $display("TESTBENCH: PASS! Received %h as expected.", data_received);
        end else begin
            $error("TESTBENCH: FAIL! Received %h, but expected %h.", data_received, expected_data);
        end
        
        // --------------------------------------------------------------------
        // Transaction 3: Send all ones (0xFF). Expect to receive 0x5A back.
        // --------------------------------------------------------------------
        expected_data = data_sent;
        data_sent = 8'hFF;
        
        $display("TESTBENCH: Tx -> %h, Expecting Rx -> %h (echo)", data_sent, expected_data);
        spi_transfer(data_sent, data_received);
        
        if (data_received == expected_data) begin
            $display("TESTBENCH: PASS! Received %h as expected.", data_received);
        end else begin
            $error("TESTBENCH: FAIL! Received %h, but expected %h.", data_received, expected_data);
        end
        
        // --------------------------------------------------------------------
        // Transaction 4: Send all zeros (0x00). Expect to receive 0xFF back.
        // --------------------------------------------------------------------
        expected_data = data_sent;
        data_sent = 8'h01;
        
        $display("TESTBENCH: Tx -> %h, Expecting Rx -> %h (echo)", data_sent, expected_data);
        spi_transfer(data_sent, data_received);
        
        if (data_received == expected_data) begin
            $display("TESTBENCH: PASS! Received %h as expected.", data_received);
        end else begin
            $error("TESTBENCH: FAIL! Received %h, but expected %h.", data_received, expected_data);
        end
        
        
        expected_data = data_sent;
        data_sent = 8'h00;
        
        $display("TESTBENCH: Tx -> %h, Expecting Rx -> %h (echo)", data_sent, expected_data);
        spi_transfer(data_sent, data_received);
        
        if (data_received == expected_data) begin
            $display("TESTBENCH: PASS! Received %h as expected.", data_received);
        end else begin
            $error("TESTBENCH: FAIL! Received %h, but expected %h.", data_received, expected_data);
        end
        
		end // End of double test loop

        // End simulation
        $display("TESTBENCH: All tests completed.");
        $finish;
    end

endmodule