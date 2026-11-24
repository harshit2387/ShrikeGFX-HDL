// Example coordinate shader for shrike_gfx_st7789.
// Draws a 100-pixel duty bar, a one-bit trace, and one 5x7 character glyph.
module dashboard_shader (
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
    wire [2:0] glyph_x = pixel_x - text_x0;
    wire [2:0] glyph_y = pixel_y - text_y0;

    widget_bar bar (
        .x(pixel_x), .y(pixel_y), .x0(16'd20), .y0(16'd40),
        .width(16'd100), .height(16'd9),
        .fill_width({8'd0, duty_fill_width}),
        .hit(bar_hit), .filled(bar_filled)
    );

    widget_scope #(.WIDTH(128)) scope (
        .x(pixel_x), .y(pixel_y), .x0(16'd8),
        .high_y(16'd100), .low_y(16'd116),
        .history(trace_history), .hit(scope_hit)
    );

    widget_text_rom font (
        .char_code(char_code), .glyph_x(glyph_x), .glyph_y(glyph_y),
        .pixel_on(font_pixel)
    );

    assign in_text = (pixel_x >= text_x0) && (pixel_x < text_x0 + 5) &&
                     (pixel_y >= text_y0) && (pixel_y < text_y0 + 7);

    always @* begin
        pixel_rgb565 = 16'h0000;
        if (bar_hit) pixel_rgb565 = bar_filled ? 16'h07E0 : 16'h4208;
        if (scope_hit) pixel_rgb565 = 16'hFFE0;
        if (in_text && font_pixel) pixel_rgb565 = 16'hFFFF;
    end
endmodule
