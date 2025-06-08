module ALUControl (
    input  logic [1:0]  ALUOpType,   // Sinal do Controlador Principal (00:LW/SW, 01:Branch, 10:R-type, 11:I-type arith)
    input  logic [2:0]  funct3,      // Campo funct3 da instrução
    input  logic        instr_30,    // Bit 30 da instrução (funct7[5] para R-type SUB/SRA)
    output logic [2:0]  ALUOp        // Saída para a ULA (3 bits)
);

    // Parâmetros para os códigos de operação da ULA (ALUOp) - devem corresponder aos da ALU.v
    localparam ALU_OP_ADD = 3'b000;
    localparam ALU_OP_SUB = 3'b001;
    localparam ALU_OP_AND = 3'b010;
    localparam ALU_OP_OR  = 3'b011;
    localparam ALU_OP_SLT = 3'b100;
    // Adicione outros se a ULA suportar mais (ex: XOR, SLL, SRL, SRA)

    always_comb begin
        // Valor padrão (pode ser ADD ou um valor de erro/não usado)
        ALUOp = ALU_OP_ADD; // Padrão seguro

        case (ALUOpType)
            2'b00: begin // LW/SW - ULA sempre faz ADD para cálculo de endereço
                ALUOp = ALU_OP_ADD;
            end
            2'b01: begin // Branch (BEQ) - ULA sempre faz SUB para comparação
                ALUOp = ALU_OP_SUB;
            end
            2'b10: begin // Tipo R
                case (funct3)
                    3'b000: begin // ADD ou SUB
                        if (instr_30) begin // Bit 30 (funct7[5]) é 1 para SUB
                            ALUOp = ALU_OP_SUB;
                        end else begin
                            ALUOp = ALU_OP_ADD;
                        end
                    end
                    3'b001: begin // SLL (Não implementado na ULA mínima, poderia ser ADD por padrão ou erro)
                        ALUOp = ALU_OP_ADD; // TODO: Implementar SLL na ULA e aqui
                    end
                    3'b010: begin // SLT
                        ALUOp = ALU_OP_SLT;
                    end
                    3'b011: begin // SLTU (Não implementado na ULA mínima)
                        ALUOp = ALU_OP_ADD; // TODO: Implementar SLTU na ULA e aqui
                    end
                    3'b100: begin // XOR (Não implementado na ULA mínima)
                        ALUOp = ALU_OP_ADD; // TODO: Implementar XOR na ULA e aqui
                    end
                    3'b101: begin // SRL ou SRA (Não implementado na ULA mínima)
                        // if (instr_30) ALUOp = ALU_OP_SRA; else ALUOp = ALU_OP_SRL;
                        ALUOp = ALU_OP_ADD; // TODO: Implementar SRL/SRA na ULA e aqui
                    end
                    3'b110: begin // OR
                        ALUOp = ALU_OP_OR;
                    end
                    3'b111: begin // AND
                        ALUOp = ALU_OP_AND;
                    end
                    default: ALUOp = ALU_OP_ADD; // Operação R não reconhecida
                endcase
            end
            2'b11: begin // Tipo I - Aritmético (ADDI, SLTI, ANDI, ORI)
                         // instr_30 (funct7) não é usado para distinguir ADDI de SUBI (não existe SUBI)
                case (funct3)
                    3'b000: ALUOp = ALU_OP_ADD;  // ADDI
                    3'b010: ALUOp = ALU_OP_SLT;  // SLTI (SLTIU usaria mesma lógica de SLT mas com $unsigned)
                    // 3'b001: SLLI - (Não implementado na ULA mínima)
                    // 3'b101: SRLI/SRAI - (Não implementado na ULA mínima)
                    3'b110: ALUOp = ALU_OP_OR;   // ORI
                    3'b111: ALUOp = ALU_OP_AND;  // ANDI
                    // 3'b100: XORI - (Não implementado na ULA mínima)
                    default: ALUOp = ALU_OP_ADD; // Operação I aritmética não reconhecida
                endcase
            end
            default: ALUOp = ALU_OP_ADD; // Tipo de ALUOpType não reconhecido
        endcase
    end

endmodule