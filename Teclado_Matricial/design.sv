module decodificador_de_teclado (
    input logic clk,
    input logic rst,
    input logic [3:0] col_matriz,
    output logic [3:0] lin_matriz,
    output logic [3:0] tecla_value,
    output logic tecla_valid
  );

  // Variaveis auxiliares
  logic [3:0] leitura_teclado;
  bit [3:0] linha;

  enum logic [2:0] {INICIAL, DEBOUNCE, DECODIFICAR, EXIBIR_SAIDA, TECLA_VALID} estado;
  logic [9:0] tp;

  always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
          tp <= 0;
		  linha <= 0;
          leitura_teclado <= 4'hF;
          estado <= INICIAL;
      end

      else begin
          case(estado)
            
              // Aguardar tecla ser pressionada 
              INICIAL: begin
                tp <= 0;
                if (col_matriz != 4'b1111) begin // Tecla pressionada
                  estado <= DEBOUNCE;
                end
                
                else begin                       // Fazendo varredura das linhas
                  if (linha < 3)
                    linha <= (linha + 1);
                  else
                    linha <= 0;
                end
              end
            
              // Aguardar sinal estabilizar
              DEBOUNCE: begin
                tp <= tp + 1;
                if (col_matriz == 4'b1111) begin  // Botao solto antes de estabilizar
                  tp <= 0;
                  estado <= INICIAL;
                end
                else if (tp >= 100) begin		  // Tempo de estabilizacao concluido
                  estado <= DECODIFICAR;
                end
              end
            
              // Decodificar e ler tecla pressionada
              DECODIFICAR: begin
                 if (col_matriz == 4'b1111) begin  // Botão solto
                   tp <= 0;
                   estado <= INICIAL;
                 end
                 else begin 					   // Decodificando por linha e coluna
                   if (linha == 0)
                     case (col_matriz)
                     	4'b1110: leitura_teclado <= 4'h1;
                        4'b1101: leitura_teclado <= 4'h2;
						4'b1011: leitura_teclado <= 4'h3;
						4'b0111: leitura_teclado <= 4'hA;
						default: leitura_teclado <= 4'hF;
                     endcase
                   else if (linha == 1)
                     case (col_matriz)
                     	4'b1110: leitura_teclado <= 4'h4;
                        4'b1101: leitura_teclado <= 4'h5;
						4'b1011: leitura_teclado <= 4'h6;
						4'b0111: leitura_teclado <= 4'hB;
						default: leitura_teclado <= 4'hF;
                     endcase
                   else if (linha == 2)
                     case (col_matriz)
                     	4'b1110: leitura_teclado <= 4'h7;
                        4'b1101: leitura_teclado <= 4'h8;
						4'b1011: leitura_teclado <= 4'h9;
						4'b0111: leitura_teclado <= 4'hC;
						default: leitura_teclado <= 4'hF;
                     endcase
                   else if (linha == 3)
                     case (col_matriz)
					    4'b1110: leitura_teclado <= 4'hF;
						4'b1101: leitura_teclado <= 4'h0;
						4'b1011: leitura_teclado <= 4'hE;
						4'b0111: leitura_teclado <= 4'hD;
						default: leitura_teclado <= 4'hF;
                     endcase
                   estado <= EXIBIR_SAIDA;			// Decodificacao concluida
                 end
              end
            
            // Exibir tecla pressionada na saida do sistema
            EXIBIR_SAIDA: begin
              if (col_matriz == 4'b1111) begin  // Botão solto
                   tp <= 0;
                   estado <= INICIAL;
              end
              else begin						// Saída exibida
                estado <= TECLA_VALID;
              end
            end
            
            // Exibir tecla ate que o botao seja solto
            TECLA_VALID: begin
              if (col_matriz == 4'b1111) begin  // Botão solto
                   tp <= 0;
                   estado <= INICIAL;
              end
            end
            default: begin
              tp <= 0;
              estado <= INICIAL;
            end
          endcase
      end
  end


  always_comb begin
      if (rst) begin
          lin_matriz = 4'b0111;
          tecla_value = 4'hF;
          tecla_valid = 0;
      end
      else begin
        case(estado) 
              INICIAL: begin
                tecla_valid = 0;
              	if(linha == 0)
                      lin_matriz = 4'b1110;
                else if(linha == 1)
                      lin_matriz = 4'b1101;
                else if(linha == 2)
                      lin_matriz = 4'b1011;
                else if(linha == 3)
                      lin_matriz = 4'b0111;		
              end
              DEBOUNCE: begin
                  tecla_value = 4'hF;
                  tecla_valid = 0;
              end
              DECODIFICAR: begin
                  tecla_value = 4'hF;
                  tecla_valid = 0;
              end
              EXIBIR_SAIDA: begin
                  tecla_value = leitura_teclado;
                  tecla_valid = 0;
              end
              TECLA_VALID: begin
                  tecla_value = leitura_teclado;
                  tecla_valid = 1;
              end
              default: begin
                  lin_matriz = 4'b1110;
                  tecla_value = 4'hF;
                  tecla_valid = 0;
              end
          endcase
  		end
	end
endmodule