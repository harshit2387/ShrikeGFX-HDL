# shrike-gfx

Reusable, zero-framebuffer display RTL for the Renesas SLG47910 ForgeFPGA used on Shrike-Lite and Shrike-Fi. The core draws pixels from live `(x,y)` coordinates and streams them directly to SPI; it does not allocate a screen buffer.

## Architecture

```text
                      +------------------------+
 start + dirty box -->| ST7789 window streamer |-- CASET / RASET / RGB565 --+
                      +------------------------+                           |
                                 ^ x,y                                      v
                      +------------------------+                 +------------------+
                      | Coordinate shader      |                 | SPI mode-0 master|--> TFT
                      | text + bar + scope     |                 | reset / CS / DC  |
                      +------------------------+                 +------------------+
                                                                          ^
                      +------------------------+                          |
 start + dirty box -->| OLED page engine       |-- page bytes -------------+
                      +------------------------+        separate SPI instance --> OLED
```

For two displays, instantiate one display wrapper per panel, with independent SPI pins and clock settings. Each wrapper includes its own reset sequencer, initialization ROM, and serializer.

## RTL files

| File | Purpose |
|---|---|
| `rtl/spi_display_master.v` | SPI mode-0 byte transport, clock divider, transaction CS, per-byte DC, and hardware reset timing |
| `rtl/shrike_gfx_init.v` | Compact initialization tables for ST7789, SSD1306, and SH1106 |
| `rtl/shrike_gfx_st7789.v` | Complete ST7789 wrapper with initialization and dirty-window pixel stream |
| `rtl/gfx_st7789_stream.v` | Sends inclusive CASET/RASET windows and RGB565 pixels computed from current coordinates |
| `rtl/shrike_gfx_oled.v` | Complete 128x64 monochrome OLED wrapper |
| `rtl/gfx_oled_engine.v` | Page-addressed SSD1306/SH1106 writer; generates each output byte from eight live pixels |
| `rtl/widget_text_rom.v` | Combinational 5x7 uppercase/numeric font subset |
| `rtl/widget_bar.v` | Coordinate hit and fill tests; caller supplies pre-scaled fill width |
| `rtl/widget_scope.v` | One-bit digital trace against a packed sample-history shift register |
| `examples/dashboard_shader.v` | Composes a bar, trace, and one text glyph into an RGB565 pixel |
| `examples/shrike_gfx_example_top.v` | Complete periodic 240x240 ST7789 example top module |

The text ROM supports `0-9`, `A-F`, `P/W/M/V/I/H/Z/O/L/T/R`, space, dash, period, colon, and percent. A string renderer can select the character for each six-pixel text cell and feed this ROM.

## Which module do I instantiate?

Your FPGA top instantiates one high-level display wrapper:

```text
your_top
├── shrike_gfx_st7789  (or shrike_gfx_oled)
│   ├── spi_display_master
│   ├── shrike_gfx_init
│   └── gfx_st7789_stream  (or gfx_oled_engine)
└── your pixel shader (for example dashboard_shader)
    ├── widget_bar
    ├── widget_scope
    └── widget_text_rom
```

The display wrapper calls the transport and renderer modules internally. Usually you do not instantiate `spi_display_master` or `gfx_st7789_stream` yourself. Your design provides `start`, the dirty window coordinates, and a combinational pixel shader; the wrapper handles initialization and sends that window to the panel.

## Use it after downloading

This is a Verilog source library, so there is no package installer. The display wrapper is the library entry point; your project top supplies its clock, reset, draw request, and pixel shader.

1. Download and extract `shrike-gfx.zip`.
2. In Go Configure, create or open your ForgeFPGA Verilog project and add every `rtl/*.v` file as a source.
3. For the ready-made demo, also add `examples/dashboard_shader.v` and `examples/shrike_gfx_example_top.v`. Set the top module to `shrike_gfx_example_top`.
4. Use the matching constraints template as a reference. Assign `spi_sck`, `spi_mosi`, `display_cs_n`, `display_dc`, and `display_rst_n` to the Pmod-connected outputs for your board revision. Set output enable on those pads. The `clk_en` signal enables the internal oscillator.
5. Connect an active-low reset to `rst_n`, set the correct panel offsets and CS parameter in the example top, then generate the bitstream.

The example refreshes a 240x240 ST7789 panel every 100 ms and draws a duty bar, a digital trace, and a `P` glyph. For a 240x240 module with no accessible CS pin, change `.CS_PIN_PRESENT(1)` to `.CS_PIN_PRESENT(0)` in the example. For 135x240 modules, also set the module's X offset. For an existing design, omit the example top and instantiate `shrike_gfx_st7789` or `shrike_gfx_oled` inside your own top module, then connect its coordinate outputs to your combinational shader and feed the resulting color or monochrome bit back to the wrapper.

## Display wrapper setup

### ST7789

Instantiate `shrike_gfx_st7789`. The wrapper defaults to a 50 MHz logic clock and a 12.5 MHz SPI clock. Set `X_OFFSET` and `Y_OFFSET` for the panel's visible area inside controller RAM; 135x240 modules commonly need an X offset, while other module variants differ. `CS_PIN_PRESENT=0` drives `display_cs_n` low for panels with CS hard-wired or omitted. Set `RESET_PIN_PRESENT=0` if the panel has no reset input. The window coordinates are 16-bit, logical, inclusive bounds and must fit the selected panel.

The core sends CASET, RASET, and RAMWR, then requests `pixel_rgb565` combinationally at each exported `pixel_x/pixel_y`. Keep the shader purely combinational so each color remains stable for the high and low bytes of the pixel. Assert `start` when `start_ready` is high; `done` pulses after the last pixel byte has left SPI.

Typical wiring between a top module, the example shader, and the display wrapper looks like this (the top module supplies `frame_start`, reset, and telemetry values):

```verilog
wire [15:0] pixel_x, pixel_y, pixel_rgb565;
wire pixel_active, start_ready, display_busy, frame_done, init_done;

dashboard_shader layer (
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .duty_fill_width(duty_fill_width), .trace_history(trace_history),
    .char_code(8'h50), .text_x0(16'd8), .text_y0(16'd8),
    .pixel_rgb565(pixel_rgb565)
);

shrike_gfx_st7789 #(
    .CLK_HZ(50000000), .SPI_HZ(12500000),
    .X_OFFSET(0), .Y_OFFSET(0)
) tft (
    .clk(clk), .rst_n(rst_n), .start(frame_start), .start_ready(start_ready),
    .win_x0(16'd0), .win_y0(16'd0), .win_x1(16'd239), .win_y1(16'd239),
    .pixel_x(pixel_x), .pixel_y(pixel_y), .pixel_active(pixel_active),
    .pixel_rgb565(pixel_rgb565), .busy(display_busy), .done(frame_done),
    .init_done(init_done), .spi_sck(spi_sck), .spi_mosi(spi_mosi),
    .display_cs_n(display_cs_n), .display_dc(display_dc),
    .display_rst_n(display_rst_n)
);
```

### SSD1306 / SH1106

Instantiate `shrike_gfx_oled` with `DISPLAY_TYPE=1` for SSD1306 or `DISPLAY_TYPE=2` for SH1106. The default SPI clock is 2 MHz. For common SH1106 panels whose visible 128 columns sit inside 132 columns of RAM, set `COLUMN_OFFSET=2` (check the module's datasheet). Coordinates must be within 128x64. Y updates round outward to whole 8-pixel pages; the shader is sampled for all eight rows in each touched page. Assert `start` when `start_ready` is high.

The engines operate independently and may be updated at different rates. A dual-display design needs enough free FPGA GPIOs for both SPI interfaces, DC, CS, and reset lines.

## Pmod signal wiring

The same signal-level wiring can be used on both Shrike-Lite and Shrike-Fi. The board documentation identifies a Pmod connector on both boards and specifies 3.3 V logic. The assignments below describe the cable from a standard 12-pin Pmod header to a display breakout; they are not SLG47910 package-pin numbers.

| Pmod pin | Display signal |
|---:|---|
| 1 | `spi_sck` |
| 2 | `spi_mosi` |
| 3 | `display_dc` |
| 4 | `display_rst_n` |
| 5 | GND |
| 6 | 3.3 V |
| 7 | `display_cs_n` |
| 8 | Optional user-driven backlight output (TFT only; expose separately in your top module) |
| 9-10 | Unused |
| 11 | GND |
| 12 | 3.3 V |

For a panel without a CS input, omit that wire and configure `CS_PIN_PRESENT=0`. Do not connect a 5 V display signal to the FPGA. For the OLED, omit backlight wiring.

The board-specific display wiring notes are in `pinmaps/shrike_lite.md` and `pinmaps/shrike_fi.md`. The files in `constraints/` are pin-assignment templates. Replace `PIN_N` only after selecting the Pmod-connected FPGA GPIO in the Go Configure I/O Planner and checking the schematic for the exact board revision. The Shrike-Lite docs note that FPGA GPIO17/18 are also connected to the RP2040 by default through zero-ohm links; avoid those pads unless the board modification is understood. The templates intentionally do not guess a package-pad number.

## Go Configure integration

1. Add the required files from `rtl/` and your top module to the Verilog project. Include `examples/dashboard_shader.v` only if using that example.
2. Connect the ForgeFPGA clock to `clk` and set the clock frequency parameter to the actual fabric clock. In a top module that exposes `clk_en`, drive it high to enable the internal oscillator.
3. Connect the display wrapper's SPI/DC/reset outputs to the chosen Pmod GPIOs in the I/O Planner. Configure each as an output with output enable asserted. Constrain the clock and use output mappings from your board revision.
4. Tie `rst_n` to a real active-low reset source or add a power-on reset in the top module. The wrapper then performs the display reset pulse and init sequence.
5. Drive `start`, window bounds, and the shader inputs from your application logic. `start_ready` indicates that initialization has completed and the writer is idle.

`constraints/shrike_lite.pcf.template` and `constraints/shrike_fi.pcf.template` are reference templates for flows that consume nextpnr-style PCF. Go Configure's I/O Planner remains the source of truth for physical pad numbers and output enables.

The board reference material is [Vicharak's hardware overview](https://github.com/vicharak-in/shrike/blob/main/docs/hardware_overview.md), [Shrike board pinouts](https://github.com/vicharak-in/shrike/blob/main/docs/shrike_pinouts.md), and the [Renesas SLG47910 datasheet](https://www.renesas.com/en/document/dst/slg47910-datasheet).

## Resource notes

There is no framebuffer or pixel RAM. The scope history is only 128 bits in the example, and the text font is a small constant ROM. This design has not yet been synthesized for SLG47910, so it makes no LUT or Fmax claim. Record those values from Go Configure after selecting a concrete top level, clock, and display combination; the renderer and both display wrappers are separate so unused blocks can be left out.

## Licensing

MIT. See `LICENSE`.
