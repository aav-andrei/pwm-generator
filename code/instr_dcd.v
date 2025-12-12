module instr_dcd (
    input clk,
    input rst_n,

    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,

    output reg read,
    output reg write,
    output reg [5:0] addr,

    input [7:0] data_read,
    output reg [7:0] data_write
);

    // Retine daca suntem la primul byte din comanda (header) sau la al doilea (data)
    reg first_byte;

    // 1 = WRITE, 0 = READ (extras din header)
    reg rw_flag;

    // Adresa latched din primul byte, folosita si la al doilea byte
    reg [5:0] latched_addr;

    // La citire, SPI trimite inapoi direct valoarea citita din regs (data_read)
    assign data_out = data_read;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Reset: stare initiala
            first_byte <= 1'b1;
            rw_flag <= 1'b0;
            latched_addr <= 6'd0;
            read <= 1'b0;
            write <= 1'b0;
            addr <= 6'd0;
            data_write <= 8'd0;
        end else begin
            // read/write sunt pulsuri de 1 ciclu (default 0, se ridica doar cand trebuie)
            read <= 1'b0;
            write <= 1'b0;

            // byte_sync = 1 cand spi_bridge a receptionat un byte complet
            if (byte_sync) begin
                if (first_byte) begin
                    rw_flag <= data_in[7];
                    latched_addr <= data_in[5:0];
                    addr <= data_in[5:0];

                    if (!data_in[7]) begin
                        read <= 1'b1;
                    end

                    first_byte <= 1'b0;

                end else begin
                    addr <= latched_addr;

                    if (rw_flag) begin
                        write <= 1'b1;
                        data_write <= data_in;
                    end
                    first_byte <= 1'b1;
                end
            end
        end
    end

endmodule
