module ref_clk_wiz (
    input  wire clk_in,
    input  wire rst,
    output reg  clk_25mhz,
    output reg  clk_24mhz,
    output wire locked
);

    reg [1:0] div25;
    reg [7:0] phase24;

    assign locked = 1'b1;

    initial begin
        div25 = 2'd0;
        phase24 = 8'd0;
        clk_25mhz = 1'b0;
        clk_24mhz = 1'b0;
    end

    always @(posedge clk_in) begin
        if (rst) begin
            div25      <= 2'd0;
            phase24    <= 8'd0;
            clk_25mhz  <= 1'b0;
            clk_24mhz  <= 1'b0;
        end else begin
            div25 <= div25 + 2'd1;
            if (div25 == 2'd1) begin
                clk_25mhz <= ~clk_25mhz;
                div25 <= 2'd0;
            end

            phase24 <= phase24 + 8'd24;
            if (phase24 >= 8'd50) begin
                phase24 <= phase24 - 8'd50;
                clk_24mhz <= ~clk_24mhz;
            end
        end
    end

endmodule
