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

    reg first_byte;
    reg rw_flag;
    reg high_flag;
    reg [5:0] reg_addr;

    assign data_out = data_read;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            first_byte <= 1'b1;
            rw_flag <= 1'b0;
            high_flag <= 1'b0;
            reg_addr <= 6'd0;
            read <= 1'b0;
            write <= 1'b0;
            addr <= 6'd0;
            data_write <= 8'd0;
        end else begin
            read <= 1'b0;
            write <= 1'b0;

            if (byte_sync) begin
                if (first_byte) begin
                    rw_flag <= data_in[7];
                    high_flag <= data_in[6];
                    reg_addr <= data_in[5:0];

                    addr <= data_in[5:0];
                    first_byte <= 1'b0;
                end else begin
                    addr <= {high_flag, reg_addr[4:0]};

                    if (rw_flag) begin
                        write <= 1'b1;
                        data_write <= data_in;
                    end else begin
                        read <= 1'b1;
                    end
                    
                    first_byte <= 1'b1;
                end
            end 
        end
    end

endmodule
