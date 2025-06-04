module ControlUnit (
    input  logic [6:0] opcode,      // Opcode da instrução
    input  logic       zero_flag,   // Flag Zero da ULA (para BEQ)

    output logic [1:0] ALUOpType,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       ALUSrc,
    output logic [2:0] ImmSel,      // Para o ImmediateGenerator
    output logic [1:0] WBDataSel,   // Write-Back Data Select: 00=ALU, 01=Mem, 10=PC+4
    output logic       BranchPCSel, // Branch condition met for PC select (beq taken)
    output logic       Jump         // JAL ou JALR
);

    // Opcodes (RISC-V standard)
    localparam OP_RTYPE   = 7'b0110011; // add, sub, and, or, slt, sll, etc.
    localparam OP_ITYPE_ARITH = 7'b0010011; // addi, slti, andi, ori, xori, slli, etc.
    localparam OP_LW      = 7'b0000011; // lw
    localparam OP_SW      = 7'b0100011; // sw
    localparam OP_BEQ     = 7'b1100011; // beq (outros branches BNE, BLT teriam mesmo opcode, funct3 diferente)
    localparam OP_JAL     = 7'b1101111; // jal
    localparam OP_JALR    = 7'b1100111; // jalr
    // localparam OP_LUI  = 7'b0110111;
    // localparam OP_AUIPC= 7'b0010111;

    // Tipos de Imediato para ImmSel (devem corresponder ao ImmediateGenerator.v)
    localparam IMM_TYPE_I = 3'b001;
    localparam IMM_TYPE_S = 3'b010;
    localparam IMM_TYPE_B = 3'b011;
    localparam IMM_TYPE_U = 3'b100; // Não usado explicitamente abaixo, mas definido
    localparam IMM_TYPE_J = 3'b101;
    localparam IMM_TYPE_NONE = 3'b000; // Para R-type ou quando não há imediato

    // Seletores para WBDataSel
    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;


    always_comb begin
        // Valores padrão (geralmente inativos)
        ALUOpType   = 2'b00;       // Default para LW/SW (ADD)
        RegWrite    = 1'b0;
        MemRead     = 1'b0;
        MemWrite    = 1'b0;
        ALUSrc      = 1'b0;       // Default para rs2_data
        ImmSel      = IMM_TYPE_NONE;
        WBDataSel   = WB_ALU;     // Default para resultado da ULA
        BranchPCSel = 1'b0;
        Jump        = 1'b0;

        case (opcode)
            OP_RTYPE: begin
                ALUOpType   = 2'b10; // R-type
                RegWrite    = 1'b1;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b0; // rs2_data
                ImmSel      = IMM_TYPE_NONE;
                WBDataSel   = WB_ALU;
                BranchPCSel = 1'b0;
                Jump        = 1'b0;
            end

            OP_ITYPE_ARITH: begin // addi, slti, andi, ori (e xori, slli se suportado)
                ALUOpType   = 2'b11; // I-type arithmetic
                RegWrite    = 1'b1;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b1; // immediate_extended
                ImmSel      = IMM_TYPE_I;
                WBDataSel   = WB_ALU;
                BranchPCSel = 1'b0;
                Jump        = 1'b0;
            end

            OP_LW: begin
                ALUOpType   = 2'b00; // LW/SW (ALU faz ADD para endereço)
                RegWrite    = 1'b1;
                MemRead     = 1'b1;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b1; // immediate_extended (offset)
                ImmSel      = IMM_TYPE_I;
                WBDataSel   = WB_MEM; // Dado da memória para registrador
                BranchPCSel = 1'b0;
                Jump        = 1'b0;
            end

            OP_SW: begin
                ALUOpType   = 2'b00; // LW/SW (ALU faz ADD para endereço)
                RegWrite    = 1'b0;  // Não escreve em registrador
                MemRead     = 1'b0;
                MemWrite    = 1'b1;
                ALUSrc      = 1'b1; // immediate_extended (offset)
                ImmSel      = IMM_TYPE_S;
                // WBDataSel não importa pois RegWrite = 0
                BranchPCSel = 1'b0;
                Jump        = 1'b0;
            end

            OP_BEQ: begin
                ALUOpType   = 2'b01; // Branch (ALU faz SUB para comparar)
                RegWrite    = 1'b0;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b0; // rs2_data para comparar com rs1_data
                ImmSel      = IMM_TYPE_B;
                // WBDataSel não importa
                BranchPCSel = zero_flag; // Desvia se zero_flag (rs1 == rs2) for verdadeiro
                Jump        = 1'b0;
            end

            OP_JAL: begin
                // ALU pode ser usada para calcular PC + Imm, mas aqui focamos nos outros sinais
                // Para JAL, rd = PC+4. O PC é atualizado para PC + offset.
                ALUOpType   = 2'b00; // Pode ser usado para PC + ImmJ (target addr) ou ser "don't care" se PC logic lida com isso
                RegWrite    = 1'b1;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b1; // Se ALU calcula PC + ImmJ, B seria ImmJ
                ImmSel      = IMM_TYPE_J;
                WBDataSel   = WB_PC4; // PC+4 vai para o registrador rd
                BranchPCSel = 1'b0;
                Jump        = 1'b1;
            end

            OP_JALR: begin
                // Para JALR, rd = PC+4. O PC é atualizado para (rs1 + offset) & ~1.
                ALUOpType   = 2'b00; // ALU faz rs1 + ImmI (target addr)
                RegWrite    = 1'b1;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b1; // immediate_extended (offset)
                ImmSel      = IMM_TYPE_I;
                WBDataSel   = WB_PC4; // PC+4 vai para o registrador rd
                BranchPCSel = 1'b0;
                Jump        = 1'b1; // Sinaliza um salto incondicional (mas o target é calculado diferentemente de JAL)
            end

            // Adicionar LUI, AUIPC se necessário
            // OP_LUI: begin ... end
            // OP_AUIPC: begin ... end

            default: begin
                // Instrução não reconhecida/ilegal. Sinais padrão geralmente são "seguros" (sem escrita).
                // Em um processador mais completo, isso poderia levantar uma exceção.
                ALUOpType   = 2'b00;
                RegWrite    = 1'b0;
                MemRead     = 1'b0;
                MemWrite    = 1'b0;
                ALUSrc      = 1'b0;
                ImmSel      = IMM_TYPE_NONE;
                WBDataSel   = WB_ALU;
                BranchPCSel = 1'b0;
                Jump        = 1'b0;
            end
        endcase
    end

endmodule