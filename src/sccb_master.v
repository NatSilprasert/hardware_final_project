module sccb_master #(
    parameter CLK_DIVIDER  = 5000,
    parameter START_DELAY  = 1000000,
    parameter RESET_DELAY  = 1000000,
    parameter REG_COUNT    = 166,
    parameter SLAVE_ADDR_W = 8'h42
) (
    input  wire       clk,
    input  wire       rst,
    output reg        scl,
    inout  wire       sda,
    output reg        config_done,
    output reg        busy,
    output reg [7:0]  current_index
);

    localparam ST_POWERUP      = 4'd0;
    localparam ST_FETCH        = 4'd1;
    localparam ST_START        = 4'd2;
    localparam ST_SEND_BYTE    = 4'd3;
    localparam ST_RELEASE_ACK  = 4'd4;
    localparam ST_STOP_0       = 4'd5;
    localparam ST_STOP_1       = 4'd6;
    localparam ST_NEXT_BYTE    = 4'd7;
    localparam ST_RESET_WAIT   = 4'd8;
    localparam ST_DONE         = 4'd9;

    reg [3:0] state;
    reg [23:0] wait_counter;
    reg [15:0] clk_div_count;
    reg [1:0] phase_index;
    reg [2:0] bit_index;
    reg [7:0] tx_byte;
    reg [15:0] reg_word;
    reg        reg_valid;
    reg        sda_drive_low;
    reg        latched_is_reset;

    wire [15:0] rom_word;
    wire        rom_valid;

    // SDA ใช้แบบ open-drain:
    // ต้องดึงลงเมื่อส่ง 0 และปล่อยเป็น Z เมื่อต้องการ 1
    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    ov7670_registers reg_rom (
        .index(current_index),
        .reg_word(rom_word),
        .valid(rom_valid)
    );

    always @(posedge clk) begin
        if (rst) begin
            state           <= ST_POWERUP;
            wait_counter    <= 24'd0;
            clk_div_count   <= 16'd0;
            phase_index     <= 2'd0;
            bit_index       <= 3'd7;
            tx_byte         <= 8'h00;
            reg_word        <= 16'h0000;
            reg_valid       <= 1'b0;
            scl             <= 1'b1;
            sda_drive_low   <= 1'b0;
            config_done     <= 1'b0;
            busy            <= 1'b1;
            current_index   <= 8'd0;
            latched_is_reset <= 1'b0;
        end else begin
            case (state)
                ST_POWERUP: begin
                    // รอให้กล้องนิ่งก่อนเริ่มคุย SCCB
                    scl         <= 1'b1;
                    sda_drive_low <= 1'b0;
                    config_done <= 1'b0;
                    busy        <= 1'b1;
                    if (wait_counter < START_DELAY - 1) begin
                        wait_counter <= wait_counter + 1'b1;
                    end else begin
                        wait_counter <= 24'd0;
                        state        <= ST_FETCH;
                    end
                end

                ST_FETCH: begin
                    // ดึงคู่ {address, value} จาก ROM มาเตรียมส่ง
                    reg_word         <= rom_word;
                    reg_valid        <= rom_valid;
                    phase_index      <= 2'd0;
                    bit_index        <= 3'd7;
                    latched_is_reset <= (rom_word[15:8] == 8'h12) && (rom_word[7:0] == 8'h80);
                    if (rom_valid) begin
                        state <= ST_START;
                    end else begin
                        state <= ST_DONE;
                    end
                end

                ST_START: begin
                    // start condition: ลด SDA ขณะ SCL ยังเป็น 1
                    scl     <= 1'b1;
                    sda_drive_low <= 1'b1;
                    tx_byte <= SLAVE_ADDR_W;
                    state   <= ST_SEND_BYTE;
                    clk_div_count <= 16'd0;
                end

                ST_SEND_BYTE: begin
                    // ส่งข้อมูลทีละ 8 บิต โดยเปลี่ยน SDA ตอน SCL=0
                    if (clk_div_count < CLK_DIVIDER - 1) begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end else begin
                        clk_div_count <= 16'd0;
                        scl <= ~scl;

                        if (scl == 1'b1) begin
                            // เปลี่ยนข้อมูลตอน SCL กำลังลงต่ำ
                            sda_drive_low <= ~tx_byte[bit_index];
                        end else begin
                            if (bit_index == 3'd0) begin
                                state <= ST_RELEASE_ACK;
                            end else begin
                                bit_index <= bit_index - 1'b1;
                            end
                        end
                    end
                end

                ST_RELEASE_ACK: begin
                    // SCCB ตัวนี้ยังไม่เช็ก ACK จริง แต่ต้องปล่อย SDA
                    // เพื่อไม่ให้ชนกับ slave ในบิตที่ 9
                    if (clk_div_count < CLK_DIVIDER - 1) begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end else begin
                        clk_div_count <= 16'd0;
                        scl <= ~scl;

                        if (scl == 1'b1) begin
                            sda_drive_low <= 1'b0;
                        end else begin
                            bit_index <= 3'd7;
                            state    <= ST_NEXT_BYTE;
                        end
                    end
                end

                ST_NEXT_BYTE: begin
                    case (phase_index)
                        2'd0: begin
                            tx_byte     <= reg_word[15:8];
                            phase_index <= 2'd1;
                            state       <= ST_SEND_BYTE;
                        end
                        2'd1: begin
                            tx_byte     <= reg_word[7:0];
                            phase_index <= 2'd2;
                            state       <= ST_SEND_BYTE;
                        end
                        default: begin
                            state <= ST_STOP_0;
                        end
                    endcase
                end

                ST_STOP_0: begin
                    // stop condition ช่วงแรก: ดึง SCL กลับเป็น 1 ขณะ SDA ยังเป็น 0
                    scl     <= 1'b1;
                    sda_drive_low <= 1'b1;
                    state   <= ST_STOP_1;
                end

                ST_STOP_1: begin
                    // stop condition ช่วงสอง: ปล่อย SDA กลับเป็น 1
                    scl     <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (latched_is_reset) begin
                        wait_counter <= 24'd0;
                        state        <= ST_RESET_WAIT;
                    end else begin
                        current_index <= current_index + 1'b1;
                        state         <= ST_FETCH;
                    end
                end

                ST_RESET_WAIT: begin
                    // หลัง reset register ต้องรอกล้องเคลียร์ค่าภายในก่อน
                    if (wait_counter < RESET_DELAY - 1) begin
                        wait_counter <= wait_counter + 1'b1;
                    end else begin
                        wait_counter  <= 24'd0;
                        current_index <= current_index + 1'b1;
                        state         <= ST_FETCH;
                    end
                end

                ST_DONE: begin
                    scl         <= 1'b1;
                    sda_drive_low <= 1'b0;
                    config_done <= 1'b1;
                    busy        <= 1'b0;
                end

                default: begin
                    state <= ST_POWERUP;
                end
            endcase
        end
    end

endmodule
