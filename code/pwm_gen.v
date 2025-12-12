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

    // functions[0] = align (0: ALIGN_LEFT, 1: ALIGN_RIGHT)
    // functions[1] = unaligned (0: mod aliniat, 1: mod intre comparatoare)
    wire align     = functions[0];
    wire unaligned = functions[1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;

        end else if (!pwm_en) begin
            // PWM dezactivat fortam iesirea LOW
            pwm_out <= 1'b0;

        end else begin
            if (compare1 == compare2) begin
                pwm_out <= 1'b0;

            end else begin
                if (!unaligned) begin

                    if (!align) begin
                        if (compare1 == 16'd0) begin
                            pwm_out <= 1'b0;
                        end else begin
                            if (count_val == 16'd0)
                                pwm_out <= 1'b1;

                            if (count_val == (compare1 + 16'd1))
                                pwm_out <= 1'b0;
                        end

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
    end

endmodule
