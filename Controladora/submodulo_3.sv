module submodulo_3 #(parameter AUTO_SHUTDOWN_T = 30000)
(
    input  logic clk,
    input  logic rst,
    input  logic infravermelho,
    input  logic enable,
    output logic C
);

logic [15:0] Tc;
enum logic [2:0] {inicial, contando, temp} estado;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        Tc     <= 0;
        estado <= inicial;
    end
    else begin
        case (estado)
            inicial: begin
                Tc <= 0;
                if (!infravermelho && enable)
                    estado <= contando;
            end
            contando: begin
                if (Tc < AUTO_SHUTDOWN_T) begin
                    Tc <= Tc + 1;
                end
                else begin
                    Tc <= 0;
                    if (infravermelho || !enable)
                        estado <= inicial;
                    else
                        estado <= temp;
                end
            end
            temp: estado <= inicial;
            default: estado <= inicial;
        endcase
    end
end

always_comb begin
    if (rst) C = 0;
    else begin
        case (estado)
            inicial:   C = 0;
            contando:  C = 0;
            temp:      C = 1;
            default:   C = 0;
        endcase
    end
end

endmodule