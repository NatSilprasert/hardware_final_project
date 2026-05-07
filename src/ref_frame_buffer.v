module ref_frame_buffer (
    input  wire        clk_a,
    input  wire        we_a,
    input  wire [16:0] addr_a,
    input  wire [11:0] din_a,
    input  wire        clk_b,
    input  wire [16:0] addr_b,
    output reg  [11:0] dout_b
);

    (* ram_style = "block" *) reg [11:0] mem [0:76799];
    integer i;

    initial begin
        for (i = 0; i < 76800; i = i + 1) begin
            mem[i] = 12'd0;
        end
    end

    always @(posedge clk_a) begin
        if (we_a) begin
            mem[addr_a] <= din_a;
        end
    end

    always @(posedge clk_b) begin
        dout_b <= mem[addr_b];
    end

endmodule
