`timescale 1ns/1ps

module tb_decodificador;
  localparam int CLK_PERIOD = 10;
  localparam int DEBOUNCE_CYCLES = 120;
  localparam int SHORT_PULSE = 10;
  localparam int TIMEOUT = 5000;

  logic clk;
  logic rst;
  logic [3:0] col_matriz;
  logic [3:0] lin_matriz;
  logic [3:0] tecla_value;
  logic tecla_valid;

  integer i, wt, waited;
  integer rows[0:2];
  integer cols[0:2];
  integer holds[0:2];
  logic [3:0] expected;
  logic [3:0] pattern;

  decodificador_de_teclado dut (
    .clk(clk),
    .rst(rst),
    .col_matriz(col_matriz),
    .lin_matriz(lin_matriz),
    .tecla_value(tecla_value),
    .tecla_valid(tecla_valid)
  );

  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  initial begin
    $dumpfile("decodificador_tb.vcd");
    $dumpvars(0, tb_decodificador);
  end

  function automatic logic [3:0] expected_key(input integer row, input integer col);
    integer idx;
    begin
      idx = row*4 + col;
      case (idx)
        0: expected_key = 4'h1;
        1: expected_key = 4'h2;
        2: expected_key = 4'h3;
        3: expected_key = 4'hA;
        4: expected_key = 4'h4;
        5: expected_key = 4'h5;
        6: expected_key = 4'h6;
        7: expected_key = 4'hB;
        8: expected_key = 4'h7;
        9: expected_key = 4'h8;
        10: expected_key = 4'h9;
        11: expected_key = 4'hC;
        12: expected_key = 4'hF;
        13: expected_key = 4'h0;
        14: expected_key = 4'hE;
        15: expected_key = 4'hD;
        default: expected_key = 4'hX;
      endcase
    end
  endfunction

  function automatic logic [3:0] col_pattern(input integer col);
    begin
      col_pattern = ~(4'b0001 << col);
    end
  endfunction

  initial begin
    integer num_tests;
    rst = 1;
    col_matriz = 4'b1111;
    @(posedge clk);
    @(posedge clk);
    rst = 0;
    $display("Reset liberado em %0t", $time);
    repeat (10) @(posedge clk);
    num_tests = 3;
    rows[0] = 1; cols[0] = 1; holds[0] = DEBOUNCE_CYCLES + 20;
    rows[1] = 0; cols[1] = 3; holds[1] = DEBOUNCE_CYCLES + 20;
    rows[2] = 3; cols[2] = 1; holds[2] = DEBOUNCE_CYCLES + 20;

    for (i = 0; i < num_tests; i = i + 1) begin
      $display("=== Teste %0d: pressionar (row=%0d,col=%0d) ===", i+1, rows[i], cols[i]);
      expected = expected_key(rows[i], cols[i]);
      pattern  = col_pattern(cols[i]);
      col_matriz = 4'b1111;
      waited = 0;
      while (lin_matriz[rows[i]] !== 1'b0 && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (waited >= TIMEOUT) begin
        $error("Timeout aguardando linha %0d ativar", rows[i]);
        disable fork;
      end
      col_matriz = pattern;
      repeat (holds[i]) @(posedge clk);
      waited = 0;
      while (!tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (waited >= TIMEOUT) begin
        $error("Timeout aguardando tecla_valid (row=%0d col=%0d)", rows[i], cols[i]);
      end else begin
        if (tecla_value !== expected) begin
          $display("DEBUG: momento da checagem:");
          $display("       time      = %0t", $time);
          $display("       row,col   = %0d,%0d", rows[i], cols[i]);
          $display("       lin_matriz= %b", lin_matriz);
          $display("       col_matriz= %b", col_matriz);
          $display("       DUT tecla_value = 0x%0h", tecla_value);
          $display("       TB expected      = 0x%0h", expected);
          $error("Valor incorreto: esperado 0x%0h, obtido 0x%0h (row=%0d,col=%0d)", expected, tecla_value, rows[i], cols[i]);
        end else begin
          $display("[OK] tecla detectada: row=%0d col=%0d valor=0x%0h tempo=%0t", rows[i], cols[i], tecla_value, $time);
        end
      end
      col_matriz = 4'b1111;
      waited = 0;
      while (tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (tecla_valid) $warning("tecla_valid não caiu após soltar (row=%0d,col=%0d)", rows[i], cols[i]);
      repeat (2) @(posedge clk);
    end

    $display("=== Teste bounce curto (não deve gerar tecla_valid) ===");
    wt = 0;
    while (lin_matriz[2] !== 1'b0 && wt < TIMEOUT) begin @(posedge clk); wt++; end
    if (wt >= TIMEOUT) $error("Timeout esperando linha 2 para bounce");
    col_matriz = col_pattern(2);
    repeat (SHORT_PULSE) @(posedge clk);
    col_matriz = 4'b1111;
    repeat (DEBOUNCE_CYCLES/4) @(posedge clk);
    if (tecla_valid) $error("Bounce indevidamente validado como tecla");
    else $display("[OK] bounce não validado");
    $display("Todos os testes terminados. tempo total=%0t", $time);
    # (CLK_PERIOD * 5);
    $finish;
  end
endmodule
