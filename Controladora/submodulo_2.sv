module submodulo_2 #(
    parameter DEBOUNCE_P =300,
    parameter SWITCH_MODE_MIN_T = 5000
)
(input logic clk,
                    input logic rst,
                    input logic pb,
                    output logic A,
                    output logic B
                    );

logic [15:0] Tp;
enum logic [2:0] {inicial, db, a, b, temp} estado;
logic reg_a, reg_b;

always_ff @(posedge rst, posedge clk)
    if (rst) begin
        Tp <= 0;
        estado <= inicial;
    end
    else begin
        case(estado)
            inicial: begin
                Tp <= 0;            // Reset timer
                if(pb == 1) estado <= db;
            end
            db: begin
                if(pb == 0) estado <= inicial;
                else if(Tp < DEBOUNCE_P) begin
                    estado <= db;
                    Tp <= Tp + 1;
                end
                else estado <= b;
            end
            b: begin
                if (pb == 0) begin
                    estado <= temp;
                    reg_b <= 1;
                end
                else if(Tp > SWITCH_MODE_MIN_T) estado <= a;
                else Tp <= Tp + 1;
            end
            a: begin
                if (pb == 0) begin
                    estado <= temp;
                    reg_a <= 1;
                end
            end
            temp: begin
                estado <= inicial;
            end
            default: estado <= inicial;
        endcase
    end

always_comb begin
    if(rst) begin
        A = 0;
        B = 0;
    end
    else
        case (estado)
            inicial: begin
                A = 0;
                B = 0;
            end
            db: begin
                A = 0;
                B = 0;
            end
            a: begin
                A = reg_a;
                B = 0;
            end
            b: begin
                A = 0;
                B = reg_b;
            end
            temp: begin
                A = reg_a;
                B = reg_b;
            end
            default:  begin
                A = 0;
                B = 0;
            end
        endcase
end

endmodule