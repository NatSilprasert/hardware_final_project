module sccb_master #(
    parameter CLK_DIVIDER  = 5000,   // SCL half-period in clk cycles (50us at 100MHz)
    parameter START_DELAY  = 1000000,// Power-up wait (10ms at 100MHz)
    parameter RESET_DELAY  = 1000000,// Post-reset wait (10ms at 100MHz)
    parameter REG_COUNT    = 172,
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
    localparam ST_START_0      = 4'd2;  // SDA goes LOW while SCL HIGH (start setup)
    localparam ST_START_1      = 4'd3;  // SCL goes LOW (start hold)
    localparam ST_SEND_BIT_LO  = 4'd4;  // SCL LOW, set SDA for data bit
    localparam ST_SEND_BIT_HI  = 4'd5;  // SCL HIGH, slave samples data
    localparam ST_ACK_LO       = 4'd6;  // SCL LOW, release SDA for ACK
    localparam ST_ACK_HI       = 4'd7;  // SCL HIGH, slave drives ACK
    localparam ST_STOP_LO      = 4'd8;  // SCL LOW, drive SDA LOW (stop setup)
    localparam ST_STOP_HI      = 4'd9;  // SCL HIGH, SDA still LOW
    localparam ST_STOP_REL     = 4'd10; // SCL HIGH, release SDA HIGH (stop)
    localparam ST_NEXT_BYTE    = 4'd11;
    localparam ST_RESET_WAIT   = 4'd12;
    localparam ST_DONE         = 4'd13;
    localparam ST_BUS_FREE     = 4'd14; // Bus idle between transactions

    reg [3:0]  state;
    reg [23:0] wait_counter;
    reg [15:0] clk_div_count;
    reg [1:0]  phase_index;
    reg [2:0]  bit_index;
    reg [7:0]  tx_byte;
    reg [15:0] reg_word;
    reg        reg_valid;
    reg        sda_drive_low;
    reg        latched_is_reset;

    wire [15:0] rom_word;
    wire        rom_valid;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    ov7670_registers reg_rom (
        .index(current_index),
        .reg_word(rom_word),
        .valid(rom_valid)
    );

    // Wait CLK_DIVIDER cycles, return 1 when done
    reg clk_div_done;
    always @(*) begin
        clk_div_done = (clk_div_count >= CLK_DIVIDER - 1);
    end

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
                // ---- Power-up delay ----
                ST_POWERUP: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b0;
                    config_done   <= 1'b0;
                    busy          <= 1'b1;
                    if (wait_counter < START_DELAY - 1) begin
                        wait_counter <= wait_counter + 1'b1;
                    end else begin
                        wait_counter <= 24'd0;
                        state        <= ST_FETCH;
                    end
                end

                // ---- Fetch register from ROM ----
                ST_FETCH: begin
                    reg_word         <= rom_word;
                    reg_valid        <= rom_valid;
                    phase_index      <= 2'd0;
                    bit_index        <= 3'd7;
                    latched_is_reset <= (rom_word[15:8] == 8'h12) && (rom_word[7:0] == 8'h80);
                    if (rom_valid)
                        state <= ST_START_0;
                    else
                        state <= ST_DONE;
                end

                // ---- START condition: SDA LOW while SCL HIGH ----
                ST_START_0: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b1;  // SDA goes LOW (start condition)
                    tx_byte       <= SLAVE_ADDR_W;
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_START_1;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- START hold: SCL goes LOW ----
                ST_START_1: begin
                    scl           <= 1'b0;  // SCL LOW after start
                    sda_drive_low <= 1'b1;  // SDA stays LOW
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        // Set up first data bit
                        sda_drive_low <= ~tx_byte[bit_index];
                        state         <= ST_SEND_BIT_LO;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- Data bit: SCL LOW, SDA has data ----
                ST_SEND_BIT_LO: begin
                    scl <= 1'b0;
                    // SDA already set from previous state
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_SEND_BIT_HI;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- Data bit: SCL HIGH, slave samples ----
                ST_SEND_BIT_HI: begin
                    scl <= 1'b1;
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        if (bit_index == 3'd0) begin
                            // All 8 bits sent, go to ACK
                            state <= ST_ACK_LO;
                        end else begin
                            bit_index     <= bit_index - 1'b1;
                            sda_drive_low <= ~tx_byte[bit_index - 1'b1];
                            state         <= ST_SEND_BIT_LO;
                        end
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- ACK: SCL LOW, release SDA ----
                ST_ACK_LO: begin
                    scl           <= 1'b0;
                    sda_drive_low <= 1'b0;  // Release SDA for slave ACK
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_ACK_HI;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- ACK: SCL HIGH, slave holds SDA ----
                ST_ACK_HI: begin
                    scl <= 1'b1;
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        bit_index     <= 3'd7;
                        state         <= ST_NEXT_BYTE;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- Select next byte or stop ----
                ST_NEXT_BYTE: begin
                    scl <= 1'b0;  // SCL LOW between bytes
                    case (phase_index)
                        2'd0: begin
                            tx_byte       <= reg_word[15:8]; // Register address
                            phase_index   <= 2'd1;
                            sda_drive_low <= ~reg_word[15];  // MSB of reg addr
                            state         <= ST_SEND_BIT_LO;
                        end
                        2'd1: begin
                            tx_byte       <= reg_word[7:0];  // Register value
                            phase_index   <= 2'd2;
                            sda_drive_low <= ~reg_word[7];   // MSB of reg value
                            state         <= ST_SEND_BIT_LO;
                        end
                        default: begin
                            // All 3 bytes sent, generate stop
                            sda_drive_low <= 1'b1;  // SDA LOW (setup for stop)
                            state         <= ST_STOP_LO;
                        end
                    endcase
                end

                // ---- STOP: SCL LOW, SDA LOW (setup) ----
                ST_STOP_LO: begin
                    scl           <= 1'b0;
                    sda_drive_low <= 1'b1;  // SDA held LOW
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_STOP_HI;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- STOP: SCL HIGH, SDA still LOW ----
                ST_STOP_HI: begin
                    scl           <= 1'b1;   // SCL goes HIGH
                    sda_drive_low <= 1'b1;   // SDA stays LOW
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_STOP_REL;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- STOP: Release SDA HIGH (actual stop) ----
                ST_STOP_REL: begin
                    scl           <= 1'b1;   // SCL stays HIGH
                    sda_drive_low <= 1'b0;   // SDA goes HIGH → STOP condition
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        state         <= ST_BUS_FREE;
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- Bus free time between transactions ----
                ST_BUS_FREE: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (clk_div_done) begin
                        clk_div_count <= 16'd0;
                        if (latched_is_reset) begin
                            wait_counter <= 24'd0;
                            state        <= ST_RESET_WAIT;
                        end else begin
                            current_index <= current_index + 1'b1;
                            state         <= ST_FETCH;
                        end
                    end else begin
                        clk_div_count <= clk_div_count + 1'b1;
                    end
                end

                // ---- Post-reset delay ----
                ST_RESET_WAIT: begin
                    if (wait_counter < RESET_DELAY - 1) begin
                        wait_counter <= wait_counter + 1'b1;
                    end else begin
                        wait_counter  <= 24'd0;
                        current_index <= current_index + 1'b1;
                        state         <= ST_FETCH;
                    end
                end

                // ---- All registers written ----
                ST_DONE: begin
                    scl           <= 1'b1;
                    sda_drive_low <= 1'b0;
                    config_done   <= 1'b1;
                    busy          <= 1'b0;
                end

                default: state <= ST_POWERUP;
            endcase
        end
    end

endmodule
