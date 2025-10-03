module submodulo_1 (
    input logic clk,
    input logic rst,
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic enable,
    output logic led,
    output logic saida
);
    
    enum logic [1:0] {LLA, LDA, LDM, LLM} estado;
    
  always_ff @(posedge rst, posedge clk)
        if (rst) 
            estado <= LDA;
        else begin
            case (estado)
                LDM: begin
                    if (a) estado <= LLA;
                    else if (b) estado <= LLM;
                    else estado <= LDM;
                end
                LLM: begin
                    if (b) estado <= LDM;
                    else if (a) estado <= LLA;
                    else estado <= LLM;
                end
                LDA: begin
                    if (d) estado <= LLA;
                    else if (a) estado <= LDM;
                    else estado <= LDA;
                end
                LLA: begin
                    if (c) estado <= LDA;
                    else if (a) estado <= LDM;
                    else estado <= LLA;
                end
                default: estado <= LDA;
            endcase
        end

    always_comb begin
        led = 0;
        saida = 0;
        enable = 0;

        if (rst) begin
            led = 0;
            saida = 0;
            enable = 0;
        end else begin
            case (estado)
                LLA: begin
                    saida = 1;
                    enable = 1;
                end
                LDM: begin
                    led = 1;
                end
                LLM: begin
                    led = 1;
                    saida = 1;
                end
                LDA: begin
                end
                default: begin
                    led = 0;
                    saida = 0;
                    enable = 0;
                end
            endcase
        end
    end

endmodule