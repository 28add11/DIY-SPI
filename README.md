# DIY-SPI
## A working, customizable SPI module, made by a hobbyist with minor brain damage

This is an SPI mode 0 implementation, for communication in ASICs/FPGAs. There is both a master and slave version, both of which have versions with buffers for reciving and transmitting data. It's tested to work on the Basys 3, communicating with the RP2040.

## What does it do?
SPI (Serial Peripheral Interface) is a standard used for communication between devices. It has one wire for a clock signal, one wire for an enable signal for the slave device, and two wires for sending data in both directions. This is a mode 0 implementation, meaning the clock is normally low, data is shifted out on the falling edge of the clock and sampled on the rising edge. The master device is the one controlling the transaction, and generates the clock and enable signals for the slave device to recive. This is an implementation of that in an HDL, basically a language used to describe real hardware on a chip. 

## But why?
SPI is a pretty important standard. If I ever want to make a product using SD cards, SPI can be used there. Even more important are the many flash chips that use SPI and it's derivatives. These often store code used to boot a system, like in a BIOS. This project provides a base to integrate these systems into a full ASIC/FPGA, and can be used for my future goals of making an SoC (system on a chip). Beyond that, it was also a pretty good learning project, not to mention fun!

## Documentation and how to use
Because there are separate modules for each application, data about them can be found in each respective folder.
The modules themselves can be found in [src](src/), which is further split up into [FPGA](src/FPGA/) and the modules themselves. FPGA contains the wrapper code I use to implement the devices in hardware, currently just showing simple functionality such as echo and sending sequential data.

## How to test
If you want to test in hardware, feel free to use the code in [FPGA](src/FPGA/). The `slaveTop.sv` and `masterTop.sv` files are the top level definitions, you can change the input/output names to match how you want to implement it. I did so on a Basys 3, so functionality is tailored to that. 
If you want to test using a simulator, the test code is in [test](test/). It's been tested in Vivado's built in simulator, and uses the FPGA test modules for the designs under test. There are more instructions for both in the [readme for FPGA](src/FPGA/README.md).


Look, you probably shouldn't use this in your own project, I am definitly a noob to digital design. But if you want to learn off it, that is more than welcome. Even better, if you want to contribute I would be very glad.
