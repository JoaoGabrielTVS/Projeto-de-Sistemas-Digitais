module submodulo_3#(parameter AUTOSHUTDOWN_T = 30000)
                    (input logic clk,
                    input logic rst,
                    input logic infra,
                    input logic enable,
                    output logic C
                    );

bit [15:0] Tc = 0;
enum logic [2:0] {inicial, contando, temp} estado;

always_ff @(posedge rst, posedge clk) 
    if(rst) begin
        Tc <= 0;
        estado <= inicial;
    end
    else 
        case (estado)
            inicial: begin
                Tc <= 0;                    // Reset timer
                if (!infra && enable)
                    estado <= contando;
            end
            contando: begin
                if (Tc < AUTOSHUTDOWN_T) begin
                    Tc <= Tc + 1;
                end
                else begin
                    Tc <= 0;
                    if (infra || !enable) begin
                        estado <= inicial;
                    end
                    else begin
                        estado <= temp;
                    end
                end
            end
            temp: begin
                estado <= inicial;
            end
            default: estado <= inicial;
        endcase

always_comb begin
    if (rst) begin
        C = 0;
    end
    else begin
        case (estado)
            inicial: C = 0;
            contando: C = 0;
            temp: C = 1;
            default: C = 0;
        endcase
    end
end

endmodule