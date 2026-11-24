// Self-contained ST7789 example top for Shrike-Lite / Shrike-Fi.
// Select this as the project's top module, add all rtl/*.v files plus
// dashboard_shader.v, then assign the output ports to Pmod GPIO in Go Configure.
module shrike_gfx_example_top (
    input  wire clk,
    input  wire rst_n,
    output wire clk_en,
    output wire spi_sck,
    output wire spi_mosi,
    output wire display_cs_n,
    output wire display_dc,
    output wire display_rst_n
);
    localparam [22:0] FRAME_PERIOD = 23'd5000000; // 100 ms at 50 MHz

    reg [22:0] frame_timer;
    reg frame_start;
    reg [6:0] duty_fill_width;
    reg [127:0] trace_history;
    wire start_ready;
    wire [15:0] pixel_x, pixel_y, pixel_rgb565;
    wire pixel_active;
    wire display_busy, frame_done, init_done;

    assign clk_en = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_timer <= 23'd0;
            frame_start <= 1'b0;
            duty_fill_width <= 7'd0;
            trace_history <= 128'd0;
        end else begin
            frame_start <= 1'b0;
            if (frame_timer == FRAME_PERIOD - 1'b1) begin
                frame_timer <= 23'd0;
                if (start_ready) begin
                    frame_start <= 1'b1;
                    if (duty_fill_width == 7'd100) duty_fill_width <= 7'd0;
                    else duty_fill_width <= duty_fill_width + 1'b1;
                    trace_history <= {trace_history[126:0], duty_fill_width[0]};
                end
            end else frame_timer <= frame_timer + 1'b1;
        end
    end

    dashboard_shader #(.COORD_BITS(8)) shader (
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .duty_fill_width({1'b0, duty_fill_width}),
        .trace_history(trace_history),
        .char_code(8'h50), // 'P'
        .text_x0(16'd8), .text_y0(16'd8),
        .pixel_rgb565(pixel_rgb565)
    );

    shrike_gfx_st7789 #(
        .CLK_HZ(50000000),
        .SPI_HZ(12500000),
        .CS_PIN_PRESENT(1),
        .RESET_PIN_PRESENT(1),
        .X_OFFSET(0),
        .Y_OFFSET(0),
        .COORD_BITS(8)
    ) display (
        .clk(clk), .rst_n(rst_n),
        .start(frame_start), .start_ready(start_ready),
        .win_x0(16'd0), .win_y0(16'd0),
        .win_x1(16'd239), .win_y1(16'd239),
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .pixel_active(pixel_active), .pixel_rgb565(pixel_rgb565),
        .busy(display_busy), .done(frame_done), .init_done(init_done),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi),
        .display_cs_n(display_cs_n), .display_dc(display_dc),
        .display_rst_n(display_rst_n)
    );
endmodule
