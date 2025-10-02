module controladora #(
    parameter DEBOUNCE_P = 300,
    parameter SWITCH_MODE_MIN_T = 5000,
    parameter AUTO_SHUTDOWN_T = 30000
)(
    input  logic clk,
    input  logic rst,
    input  logic infra,
    input  logic push_button,
    output logic led,
    output logic saida
);

    // sinais internos
    logic clk_1khz;
    logic A, B, C, enable;

    // divisor de frequência
    divfreq df(
        .clock(clk),
        .reset(rst),
        .clk_1(clk_1khz)
    );

    // submódulo 1 - máquina de estados principal
    submodulo_1 sm1(
        .clk(clk_1khz),
        .rst(rst),
        .a(A),
        .b(B),
        .c(C),
        .d(infra),
        .enable(enable),
        .led(led),
        .saida(saida)
    );

    // submódulo 2 - debounce + controle de modos
    submodulo_2 #(
        .DEBOUNCE_P(DEBOUNCE_P),
        .SWITCH_MODE_MIN_T(SWITCH_MODE_MIN_T)
    ) sm2(
        .clk(clk_1khz),
        .rst(rst),
        .pb(push_button),
        .A(A),
        .B(B)
    );

    // submódulo 3 - auto shutdown
    submodulo_3 #(
        .AUTOSHUTDOWN_T(AUTO_SHUTDOWN_T)
    ) sm3(
        .clk(clk_1khz),
        .rst(rst),
        .infra(infra),
        .enable(enable),
        .C(C)
    );

endmodule