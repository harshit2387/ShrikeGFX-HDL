// Zero-framebuffer SSD1306/SH1106 page-mode update engine.
// The caller supplies monochrome pixels at pixel_x/pixel_y during pixel_active.
// A page is 8 vertical pixels; each completed column emits one data byte.
module gfx_oled_engine #(
    parameter integer COLUMN_OFFSET = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  win_x0,
    input  wire [7:0]  win_y0,
    input  wire [7:0]  win_x1,
    input  wire [7:0]  win_y1,
    output wire        busy,
    output reg         done,
    output wire [15:0] pixel_x,
    output wire [15:0] pixel_y,
    output wire        pixel_active,
    input  wire        pixel_on,
    output wire        tx_valid,
    input  wire        tx_ready,
    output reg  [7:0]  tx_data,
    output reg         tx_dc,
    output reg         tx_last,
    input  wire        tx_done
);
    localparam [2:0] S_IDLE       = 3'd0;
    localparam [2:0] S_PAGE       = 3'd1;
    localparam [2:0] S_COL_LOW    = 3'd2;
    localparam [2:0] S_COL_HIGH   = 3'd3;
    localparam [2:0] S_SAMPLE     = 3'd4;
    localparam [2:0] S_DATA       = 3'd5;
    localparam [2:0] S_WAIT_FINAL = 3'd6;

    reg [2:0] state;
    reg [7:0] x0_reg, x1_reg, x_reg;
    reg [2:0] page_reg, page_last;
    reg [2:0] bit_index;
    reg [7:0] byte_reg;
    wire last_column;

    assign busy = (state != S_IDLE);
    assign pixel_x = {8'd0, x_reg};
    assign pixel_y = ({13'd0, page_reg, 3'b000}) + bit_index;
    assign pixel_active = (state == S_SAMPLE);
    assign last_column = (x_reg == x1_reg);
    assign tx_valid = (state == S_PAGE) || (state == S_COL_LOW) ||
                      (state == S_COL_HIGH) || (state == S_DATA);

    always @* begin
        tx_data = 8'h00;
        tx_dc = 1'b0;
        tx_last = 1'b0;
        case (state)
            S_PAGE:     tx_data = 8'hB0 | page_reg;
            S_COL_LOW:  tx_data = 8'h00 | ((x0_reg + COLUMN_OFFSET) & 8'h0F);
            S_COL_HIGH: begin
                tx_data = 8'h10 | (((x0_reg + COLUMN_OFFSET) >> 4) & 8'h0F);
                tx_last = 1'b1;
            end
            S_DATA: begin
                tx_data = byte_reg;
                tx_dc = 1'b1;
                tx_last = last_column;
            end
            default: begin end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            x0_reg <= 8'd0; x1_reg <= 8'd0; x_reg <= 8'd0;
            page_reg <= 3'd0; page_last <= 3'd0;
            bit_index <= 3'd0;
            byte_reg <= 8'd0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (state == S_IDLE) begin
                if (start) begin
                    if ((win_x1 >= win_x0) && (win_y1 >= win_y0) &&
                        (win_x1 < 128) && (win_y1 < 64)) begin
                        x0_reg <= win_x0;
                        x1_reg <= win_x1;
                        x_reg <= win_x0;
                        page_reg <= win_y0[5:3];
                        page_last <= win_y1[5:3];
                        bit_index <= 3'd0;
                        byte_reg <= 8'd0;
                        state <= S_PAGE;
                    end else done <= 1'b1;
                end
            end else begin
                case (state)
                    S_PAGE: if (tx_valid && tx_ready) state <= S_COL_LOW;
                    S_COL_LOW: if (tx_valid && tx_ready) state <= S_COL_HIGH;
                    S_COL_HIGH: if (tx_valid && tx_ready) begin
                        bit_index <= 3'd0;
                        byte_reg <= 8'd0;
                        state <= S_SAMPLE;
                    end
                    S_SAMPLE: begin
                        byte_reg[bit_index] <= pixel_on;
                        if (bit_index == 3'd7) state <= S_DATA;
                        else bit_index <= bit_index + 1'b1;
                    end
                    S_DATA: if (tx_valid && tx_ready) begin
                        if (last_column) begin
                            if (page_reg == page_last) state <= S_WAIT_FINAL;
                            else begin
                                page_reg <= page_reg + 1'b1;
                                x_reg <= x0_reg;
                                state <= S_PAGE;
                            end
                        end else begin
                            x_reg <= x_reg + 1'b1;
                            bit_index <= 3'd0;
                            byte_reg <= 8'd0;
                            state <= S_SAMPLE;
                        end
                    end
                    S_WAIT_FINAL: if (tx_done) begin
                        state <= S_IDLE;
                        done <= 1'b1;
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end
endmodule
