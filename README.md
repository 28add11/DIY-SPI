# DIY-SPI
## A working, customizable SPI module, made by a hobbyist with minor brain damage

This is an SPI mode 0 implementation, for communication in ASICs/FPGAs. There is both a master and slave version, both of which have versions with buffers for reciving and transmitting data. It's tested to work on the Basys 3, communicating with the RP2040.

## Documentation and how to use
Because there will eventually (hopefully) be multiple different modules with differences between them, documentation of the inner workings and how to use them will be provided in their respective folders.
The modules themselves can be found in [src](src/), which is further split up into [FPGA](src/FPGA/) and the modules themselves. FPGA contains the wrapper code I use to implement the devices in hardware, currently just showing simple functionality.

## How to test
If you want to test in hardware, feel free to use the code in [FPGA](src/FPGA/). The `FPGAtop.sv` file is the top level definition, you can change the input/output names to match how you want to implement it. I did so on a Basys 3, so functionality is tailored to that. 
If you want to test using a simulator, the test code is in [test](test/). It's been tested in Vivado's built in simulator, and uses the `FPGAtop.sv` module as a top level definition. 
> [!IMPORTANT]
> For testing sake, the `FPGAtop.sv` module will likely stay the same, but use the basys3's included switches to change which test is being run. Keep this in mind if you plan on implementing anything in here



Look, you probably shouldn't use this in your own project, I am definitly a noob to digital design. But if you want to learn off it, that is more than welcome. Even better, if you want to contribute I would be very glad.
