// Compact display initialization sequencer.
// DISPLAY_TYPE: 0 = ST7789, 1 = SSD1306 SPI (page addressing), 2 = SH1106 SPI.
// ROM record format: {valid, dc, end_transaction, delay_ms[7:0], byte[7:0]}.
module shrike_gfx_init #(
    parameter integer CLK_HZ = 50000000,
    parameter integer DISPLAY_TYPE = 0,
    parameter [7:0] ST7789_MADCTL_VAL = 8'h00,
    parameter [7:0] ST7789_COLMOD_VAL = 8'h55
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       reset_done,
    output wire       tx_valid,
    input  wire       tx_ready,
    output wire [7:0] tx_data,
    output wire       tx_dc,
    output wire       tx_last,
    input  wire       tx_done,
    output reg        init_done
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

    localparam integer MAX_DELAY_MS = (DISPLAY_TYPE == 0) ? 150 : 100;
    localparam integer MAX_DELAY_CYCLES = (CLK_HZ / 1000) * MAX_DELAY_MS;
    localparam integer DELAY_W = clog2(MAX_DELAY_CYCLES + 1);

    localparam [1:0] S_WAIT_RESET = 2'd0;
    localparam [1:0] S_SEND = 2'd1;
    localparam [1:0] S_WAIT_TX = 2'd2;
    localparam [1:0] S_DELAY = 2'd3;

    reg [1:0] state;
    reg [5:0] index;
    reg [DELAY_W-1:0] delay_count;
    wire [18:0] word;

    function [18:0] make_word;
        input valid;
        input dc;
        input last;
        input [7:0] delay_ms;
        input [7:0] data;
        begin make_word = {valid, dc, last, delay_ms, data}; end
    endfunction

    function [18:0] init_word;
        input [5:0] idx;
        begin
            init_word = 19'd0;
            if (DISPLAY_TYPE == 0) begin
                case (idx)
                    0: init_word = make_word(1,0,1,150,8'h01); // SWRESET
                    1: init_word = make_word(1,0,1,120,8'h11); // SLPOUT
                    2: init_word = make_word(1,0,0,0,8'h36);  // MADCTL
                    3: init_word = make_word(1,1,1,0,ST7789_MADCTL_VAL);
                    4: init_word = make_word(1,0,0,0,8'h3A);  // COLMOD
                    5: init_word = make_word(1,1,1,0,ST7789_COLMOD_VAL);
                    6: init_word = make_word(1,0,1,0,8'h21);  // INVON
                    7: init_word = make_word(1,0,1,10,8'h13); // NORON
                    8: init_word = make_word(1,0,1,100,8'h29);// DISPON
                    default: init_word = 19'd0;
                endcase
            end else if (DISPLAY_TYPE == 1) begin
                case (idx)
                    0:  init_word = make_word(1,0,1,0,8'hAE);
                    1:  init_word = make_word(1,0,0,0,8'hD5);
                    2:  init_word = make_word(1,1,1,0,8'h80);
                    3:  init_word = make_word(1,0,0,0,8'hA8);
                    4:  init_word = make_word(1,1,1,0,8'h3F);
                    5:  init_word = make_word(1,0,0,0,8'hD3);
                    6:  init_word = make_word(1,1,1,0,8'h00);
                    7:  init_word = make_word(1,0,1,0,8'h40);
                    8:  init_word = make_word(1,0,0,0,8'h8D);
                    9:  init_word = make_word(1,1,1,0,8'h14);
                    10: init_word = make_word(1,0,0,0,8'h20);
                    11: init_word = make_word(1,1,1,0,8'h02); // page mode
                    12: init_word = make_word(1,0,1,0,8'hA1);
                    13: init_word = make_word(1,0,1,0,8'hC8);
                    14: init_word = make_word(1,0,0,0,8'hDA);
                    15: init_word = make_word(1,1,1,0,8'h12);
                    16: init_word = make_word(1,0,0,0,8'h81);
                    17: init_word = make_word(1,1,1,0,8'h7F);
                    18: init_word = make_word(1,0,0,0,8'hD9);
                    19: init_word = make_word(1,1,1,0,8'hF1);
                    20: init_word = make_word(1,0,0,0,8'hDB);
                    21: init_word = make_word(1,1,1,0,8'h40);
                    22: init_word = make_word(1,0,1,0,8'hA4);
                    23: init_word = make_word(1,0,1,0,8'hA6);
                    24: init_word = make_word(1,0,1,100,8'hAF);
                    default: init_word = 19'd0;
                endcase
            end else begin
                case (idx)
                    0:  init_word = make_word(1,0,1,0,8'hAE);
                    1:  init_word = make_word(1,0,0,0,8'hD5);
                    2:  init_word = make_word(1,1,1,0,8'h80);
                    3:  init_word = make_word(1,0,0,0,8'hA8);
                    4:  init_word = make_word(1,1,1,0,8'h3F);
                    5:  init_word = make_word(1,0,0,0,8'hD3);
                    6:  init_word = make_word(1,1,1,0,8'h00);
                    7:  init_word = make_word(1,0,1,0,8'h40);
                    8:  init_word = make_word(1,0,0,0,8'hAD);
                    9:  init_word = make_word(1,1,1,0,8'h8B); // internal DC-DC
                    10: init_word = make_word(1,0,1,0,8'hA1);
                    11: init_word = make_word(1,0,1,0,8'hC8);
                    12: init_word = make_word(1,0,0,0,8'hDA);
                    13: init_word = make_word(1,1,1,0,8'h12);
                    14: init_word = make_word(1,0,0,0,8'h81);
                    15: init_word = make_word(1,1,1,0,8'h80);
                    16: init_word = make_word(1,0,0,0,8'hD9);
                    17: init_word = make_word(1,1,1,0,8'h22);
                    18: init_word = make_word(1,0,0,0,8'hDB);
                    19: init_word = make_word(1,1,1,0,8'h35);
                    20: init_word = make_word(1,0,1,0,8'hA4);
                    21: init_word = make_word(1,0,1,0,8'hA6);
                    22: init_word = make_word(1,0,1,100,8'hAF);
                    default: init_word = 19'd0;
                endcase
            end
        end
    endfunction

    assign word = init_word(index);
    assign tx_valid = (state == S_SEND) && reset_done && word[18];
    assign tx_dc = word[17];
    assign tx_last = word[16];
    assign tx_data = word[7:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_WAIT_RESET;
            index <= 6'd0;
            delay_count <= {DELAY_W{1'b0}};
            init_done <= 1'b0;
        end else begin
            case (state)
                S_WAIT_RESET: begin
                    if (reset_done) state <= S_SEND;
                end
                S_SEND: begin
                    if (!word[18]) begin
                        init_done <= 1'b1;
                    end else if (tx_valid && tx_ready) begin
                        state <= S_WAIT_TX;
                    end
                end
                S_WAIT_TX: begin
                    if (tx_done) begin
                        if (word[16] && word[15:8] != 0) begin
                            delay_count <= (CLK_HZ / 1000) * word[15:8];
                            state <= S_DELAY;
                        end else if (word[16]) begin
                            index <= index + 1'b1;
                            state <= S_SEND;
                        end else begin
                            index <= index + 1'b1;
                            state <= S_SEND;
                        end
                    end
                end
                S_DELAY: begin
                    if (delay_count == 0) begin
                        index <= index + 1'b1;
                        state <= S_SEND;
                    end else delay_count <= delay_count - 1'b1;
                end
                default: state <= S_WAIT_RESET;
            endcase
        end
    end
endmodule
