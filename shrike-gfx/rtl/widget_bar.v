// Rectangular bar primitive. fill_width is supplied pre-scaled by the caller,
// so this widget needs only coordinate comparisons and no divider/multiplier.
module widget_bar (
    input  wire [15:0] x,
    input  wire [15:0] y,
    input  wire [15:0] x0,
    input  wire [15:0] y0,
    input  wire [15:0] width,
    input  wire [15:0] height,
    input  wire [15:0] fill_width,
    output wire        hit,
    output wire        filled
);
    wire [15:0] rel_x = x - x0;
    wire [15:0] rel_y = y - y0;
    assign hit = (x >= x0) && (y >= y0) && (rel_x < width) && (rel_y < height);
    assign filled = hit && (rel_x < fill_width);
endmodule
