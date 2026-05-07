`timescale 1ns/1ps

module tb_sccb_master;
    reg clk;
    reg rst;
    wire scl;
    wire sda;
    wire config_done;
    wire busy;
    wire [7:0] current_index;

    reg sda_slave_drive;
    reg sda_slave_value;

    // จำลอง open-drain แบบง่าย: ตอน master ปล่อยเส้น ให้ slave ดึงลงได้
    assign sda = sda_slave_drive ? sda_slave_value : 1'bz;

    sccb_master #(
        .CLK_DIVIDER(2),
        .START_DELAY(4),
        .RESET_DELAY(4),
        .REG_COUNT(166)
    ) dut (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda(sda),
        .config_done(config_done),
        .busy(busy),
        .current_index(current_index)
    );

    always #5 clk = ~clk;

    initial begin
        clk             = 1'b0;
        rst             = 1'b1;
        sda_slave_drive = 1'b0;
        sda_slave_value = 1'b1;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        // testbench นี้เช็กว่าระบบวิ่งจน config_done ได้
        repeat (75000) @(posedge clk) begin
            if (config_done) begin
                $display("PASS: tb_sccb_master index=%0d busy=%0b", current_index, busy);
                $finish;
            end
        end

        $display("ERROR: sccb_master did not finish configuration");
        $finish;
    end

endmodule
