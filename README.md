I2C Master Controller (Verilog)

A simple yet functional I2C master controller implemented in Verilog, designed for simulation and educational purposes.

## Project Overview

This project provides a hierarchical Verilog implementation of an I2C master controller with the following components:

- **i2c_master.v**: Top-level module that instantiates and wires all submodules
- **i2c_controller.v**: Wrapper that interfaces with the FSM
- **i2c_fsm.v**: Simplified finite-state machine handling I2C address and data phases
- **i2c_shift_reg.v**: Byte shift register for serializing/deserializing data
- **i2c_clk_div.v**: Parameterizable clock divider for I2C timing

## Features

- 7-bit addressing (+ R/W bit)
- Single-byte read/write transfers
- Open-drain tristate bus modeling
- Simple testbench with verification
- Waveform generation (VCD) for simulation inspection

## Requirements

- **Icarus Verilog** (iverilog + vvp) - Free, open-source Verilog simulator
- **Optional**: GTKWave for waveform visualization

### Install on Windows:
```powershell
# Using Chocolatey
choco install iverilog gtkwave
```

Or download from:
- [Icarus Verilog](http://iverilog.icarus.com/)
- [GTKWave](http://gtkwave.sourceforge.net/)

## Building & Simulation

### Option A: PowerShell Script (Windows)

```powershell
.\simulate.ps1
```

### Option B: Manual Compilation

```bash
iverilog -o simv i2c_clk_div.v i2c_fsm.v i2c_controller.v i2c_shift_reg.v i2c_master.v i2c_master_tb.v
vvp simv
```

### Viewing Waveforms

After simulation completes and generates `i2c_master_tb.vcd`:

```bash
gtkwave i2c_master_tb.vcd
```

Or open with any VCD viewer.

## Testing

The testbench in `i2c_master_tb.v` performs:
- A write transfer (master sends 0xA5 to slave at address 0x50)
- A read transfer (master reads from slave at address 0x50)

Expected output:
```
TRANSFER DONE op=0 addr=50 data=a5 ack_error=0 rx_data=00
TRANSFER DONE op=1 addr=50 data=00 ack_error=0 rx_data=00
TEST COMPLETE: busy=0 ack_error=0 rx_data=00
```

The waveform shows:
- SCL and SDA bus activity
- Shift register loading and shifting
- FSM state transitions
- Control strobes (shift_load, shift_shift)

## File Structure

```
.
├── i2c_master.v         # Top module
├── i2c_controller.v     # Controller wrapper
├── i2c_fsm.v            # FSM state machine
├── i2c_shift_reg.v      # Shift register
├── i2c_clk_div.v        # Clock divider
├── i2c_master_tb.v      # Testbench
├── simulate.ps1         # Windows simulation script
├── README.md            # This file
└── .gitignore           # Git ignore rules
```

## Limitations & Future Work

- **Single-byte transfers only** – extend FSM for multi-byte sequences
- **No clock stretching** – simplified for demonstration
- **No bus arbitration** – single master design
- **Simplified slave behavior** – testbench uses default responses

## Enhancement Ideas

1. Implement multi-byte read/write with repeated START
2. Add clock-stretching support (monitor SCL from slave)
3. Create a behavioral I2C slave model for testing
4. Add error recovery and retry logic
5. Support 10-bit addressing
6. Integrate with FPGA toolchain (Yosys, nextpnr, etc.)

## Architecture Notes

### Open-Drain Modeling
The design uses Verilog `tri1` for open-drain simulation:
```verilog
assign sda = sda_oe ? 1'b0 : 1'bz;
```
This models the wired-AND behavior of I2C buses.

### Timing
- **clk_en**: Pulses once every DIV clock cycles (default: DIV=100)
- **FSM**: Advances on clk_en pulses, handling one bit per pulse
- **Shift register**: Shifts on shift_shift strobe

## License

This project is provided as-is for educational and hobbyist purposes.

## Author

Created as part of an I2C master controller design exercise.

