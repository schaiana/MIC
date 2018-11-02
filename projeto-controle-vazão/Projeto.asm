	ORG 0000h

	;P2.0 = Sensor de nível 1.1
	;P2.1 = Sensor de nível 1.2
	;P2.2 = Sensor de nível 1.3
	;P2.3 = Sensor de nível 1.4

	;P2.4 = Sensor de nível 2.1
	;P2.5 = Sensor de nível 2.2
	;P2.6 = Sensor de nível 2.3
	;P2.7 = Sensor de nível 2.4	

	;P3.1 = Válvula F1, com acionamento em 1
	;P3.2 = Válvula F2, com acionamento em 1
	;P3.3 = Válvula F3, com acionamento em 1
	;P3.4 = Válvula C1, com acionamento em 1
	;P3.5 = Válvula C2, com acionamento em 1
	;P3.6 = Mostra erro na entrada Vin, com acionamento em 1
	;P3.7 = Mostra erro na entrada Vout, com acionamento em 1

	;P0 = Vin (Digitar valor desejado em % na porta P0)
	;P1 = Vout (Digitar valor desejado em % na porta P1)
	
	MOV P2, #00h ;Zera a entrada P2
	MOV P3, #00h ;Zera a entrada P3

	;Configura o timer0
        CLR     tr0             ;Para timer0
        CLR     tf0             ;Limpa a flag de overflow
        ANL     tmod, #0xF0
        ORL     tmod, #0x01     ;Configura para modo 1
        MOV     tl0, #0
        MOV     th0, #0         ;Limpa o contador do timer0

INICIO:
	MOV A, P0			   ;Move Vin para A
	CJNE A, #100d, VIN_DIFERENTE_DE_100 ;Salta se A for diferente de 100
	JMP CONFERE_VOUT		;Se Vin for igual a 100, confere Vout

VIN_DIFERENTE_DE_100:
	JC CONFERE_VOUT		;Se o carry for igual a 1, quer dizer que o valor é menor do que 100, então ele salta
	SETB P3.6	;Se P0 for maior do que 100, seta a saída P3.6 para indicar erro
	JMP INICIO	;Volta para o início

CONFERE_VOUT:
	CLR P3.6	;Coloca 0 em P3.6, pois Vin está dentro do esperado
	MOV A, P1			   ;Move Vout para A
	CJNE A, #100d, VOUT_DIFERENTE_DE_100 ;Salta se A for diferente de 100
	JMP INICIA_CICLO			   ;Se Vout for igual a 100, inicia ciclo

VOUT_DIFERENTE_DE_100:
	JC INICIA_CICLO	;Se o carry for igual a 1, quer dizer que o valor é menor do que 100, então ele salta
	SETB P3.7	;SE P1 for maior do que 100, seta a saída P3.7 para indicar erro
	JMP INICIO 	;Volta para o início

INICIA_CICLO:
	CLR P3.7	;Coloca 0 em P3.7 pois Vout está dentro do esperado
TESTAN1:
	;Lê valores de nível do reservatório 1
	MOV C, P2.0
	MOV A.0, C
	MOV C, P2.1
	MOV A.1, C
	MOV C, P2.2
	MOV A.2, C
	MOV C, P2.3
	MOV A.3, C
	CJNE A, #07d, ABRIRF1 ;Se N1 nao estiver no nivel 3, salta
	JMP COMPARAVISC1
ABRIRF1:
	SETB P3.1 ;Abre a válvula F1
	;TIMER
	setb    tr0             ;Inicia o temporizador
LOOP:
	MOV R1, TL0
	CJNE R1, #28d, LOOP	;Se o temporizador não chegou em 28, salta
	CLR    tr0             ;Para temporizador
	MOV     tl0, #0
        MOV     th0, #0         ;Limpa o contador do timer0
	;Fim do timer
	
        CLR P3.1 ;Fecha válvula F1

	
	JMP INCREMENTA_N1 	
;Incrementa o nível 1, só precisa fazer isso na simulação, na prática o valor seria lido
INCREMENTA_N1:
	MOV A, P2	;Move sensor para A
	ANL A, #0Fh	;Deixa somente sensor N1
	SETB C
	RLC A		;Rotaciona pra esquerda e coloca 1 no bit 0
	ANL A, #0Fh	;Lógica "E" para deixar somente os 4 bits da esquerda
	ORL P2, A	;Lógica "OU" para colocar o valor de volta em P2
	JMP TESTAN1

COMPARAVISC1:
	MOV R0, P1	;Vout em R0
	MOV A, P0	;Vin em A
	SUBB A, R0 	;Vin - Vout
	JC VINMENOR	;Se Vin é menor que Vout, será habilitado o carry 
	MOV R7, A 	;Registra valor da diferença em R7
	JMP TESTAN2 	;Se Vout for menor que Vin, passa para próximo tanque e libera C2
	
VINMENOR: 	;Precisa trocar a ordem da subtração, pois gerou complemento de 2
	CLR A
	CLR C
	MOV A, P1
	MOV R0, P0
	SUBB A, R0 	;Diferença entre os valores
	MOV R7, A  	;Registra valor da diferença em R7
	JMP ABRIRC1

ABRIRC1:
	SETB P3.4 	;Abre a válvula C1
	
	;Timer = R7 * 10 segundos
	MOV A, #00d	;Zera A, que irá contar quantas vezes o temporizador rodou
	MOV B, R7	;B: número de vezes que o temporizador precisa rodar
LOOP3:
	MOV TL0, #00d
	MOV TH0, #00d	;Limpa o contador do timer0
	SETB    TR0     ;Inicia o temporizador
LOOP4:
	MOV R1, TL0
	CJNE R1, #08d, LOOP4	;Salta se o temporizador não chegou em 8
	CLR    tr0		;Para temporizador
	INC A     		;Incrementa o número de vezes que o temporizador rodou
	;Fim do timer
	
	CJNE A, B, LOOP3	;Se o temporizador não rodou R7 vezes (valor da diferença entre Vin e Vout), ele salta
	;Fim do timer, já rodou R7*10
	CLR P3.4		;Fecha a válvula C1
	
	JMP TESTAN2
TESTAN2:
	CLR A
	;Lê valores de nível do reservatório 2
	MOV C, P2.4
	MOV A.0, C
	MOV C, P2.5
	MOV A.1, C
	MOV C, P2.6
	MOV A.2, C
	MOV C, P2.7
	MOV A.3, C
	
	CJNE A, #03d, ABRIRF2	;Se N2 não estiver no nível 2, salta
	JMP COMPARAVISC2

COMPARAVISC2:
	MOV R0, P0
	MOV A, P1
	SUBB A, R0	;Vout - Vin
	JC VINMAIOR	;Se Vout é menor que Vin, será habilitado o carry
	MOV R7, A	;Registra valor da diferença em R7
	JMP  ABRIRF3
	
VINMAIOR: ; 
	CLR A
	CLR C
	MOV A, P0
	MOV R0, P1
	SUBB A, R0 	;Valor de A será a diferença dos valores de A e R0
	MOV R7, A  	;Registra valor da diferença em R7
	JMP ABRIRC2

ABRIRF2:
	SETB P3.2 	;Abre a válvula F2
	;Timer
	MOV TL0, #00d
	MOV TH0, #00d		;Limpa o contador do timer0
	SETB    tr0             ;Inicia o temporizador
LOOP_2:
	MOV R1, TL0		;Lê o valor do temporizador para comparação
	CJNE R1, #28d, LOOP_2 	;Salta se o temporizador não chegou em 28
	CLR    tr0             	;Para temporizador
	MOV     tl0, #0
        MOV     th0, #0         ;Limpa o contador do timer0
	;Fim do timer
	
        CLR P3.2		;Fecha válvula F2
	JMP INCREMENTA_N2

INCREMENTA_N2:
	MOV A, P2		;Move sensor para A
	ANL A, #0F0h		;Deixa somente o sensor N1
	RRC A			;Rotaciona 4x para a direita
	RRC A
	RRC A
	RRC A
	ANL A, #0Fh		;Limpa os 4 bits da esquerda
	
	SETB C
	RLC A			;Rotaciona A para a esquerda e coloca 1 no bit 0
	ANL A, #0Fh		;Lógica "E" para limpar os 4 bits da esquerda
	CLR C
	RLC A			;Rotaciona 4 bits pra esquerda
	RLC A
	RLC A
	RLC A
	
	ORL P2, A		;Escreve o valor modificado em P2
	JMP DECREMENTA_N1
	
DECREMENTA_N1:
	MOV A, P2	;Move sensor para A
	ANL A, #0Fh	;Deixa somente o sensor N1
	CLR C
	RRC A		;Rotaciona A para a esquerda e coloca 1 no bit 0
	ANL A, #0Fh	;Lógica "E" para limpar os 4 bits da direita
	ANL P2, #0F0h	;Lógica "E" para limpar os 4 bits da esquerda
	ORL P2, A	;Escreve o valor modificado em P2
	JMP TESTAN2
	

ABRIRC2:
	SETB P3.5 	;Abre a válvula C2
	
	;Timer = R7 * 10 segundos
	MOV A, #00d
	MOV B, R7
LOOP5:
	MOV TL0, #00d
	MOV TH0, #00d		;Limpa o contador do timer0
	SETB    TR0             ;Inicia o temporizador
LOOP6:
	MOV R1, TL0
	CJNE R1, #08d, LOOP6
	CLR    tr0             ;Para temporizador
	INC A     
	;Fim do timer
	
	CJNE A, B, LOOP5	;Se o temporizador não rodou R7 vezes (valor da diferença entre Vin e Vout), ele salta
	;Fim do timer, já rodou R7*10
	CLR P3.5 	;Fecha a válvula C2
	
	JMP ABRIRF3

ABRIRF3:
	SETB P3.3 	;Abre a válvula F3
	;Timer
	MOV TL0, #00d
	MOV TH0, #00d		;Limpa o contador do timer0
	SETB    tr0             ;Inicia o temporizador
LOOP_3:
	MOV R1, TL0
	CJNE R1, #28d, LOOP_3
	CLR    tr0             ;Para temporizador
	MOV     tl0, #0
        MOV     th0, #0         ;Limpa o contador do timer0
	;Fim do timer
	
        CLR P3.3 	;Fecha válvula F3
        JMP DECREMENTA_N2

DECREMENTA_N2:
	MOV A, P2	;Move sensor para A
	ANL A, #0F0h	;Deixa somente o sensor N1
	RRC A		;Rotaciona 4x para direita
	RRC A
	RRC A
	RRC A
	ANL A, #0Fh	;Limpa os 4 bits da esquerda
	
	CLR C
	RRC A		;Rotaciona A para a esquerda e coloca 1 no bit 0
	ANL A, #0Fh
	CLR C
	RLC A
	RLC A
	RLC A
	RLC A
	
	ANL P2, #0Fh
	ORL P2, A
        JMP INICIO 	;Volta para o começo
	END