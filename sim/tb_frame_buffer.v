`timescale 1ns/1ps

module tb_frame_buffer;
    reg         wr_clk;
    reg         wr_en;
    reg [16:0]  wr_addr;
    reg [11:0]  wr_data;
    reg         rd_clk;
    reg [16:0]  rd_addr;
    wire [11:0] rd_data;

    frame_buffer #(
        .DEPTH(16)
    ) dut (
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    always #5  wr_clk = ~wr_clk;
    always #7  rd_clk = ~rd_clk;

    initial begin
        wr_clk  = 1'b0;
        wr_en   = 1'b0;
        wr_addr = 17'd0;
        wr_data = 12'd0;
        rd_clk  = 1'b0;
        rd_addr = 17'd0;

        // เขียนข้อมูล 3 จุดจากฝั่งกล้อง
        @(posedge wr_clk);
        wr_en   = 1'b1;
        wr_addr = 17'd0;
        wr_data = 12'h123;

        @(posedge wr_clk);
        wr_addr = 17'd1;
        wr_data = 12'hABC;

        @(posedge wr_clk);
        wr_addr = 17'd5;
        wr_data = 12'hF0F;

        @(posedge wr_clk);
        wr_en = 1'b0;

        // อ่านกลับจาก clock อีกฝั่ง
        rd_addr = 17'd0;
        @(posedge rd_clk);
        @(negedge rd_clk);
        if (rd_data != 12'h123) begin
            $display("ERROR: read addr 0 mismatch data=%03h", rd_data);
            $finish;
        end

        rd_addr = 17'd1;
        @(posedge rd_clk);
        @(negedge rd_clk);
        if (rd_data != 12'hABC) begin
            $display("ERROR: read addr 1 mismatch data=%03h", rd_data);
            $finish;
        end

        rd_addr = 17'd5;
        @(posedge rd_clk);
        @(negedge rd_clk);
        if (rd_data != 12'hF0F) begin
            $display("ERROR: read addr 5 mismatch data=%03h", rd_data);
            $finish;
        end

        // ลองอ่านเกินขอบเขต ต้องได้ศูนย์
        rd_addr = 17'd20;
        @(posedge rd_clk);
        @(negedge rd_clk);
        if (rd_data != 12'h000) begin
            $display("ERROR: out-of-range read mismatch data=%03h", rd_data);
            $finish;
        end

        $display("PASS: tb_frame_buffer");
        $finish;
    end

endmodule
