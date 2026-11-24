// Compact digital logic analyzer trace: one captured bit per horizontal pixel.
// history[0] corresponds to x0; each sample is drawn at high_y or low_y.
// A shift register in a caller can maintain this history without framebuffer RAM.
module widget_scope #(
    parameter integer WIDTH = 128
) (
    input  wire [15:0] x,
    input  wire [15:0] y,
    input  wire [15:0] x0,
    input  wire [15:0] high_y,
    input  wire [15:0] low_y,
    input  wire [WIDTH-1:0] history,
    output reg         hit
);
    reg [15:0] sample_index;
    always @* begin
        sample_index = x - x0;
        hit = 1'b0;
        if ((x >= x0) && (sample_index < WIDTH)) begin
            if (history[sample_index]) hit = (y == high_y);
            else hit = (y == low_y);
        end
    end
endmodule
