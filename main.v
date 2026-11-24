// Minimal ST7789 test screen: solid red with one white pixel.
// The renderer is coordinate-based and uses the reusable shrike-gfx stream driver.
(* top *)
module mux21 #(
    parameter integer CLK_HZ = 50000000,
    parameter [15:0] LCD_WIDTH = 16'd240,
    parameter [15:0] LCD_HEIGHT = 16'd240,
    parameter [15:0] SPI_HALF_PERIOD = 16'd25,
    parameter [7:0] MADCTL_VAL = 8'h00,
    parameter [7:0] COLMOD_VAL = 8'h55,
    parameter integer PIXEL_ENABLE = 1,
    parameter [15:0] PIXEL_X = 16'd120,
    parameter [15:0] PIXEL_Y = 16'd120,
    parameter [15:0] PIXEL_COLOR = 16'hFFFF,
    parameter [15:0] BACKGROUND_COLOR = 16'hF800,
    parameter integer CS_PIN_PRESENT = 1,
    parameter integer RESET_PIN_PRESENT = 1,
    parameter integer X_OFFSET = 0,
    parameter integer Y_OFFSET = 0
) (
    (* iopad_external_pin, clkbuf_inhibit *) input wire clk,
    (* iopad_external_pin *) output wire clk_en,
    (* iopad_external_pin *) output wire lcd_sck,
    (* iopad_external_pin *) output wire lcd_sck_oe,
    (* iopad_external_pin *) output wire lcd_mosi,
    (* iopad_external_pin *) output wire lcd_mosi_oe,
    (* iopad_external_pin *) output wire lcd_cs_n,
    (* iopad_external_pin *) output wire lcd_cs_n_oe,
    (* iopad_external_pin *) output wire lcd_dc,
    (* iopad_external_pin *) output wire lcd_dc_oe,
    (* iopad_external_pin *) output wire lcd_reset_n,
    (* iopad_external_pin *) output wire lcd_reset_n_oe,
    (* iopad_external_pin *) output wire lcd_backlight,
    (* iopad_external_pin *) output wire lcd_backlight_oe
);
    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                clog2 = clog2 + 1;
                v = v >> 1;
            end
            if (clog2 < 1) clog2 = 1;
        end
    endfunction

    localparam integer SPI_HZ = CLK_HZ / (2 * SPI_HALF_PERIOD);
    localparam integer DISPLAY_MAX_DIM = (LCD_WIDTH > LCD_HEIGHT) ? LCD_WIDTH : LCD_HEIGHT;
    localparam integer COORD_BITS = clog2(DISPLAY_MAX_DIM);
    localparam [15:0] X_END = LCD_WIDTH - 16'd1;
    localparam [15:0] Y_END = LCD_HEIGHT - 16'd1;

    reg logic_rst_n = 1'b0;
    wire start_ready;
    wire [15:0] pixel_x;
    wire [15:0] pixel_y;
    wire pixel_active;
    wire display_busy;
    wire display_done;
    wire init_done;
    reg [15:0] pixel_rgb565;

    assign clk_en = 1'b1;
    assign lcd_sck_oe = 1'b1;
    assign lcd_mosi_oe = 1'b1;
    assign lcd_cs_n_oe = 1'b1;
    assign lcd_dc_oe = 1'b1;
    assign lcd_reset_n_oe = 1'b1;
    assign lcd_backlight = 1'b1;
    assign lcd_backlight_oe = 1'b1;

    always @(posedge clk)
        logic_rst_n <= 1'b1;

    // A simple uniform fill minimizes logic and keeps the test visible.
    // The single-pixel override is independent of pixel_active so both RGB565 bytes match.
    always @* begin
        pixel_rgb565 = BACKGROUND_COLOR;
        if (PIXEL_ENABLE && (pixel_x == PIXEL_X) && (pixel_y == PIXEL_Y))
            pixel_rgb565 = PIXEL_COLOR;
    end

    shrike_gfx_st7789 #(
        .CLK_HZ(CLK_HZ),
        .SPI_HZ(SPI_HZ),
        .CS_PIN_PRESENT(CS_PIN_PRESENT),
        .RESET_PIN_PRESENT(RESET_PIN_PRESENT),
        .X_OFFSET(X_OFFSET),
        .Y_OFFSET(Y_OFFSET),
        .MADCTL_VAL(MADCTL_VAL),
        .COLMOD_VAL(COLMOD_VAL),
        .COORD_BITS(COORD_BITS)
    ) display (
        .clk(clk),
        .rst_n(logic_rst_n),
        .start(start_ready),
        .start_ready(start_ready),
        .win_x0(16'd0),
        .win_y0(16'd0),
        .win_x1(X_END),
        .win_y1(Y_END),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_active(pixel_active),
        .pixel_rgb565(pixel_rgb565),
        .busy(display_busy),
        .done(display_done),
        .init_done(init_done),
        .spi_sck(lcd_sck),
        .spi_mosi(lcd_mosi),
        .display_cs_n(lcd_cs_n),
        .display_dc(lcd_dc),
        .display_rst_n(lcd_reset_n)
    );
endmodule