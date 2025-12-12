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

    // Contor pentru prescaler
    reg [15:0] ps_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset global
            count_val <= 16'd0;
            ps_cnt <= 16'd0;

        end else if (count_reset) begin
            // Reset comandat din software
            count_val <= 16'd0;
            ps_cnt <= 16'd0;

        end else if (!en) begin
            // Daca modulul e dezactivat, valorile raman neschimbate
            count_val <= count_val;
            ps_cnt <= ps_cnt;

        end else begin
            // Fara prescaler contorul se actualizeaza la fiecare clk
            if (prescale == 8'd0) begin
                if (upnotdown) begin
                    // Numarare crescatoare cu wrap la period
                    if (count_val == period)
                        count_val <= 16'd0;
                    else
                        count_val <= count_val + 16'd1;
                end else begin
                    // Numarare descrescatoare cu wrap la 0 → period
                    if (count_val == 16'd0)
                        count_val <= period;
                    else
                        count_val <= count_val - 16'd1;
                end

            end else begin
                // Cu prescaler update doar o data la 2^prescale cicluri
                ps_cnt <= ps_cnt + 16'd1;
                if (ps_cnt == ((16'd1 << prescale) - 1)) begin
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
