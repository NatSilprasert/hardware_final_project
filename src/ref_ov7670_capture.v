module ref_ov7670_capture (
    input  wire        pclk,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,
    output wire [16:0] addr,
    output wire [11:0] dout,
    output reg         we
);

    reg [15:0] d_latch;
    reg [11:0] dout_reg;
    reg [1:0]  wr_hold;
    reg [9:0]  x;
    reg [9:0]  y;

    assign addr = y * 320 + x;
    assign dout = dout_reg;

    always @(posedge pclk) begin
        if (vsync) begin
            x       <= 0;
            y       <= 0;
            wr_hold <= 0;
            we      <= 0;
        end else begin
            d_latch <= {d_latch[7:0], d};
            wr_hold <= {wr_hold[0], (href && !wr_hold[0])};
            we <= wr_hold[1];
            if (wr_hold[1]) begin
                dout_reg <= {
                    d_latch[15:12],
                    d_latch[10:7],
                    d_latch[4:1]
                };
                if (x < 319) begin
                    x <= x + 1;
                end else begin
                    x <= 0;
                    if (y < 239)
                        y <= y + 1;
                    else
                        y <= 0;
                end
            end
        end
    end

endmodule
