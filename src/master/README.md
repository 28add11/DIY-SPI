# SPI Mode 0 Master

This folder consists of my implementation of an SPI mode 0 master in
SystemVerilog. It can theoretically support any bit width for each
transaction and can run up to \~7 MHz in real
tests, though theoretical speeds are half of the system clock. It's
tested to work on the Basys 3 FPGA with the RP2040 at a minimum of 100
MHz system clock, though this could be increased.

> [!WARNING]
> This is not going to be perfect. A lot of the functionality isn't totally verified, and it probably will require tweaking (see [XKCD 1742](https://xkcd.com/1742/)).
> If you do find something that doesn't work though, let me know, and I would be happy to implement it.

In this folder, [master.sv](master.sv), which contains the
`SPIMaster` module has all the logic for the main SPI implementation,
while [clkPrescale.sv](clkPrescale.sv) contains the clock prescaler
used to step the system clock down to a user defined level for the SCK
signal. To implement this, you'll also need the [FIFO.sv](../FIFO.sv)
file from the `src` directory.

For a simple demonstration of this module, see
[masterTop.sv](../FPGA/master/masterTop.sv).

# How to use it

## Instantiation

After getting the correct files, you can instantiate the ` SPIMaster`
module, which has 3 parameters. `WIDTH` selects the bit width (8 bits
by default), and `TxFIFODepth`/`RxFIFODepth` determine how deep each
respective FIFO should be (8 WIDTH wide words by default). The following
table lists input/output descriptions:

  
|**Port**                    |      **Description**
|----------------------------|-----------------------------------------|
|`clk`                       | System clock|
|`rst_n`                     | Active high synchronous reset|
|`CS_n`, `SCK`, `MOSI`       | SPI outputs|
|`MISO`                      | SPI input, synchronization is implementer's responsibility|
|`RXdata`                    | `WIDTH` wide bus, outputs data from receive FIFO|
|`readEn`                    | Read from receive FIFO|
|`RXFIFOempty`, `RXFIFOfull`, `TXFIFOempty`, `TXFIFOfull`| FIFO flags|
|`TXdata`                    | `WIDTH` wide bus, input data to transmit FIFO|
|`writeEn`                   | Write to transmit FIFO. Data must be held for at least 1 clock cycle.|
|`startTransaction`          | When pulsed (or held, as long as transmit FIFO has data) will begin an SPI transaction|
|`doneTransaction`           | Will go low when busy (transmitting)|
|`prescale1`, `prescale2`    | 8 bit wide buses, for the clock prescale value. Must be held at the desired value for the whole transaction, but can be changed on the fly.|
|----------------------------|------------------------------------------|

## SCK Generation

The `prescalen` values control the speed of the resulting SCK,
following the equation $\frac{clk}{2(prescale1 + 1)(prescale2 + 1)}$.
So, when the system clock is 100 MHz, the slowest SCK possible is 762.9
Hz (`prescale1` and `prescale2` == 255), while the highest is 50 MHz.

Both prescale signals can be changed on the fly, however I doubt that
this is useful.

## Operation

### Reset

First, the device needs to be reset with the `rst_n` port. It should
be brought low for at least one clock cycle, then brought high again.

### Load data

`TXdata` should be set with whatever data needs to be sent, then
`writeEn` should go high. After one cycle, data will be loaded in the
transmit FIFO. `writeEn` can then remain high to load more data,
though beware that `TXFIFOfull` will only be asserted on the clock
cycle after the final write. Alternatively, `writeEn` can go low until
the next word of data is ready.

### Send data

Once data is loaded, ` TXFIFOempty` goes low, and `doneTransaction`
goes high, `startTransaction` can be asserted for at least one cycle
to begin the SPI transaction. After one clock cycle, `CS_n` will go
low, and data will start to be loaded from the transmit FIFO. One cycle
later, the transmit FIFO flags will be updated. After half of an SPI
cycle as defined by the prescale signals, the transaction will begin,
and data will be sent and received serially. Finally, data is written to
the receive FIFO, then after another half SPI cycle `CS_n` returns to
high and the transaction is done.

### Read data

To read data from the receive FIFO, first check that it isn't empty,
then set `readEn` high. After one cycle, data is put into the FIFO
output registers, so it will be readable on the cycle following that. In
other words, if `readEn` is asserted on cycle 0, the data will be
usable on cycle 2. `readEn` can remain high to read more data, like
the FIFO write behavior, or it can return low.
