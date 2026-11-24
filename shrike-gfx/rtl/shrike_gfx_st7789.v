// Ready-to-integrate ST7789 display controller + init + window streamer.
// Supply pixel_rgb565 combinationally from a coordinate shader.
module shrike_gfx_st7789 #(
    parameter integer CLK_HZ = 50000000,
    parameter integer SPI_HZ = 12500000,
    parameter integer CS_PIN_PRESENT = 1,
    parameter integer RESET_PIN_PRESENT = 1,
    parameter integer X_OFFSET = 0,
    parameter integer Y_OFFSET = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output wire        start_ready,
    input  wire [15:0] win_x0,
    input  wire [15:0] win_y0,
    input  wire [15:0] win_x1,
    input  wire [15:0] win_y1,
    output wire [15:0] pixel_x,
    output wire [15:0] pixel_y,
    output wire        pixel_active,
    input  wire [15:0] pixel_rgb565,
    output wire        busy,
    output wire        done,
    output wire        init_done,
    output wire        spi_sck,
    output wire        spi_mosi,
    output wire        display_cs_n,
    output wire        display_dc,
    output wire        display_rst_n
);
    wire reset_done;
    wire master_ready;
    wire master_done;
    wire [7:0] init_data, gfx_data;
    wire init_dc, init_last, init_valid, init_tx_done;
    wire gfx_dc, gfx_last, gfx_valid, gfx_tx_done, gfx_busy, gfx_done;
    wire [7:0] selected_data;
    wire selected_dc, selected_last, selected_valid;
    wire init_ready, gfx_ready;

    assign selected_valid = init_done ? gfx_valid : init_valid;
    assign selected_data  = init_done ? gfx_data : init_data;
    assign selected_dc    = init_done ? gfx_dc : init_dc;
    assign selected_last  = init_done ? gfx_last : init_last;
    assign init_ready = !init_done && master_ready;
    assign gfx_ready = init_done && master_ready;
    assign init_tx_done = master_done;
    assign gfx_tx_done = master_done;
    assign busy = !init_done || gfx_busy;
    assign done = gfx_done;
    assign start_ready = init_done && !gfx_busy;

    spi_display_master #(
        .CLK_HZ(CLK_HZ), .SPI_HZ(SPI_HZ),
        .CS_PIN_PRESENT(CS_PIN_PRESENT),
        .RESET_PIN_PRESENT(RESET_PIN_PRESENT),
        .POWER_UP_MS(10), .RESET_LOW_MS(10), .RESET_SETTLE_MS(120)
    ) transport (
        .clk(clk), .rst_n(rst_n),
        .tx_valid(selected_valid), .tx_ready(master_ready),
        .tx_data(selected_data), .tx_dc(selected_dc), .tx_last(selected_last),
        .tx_done(master_done), .reset_done(reset_done),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi),
        .display_cs_n(display_cs_n), .display_dc(display_dc),
        .display_rst_n(display_rst_n)
    );

    shrike_gfx_init #(.CLK_HZ(CLK_HZ), .DISPLAY_TYPE(0)) init_seq (
        .clk(clk), .rst_n(rst_n), .reset_done(reset_done),
        .tx_valid(init_valid), .tx_ready(init_ready),
        .tx_data(init_data), .tx_dc(init_dc), .tx_last(init_last),
        .tx_done(init_tx_done), .init_done(init_done)
    );

    gfx_st7789_stream #(.X_OFFSET(X_OFFSET), .Y_OFFSET(Y_OFFSET)) stream (
        .clk(clk), .rst_n(rst_n), .start(start && start_ready),
        .win_x0(win_x0), .win_y0(win_y0), .win_x1(win_x1), .win_y1(win_y1),
        .busy(gfx_busy), .done(gfx_done),
        .pixel_x(pixel_x), .pixel_y(pixel_y), .pixel_active(pixel_active),
        .pixel_rgb565(pixel_rgb565),
        .tx_valid(gfx_valid), .tx_ready(gfx_ready),
        .tx_data(gfx_data), .tx_dc(gfx_dc), .tx_last(gfx_last),
        .tx_done(gfx_tx_done)
    );
endmodule
