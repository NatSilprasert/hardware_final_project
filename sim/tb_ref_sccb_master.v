`timescale 1ns / 1ps

module tb_ref_sccb_master;

    reg        clk;
    reg        rst;
    reg        start;
    reg  [7:0] addr;
    reg  [7:0] data;
    wire       done;
    wire       scl;
    wire       sda;

    pullup (sda);

    ref_sccb_master uut (
        .clk   (clk),
        .rst   (rst),
        .start (start),
        .addr  (addr),
        .data  (data),
        .done  (done),
        .scl   (scl),
        .sda   (sda)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        start = 0;
        addr = 8'h12;
        data = 8'h80;
        #100;
        rst = 0;
        #100;
        start = 1;
        #10;
        start = 0;
        wait (done);
        $display("PASS: ref_sccb_master done");
        $finish;
    end

endmodule
