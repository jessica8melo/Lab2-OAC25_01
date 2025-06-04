module ALU (
    input  logic [31:0] A,         // Operando A
    input  logic [31:0] B,         // Operando B
    input  logic [2:0]  ALUOp,     // Sinal de controle para selecionar a operação da ULA
                                   // 3 bits podem selecionar até 8 operações
    output logic [31:0] Result,    // Resultado da operação da ULA
    output logic        Zero       // Flag Zero: '1' se Result é 0, '0' caso contrário
);

    // Parâmetros para os códigos de operação da ULA (ALUOp)
    // Estes valores seriam definidos pela unidade de controle principal
    localparam ALU_OP_ADD = 3'b000;
    localparam ALU_OP_SUB = 3'b001;
    localparam ALU_OP_AND = 3'b010;
    localparam ALU_OP_OR  = 3'b011;
    localparam ALU_OP_SLT = 3'b100;

    // Lógica combinacional para as operações da ULA
    always_comb begin
        // Valor padrão para Result
        Result = 32'b0;

        case (ALUOp)
            ALU_OP_ADD: begin
                Result = A + B;
            end
            ALU_OP_SUB: begin
                Result = A - B;
            end
            ALU_OP_AND: begin
                Result = A & B;
            end
            ALU_OP_OR: begin
                Result = A | B;
            end
            ALU_OP_SLT: begin
                // Comparação com sinal (signed comparison)
                // Se A < B, Result = 1, senão Result = 0.
                if ($signed(A) < $signed(B)) begin
                    Result = 32'd1;
                end else begin
                    Result = 32'd0;
                end
            end
            default: begin
                Result = 32'b0; // Operação não definida ou "não fazer nada"
                                 // Em um processador real, este caso pode ser tratado como NOP
                                 // ou gerar uma exceção de instrução ilegal se ALUOp for inválido.
            end
        endcase
    end

    // Geração da flag Zero
    // A flag Zero é '1' se todos os bits de Result forem '0'
    assign Zero = (Result == 32'b0);

endmodule