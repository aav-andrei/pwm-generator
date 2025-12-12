module regs (
    input clk,
    input rst_n,
    input read,
    input write,
    input [5:0] addr,
    output reg [7:0] data_read,
    input [7:0] data_write,
    input [15:0] counter_val,
    output reg [15:0] period,
    output reg en,
    output reg count_reset,
    output reg upnotdown,
    output reg [7:0] prescale,
    output reg pwm_en,
    output reg [7:0] functions,
    output reg [15:0] compare1,
    output reg [15:0] compare2
);

    // Contor folosit ca “stretcher” pentru semnalul count_reset
    reg [1:0] reset_cnt;
    
    always @* begin
        case (addr[4:0])
            5'h00: data_read = addr[5] ? period[15:8] : period[7:0];
            5'h02: data_read = {7'd0, en};
            5'h03: data_read = addr[5] ? compare1[15:8] : compare1[7:0];
            5'h05: data_read = addr[5] ? compare2[15:8] : compare2[7:0];
            5'h07: data_read = 8'd0;
            5'h08: data_read = addr[5] ? counter_val[15:8]  : counter_val[7:0];
            5'h0A: data_read = prescale;
            5'h0B: data_read = {7'd0, upnotdown};
            5'h0C: data_read = {7'd0, pwm_en};
            5'h0D: data_read = functions;
            default: data_read = 8'd0;
        endcase
    end

    // Registrele se actualizeaza doar pe clk, cand instr_dcd ridica write=1.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Setari default
            period <= 16'd0;
            en <= 1'b0;
            count_reset <= 1'b0;
            upnotdown <= 1'b1;
            prescale <= 8'd0;
            pwm_en <= 1'b0;
            functions <= 8'd0;
            compare1 <= 16'd0;
            compare2 <= 16'd0;
            reset_cnt <= 2'd0;

        end else begin
            // Daca s-a cerut reset, il tinem activ cateva cicluri apoi il coboram automat
            if (reset_cnt != 2'd0) begin
                reset_cnt <= reset_cnt + 2'd1;
                if (reset_cnt == 2'd2) begin
                    count_reset <= 1'b0;
                    reset_cnt <= 2'd0;
                end
            end

            // La write, decodam adresa si scriem in registrul corespunzator
            if (write) begin
                case (addr[4:0])
                    5'h00: begin
                        if (!addr[5]) period[7:0] <= data_write;
                        else period[15:8] <= data_write;
                    end

                    5'h02: en <= data_write[0];

                    5'h03: begin
                        if (!addr[5]) compare1[7:0] <= data_write;
                        else compare1[15:8] <= data_write;
                    end

                    5'h05: begin
                        if (!addr[5]) compare2[7:0] <= data_write;
                        else compare2[15:8] <= data_write;
                    end

                    5'h07: begin
                        count_reset <= data_write[0];
                        if (data_write[0]) reset_cnt <= 2'd1;
                    end

                    5'h0A: prescale <= data_write;
                    5'h0B: upnotdown <= data_write[0];
                    5'h0C: pwm_en <= data_write[0];
                    5'h0D: functions <= data_write;

                    default: ;
                endcase
            end
        end
    end
endmodule
