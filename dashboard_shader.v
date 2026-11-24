// Example coordinate shader for shrike_gfx_st7789.
// Draws a 100-pixel duty bar, a one-bit trace, and one 5x7 character glyph.
module dashboard_shader #(
    parameter [15:0] BACKGROUND_COLOR = 16'h0000,
    parameter integer COORD_BITS = 16
) (
    input  wire [15:0] pixel_x,
    input  wire [15:0] pixel_y,
    input  wire [7:0]  duty_fill_width,
    input  wire [127:0] trace_history,
    input  wire [7:0]  char_code,
    input  wire [15:0] text_x0,
    input  wire [15:0] text_y0,
    output reg  [15:0] pixel_rgb565
);
    wire bar_hit, bar_filled;
    wire scope_hit;
    wire font_pixel;
    wire in_text;
    wire [COORD_BITS-1:0] coord_x = pixel_x[COORD_BITS-1:0];
    wire [COORD_BITS-1:0] coord_y = pixel_y[COORD_BITS-1:0];
    wire [COORD_BITS-1:0] text_x = text_x0[COORD_BITS-1:0];
    wire [COORD_BITS-1:0] text_y = text_y0[COORD_BITS-1:0];
    wire [COORD_BITS-1:0] glyph_x_full = coord_x - text_x;
    wire [COORD_BITS-1:0] glyph_y_full = coord_y - text_y;
    wire [2:0] glyph_x = glyph_x_full[2:0];
    wire [2:0] glyph_y = glyph_y_full[2:0];

    localparam [COORD_BITS-1:0] BAR_X0 = 20;
    localparam [COORD_BITS-1:0] BAR_Y0 = 40;
    localparam [COORD_BITS-1:0] BAR_WIDTH = 100;
    localparam [COORD_BITS-1:0] BAR_HEIGHT = 9;
    localparam [COORD_BITS-1:0] SCOPE_X0 = 8;
    localparam [COORD_BITS-1:0] SCOPE_HIGH_Y = 100;
    localparam [COORD_BITS-1:0] SCOPE_LOW_Y = 116;
    localparam [COORD_BITS-1:0] TEXT_WIDTH = 5;
    localparam [COORD_BITS-1:0] TEXT_HEIGHT = 7;

    widget_bar #(.COORD_BITS(COORD_BITS)) bar (
        .x(coord_x), .y(coord_y), .x0(BAR_X0), .y0(BAR_Y0),
        .width(BAR_WIDTH), .height(BAR_HEIGHT),
        .fill_width(duty_fill_width),
        .hit(bar_hit), .filled(bar_filled)
    );

    widget_scope #(.WIDTH(128), .COORD_BITS(COORD_BITS)) scope (
        .x(coord_x), .y(coord_y), .x0(SCOPE_X0),
        .high_y(SCOPE_HIGH_Y), .low_y(SCOPE_LOW_Y),
        .history(trace_history), .hit(scope_hit)
    );

    widget_text_rom font (
        .char_code(char_code), .glyph_x(glyph_x), .glyph_y(glyph_y),
        .pixel_on(font_pixel)
    );

    assign in_text = (coord_x >= text_x) && (coord_x < text_x + TEXT_WIDTH) &&
                     (coord_y >= text_y) && (coord_y < text_y + TEXT_HEIGHT);

    always @* begin
        pixel_rgb565 = BACKGROUND_COLOR;
        if (bar_hit) pixel_rgb565 = bar_filled ? 16'h07E0 : 16'h4208;
        if (scope_hit) pixel_rgb565 = 16'hFFE0;
        if (in_text && font_pixel) pixel_rgb565 = 16'hFFFF;
    end
endmodule
