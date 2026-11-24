// Small combinational 5x7 font ROM. Supports 0-9, A-F, P/W/M/V/I/H/Z/O/L/T/R,
// space, dash, period, colon and percent. Use glyph_x=0..4, glyph_y=0..6;
// advance text cells by 6 pixels to leave a one-pixel gap.
module widget_text_rom (
    input  wire [7:0] char_code,
    input  wire [2:0] glyph_x,
    input  wire [2:0] glyph_y,
    output wire       pixel_on
);
    function [4:0] font_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            font_row = 5'b00000;
            case (ch)
                "0": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b10011;
                    3:font_row=5'b10101; 4:font_row=5'b11001; 5:font_row=5'b10001;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "1": case (row)
                    0:font_row=5'b00100; 1:font_row=5'b01100; 2:font_row=5'b00100;
                    3:font_row=5'b00100; 4:font_row=5'b00100; 5:font_row=5'b00100;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "2": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b00001;
                    3:font_row=5'b00010; 4:font_row=5'b00100; 5:font_row=5'b01000;
                    6:font_row=5'b11111; default:font_row=0; endcase
                "3": case (row)
                    0:font_row=5'b11110; 1:font_row=5'b00001; 2:font_row=5'b00001;
                    3:font_row=5'b01110; 4:font_row=5'b00001; 5:font_row=5'b00001;
                    6:font_row=5'b11110; default:font_row=0; endcase
                "4": case (row)
                    0:font_row=5'b00010; 1:font_row=5'b00110; 2:font_row=5'b01010;
                    3:font_row=5'b10010; 4:font_row=5'b11111; 5:font_row=5'b00010;
                    6:font_row=5'b00010; default:font_row=0; endcase
                "5": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b11110; 4:font_row=5'b00001; 5:font_row=5'b00001;
                    6:font_row=5'b11110; default:font_row=0; endcase
                "6": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b11110; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "7": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b00001; 2:font_row=5'b00010;
                    3:font_row=5'b00100; 4:font_row=5'b01000; 5:font_row=5'b01000;
                    6:font_row=5'b01000; default:font_row=0; endcase
                "8": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b01110; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "9": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b01111; 4:font_row=5'b00001; 5:font_row=5'b00001;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "A": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b11111; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b10001; default:font_row=0; endcase
                "B": case (row)
                    0:font_row=5'b11110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b11110; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b11110; default:font_row=0; endcase
                "C": case (row)
                    0:font_row=5'b01111; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b10000; 4:font_row=5'b10000; 5:font_row=5'b10000;
                    6:font_row=5'b01111; default:font_row=0; endcase
                "D": case (row)
                    0:font_row=5'b11110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b10001; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b11110; default:font_row=0; endcase
                "E": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b11110; 4:font_row=5'b10000; 5:font_row=5'b10000;
                    6:font_row=5'b11111; default:font_row=0; endcase
                "F": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b11110; 4:font_row=5'b10000; 5:font_row=5'b10000;
                    6:font_row=5'b10000; default:font_row=0; endcase
                "P": case (row)
                    0:font_row=5'b11110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b11110; 4:font_row=5'b10000; 5:font_row=5'b10000;
                    6:font_row=5'b10000; default:font_row=0; endcase
                "W": case (row)
                    0:font_row=5'b10001; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b10101; 4:font_row=5'b10101; 5:font_row=5'b10101;
                    6:font_row=5'b01010; default:font_row=0; endcase
                "M": case (row)
                    0:font_row=5'b10001; 1:font_row=5'b11011; 2:font_row=5'b10101;
                    3:font_row=5'b10101; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b10001; default:font_row=0; endcase
                "V": case (row)
                    0:font_row=5'b10001; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b10001; 4:font_row=5'b10001; 5:font_row=5'b01010;
                    6:font_row=5'b00100; default:font_row=0; endcase
                "I": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b00100; 2:font_row=5'b00100;
                    3:font_row=5'b00100; 4:font_row=5'b00100; 5:font_row=5'b00100;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "H": case (row)
                    0:font_row=5'b10001; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b11111; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b10001; default:font_row=0; endcase
                "Z": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b00001; 2:font_row=5'b00010;
                    3:font_row=5'b00100; 4:font_row=5'b01000; 5:font_row=5'b10000;
                    6:font_row=5'b11111; default:font_row=0; endcase
                "O": case (row)
                    0:font_row=5'b01110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b10001; 4:font_row=5'b10001; 5:font_row=5'b10001;
                    6:font_row=5'b01110; default:font_row=0; endcase
                "L": case (row)
                    0:font_row=5'b10000; 1:font_row=5'b10000; 2:font_row=5'b10000;
                    3:font_row=5'b10000; 4:font_row=5'b10000; 5:font_row=5'b10000;
                    6:font_row=5'b11111; default:font_row=0; endcase
                "T": case (row)
                    0:font_row=5'b11111; 1:font_row=5'b00100; 2:font_row=5'b00100;
                    3:font_row=5'b00100; 4:font_row=5'b00100; 5:font_row=5'b00100;
                    6:font_row=5'b00100; default:font_row=0; endcase
                "R": case (row)
                    0:font_row=5'b11110; 1:font_row=5'b10001; 2:font_row=5'b10001;
                    3:font_row=5'b11110; 4:font_row=5'b10100; 5:font_row=5'b10010;
                    6:font_row=5'b10001; default:font_row=0; endcase
                "-": case (row)
                    3:font_row=5'b11111; default:font_row=0; endcase
                ".": case (row)
                    6:font_row=5'b00100; default:font_row=0; endcase
                ":": case (row)
                    2:font_row=5'b00100; 5:font_row=5'b00100; default:font_row=0; endcase
                "%": case (row)
                    0:font_row=5'b11001; 1:font_row=5'b11010; 2:font_row=5'b00100;
                    3:font_row=5'b01000; 4:font_row=5'b10110; 5:font_row=5'b00110;
                    6:font_row=5'b00000; default:font_row=0; endcase
                default: font_row = 5'b00000;
            endcase
        end
    endfunction

    wire [4:0] row_bits = font_row(char_code, glyph_y);
    assign pixel_on = (glyph_x < 5) && row_bits[4-glyph_x];
endmodule
