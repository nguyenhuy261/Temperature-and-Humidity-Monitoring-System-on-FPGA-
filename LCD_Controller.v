module LCD_Controller (
    input wire clk,
    input wire reset,
    input wire [7:0] temperature, // Dữ liệu nhiệt độ từ DHT11
    input wire [7:0] humidity,    // Dữ liệu độ ẩm từ DHT11
    output reg lcd_rs, lcd_e,
    output reg [7:0] lcd_db
);

    reg [5:0] state = 0;
    reg [23:0] counter = 0;
    reg [7:0] temp_digit1, temp_digit2;
    reg [7:0] hum_digit1, hum_digit2;

    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter[21]) begin  
            case (state)
                0: begin lcd_rs <= 0; lcd_db <= 8'h38; lcd_e <= 1; state <= 1; end
                1: begin lcd_e <= 0; state <= 2; end
                2: begin lcd_db <= 8'h0C; lcd_e <= 1; state <= 3; end
                3: begin lcd_e <= 0; state <= 4; end
                4: begin lcd_db <= 8'h06; lcd_e <= 1; state <= 5; end
                5: begin lcd_e <= 0; state <= 6; end
                6: begin lcd_db <= 8'h01; lcd_e <= 1; state <= 7; end  
                7: begin lcd_e <= 0; state <= 8; end

                // Đặt con trỏ tại ô số 2 trên dòng 1 (0x82)
                8: begin lcd_db <= 8'h82; lcd_rs <= 0; lcd_e <= 1; state <= 9; end
                9: begin lcd_e <= 0; state <= 10; end

                // Hiển thị "Nhiet Do:"
                10: begin lcd_rs <= 1; lcd_db <= "N"; lcd_e <= 1; state <= 11; end
                11: begin lcd_e <= 0; state <= 12; end
                12: begin lcd_db <= "h"; lcd_e <= 1; state <= 13; end
                13: begin lcd_e <= 0; state <= 14; end
                14: begin lcd_db <= "i"; lcd_e <= 1; state <= 15; end
                15: begin lcd_e <= 0; state <= 16; end
                16: begin lcd_db <= "e"; lcd_e <= 1; state <= 17; end
                17: begin lcd_e <= 0; state <= 18; end
                18: begin lcd_db <= "t"; lcd_e <= 1; state <= 19; end
                19: begin lcd_e <= 0; state <= 20; end
                20: begin lcd_db <= " "; lcd_e <= 1; state <= 21; end
                21: begin lcd_e <= 0; state <= 22; end
                22: begin lcd_db <= "D"; lcd_e <= 1; state <= 23; end
                23: begin lcd_e <= 0; state <= 24; end
                24: begin lcd_db <= "o"; lcd_e <= 1; state <= 25; end
                25: begin lcd_e <= 0; state <= 26; end
                26: begin lcd_db <= ":"; lcd_e <= 1; state <= 27; end
                27: begin lcd_e <= 0; state <= 28; end

                // Hiển thị giá trị nhiệt độ
                28: begin
                    temp_digit1 <= ((temperature / 10) % 10) + 8'h30;  
                    temp_digit2 <= (temperature % 10) + 8'h30;  
                    lcd_db <= temp_digit1; lcd_e <= 1; state <= 29;
                end
                29: begin lcd_e <= 0; state <= 30; end
                30: begin lcd_db <= temp_digit2; lcd_e <= 1; state <= 31; end
                31: begin lcd_e <= 0; state <= 32; end

                // Hiển thị "°C"
                32: begin lcd_db <= 8'hDF; lcd_e <= 1; state <= 33; end // Ký tự '°'
                33: begin lcd_e <= 0; state <= 34; end
                34: begin lcd_db <= "C"; lcd_e <= 1; state <= 35; end
                35: begin lcd_e <= 0; state <= 36; end

                // Đặt con trỏ tại ô số 3 trên dòng 2 (0xC3)
                36: begin lcd_db <= 8'hC3; lcd_rs <= 0; lcd_e <= 1; state <= 37; end
                37: begin lcd_e <= 0; state <= 38; end

                // Hiển thị "Do Am:"
                38: begin lcd_rs <= 1; lcd_db <= "D"; lcd_e <= 1; state <= 39; end
                39: begin lcd_e <= 0; state <= 40; end
                40: begin lcd_db <= "o"; lcd_e <= 1; state <= 41; end
                41: begin lcd_e <= 0; state <= 42; end
                42: begin lcd_db <= " "; lcd_e <= 1; state <= 43; end
                43: begin lcd_e <= 0; state <= 44; end
                44: begin lcd_db <= "A"; lcd_e <= 1; state <= 45; end
                45: begin lcd_e <= 0; state <= 46; end
                46: begin lcd_db <= "m"; lcd_e <= 1; state <= 47; end
                47: begin lcd_e <= 0; state <= 48; end
                48: begin lcd_db <= ":"; lcd_e <= 1; state <= 49; end
                49: begin lcd_e <= 0; state <= 50; end

                // Hiển thị giá trị độ ẩm
                50: begin
                    hum_digit1 <= ((humidity / 10) % 10) + 8'h30;
                    hum_digit2 <= (humidity % 10) + 8'h30;
                    lcd_db <= hum_digit1; lcd_e <= 1; state <= 51;
                end
                51: begin lcd_e <= 0; state <= 52; end
                52: begin lcd_db <= hum_digit2; lcd_e <= 1; state <= 53; end
                53: begin lcd_e <= 0; state <= 54; end

                // Hiển thị "%"
                54: begin lcd_db <= "%"; lcd_e <= 1; state <= 55; end
                55: begin lcd_e <= 0; state <= 56; end

                // Lặp lại hiển thị dữ liệu mới
                56: begin
                    state <= 8;  // Quay lại trạng thái 8 để cập nhật dữ liệu
                end

                default: state <= 0;
            endcase
            counter <= 0;
        end
    end
endmodule
