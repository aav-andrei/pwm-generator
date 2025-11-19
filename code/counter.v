module counter (
    input clk,
    input rst_n,
    output reg [15:0] count_val,
    input [15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input [7:0] prescale
);

    reg [15:0] next_val;
    reg [15:0] ps_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_val <= 16'd0;
            ps_cnt <= 16'd0;
        end else begin
            if (count_reset) begin
                count_val <= 16'd0;
                ps_cnt <= 16'd0;
            end else if (!en) begin
                count_val <= count_val;
                ps_cnt <= ps_cnt;
            end else begin
                ps_cnt <= ps_cnt + 16'd1;
                if (ps_cnt == (16'd1 << prescale)) begin
                    ps_cnt <= 16'd0;
                    if (upnotdown) begin
                        if (count_val == period)
                            count_val <= 16'd0;
                        else
                            count_val <= count_val + 16'd1;
                    end else begin
                        if (count_val == 16'd0)
                            count_val <= period;
                        else
                            count_val <= count_val - 16'd1;
                    end
                end
            end
        end
    end
endmodule
