# Shrike-Fi display wiring

Use the board's 3.3 V Pmod connector for a display breakout. Connect the display pins to the FPGA-facing Pmod signals as below, then select the matching package pads in Go Configure for your board revision.

| Pmod pin | `shrike_gfx_st7789` / `shrike_gfx_oled` port |
|---:|---|
| 1 | `spi_sck` |
| 2 | `spi_mosi` |
| 3 | `display_dc` |
| 4 | `display_rst_n` |
| 5 | GND |
| 6 | 3.3 V |
| 7 | `display_cs_n` |
| 8 | Optional user backlight output for TFT |
| 9-10 | Unused |
| 11 | GND |
| 12 | 3.3 V |

For a module without a CS connection, set `CS_PIN_PRESENT=0`. A backlight pin is not driven by the wrapper; add a PWM or constant-high signal in the application top if the TFT breakout requires it.

Keep the display GPIOs on Pmod-connected pads. FPGA GPIO3-6 are routed to the ESP32-S3 communication interface, so use the Pmod pads for the display signals. FPGA GPIO16 is connected to the user LED.

The mapping above is the external Pmod-to-display wiring, not the SLG47910 package-pad assignment. Consult the [Shrike pinout guide](https://github.com/vicharak-in/shrike/blob/main/docs/shrike_pinouts.md) and your board revision's schematic before entering package pads in the I/O Planner.
