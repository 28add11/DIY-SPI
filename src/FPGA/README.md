# FPGA Demos For SPI Modules

This folder contains the demos/tests for the SPI modules, to be
implemented on the Basys 3 FPGA. These are very simple in functionality,
but designed to demonstrate that the underlying modules work as expected
and can be used in other projects.

## How to use

Each folder, [master](master/) and [slave](slave/), contain the top
modules for their respective design. This base folder just contains sub
modules shared between both designs (synchronizers for
[signals](sync.sv) and [reset](safeReset.sv)).

### Hardware

**Note: applies specifically to basys3**

After adding all the files to a Vivado project, you can use [Digilent's
provided constraints files](https://github.com/Digilent/digilent-xdc/)
and modify them slightly to get them working. For the master
implementation, uncomment the clock lines, all of the switches, the
first two LEDs, and another input (I used a button personally) renamed
to `rst`. For the slave, uncomment the clock lines, first two switches
and LEDs, and the whole seven segment display block. For both, you can
then rename some generic I/O lines to `CS_n`, `SCLK`, `MOSI`, and
`MISO` for the SPI interface itself.

### Software Tests

The files in [test](../../test) contain some simple checks that both
master and slave work, and it should be simple to run them with your
test suite of choice. They will display messages about the transactions
and if they succeeded or failed. The master especially can represent a
long time in simulation, so beware of any resulting big files!

## Functionality

### Master

Once loaded onto the board or a simulator, it will use the switches to
choose the prescale value. Switches 0 through 7 will select
`prescale1`, and switches 8 through 15 will select `prescale2`. It
needs to be reset initially using whatever signal you assigned to that,
then will immediately start transmitting after coming out of reset. It
transmits an 8-bit value, starting from zero and incrementing with every
transaction. It expects the slave device to do the same, meaning both
devices transmit and receive the same data on the same transaction. For
example, coming out of reset, the transactions are expected to go 0, 1,
2… 255, 0. This will repeat indefinitely. If at any point the data does
not match this, `led\[0\]`should go low.

### Slave

The slave module is much simpler. It should just echo back any data sent
to it on the next transaction. For example, if a master sends 0, 1, 2,
the slave will send (x), 0, 1 and so on. The module will use the slave
without a FIFO if the first switch is off, and will use the slave with a
FIFO when it is on. The two LEDs indicate if the receive and transmit
FIFOs are empty (when enabled) respectively. The seven segment display
is used to show the received byte in hexadecimal.
