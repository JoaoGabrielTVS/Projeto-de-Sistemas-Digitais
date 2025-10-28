`timescale 1ns/1ps

module tb_decodificador;
  localparam int CLK_PERIOD = 10; // ns
  localparam int DEBOUNCE_CYCLES = 120; // > 100 do seu TP
  localparam int SHORT_PULSE = 10; // < debounce
  localparam int TIMEOUT = 5000;

  logic clk;
  logic rst;               // active-high reset no seu design
  logic [3:0] col_matriz;  // entrada (active-low: 1111 = none)
  logic [3:0] lin_matriz;  // saída do DUT
  logic [3:0] tecla_value; // saída do DUT
  logic       tecla_valid; // saída do DUT

  // instancia do DUT
  decodificador_de_teclado dut (
    .clk(clk),
    .rst(rst),
    .col_matriz(col_matriz),
    .lin_matriz(lin_matriz),
    .tecla_value(tecla_value),
    .tecla_valid(tecla_valid)
  );

  // clock
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // dump waveform
  initial begin
    $dumpfile("decodificador_tb.vcd");
    $dumpvars(0, tb_decodificador);
  end

  // expected_key usando case para evitar inicializadores de array problemáticos
  function automatic logic [3:0] expected_key(input integer row, input integer col);
    integer idx;
    begin
      idx = row*4 + col; // 0..15
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
      col_pattern = ~(4'b0001 << col); // ex: col=0 -> ~(0001)=1110
    end
  endfunction

  // Testbench principal
  initial begin
    integer wt;
    integer waited;
    logic [3:0] expected;
    logic [3:0] pattern;
    integer row, col;

    // reset ativo
    rst = 1;
    col_matriz = 4'b1111;
    @(posedge clk);
    @(posedge clk);
    // libera reset
    rst = 0;
    $display("Reset liberado em %0t", $time);

    // aguarda estabilizar
    repeat (10) @(posedge clk);

    // Teste 1: pressione '5' (row=1,col=1) e mantenha > debounce
    $display("=== Teste 1: pressionar '5' (row1,col1) ===");
    
    // Lógica para pressionar tecla '5'
    row = 1; col = 1;
    expected = expected_key(row, col);
    pattern = col_pattern(col);
    
    col_matriz = 4'b1111;
    waited = 0;
    while (lin_matriz[row] !== 1'b0 && waited < TIMEOUT) begin
      @(posedge clk); waited++;
    end
    if (waited >= TIMEOUT) begin
      $error("Timeout aguardando linha %0d ativar", row);
    end else begin
      col_matriz = pattern;
      repeat (DEBOUNCE_CYCLES + 20) @(posedge clk);
      
      waited = 0;
      while (!tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (waited >= TIMEOUT) begin
        $error("Timeout aguardando tecla_valid (row=%0d col=%0d)", row, col);
      end else begin
        if (tecla_value !== expected) begin
          $display("DEBUG: momento da checagem:");
          $display("       time      = %0t", $time);
          $display("       row,col   = %0d,%0d", row, col);
          $display("       lin_matriz= %b", lin_matriz);
          $display("       col_matriz= %b", col_matriz);
          $display("       DUT tecla_value = 0x%0h", tecla_value);
          $display("       TB expected      = 0x%0h", expected);
          $error("Valor incorreto: esperado 0x%0h, obtido 0x%0h (row=%0d,col=%0d)", expected, tecla_value, row, col);
        end else begin
          $display("[OK] tecla detectada: row=%0d col=%0d valor=0x%0h tempo=%0t", row, col, tecla_value, $time);
        end
      end
      
      col_matriz = 4'b1111;
      waited = 0;
      while (tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (tecla_valid) $warning("tecla_valid não caiu após soltar (row=%0d,col=%0d)", row, col);
    end

    // Teste 4: pressionar 'A' (row0,col3)
    $display("=== Teste 4: pressionar 'A' (row0,col3) ===");
    
    // Lógica para pressionar tecla 'A'
    row = 0; col = 3;
    expected = expected_key(row, col);
    pattern = col_pattern(col);
    
    col_matriz = 4'b1111;
    waited = 0;
    while (lin_matriz[row] !== 1'b0 && waited < TIMEOUT) begin
      @(posedge clk); waited++;
    end
    if (waited >= TIMEOUT) begin
      $error("Timeout aguardando linha %0d ativar", row);
    end else begin
      col_matriz = pattern;
      repeat (DEBOUNCE_CYCLES + 20) @(posedge clk);
      
      waited = 0;
      while (!tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (waited >= TIMEOUT) begin
        $error("Timeout aguardando tecla_valid (row=%0d col=%0d)", row, col);
      end else begin
        if (tecla_value !== expected) begin
          $display("DEBUG: momento da checagem:");
          $display("       time      = %0t", $time);
          $display("       row,col   = %0d,%0d", row, col);
          $display("       lin_matriz= %b", lin_matriz);
          $display("       col_matriz= %b", col_matriz);
          $display("       DUT tecla_value = 0x%0h", tecla_value);
          $display("       TB expected      = 0x%0h", expected);
          $error("Valor incorreto: esperado 0x%0h, obtido 0x%0h (row=%0d,col=%0d)", expected, tecla_value, row, col);
        end else begin
          $display("[OK] tecla detectada: row=%0d col=%0d valor=0x%0h tempo=%0t", row, col, tecla_value, $time);
        end
      end
      
      col_matriz = 4'b1111;
      waited = 0;
      while (tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (tecla_valid) $warning("tecla_valid não caiu após soltar (row=%0d,col=%0d)", row, col);
    end

    // Teste 2: bounce curto (não deve validar)
    $display("=== Teste 2: bounce curto (não deve gerar tecla_valid) ===");
    wt = 0;
    while (lin_matriz[2] !== 1'b0 && wt < TIMEOUT) begin @(posedge clk); wt++; end
    if (wt >= TIMEOUT) $error("Timeout esperando linha 2 para bounce");
    col_matriz = col_pattern(2);
    repeat (SHORT_PULSE) @(posedge clk);
    col_matriz = 4'b1111;
    repeat (DEBOUNCE_CYCLES/4) @(posedge clk);
    if (tecla_valid) $error("Bounce indevidamente validado como tecla");
    else $display("[OK] bounce não validado");

    // Teste 3: pressionar '0' (row3,col1)
    $display("=== Teste 3: pressionar '0' (row3,col1) ===");
    
    // Lógica para pressionar tecla '0'
    row = 3; col = 1;
    expected = expected_key(row, col);
    pattern = col_pattern(col);
    
    col_matriz = 4'b1111;
    waited = 0;
    while (lin_matriz[row] !== 1'b0 && waited < TIMEOUT) begin
      @(posedge clk); waited++;
    end
    if (waited >= TIMEOUT) begin
      $error("Timeout aguardando linha %0d ativar", row);
    end else begin
      col_matriz = pattern;
      repeat (DEBOUNCE_CYCLES + 20) @(posedge clk);
      
      waited = 0;
      while (!tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (waited >= TIMEOUT) begin
        $error("Timeout aguardando tecla_valid (row=%0d col=%0d)", row, col);
      end else begin
        if (tecla_value !== expected) begin
          $display("DEBUG: momento da checagem:");
          $display("       time      = %0t", $time);
          $display("       row,col   = %0d,%0d", row, col);
          $display("       lin_matriz= %b", lin_matriz);
          $display("       col_matriz= %b", col_matriz);
          $display("       DUT tecla_value = 0x%0h", tecla_value);
          $display("       TB expected      = 0x%0h", expected);
          $error("Valor incorreto: esperado 0x%0h, obtido 0x%0h (row=%0d,col=%0d)", expected, tecla_value, row, col);
        end else begin
          $display("[OK] tecla detectada: row=%0d col=%0d valor=0x%0h tempo=%0t", row, col, tecla_value, $time);
        end
      end
      
      col_matriz = 4'b1111;
      waited = 0;
      while (tecla_valid && waited < TIMEOUT) begin
        @(posedge clk); waited++;
      end
      if (tecla_valid) $warning("tecla_valid não caiu após soltar (row=%0d,col=%0d)", row, col);
    end

    $display("Todos os testes terminados. tempo total=%0t", $time);
    # (CLK_PERIOD * 5);
    $finish;
  end

endmodule