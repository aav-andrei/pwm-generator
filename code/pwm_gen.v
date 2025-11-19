module pwm_gen (
    input clk,
    input rst_n,
    input pwm_en,
    input [15:0] period,
    input [7:0] functions,
    input [15:0] compare1,
    input [15:0] compare2,
    input [15:0] count_val,
    output reg pwm_out
);

    wire align       = functions[0];
    wire unaligned   = functions[1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_out <= 1'b0;
        else if (!pwm_en)
            pwm_out <= pwm_out;
        else begin
            if (!unaligned) begin
                if (!align) begin
                    if (count_val == 16'd0)
                        pwm_out <= 1'b1;
                    else if (count_val == compare1)
                        pwm_out <= 1'b0;
                end else begin
                    if (count_val == 16'd0)
                        pwm_out <= 1'b0;
                    else if (count_val == compare1)
                        pwm_out <= 1'b1;
                end
            end else begin
                if (count_val == compare1)
                    pwm_out <= 1'b1;
                else if (count_val == compare2)
                    pwm_out <= 1'b0;
            end
        end
    end

endmodule
