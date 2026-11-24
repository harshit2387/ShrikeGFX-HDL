// Byte-oriented SPI mode-0 master for small display controllers.
// A transaction begins with the first accepted byte and CS stays low until
// tx_last is accepted. DC is sampled for each byte, allowing command/data
// changes while CS is low. The source may insert arbitrary gaps between bytes.
module spi_display_master #(
    parameter integer CLK_HZ = 50000000,
    parameter integer SPI_HZ = 2000000,
    parameter integer CS_PIN_PRESENT = 1,
    parameter integer RESET_PIN_PRESENT = 1,
    parameter integer POWER_UP_MS = 10,
    parameter integer RESET_LOW_MS = 10,
    parameter integer RESET_SETTLE_MS = 120
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_valid,
    output wire       tx_ready,
    input  wire [7:0] tx_data,
    input  wire       tx_dc,
    input  wire       tx_last,
    output reg        tx_done,
    output wire       reset_done,
    output wire       spi_sck,
    output reg        spi_mosi,
    output wire       display_cs_n,
    output reg        display_dc,
    output wire       display_rst_n
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

    function integer max_int;
        input integer a;
        input integer b;
        begin max_int = (a > b) ? a : b; end
    endfunction

    localparam integer HALF_DIV = max_int(1, (CLK_HZ + (2 * SPI_HZ) - 1) / (2 * SPI_HZ));
    localparam integer DIV_W = clog2(HALF_DIV + 1);
    localparam integer POWER_CYCLES = max_int(1, (CLK_HZ / 1000) * POWER_UP_MS);
    localparam integer LOW_CYCLES = max_int(1, (CLK_HZ / 1000) * RESET_LOW_MS);
    localparam integer SETTLE_CYCLES = max_int(1, (CLK_HZ / 1000) * RESET_SETTLE_MS);
    localparam integer WAIT_MAX = max_int(POWER_CYCLES, max_int(LOW_CYCLES, SETTLE_CYCLES));
    localparam integer WAIT_W = clog2(WAIT_MAX + 1);

    localparam [1:0] R_POWER = 2'd0;
    localparam [1:0] R_LOW = 2'd1;
    localparam [1:0] R_SETTLE = 2'd2;
    localparam [1:0] R_READY = 2'd3;

    reg [1:0] reset_state;
    reg [WAIT_W-1:0] reset_count;
    reg reset_pin_reg;
    reg reset_done_reg;
    reg [DIV_W-1:0] div_count;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg last_reg;
    reg active;
    reg cs_n_reg;
    reg sck_reg;

    assign reset_done = reset_done_reg;
    assign display_rst_n = RESET_PIN_PRESENT ? reset_pin_reg : 1'b1;
    assign display_cs_n = CS_PIN_PRESENT ? cs_n_reg : 1'b0;
    assign spi_sck = sck_reg;
    assign tx_ready = reset_done_reg && !active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_state <= R_POWER;
            reset_count <= POWER_CYCLES;
            reset_pin_reg <= 1'b0;
            reset_done_reg <= 1'b0;
            div_count <= {DIV_W{1'b0}};
            bit_count <= 3'd0;
            shift_reg <= 8'h00;
            last_reg <= 1'b1;
            active <= 1'b0;
            cs_n_reg <= 1'b1;
            sck_reg <= 1'b0;
            spi_mosi <= 1'b0;
            display_dc <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (reset_state)
                R_POWER: begin
                    if (reset_count == 0) begin
                        reset_pin_reg <= 1'b0;
                        reset_count <= LOW_CYCLES;
                        reset_state <= R_LOW;
                    end else reset_count <= reset_count - 1'b1;
                end
                R_LOW: begin
                    if (reset_count == 0) begin
                        reset_pin_reg <= 1'b1;
                        reset_count <= SETTLE_CYCLES;
                        reset_state <= R_SETTLE;
                    end else reset_count <= reset_count - 1'b1;
                end
                R_SETTLE: begin
                    if (reset_count == 0) begin
                        reset_done_reg <= 1'b1;
                        reset_state <= R_READY;
                    end else reset_count <= reset_count - 1'b1;
                end
                default: begin end
            endcase

            if (tx_ready && tx_valid) begin
                active <= 1'b1;
                if (cs_n_reg) cs_n_reg <= 1'b0;
                display_dc <= tx_dc;
                shift_reg <= tx_data;
                last_reg <= tx_last;
                spi_mosi <= tx_data[7];
                sck_reg <= 1'b0;
                bit_count <= 3'd0;
                div_count <= {DIV_W{1'b0}};
            end else if (active) begin
                if (div_count == HALF_DIV - 1) begin
                    div_count <= {DIV_W{1'b0}};
                    if (!sck_reg) begin
                        sck_reg <= 1'b1;
                    end else begin
                        sck_reg <= 1'b0;
                        if (bit_count == 3'd7) begin
                            active <= 1'b0;
                            tx_done <= 1'b1;
                            if (last_reg) cs_n_reg <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            spi_mosi <= shift_reg[6];
                        end
                    end
                end else div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
