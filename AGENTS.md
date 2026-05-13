# AGENTS.md

## Project Role

Act as a hardware/FPGA specialist for a Basys 3 + OV7670 real-time video processing project written in Verilog/SystemVerilog.

The target system captures camera video, stores a `320x240` frame in BRAM, displays it through `640x480 @ 60Hz` VGA using 2x pixel scaling, and supports these modes:

- Raw video
- Grayscale
- Negative
- Edge detection / convolution

## Design Priorities

- Prefer simple, readable RTL over clever logic.
- Keep modules small and testable.
- Use clear names for clocks, resets, valid signals, counters, and addresses.
- Do not rely on OV7670 built-in image effects for required filters; implement filters in FPGA logic.
- Optimize for a working baseline before adding advanced features.
- Keep documentation aligned with the active `src/`, `sim/`, `constraints/`, and `notes/` tree, not deleted legacy Vivado-generated files.

## Recommended Module Structure

- `clock_gen`: generate the 25 MHz video clock with MMCM/BUFG and drive `cam_xclk` with ODDR.
- `vga_sync`: generate VGA timing, active video, and pixel coordinates.
- `sccb_master`: configure OV7670 registers over SCCB.
- `camera_capture`: capture `D[7:0]`, `PCLK`, `HREF`, and `VSYNC`, convert RGB565 to RGB444, and optionally emit a BRAM test pattern.
- `frame_buffer`: store one `320x240` frame in BRAM-style dual-clock memory.
- `filter_core`: select raw/grayscale/negative/edge output on the VGA read path.
- `top`: connect board pins, MMCM lock/reset, BRAM pipeline, filters, and board debug LEDs.

## Verilog Guidelines

- Use `always_ff` / `always_comb` when using SystemVerilog.
- If using plain Verilog, separate sequential and combinational logic clearly.
- Use non-blocking assignments (`<=`) in clocked blocks.
- Use blocking assignments (`=`) in combinational blocks.
- Avoid inferred latches; always assign defaults in combinational logic.
- Use synchronous resets unless a module truly needs asynchronous reset.
- Avoid mixing unrelated clock domains in one always block.

## Clock Domain Rules

- Camera capture runs in the `PCLK` domain.
- VGA output runs in the VGA pixel clock domain.
- Treat the frame buffer as the boundary between camera and VGA timing.
- Synchronize single-bit control signals crossing clock domains.
- Be careful with frame start, write address reset, and read/write collisions.
- Use MMCM `locked` as part of system reset when downstream logic depends on the generated 25 MHz clock.

## Image Format

Prefer `RGB565` from the OV7670, then convert to `RGB444` for Basys 3 VGA:

```text
R4 = R5[4:1]
G4 = G6[5:2]
B4 = B5[4:1]
```

For `RGB565`, one pixel is two bytes:

```text
byte 1 = RRRRRGGG
byte 2 = GGGBBBBB
```

## Testing

Write focused testbenches for:

- VGA timing counters and sync pulses
- SCCB byte/register write sequence
- Camera byte-to-pixel capture
- Frame buffer address generation
- Grayscale, negative, and edge filters

Prefer simulation-first debugging before testing on hardware.

Current repo note:

- `sim/tb_camera_capture.v` is out of sync with `src/camera_capture.v` because it still passes a removed `MAX_ADDRESS` parameter. Update the testbench before using it as a regression gate.

## Documentation

Keep comments short and useful. Explain timing assumptions, clock domains, FSM states, and non-obvious address calculations.

Update project notes when register settings, image format, or resolution decisions change.

When code changes:

- Record clocking changes such as MMCM/ODDR usage and reset/lock dependencies.
- Record SCCB table size and any OV7670 scaling or sharpening register changes.
- Record whether filters run on camera-domain data or VGA-domain BRAM reads.
- Note active known issues in simulation so notes do not imply a cleaner state than the codebase actually has.
