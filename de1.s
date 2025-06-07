.data
	val1: .word 10
	val2: .word 5
	result_sw: .word 0

.text
    li gp,0x10010000 

    lw t0,0(gp) # t0 = 10
    
    # --- Teste de addi ---
    addi t1, t0, 10    # t1 = t0 + 10 = 10 + 10 = 20
    
    # --- Teste de sub ---
    sub t2, t1, t0     # t2 = t1 - t0 = 20 - 10 = 10
    
    # --- Teste de and ---
    li a0, 0xC      # a0 = 12
    li a1, 0xA      # a1 = 10
    and t3, a0, a1     # t3 = a0 AND a1 = 8
    
    # --- Teste de or ---
    or t4, a0, a1      # t4 = a0 OR a1 = 14
    
    # --- Teste de slt (set less than) ---
    slt t5, t0, t1     # t5 = 1 (porque t0=10 é menor que t1=20)
    slt t6, t1, t0     # t6 = 0 (porque t1=20 não é menor que t0=10)
    
    # --- Teste de sw ---
    la a2, result_sw   # Carrega o endereço de result_sw em a2
    sw t2, 0(a2)       # Armazena t2 (10) no endereço de result_sw
    lw s1, 0(a2)       # s1 deve ser 10
    
    # --- Teste de beq ---
    beq t0, t0, label_beq_true	
    addi s2, x0, 99    # s2 = 99 (apenas para verificar que não passou aqui)
label_beq_true:
    addi s2, x0, 1     # s2 = 1 (se o beq funcionou)
    
    # --- Teste de jal ---
    jal ra, sub_rotina
    addi s3, x0, 50    # s3 = 50 (para verificar que retornou)
    j end_program      # Salta para o fim para não executar a sub-rotina novamente

sub_rotina:
    addi s0, x0, 100   # s0 = 100 (apenas para mostrar que entrou na sub-rotina)
    jr ra              # Retorna para o endereço em ra (onde o jal foi chamado)

    # --- Teste de jalr  ---
    la a3, end_program # Carrega o endereço de end_program em a3
    addi a3, a3, 0     # Adiciona 0 (offset) ao endereço (necessário para jalr)
    jalr x0, a3, 0     # Salta para o endereço em a3 + 0, não salva retorno (x0)
    addi s4, x0, 999   # s4 = 999 (apenas para verificar que não passou aqui)

end_program:
    # Loop infinito para parar a execução no Rars
    j end_program