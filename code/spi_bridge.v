module spi_bridge (
    input clk,
    input rst_n,

    input sclk,
    input cs_n,
    input miso,          // MASTER → SLAVE
    output reg mosi,     // SLAVE → MASTER

    output reg byte_sync,
    output reg [7:0] data_in,
    input [7:0] data_out
);

    reg [7:0] shift_in;
    reg [7:0] shift_out;
    reg [2:0] bit_cnt;

    reg sclk_d;
    wire sclk_r = ~sclk_d & sclk;   // rising edge detect
    wire sclk_f = sclk_d & ~sclk;   // falling edge detect

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_d <= 1'b0;
        else
            sclk_d <= sclk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_in <= 8'd0;
            shift_out <= 8'd0;
            mosi <= 1'b0;
            bit_cnt <= 3'd0;
            byte_sync <= 1'b0;
            data_in <= 8'd0;
        end else begin
            byte_sync <= 1'b0;

            if (cs_n) begin
                bit_cnt <= 3'd0;
                shift_out <= data_out;
            end else begin
                // SHIFT-IN (Master → Slave)
                if (sclk_r) begin
                    shift_in <= {shift_in[6:0], miso};

                    if (bit_cnt == 3'd7) begin
                        data_in <= {shift_in[6:0], miso};
                        byte_sync <= 1'b1;
                        bit_cnt <= 3'd0;
                        shift_out <= data_out;
                    end else begin
                        bit_cnt <= bit_cnt + 3'd1;
                    end
                end

                // SHIFT-OUT (Slave → Master)
                if (sclk_f) begin
                    mosi <= shift_out[7];
                    shift_out <= {shift_out[6:0], 1'b0};
                end
            end
        end
    end

endmodule
