module spi_bridge (
    input clk,
    input rst_n,

    input sclk,
    input cs_n,
    input mosi, // MASTER → SLAVE
    output reg miso, // SLAVE  → MASTER

    output reg byte_sync,
    output reg [7:0] data_in,
    input [7:0] data_out
);

    // shift_in = registru de shift pentru byte-ul primit pe MOSI
    // shift_out = registru de shift pentru byte-ul trimis pe MISO
    reg [7:0] shift_in;
    reg [7:0] shift_out;

    // contor de biti (0..7) in cadrul unui byte SPI
    reg [2:0] bit_cnt;

    reg sclk_prev;
    wire sclk_r = ~sclk_prev & sclk;
    wire sclk_f = sclk_prev & ~sclk;

    // Memoram valoarea anterioară a lui SCLK
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_prev <= 1'b0;
        else
            sclk_prev <= sclk;
    end

    // Logica principala SPI (sincrona cu clk-ul intern)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initializari deterministe
            shift_in <= 8'd0;
            shift_out <= 8'd0;
            miso <= 1'b0;
            bit_cnt <= 3'd0;
            byte_sync <= 1'b0;
            data_in <= 8'd0;
        end else begin
            // byte_sync e un impuls de 1 ciclu cand s-a receptionat un byte complet
            byte_sync <= 1'b0;

            if (cs_n) begin
                bit_cnt <= 3'd0;
                shift_out <= data_out;
            end else begin

                if (sclk_r) begin
                    shift_in <= {shift_in[6:0], mosi};

                    if (bit_cnt == 3'd7) begin
                        data_in <= {shift_in[6:0], mosi};
                        byte_sync <= 1'b1;
                        bit_cnt <= 3'd0;
                        shift_out <= data_out;
                    end else begin
                        bit_cnt <= bit_cnt + 3'd1;
                    end
                end

                if (sclk_f) begin
                    miso <= shift_out[7];
                    shift_out <= {shift_out[6:0], 1'b0};
                end
            end
        end
    end

endmodule
