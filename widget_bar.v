// Rectangular bar primitive. fill_width is supplied pre-scaled by the caller,
// so this widget needs only coordinate comparisons and no divider/multiplier.
module widget_bar #(
    // Defaults to the original 16-bit interface; compact dashboards may
    // narrow the coordinate datapath to their display dimensions.
    parameter integer COORD_BITS = 16
) (
    input  wire [COORD_BITS-1:0] x,
    input  wire [COORD_BITS-1:0] y,
    input  wire [COORD_BITS-1:0] x0,
    input  wire [COORD_BITS-1:0] y0,
    input  wire [COORD_BITS-1:0] width,
    input  wire [COORD_BITS-1:0] height,
    input  wire [COORD_BITS-1:0] fill_width,
    output wire        hit,
    output wire        filled
);
    wire [COORD_BITS-1:0] rel_x = x - x0;
    wire [COORD_BITS-1:0] rel_y = y - y0;
    assign hit = (x >= x0) && (y >= y0) && (rel_x < width) && (rel_y < height);
    assign filled = hit && (rel_x < fill_width);
endmodule
