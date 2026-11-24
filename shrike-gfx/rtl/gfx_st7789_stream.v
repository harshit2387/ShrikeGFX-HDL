// Zero-framebuffer ST7789 window writer. The caller supplies one RGB565 color
// combinationally for the current (pixel_x,pixel_y); that color is serialized
// high byte then low byte. Coordinates are logical display coordinates.
module gfx_st7789_stream #(
    parameter integer X_OFFSET = 0,
    parameter integer Y_OFFSET = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [15:0] win_x0,
    input  wire [15:0] win_y0,
    input  wire [15:0] win_x1,
    input  wire [15:0] win_y1,
    output wire        busy,
    output reg         done,
    output wire [15:0] pixel_x,
    output wire [15:0] pixel_y,
    output wire        pixel_active,
    input  wire [15:0] pixel_rgb565,
    output wire        tx_valid,
    input  wire        tx_ready,
    output reg  [7:0]  tx_data,
    output reg         tx_dc,
    output reg         tx_last,
    input  wire        tx_done
);
    localparam [3:0] S_IDLE       = 4'd0;
    localparam [3:0] S_CASET      = 4'd1;
    localparam [3:0] S_X0_HI      = 4'd2;
    localparam [3:0] S_X0_LO      = 4'd3;
    localparam [3:0] S_X1_HI      = 4'd4;
    localparam [3:0] S_X1_LO      = 4'd5;
    localparam [3:0] S_RASET      = 4'd6;
    localparam [3:0] S_Y0_HI      = 4'd7;
    localparam [3:0] S_Y0_LO      = 4'd8;
    localparam [3:0] S_Y1_HI      = 4'd9;
    localparam [3:0] S_Y1_LO      = 4'd10;
    localparam [3:0] S_RAMWR      = 4'd11;
    localparam [3:0] S_PIXEL_HI   = 4'd12;
    localparam [3:0] S_PIXEL_LO   = 4'd13;
    localparam [3:0] S_WAIT_FINAL = 4'd14;

    reg [3:0] state;
    reg [15:0] x0_reg, y0_reg, x1_reg, y1_reg;
    reg [15:0] x_reg, y_reg;
    reg [15:0] x0_addr, y0_addr, x1_addr, y1_addr;
    wire last_pixel;

    assign busy = (state != S_IDLE);
    assign pixel_x = x_reg;
    assign pixel_y = y_reg;
    assign pixel_active = (state == S_PIXEL_HI) || (state == S_PIXEL_LO);
    assign last_pixel = (x_reg == x1_reg) && (y_reg == y1_reg);
    assign tx_valid = (state >= S_CASET) && (state <= S_PIXEL_LO);

    always @* begin
        tx_data = 8'h00;
        tx_dc = 1'b0;
        tx_last = 1'b0;
        case (state)
            S_CASET:  begin tx_data = 8'h2A; tx_last = 1'b0; end
            S_X0_HI:  tx_data = x0_addr[15:8];
            S_X0_LO:  tx_data = x0_addr[7:0];
            S_X1_HI:  tx_data = x1_addr[15:8];
            S_X1_LO:  begin tx_data = x1_addr[7:0]; tx_last = 1'b1; end
            S_RASET:  begin tx_data = 8'h2B; tx_last = 1'b0; end
            S_Y0_HI:  tx_data = y0_addr[15:8];
            S_Y0_LO:  tx_data = y0_addr[7:0];
            S_Y1_HI:  tx_data = y1_addr[15:8];
            S_Y1_LO:  begin tx_data = y1_addr[7:0]; tx_last = 1'b1; end
            S_RAMWR:  begin tx_data = 8'h2C; tx_last = 1'b0; end
            S_PIXEL_HI: begin tx_data = pixel_rgb565[15:8]; tx_dc = 1'b1; end
            S_PIXEL_LO: begin
                tx_data = pixel_rgb565[7:0];
                tx_dc = 1'b1;
                tx_last = last_pixel;
            end
            default: begin end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            x0_reg <= 16'd0; y0_reg <= 16'd0;
            x1_reg <= 16'd0; y1_reg <= 16'd0;
            x_reg <= 16'd0; y_reg <= 16'd0;
            x0_addr <= 16'd0; y0_addr <= 16'd0;
            x1_addr <= 16'd0; y1_addr <= 16'd0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (state == S_IDLE) begin
                if (start) begin
                    if ((win_x1 >= win_x0) && (win_y1 >= win_y0)) begin
                        x0_reg <= win_x0; y0_reg <= win_y0;
                        x1_reg <= win_x1; y1_reg <= win_y1;
                        x_reg <= win_x0; y_reg <= win_y0;
                        x0_addr <= win_x0 + X_OFFSET;
                        y0_addr <= win_y0 + Y_OFFSET;
                        x1_addr <= win_x1 + X_OFFSET;
                        y1_addr <= win_y1 + Y_OFFSET;
                        state <= S_CASET;
                    end else done <= 1'b1;
                end
            end else if (tx_valid && tx_ready) begin
                case (state)
                    S_CASET:  state <= S_X0_HI;
                    S_X0_HI:  state <= S_X0_LO;
                    S_X0_LO:  state <= S_X1_HI;
                    S_X1_HI:  state <= S_X1_LO;
                    S_X1_LO:  state <= S_RASET;
                    S_RASET:  state <= S_Y0_HI;
                    S_Y0_HI:  state <= S_Y0_LO;
                    S_Y0_LO:  state <= S_Y1_HI;
                    S_Y1_HI:  state <= S_Y1_LO;
                    S_Y1_LO:  state <= S_RAMWR;
                    S_RAMWR:  state <= S_PIXEL_HI;
                    S_PIXEL_HI: state <= S_PIXEL_LO;
                    S_PIXEL_LO: begin
                        if (last_pixel) state <= S_WAIT_FINAL;
                        else begin
                            state <= S_PIXEL_HI;
                            if (x_reg == x1_reg) begin
                                x_reg <= x0_reg;
                                y_reg <= y_reg + 1'b1;
                            end else x_reg <= x_reg + 1'b1;
                        end
                    end
                    default: state <= S_IDLE;
                endcase
            end

            if ((state == S_WAIT_FINAL) && tx_done) begin
                state <= S_IDLE;
                done <= 1'b1;
            end
        end
    end
endmodule
