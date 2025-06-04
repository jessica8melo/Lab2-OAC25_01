`ifndef PARAM
	// `include "Parametros.v"
`endif

module RegisterFile (
    input logic clk,          // Clock
    input logic rst,          // Reset
    input logic we,           // Write Enable (habilita escrita)

    input logic [4:0] ra1,    // Endereço de leitura para rs1
    input logic [4:0] ra2,    // Endereço de leitura para rs2
    input logic [4:0] ra_disp,// Endereço de leitura para disp/offset (ex: para lw/sw, jalr)

    input logic [4:0] wa,     // Endereço de escrita (rd)
    input logic [31:0] wd,    // Dado a ser escrito

    output logic [31:0] rd1,   // Dado lido de rs1
    output logic [31:0] rd2,   // Dado lido de rs2
    output logic [31:0] rd_disp // Dado lido de ra_disp
);

    // Definição dos parâmetros dos registradores especiais e seus valores iniciais
    localparam SP_ADDR     = 5'd2;           // Endereço do Stack Pointer (x2)
    localparam GP_ADDR     = 5'd3;           // Endereço do Global Pointer (x3)
    localparam SP_INIT_VAL = 32'h1001_03FC;  // Valor inicial do SP
    localparam GP_INIT_VAL = 32'h1001_0000;  // Valor inicial do GP
    localparam ZERO_ADDR   = 5'd0;           // Endereço do registrador zero (x0)

    // Banco de 32 registradores de 32 bits
    logic [31:0] registers [0:31];

    // Lógica de Leitura (combinacional)
    // O registrador x0 (endereço 0) sempre retorna 0
    assign rd1     = (ra1 == ZERO_ADDR) ? 32'b0 : registers[ra1];
    assign rd2     = (ra2 == ZERO_ADDR) ? 32'b0 : registers[ra2];
    assign rd_disp = (ra_disp == ZERO_ADDR) ? 32'b0 : registers[ra_disp];

    // Lógica de Escrita (síncrona com o clock) e Reset
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            // Inicialização no Reset
            registers[ZERO_ADDR] <= 32'b0; // Garante que x0 seja 0
            for (integer i = 1; i < 32; i = i + 1) begin // Começa em 1 para não sobrescrever x0 explicitamente de novo
                if (i == SP_ADDR) begin
                    registers[i] <= SP_INIT_VAL;
                end else if (i == GP_ADDR) begin
                    registers[i] <= GP_INIT_VAL;
                end else begin
                    registers[i] <= 32'b0; // Inicializa os demais com 0
                end
            end
        end else begin
            // Operação de escrita normal
            // Só escreve se we=1 e o endereço de escrita não for x0
            if (we && (wa != ZERO_ADDR)) begin
                registers[wa] <= wd;
            end
        end
    end

endmodule