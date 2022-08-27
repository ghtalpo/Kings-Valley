
;-------------------------------------------------------------------------------
;
; King's Valley (RC727)
;
; Copyright 1985 Konami
;
; Desensamblado	e interpretado por Manuel Pazos	(jose.manuel.pazos@gmail.com)
; Santander,  17-07-2009
;
;-------------------------------------------------------------------------------


VERSION2	equ	1	; Segunda version de la ROM con correccion de fallos

;-------------------------------------------------------------------------------
; Modificando la constante VERSION2 se pueden generar las dos versiones del juego que existen
; La version 2 [A1] corrige algunos fallos de la version previa como:
; 상수 VERSION2를 수정하면 존재하는 두 가지 버전의 게임을 생성할 수 있습니다.
; 버전 2[A1]는 다음과 같은 이전 버전의 일부 버그를 수정합니다.
;
; - Impide que se pueda lanzar un cuchillo cuando la puerta se esta abriendo.
;   De esta forma se evita que se corrompa el grafico de la puerta al pasar el cuchillo sobre ella
;
; - Impide que se pueda lanzar un cuchillo cuando se esta pegado a un objeto (gema, pico, etc...)
;   En la version original atravesaba el objeto al lanzar el cuchillo
;
; - Se puede picar sobre un muro trampa
;
; - Corregida la posicion del muro trampa de la piramide 10 de la pantalla de la izquierda, abajo a la izquierda (aparece al coger el cuchillo)
;   La version original lo ten�a en la pantalla de la derecha bajo las escaleras. Pero hacia falta cabar un par de ladrillos del suelo para que apareciese.
;
; - Modificaci�n de la posicion del muro trampa de la pir�mide 12, en la pantalla de la derecha, abajo a la derecha (aparece al coger el pico) Se ha movido un tile a la derecha (?)
;
; - Los muros trampa se detienen al chocar contra un objeto. En la version anterior lo borraba (erroneamente decrementaba los decimales X en vez de la coordenada Y)
;-------------------------------------------------------------------------------

; En la piramide 10-2 hay una momia que parece por encima del suelo (!?)
; 피라미드 10-2에는 땅 위에 있는 듯한 미라(!?)

;-------------------------------------------------------------------------------
; Estructuras
;-------------------------------------------------------------------------------

;--------------------------------------
; ACTOR
;--------------------------------------
ACTOR_STATUS:	 equ	0
ACTOR_CONTROL:	 equ	1			; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha
									; 1 = 위쪽, 2 = 아래쪽, 4 = 왼쪽, 8 = 오른쪽
ACTOR_SENTIDO:	 equ	2			; 1 = Izquierda, 2 = Derecha
									; 1 = 왼쪽, 2 = 오른쪽
ACTOR_Y:	 equ	3
ACTOR_X_DECIMAL: equ	4
ACTOR_X:	 equ	5
ACTOR_ROOM:	 equ	6
ACTOR_SPEEDXDEC: equ	7
ACTOR_SPEED_X:	 equ	8
ACTOR_SPEEDROOM: equ	9
ACTOR_MOV_CNT:	 equ	0Ah
ACTOR_FRAME:	 equ	0Bh
ACTOR_JMP_P:	 equ	0Ch		; Puntero a tabla con los valores del salto
								; 점프 값이 있는 테이블에 대한 포인터
ACTOR_JMP_P_H:	 equ	0Dh
ACTOR_JUMPSENT:	 equ	0Eh		; 0 = Subiendo,	1 = Cayendo
								; 0 = 상승, 1 = 하락
ACTOR_SENT_ESC:	 equ	0Fh		; Sentido en el	que van	las escaleras. 0 = \  1	= /
								; 계단이 가는 방향. 0 = \ 1 = /
ACTOR_POS_RELAT: equ	10h		; 0 = A	la misma altura	(o casi), 1 = Momia por	encima,	2 = Por	debajo
								; 0 = 같은 높이(또는 거의)에서, 1 = 위의 미라, 2 = 아래
ACTOR_TIMER:	 equ	11h
ACTOR_TIPO:	 equ	14h
ACTOR_STRESS:	 equ	15h		; Contador de stress de	la momia (para saber si	choca muy a menudo)
								; 미라 스트레스 카운터(너무 자주 충돌하는지 알기 위해)

;--------------------------------------
; Puerta giratoria
;--------------------------------------
SPINDOOR_STATUS: equ	0
SPINDOOR_Y:	 equ	1
SPINDOOR_X_DEC:	 equ	2
SPINDOOR_X:	 equ	3
SPINDOOR_ROOM:	 equ	4
SPINDOOR_SENT:	 equ	5
SPINDOOR_TIMER:	 equ	6

;--------------------------------------
; MUSIC
;--------------------------------------
MUSIC_CNT_NOTA:	 equ	0
MUSIC_DURAC_NOTA: equ	1
MUSIC_ID:	 equ	2
MUSIC_ADD_LOW:	 equ	3
MUSIC_ADD_HIGH:	 equ	4
MUSIC_OCTAVA:	 equ	5			; Octava?
MUSIC_VOLUME_CH: equ	6			; Volumen canal
									; 채널 볼륨
MUSIC_VOLUME:	 equ	7
MUSIC_CNT_LOOP:	 equ	9			; Veces	que se ha reproducido un pattern
									; 패턴이 재생된 횟수
MUSIC_TEMPO:	 equ	0Ah

;-------------------------------------------------------------------------------
; BIOS
;-------------------------------------------------------------------------------

byte_6:		equ	6
byte_7:		equ	7
WRTVDP:		equ	#47
RDVRM:		equ	#4a
WRTVRM:		equ	#4d
SETRD:		equ	#50
SETWR:		equ	#53
WRTPSG:		equ	#93
RDPSG:		equ	#96
RDVDP:		equ	#13e
SNSMAT:		equ	#141	;  Read	keyboard row

H_TIMI:		equ	#fd9a





;-------------------------------------------------------------------------------
;
; ROM header
;
;-------------------------------------------------------------------------------
		SIZE    16 * 1024       ; ROM de 16K

		org	#4000

		dw	4241h
		dw	startCode
		dw	0
		dw	0
		dw	0
		dw	0
		dw	0
		dw	0

;----------------------------------------------------
; Suma HL + A
;----------------------------------------------------

ADD_A_HL:
		add	a, l
		ld	l, a
		ret	nc
		inc	h
		ret

;----------------------------------------------------
; Suma DE + A
;----------------------------------------------------

ADD_A_DE:
		add	a, e
		ld	e, a
		ret	nc
		inc	d
		ret


;-------------------------------------------------------------------------------
;
; MAIN
;
; Funcion principal llamada desde el gancho de interrupcion (50	o 60 Hz)
; Actualiza el reproductor de sonido
; Evita	que se ejecute la logica al producirse una interrupcion	si no ha
; terminado la iteracion anterior
; 인터럽트 후크(50 또는 60Hz)에서 호출되는 주요 기능
; 사운드 플레이어 업데이트
; 이전 반복이 완료되지 않은 경우 인터럽트 시 로직 실행 방지
;-------------------------------------------------------------------------------

tickMain:
		call	RDVDP		; Borra	el flag	de interrupcion
							; 인터럽트 플래그 지우기
		di
		call	updateSound	; Actualiza el driver de sonido
							; 사운드 드라이버 업데이트

		ld	hl, tickInProgress ; Si	el bit0	esta a 1 no se ejecuta la logica del juego
								; bit0이 1이면 게임 로직이 실행되지 않습니다.
		bit	0, (hl)
		jr	nz, tickMain2	; No se	ha terminado la	iteracion anterior
							; 이전 반복이 완료되지 않았습니다.

		inc	(hl)		; Indica que se	va a realizar una iteracion
						; 반복이 수행될 것임을 나타냅니다.
		ei
		call	chkControls	; Actualiza el estado de los controles
							; 컨트롤 상태 업데이트
		call	runGame		; Ejecuta la logica del	juego
							; 게임 로직 실행

		xor	a
		ld	(tickInProgress), a ; Indica que ha terminado la iteracion actual
								; 현재 반복이 완료되었음을 나타냅니다.

tickMain2:
		call	RDVDP		; Lee y	borra el flag de interrupcion
							; 인터럽트 플래그 읽기 및 지우기
		or	a		; Se ha	producido una interrupcion mientras se ejecutaba logica	del juego?
					; 게임 로직 실행 중 중단이 발생했습니까?
		di
		call	m, updateSound	; Si, actualiza	el sonido
								; 예, 사운드를 업데이트합니다.
		ei
		ret


;----------------------------------------------------
; Lee el estado	de las teclas
; Proteccion anticopia (!?)
; Si se	ejecuta	en RAM machaca el programa
; 키 상태 읽기
; 복사 방지(!?)
; RAM에서 실행되면 프로그램이 손상됩니다.
;----------------------------------------------------

ReadKeys_AC:
		ld	hl, KonamiLogo2
		ld	a, (JumpIndex2)
		ld	(hl), a
		inc	hl
		ld	(hl), 0C9h	; RET opcode
		jp	ReadKeys

;----------------------------------------------------
; Jump index
; (SP) = Puntero a funciones
;  A = Indice de la funcion
; 점프 인덱스
; (SP) = 함수에 대한 포인터
;  A = 함수의 인덱스
;----------------------------------------------------

jumpIndex:
		add	a, a

JumpIndex2:
		pop	hl
		call	getIndexHL_A
		jp	(hl)


;----------------------------------------------------
; Igual	que WriteDataVRAM pero escribiendo siempre 0
; WriteDataVRAM과 동일하지만 항상 0을 씁니다.
;----------------------------------------------------

ClearDataVRAM:
		ld	c, 0		; Mascara a aplicar con	AND al byte a escribir
		jr	writeDataVRAM2


;----------------------------------------------------
; Escribe en la	VRAM datos con formato
; In:
;   C =	Mascara	AND aplicada al	dato a escribir
;  DE =	direccion datos
;  0-1:	VRAM address
;  2...: Datos
; Datos:
;  FE: next block (nueva direccion + datos)
;  FF: end datos
;
; 포맷된 데이터를 VRAM에 쓰기
; 입력:
;   C = 쓸 데이터에 적용된 AND 마스크
;  DE = 데이터 주소
;  0-1: VRAM 주소
;  2...: 데이터
; 데이터:
;  FE: 다음 블록(새 주소 + 데이터)
;  FF: 종료 데이터
;----------------------------------------------------

WriteDataVRAM:
		ld	c, 0FFh		; Mascara a aplicar con	AND al byte a escribir
						; 쓸 바이트에 AND로 적용할 마스크

writeDataVRAM2:
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ex	de, hl
		inc	de

writeDataVRAM3:
		ld	a, (de)
		inc	de
		ld	b, a
		inc	b		; Es #FF?
		ret	z		; Fin de los datos
					; 데이터의 끝

		inc	b		; Es #FE?
		jr	z, writeDataVRAM2 ; Cambia puntero a VRAM
								; VRAM에 대한 포인터 변경

		and	c		; Aplica mascara AND al	dato a escribir	en la VRAM
					; VRAM에 쓸 데이터에 AND 마스크 적용
		call	WRTVRM
		inc	hl
		jr	writeDataVRAM3

;-------------------------------------------------------------------------------
;
; Boot code
;
; Fija la rutina de interrupcion que llamara a la logica del juego cada	frame
; Borra	el area	de variables
; Inicializa el	hardware (modo de video, PSG)
; Ejecuta un loop infinito, tipico de Konami.
;
; 매 프레임마다 게임 로직을 호출하는 인터럽트 루틴 수정
; 변수 영역 지우기
; 하드웨어 초기화(비디오 모드, PSG)
; Konami의 전형적인 무한 루프를 실행합니다.
;-------------------------------------------------------------------------------

startCode:
		di
		im	1
		ld	a, 0C3h
		ld	(H_TIMI), a
		ld	hl, tickMain
		ld	(H_TIMI+1), hl	; Pone la rutina de interrupcion que lleva la logica del juego
							; 게임의 논리를 전달하는 인터럽트 루틴을 넣습니다.

		ld	sp, stackTop	; Fija el lugar de la pila
							; 더미의 위치를 ​​​​설정하십시오
		ld	hl, GameStatus
		ld	de, subStatus
		ld	bc, 6FFh
		ld	(hl), 0
		ldir			; Inicializa el	area de	variables del juego
						; 게임 변수 영역 초기화

		ld	a, 1
		ld	(tickInProgress), a ; Evita que	se ejecute la logica del juego mientras	se inicializa el hardware
								; 하드웨어가 초기화되는 동안 게임 로직이 실행되지 않도록 방지
		call	initHardware	; Inicializa el	modo de	video y	el PSG
								; 비디오 모드 및 PSG 초기화

		xor	a
		ld	(tickInProgress), a ; Permite que se ejecute la	logica del juego en la proxima interrupcion
								; 다음 인터럽트에서 게임 로직이 실행되도록 허용
		call	RDVDP		; Borra	el flag	de interrupcion
							; 인터럽트 플래그 지우기
		ei

dummyLoop:
		jr	$

;----------------------------------------------------
; VRAM write con proteccion anticopia
; Antes	de escribir en la VRAM machaca el codigo si se ejecuta en RAM
;
; 복사 방지 기능이 있는 VRAM 쓰기
; VRAM에 쓰기 전에 RAM에서 실행 중인 경우 코드를 파쇄하십시오.
;----------------------------------------------------

VRAM_writeAC:
		ld	(copyProtect_+1), de ; Proteccion anticopia (!?)
								; 복사 방지(!?)
		jp	setFillVRAM

;-------------------------------------------------------------------------------
;
; Tick game
;
;-------------------------------------------------------------------------------

runGame:
		ld	hl, timer
		inc	(hl)		; Incrementa timer global del juego
						; 글로벌 게임 타이머 증가

		ld	bc, (GameStatus) ;  C =	Game status, B = Substatus
		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
								; bit 6 = 플레이어 제어 게이트(?)
		bit	6, a		; Se esta jugando?
						; 재생 중입니까?
		jr	nz, runGame2	; Si, no esta en modo demo o en	el menu
							; 예, 데모 모드나 메뉴에 없습니다.

		ld	hl, chkPushAnyKey ; Se a�ade esta funcion para comprobar si se pulsa una tecla y hay que empezar una partida
							; 이 기능은 키가 눌렸는지, 게임을 시작해야 하는지 확인하기 위해 추가되었습니다.
		push	hl

runGame2:
		ld	a, c
		call	jumpIndex

		dw KonamiLogo		; 0 = Muestra el logo de Konami
							; 0 = Konami 로고 표시
		dw WaitMainMenu		; 1 = Espera en	el menu. Si   no se pulsa una tecla salta a la demo
							; 1 = 메뉴에서 기다립니다. 아무 키도 누르지 않은 경우 데모로 이동
		dw SetDemo		; 2 = Prepara el modo demo
						; 2 = 데모 모드 준비
		dw iniciaPartida	; 3 = Reproduce	musica inicio, parpadea	PLAY START y pasa al modo de juego
							; 3 = 음악 시작 재생, PLAY START 플래시 및 게임 모드로 이동
		dw StartGame		; 4 = Borra menu, dibuja piramide, puerta y como entra el prota
							; 4 = 메뉴 삭제, 피라미드 그리기, 문 및 주인공이 들어가는 방식
		dw gameLogic		; 5 = Logica del pergamino o del juego
							; 5 = 스크롤 또는 게임 로직
		dw tickMuerto		; 6 = Pierde una vida /	Muestra	mensaje	de Game	Over
							; 6 = 생명을 잃음 / 게임 오버 메시지 표시
		dw tickGameOver		; 7 = Game Over
		dw stageClear		; 8 = Stage clear (suma	una vida y activa el pergamino)
							; 8 = 스테이지 클리어(생명력 추가 및 스크롤 활성화)
		dw ScrollPantalla	; 9 = Scroll pantalla
							; 9 = 스크롤 화면
		dw FinalJuego		; 10 = Muestra el final	del juego
							; 10 = 게임의 끝을 보여줍니다


;----------------------------------------------------------------------------
; Konami logo (0)
; 0 = Inicializa logo: borra pantalla, carga graficos y	pone modo grafico
; 1 = Sube el logo cada	2 frames. Subraya Konami y pone	el texto "SOFTWARE"
; 2 = Espera un	rato y borra la	pantalla.
; 3 = Dibuja el	menu.
;
; 0 = 로고 초기화: 화면 지우기, 그래픽 로드 및 그래픽 모드 설정
; 1 = 2 프레임마다 로고를 업로드합니다. Konami에 밑줄을 긋고 "SOFTWARE"라는 텍스트를 넣습니다.
; 2 = 잠시 기다렸다가 화면을 지웁니다.
; 3 = 메뉴를 그립니다.
;----------------------------------------------------------------------------

KonamiLogo:
		djnz	KonamiLogo2
		ld	a, (timer)
		rra
		ret	nc		; Sube el logo cada dos	frames
					; 두 프레임마다 로고 업로드

		call	dibujaLogo
		ret	nz		; Aun esta subiendo el logo
					; 로고는 아직 업로드 중입니다.

		ld	de, TXT_Sofware
		call	unpackGFXset	; Subraya Konami y pone	texto "Software"
								; Konami에 밑줄을 긋고 "Software"라는 텍스트를 입력합니다.
		xor	a
		jr	UpdateSubstatus

KonamiLogo2:
		djnz	KingsValleyLogo
		ld	hl, waitCounter
		dec	(hl)
		ret	nz		; Espera un rato mostrando el logo
					; 로고를 표시하는 동안 잠시 기다리십시오

		call	clearScreen
		call	setColor
		xor	a
		ld	(gameLogoCnt), a ; Contador que	indica que parte del logo del menu se esta pintando
							; 메뉴 로고의 일부가 그려지고 있음을 나타내는 카운터
		jr	doNextSubStatus

KingsValleyLogo:
		djnz	InitLogo
		call	drawGameLogo	; Dibuja el menu
								; 메뉴를 그리다
		ret	c
		xor	a
		jp	NextGameStatus_

InitLogo:
		call	clearScreen
		call	LoadIntroGfx
		call	SetVideoMode

doNextSubStatus:
		jp	NextSubStatus

;----------------------------------------------------------------------------
; Menu (1)
; Espera un rato y salta a la demo
; 잠시 기다렸다가 데모로 이동
;----------------------------------------------------------------------------

WaitMainMenu:
		ld	hl, waitCounter
		dec	(hl)
		ret	nz		; Hay que seguir esperando
					; 우리는 계속 기다려야 해요

		jp	NextGameStatusT	; Pasa al modo demo
							; 데모 모드로 전환

;----------------------------------------------------------------------------
;
; Game demo (2)
; Pone el status de juego e inicializa las variables de	la demo
; 게임 상태 설정 및 데모 변수 초기화
;
;----------------------------------------------------------------------------

SetDemo:
		ld	hl, 4		; Start	game status, substatus = 0
		ld	(GameStatus), hl
		ld	l, 0
		ld	(PiramidesPasadas), hl ; Cada bit indica si la piramide	correspondiente	ya esta	pasada/terminada
									; 각 비트는 해당 피라미드가 이미 통과/완료되었는지 여부를 나타냅니다.
		ld	a, l
		ld	(numFinishGame), a ; Numero de veces que se ha terminado el juego
								; 게임이 끝난 횟수

		call	setDatosPartida

		ld	hl, 805h	; Piramide 5, puerta de	la derecha
						; 피라미드 5, 오른쪽 문
		ld	(piramideDest),	hl

		ld	hl, DemoKeyData	; Controles grabados de	la demo
							; 녹음된 데모 컨트롤
		ld	(keyPressDemo),	hl ; Puntero a los controles grabados
								; 기록된 컨트롤에 대한 포인터

		ld	a, 8
		ld	(KeyHoldCntDemo), a
		ret

UpdateSubstatus:
		ld	(waitCounter), a

NextSubStatus:
		ld	hl, subStatus
		inc	(hl)

doNothing:
		ret

;----------------------------------------------------------------------------
;
; Start	game (4)
;
;
;----------------------------------------------------------------------------

StartGame:
		ld	a, (flagPiramideMap) ; 0 = Mostrando mapa, 1 = Dentro de la piramide
								; ; 0 = 지도 보기, 1 = 피라미드 내부
		rra			; Se esta mostrando el mapa de piramides?
					; 피라미드 지도가 표시됩니까?
		jp	nc, showMap

		ld	a, b		; Substatus
		or	a		; Si es	igual a	cero esta haciendo la cortinilla desde el menu
					; 0이면 메뉴에서 커튼을 만드는 것입니다.
		jr	z, waitEntrada	; No dibuja el brillo de las gemas
							; 보석의 광택을 그리지 않습니다

		push	bc
		call	drawBrilloGemas	; Dibuja el brillo de las gemas
								; 보석의 반짝임을 그려
		pop	bc

; Sub1:	Espera en las escaleras	de la entrada
; Sub1: 입구 계단에서 대기

waitEntrada:
		djnz	bajaEscaleras
		ld	hl, waitCounter
		dec	(hl)
		ret	nz
		jr	UpdateSubstatus

; Sub2:	Baja por las escaleras
; Sub2: 계단을 내려가
bajaEscaleras:
		djnz	initStage2
		call	updateSprites
		jp	escalerasEntrada



;-------------------------------------------------------------------------------
; Se ejecuta tras perder una vida o al empezar una partida.
; Borra	lo que hay en pantalla con una cortinilla negra	de izquierda a derecha.
; 생명을 잃거나 게임을 시작할 때 실행됩니다.
; 왼쪽에서 오른쪽으로 검은색 와이프로 화면의 내용을 지웁니다.
; Substatus = 0
;-------------------------------------------------------------------------------

InitStage:
		call	drawCortinilla
		ret	p


		call	hideSprAttrib	; Quita	sprites	de la pantalla
								; 화면에서 스프라이트 제거
		ld	hl, Vidas
		dec	(hl)		; Quita	una vida
						; 목숨을 걸다

		ld	a, (flagMuerte)
		or	a
		jr	nz, dummyJump	; (!?)

dummyJump:				; Descomprime graficos y mapa con todos	los elementos
						; 모든 요소가 포함된 차트 및 지도 압축 풀기
		call	unpackStage
		call	AI_Salidas	; Pinta	la salida abierta
							; 열린 출구를 칠하다
		call	setSprDoorProta
		call	setAttribProta	; Actualiza atributos de los sprites del prota
								; 주인공 스프라이트의 속성 업데이트
		call	updateSprites	; Actualiza attributos de los sprites (RAM->VRAM)
								; 스프라이트 속성 업데이트(RAM->VRAM)
		call	setupRoom	; Pinta	pantalla
							; 페인트 스크린
		call	renderHUD	; Dibuja el marcador, puntos, vidas
							; 마커, 포인트, 생명을 그립니다.
		ld	a, 10h
		jr	UpdateSubstatus

; Sub3:	Comienza la fase
; Sub3: 단계 시작

initStage2:
		djnz	InitStage
; Ha bajado las	escaleras y ya se ha cerrado la	puerta
; 그는 계단을 내려갔고 문은 이미 닫혀 있었다
		ld	hl, waitCounter
		dec	(hl)
		ret	nz

		xor	a
		ld	(flagStageClear), a
		call	AI_Salidas

		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		bit	6, a
		jr	z, initStage3

		ld	a, 8Bh		; Ingame music
		call	setMusic

initStage3:
		ld	hl, flagVivo
		ld	(hl), 1

NextGameStatusT:
		ld	a, 20h

NextGameStatus_:
		ld	(waitCounter), a

NextGameStatus:
		ld	hl, GameStatus
		inc	(hl)

ResetSubStatus:
		xor	a
		ld	(subStatus), a
		ret

showMap:
		djnz	doCortinilla
		ld	hl, waitCounter
		dec	(hl)
		ret	nz

		call	renderMarcador
		call	setupPergamino
		jr	initStage3

doCortinilla:
		call	drawCortinilla
		ret	p

		ld	hl, Vidas
		dec	(hl)
		ld	a, 1
		jp	UpdateSubstatus

;----------------------------------------------------
;
; Logica del juego
; 게임 논리
;
;----------------------------------------------------

gameLogic:
		ld	a, (flagPiramideMap) ; 0 = Mostrando mapa, 1 = Dentro de la piramide
								; 0 = 지도 보기, 1 = 피라미드 내부
		rra			; Esta en modo juego o mapa?
					; 게임 모드인가요, 맵 모드인가요?
		push	af
		call	c, tickGame	; Logica del juego
							; 게임 논리
		pop	af
		call	nc, tickPergamino ; Logica del pergamino
									; 양피지(?) 논리

		ld	a, (flagEndPergamino) ;	1 = Ha terminado de mostar el pergamino/mapa
									; 1 = 스크롤/지도 표시 완료
		or	a
		jr	z, chkVivo

		ld	a, 7
		ld	(GameStatus), a
		jr	NextGameStatus

chkVivo:
		ld	a, (flagVivo)
		or	a		; Esta vivo?
					; 살아있어?
		ret	nz		; Si
					; 예
		jr	NextGameStatusT	; No, pasa al siguiente	status
							; 아니요, 다음 상태로 이동합니다.

;----------------------------------------------------
;
; Pierde una vida / Muestra Game over
; 목숨을 잃다 / Show Game over
;
;----------------------------------------------------

tickMuerto:
		ld	a, (MusicChanData)
		or	a
		ret	nz		; Esta sonando la musica de muerte
					; 죽음의 음악이 흐르고 있어

		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		bit	6, a		; Esta en modo demo?
						; 데모 모드인가요?
		jr	nz, pierdeVida

		xor	a
		jp	setGameStatus	; Reinicia el juego al morir en	el modo	demo
							; 데모 모드에서 사망 시 게임 다시 시작

pierdeVida:
		ld	a, (Vidas)
		or	a
		jr	nz, setGameMode

; Borra	el area	donde se imprimira el mensaje de GAME OVER
; GAME OVER 메시지가 인쇄될 영역을 삭제합니다.
		xor	a
		ld	hl, 3929h
		ld	b, 5

clrGameOverArea:
		push	bc
		xor	a
		ld	bc, 0Ch
		call	setFillVRAM
		ld	a, 20h
		call	ADD_A_HL
		pop	bc
		djnz	clrGameOverArea

		ld	a, 9Ah		; Musica de GAME OVER
						; 게임 오버 음악
		call	setMusic

		ld	de, TXT_GameOver
		call	WriteDataVRAM	; Imprime mensaje de GAME OVER
								; GAME OVER 메시지 인쇄

		ld	a, 6
		ld	(GameStatus), a	; (!?) Para que	pone esto si en	la siguiente llamada se	cambia?
							; (!?) 다음 호출에서 변경되면 왜 이것을 넣습니까?
		ld	a, 0B8h
		jp	NextGameStatus_	; Pasa al estado de Game Over
							; 게임 오버 상태로 이동

setGameMode:
		ld	a, 4		; Empezando la partida
						; 게임 시작

setGameStatus:
		ld	(GameStatus), a
		ld	a, 20h
		ld	(waitCounter), a
		jp	ResetSubStatus

;----------------------------------------------------
;
; Logica del Game Over
; Hace una pausa suficientemente larga como para que termine la	musica
; Si se	esta pulsando alguna direccion vuelve al menu. De lo contrario muestra el logo de Konami.
; 게임 종료 로직
; 그는 음악이 끝날 때까지 충분히 오래 멈춥니다.
; 아무 주소나 누르면 메뉴로 돌아갑니다. 그렇지 않으면 Konami 로고가 표시됩니다.
;
;----------------------------------------------------

tickGameOver:
		ld	hl, timer
		ld	a, (hl)
		and	1
		ret	z		; Procesa una de cada dos iteraciones
					; 2번의 반복 중 1번 처리
		inc	hl
		dec	(hl)
		ret	nz		; Decrementa el	tiempo de espera
					; 대기 시간 줄이기

		call	chkPushAnyKey	; Comprueba si se pulsa	una tecla para volver al menu
								; 메뉴로 돌아가기 위해 키를 눌렀는지 확인

		ld	a, (GameStatus)
		cp	7		; Modo Game Over?
					; 게임 오버 모드?
		ld	de, controlPlayer ; bit	6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		jr	z, reiniciaJuego

		ld	a, (de)
		and	10111111b	; Borra	el bit 6
						; 비트 6 지우기
		ld	(de), a
		ret

reiniciaJuego:
		ld	a, (de)
		and	10111111b	; Borra	el bit 6
						; 비트 6 지우기
		ld	(de), a
		xor	a
		jr	setGameStatus	; Muestra el logo de Konami
							; Konami 로고를 표시합니다.

;----------------------------------------------------
;
; Stage	clear
;
; Silencia el sonido, incrementa la vidas y activa el pergamino
; 소리를 멈추고 생명을 늘리며 두루마리를 활성화합니다.
;
;----------------------------------------------------

stageClear:
		ld	a, 20h		; Silencio
						; 고요
		call	setMusic

		ld	hl, Vidas
		inc	(hl)		; Incrementa las vidas
						; 수명을 늘리다
		inc	hl
		ld	a, (hl)
		add	a, 1
		daa
		ld	(hl), a		; Activa pergamino/mapa
						; 스크롤/맵 활성화
		xor	a
		ld	(flagEndPergamino), a ;	1 = Ha terminado de mostar el pergamino/mapa
									; 1 = 스크롤/지도 표시 완료
		jr	setGameMode


;----------------------------------------------------
;
; Scroll de la pantalla
; Mueve	la pantalla y actualiza	la posicion del	prota
; al cambiar de	una habitacion a otra
;
; 화면 스크롤
; 한 방에서 다른 방으로 변경할 때 화면을 이동하고 주인공의 위치를 ​​업데이트
;
;----------------------------------------------------

ScrollPantalla:
		call	tickScroll
		ret	c		; No ha	terminado el scroll
					; 스크롤이 끝나지 않았다

		ld	hl, GameStatus
		ld	(hl), 5		; Modo = jugando
						; 모드 = 재생
		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
								; 1 = 왼쪽, 2 = 오른쪽
		rra
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
							; X 좌표의 상단 피라미드의 방을 나타냅니다.
		ld	c, 0F0h		; Coordena X del prota en la parte derecha de la pantalla
						; 화면 오른쪽에 있는 주인공의 X 좌표
		ld	b, a
		dec	b		; Mueve	el prota una pantalla a	la izquierda
					; 영웅을 왼쪽으로 한 화면 이동
		jr	c, scrollPantalla2
		inc	b
		inc	b		; Mueve	el prota una pantalla a	la derecha
					; 영웅을 한 화면 오른쪽으로 이동
		ld	c, 4		; Coordenada X en la parte izquierda
						; 왼쪽의 X 좌표

scrollPantalla2:
		ld	(ProtaX), bc	; Coloca al prota en la	posicion correcta
							; 주인공을 올바른 위치에 배치
		jp	setAttribProta	; Actualiza atributos de los sprites del prota
							; 주인공 스프라이트의 속성 업데이트

;----------------------------------------------------
;
; Game ending
;
;----------------------------------------------------

FinalJuego:
		jp	ShowEnding

;----------------------------------------------------
;
; Inicia una partida
;
; - Reproduce musica de	inicio de partida
; - Parpadea PLAY START
; - Inicia las variables de la partida y pasa el estado	de juego
;
; 게임 시작
;
; - 게임 시작 음악 재생
; - PLAY START가 깜박입니다.
; - 게임 변수 초기화 및 게임 상태 전달
;
;----------------------------------------------------

iniciaPartida:
		djnz	PlayIntroMusic
		ld	hl, waitCounter
		dec	(hl)
		jr	z, ComienzaPartida

		bit	2, (hl)		; Parpadea cada	4 frames
						; 4프레임마다 깜박임
		ld	de, TXT_PLAY_START
		jp	nz, ClearDataVRAM ; Borra texto
								; 텍스트 삭제

		jp	WriteDataVRAM	; Muestra "PLAY START"
							; "PLAY START" 표시

ComienzaPartida:
		call	IniciaDatosPartida
		jp	NextGameStatusT

PlayIntroMusic:
		ld	a, 97h		; Musica de incio de partida
						; 게임 시작 음악
		call	setMusic
		ld	a, 50h
		ld	(waitCounter), a
		jp	NextSubStatus


;----------------------------------------------------
;
;----------------------------------------------------

setColor:
		ld	b, 0E0h
		ld	c, 7
		jp	WRTVDP

;----------------------------------------------------
;
; Cargar graficos del logo de Konami, la fuente	y el menu
; Konami 로고, 글꼴 및 메뉴의 그래픽 업로드
;
;----------------------------------------------------

LoadIntroGfx:
		call	loadKonamiLogo	; Logo de Konami
								; 코나미 로고

		call	loadFont	; Fuente
							; 폰트

		ld	hl, 8
		ld	de, GFX_Space	; Espacio en blanco
							; 빈 공간
		call	UnpackPatterns	; Patron de espacio en blanco
								; 공백 패턴

setGfxMenu:
		ld	de, GFX_Menu	; Logo de King's Valley y piramide del menu
							; King's Valley 로고 및 메뉴 피라미드
		ld	hl, 2480h	; BG char
		call	UnpackPatterns

		ld	de, ATTRIB_Menu	; Atributos de color de	la piramide del	menu
							; 메뉴 피라미드의 색상 속성
		ld	hl, 480h	; BG Attrib
		call	UnpackPatterns

		ld	hl, 44D8h	; #4D8 = Tabla de color	del logo
						; #4D8 = 로고 색상 차트
		ld	b, 16h

coloreaLogo:
		push	bc
		push	hl
		ld	de, COLORES_LOGO ; Atributos de	color del logo de King's Valley del menu
							; King's Valley 메뉴 로고의 색상 속성
		call	UnpackPatterns
		pop	hl
		ld	bc, 10h
		add	hl, bc
		pop	bc
		djnz	coloreaLogo

		ld	a, 40h		; Color
		ld	bc, 10h		; Bytes	a rellenar
						; 채울 바이트
		jp	fillVRAM3Bank


;----------------------------------------------------
; Inicializa las variables para	una partida nueva
; 새 게임에 대한 변수 초기화
;----------------------------------------------------

IniciaDatosPartida:
		ld	hl, score_0000xx
		ld	bc, 0E7h
		ld	d, h
		ld	e, l
		inc	e
		ld	(hl), 0
		ldir

;----------------------------------------------------
;
; Inicializa los valores para una partida nueva
; 새 게임의 값 초기화
;
;----------------------------------------------------

setDatosPartida:
		ld	hl, ValoresIniciales
		ld	de, Vidas
		ld	bc, 7
		ldir
		ret
ValoresIniciales:db    5
					; Vidas
		db    1			; No muestra el	pergamino
		db    0			; Contador de vidas extra
		db    2			; Flag vivo
		db    1			; Piramide actual
		db    1			; Piramide destino
		db    8			; Direccion de la flecha
					; 생명
					; 양피지를 보여주지 않는다
					; 추가 생명 카운터
					; 라이브 플래그
					; 현재 피라미드
					; 운명의 피라미드
					; 화살표 방향

;----------------------------------------------------
;
; Carga	los graficos y prepara la piramide actual
; 차트 로드 및 현재 피라미드 준비
;
;----------------------------------------------------

unpackStage:
		call	loadGameGfx	; Carga	los graficos y sprites
							; 그래픽 및 스프라이트 로드
		jp	setupStage	; Descomprime el mapa actual
						; 현재 지도 압축 풀기

;----------------------------------------------------
; Cortinilla vertical
; 수직 블라인드
;----------------------------------------------------

drawCortinilla:
		ld	hl, timer
		dec	(hl)
		inc	hl
		dec	(hl)
		ret	m

		ld	a, (hl)
		ld	h, 38h		; #3800	es el area del BG map
						; #3800은 BG 맵의 영역입니다.
		xor	1Fh
		ld	l, a
		ld	b, 18h		; Numero de patrones a escribir	verticales
						; 세로로 쓸 패턴 수
		xor	a

drawCortinilla2:
		call	WRTVRM
		ld	de, 20h
		add	hl, de		; Siguiente columna
						; 다음 열
		djnz	drawCortinilla2


;----------------------------------------------------
; Borra	los atributos de los sprites de	la VRAM
; VRAM에서 스프라이트 속성 지우기
;----------------------------------------------------

HideSprites:
		ld	hl, 3B00h	; Sprite attribute area
						; 스프라이트 속성 영역
		ld	bc, 80h		; Numero de bytes a rellenar (32 sprites * 4 bytes)
						; 채울 바이트 수(32개의 스프라이트 * 4바이트)
		ld	a, 0C3h		; Valor	a rellenar
						; 채울 값
		call	setFillVRAM
		xor	a
		ret


;----------------------------------------------------
; Oculta los sprites colocando su coordenada Y de los
; atributos RAM	en #E1
; RAM 속성의 Y 좌표를 #E1로 설정하여 스프라이트를 숨깁니다.
;----------------------------------------------------

hideSprAttrib:
		ld	b, 20h

hideSprAttrib2:
		ld	hl, sprAttrib	; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
							; RAM의 스프라이트 속성 테이블(Y, X, Spr, Col)

hideSprAttrib3:
		ld	(hl), 0E1h
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		djnz	hideSprAttrib3
		ret

;----------------------------------------------------
; Quita	momias
; 미라를 제거하다
;----------------------------------------------------

quitaMomias:
		ld	hl, enemyAttrib
		ld	b, 0Ah
		jr	hideSprAttrib3


;----------------------------------------------------
; Dibuja los textos
; (C) KONAMI PYRAMID-xx
; El numero de la piramide se calcula:
; veces	que se ha terminado el juego * 15 + piramide actual
;
; 텍스트를 그리다
; (C) KONAMI 피라미드-xx
; 피라미드의 수는 다음과 같이 계산됩니다.
; 시간 게임 오버 * 15 + 현재 피라미드
;----------------------------------------------------

drawPyramidNumber:
		ld	de, TXT_KONAMI_PYR
		call	WriteDataVRAM
		ld	a, (numFinishGame) ; Numero de veces que se ha terminado el juego
								; 게임이 끝난 횟수
		ld	b, a
		add	a, a
		add	a, a
		add	a, a
		add	a, a
		sub	b		; x15
		ld	b, a
		ld	a, (piramideActual)
		add	a, b
		ld	hl, 3AF3h	; Coordenadas
						; 좌표
		jp	drawDigit


;----------------------------------------------------
; Dibuja el numero de vidas
; 생명의 수를 그리다
;----------------------------------------------------

dibujaVidas:
		ld	hl, 381Dh	; VRAM address name table = coordendas de las vidas
						; VRAM 주소 이름 테이블 = 생활 좌표
		ld	a, (Vidas)

drawDigit:
		call	convDecimal
		ld	b, 1
		jp	renderNumber3

;----------------------------------------------------
; Convierte un valor a decimal
; 값을 십진수로 변환
;----------------------------------------------------

convDecimal:
		ld	b, a
		sub	64h
		jr	nc, convDecimal
		ld	c, 0

convDecimal2:
		ld	a, b
		sub	0Ah
		jr	c, convDecimal3
		push	af
		ld	a, c
		add	a, 10h
		ld	c, a
		pop	af
		ld	b, a
		jr	nz, convDecimal2

convDecimal3:
		ld	a, c
		or	b
		ret


;----------------------------------------------------
; Setup	menu
;----------------------------------------------------

SetUpMenu:
		call	setGfxMenu	; Carga	los graficos del logo del menu
							; 메뉴 로고 그래픽 로드
		xor	a
		ld	(gameLogoCnt), a

loopDrawLogo:
		call	drawGameLogo
		jr	c, loopDrawLogo
		ret
;---------------------------------------------------
;
; Dibuja el logo de KING'S VALLEY del menu
; Lo hace pintando columna a columna cada palabra
;
; 메뉴에서 KING'S VALLEY 로고 그리기
; 각 단어를 열별로 페인팅하여 이를 수행합니다.
;
;---------------------------------------------------

drawGameLogo:
		ld	hl, gameLogoCnt	; Contador para	saber que parte	del logo del menu se esta pintado
							; 메뉴 로고의 어느 부분이 그려져 있는지 알 수 있는 카운터
		ld	a, (hl)
		inc	(hl)
		cp	16h		; Ha terminado de pintar KING'S VALLEY?
					; KING's VALLEY 그림을 완성하셨나요?

copyProtect_:
		jp	nc, drawMenuEnd
		ld	hl, 38A7h	; Coordenadas de KING'S
						; KING'S의 좌표
		cp	9		; Ha terminado de pintar "KING'S"?
					; "KING's" 그림은 다 완성하셨나요?
		jr	c, drawGameLogo2
		ld	hl, 3904h	; Coordenadas de VALLEY
						; VALLEY 좌표

drawGameLogo2:
		ld	c, a
		add	a, l
		ld	l, a
		ld	a, c
		add	a, a
		add	a, 9Bh		; #9B es el primer patron que forma el logo. KING'S(#9B-#AC), VALLEY(#AD-C6)
						; #9B는 로고를 형성하는 첫 번째 패턴입니다. KING'S(#9B-#AC), VALLEY(#AD-C6)
		ld	c, a
		ld	b, 2		; Numero de patrones a pintar por iteracion
						; 반복당 페인트할 패턴 수

drawGameLogo3:
		ld	a, c
		call	WRTVRM
		ld	a, 20h		; Incrementa la	coordenada Y (siguiente	fila de	patrones)
						; Y 좌표 증가(패턴의 다음 행)
		call	ADD_A_HL
		inc	c
		djnz	drawGameLogo3

		ld	a, l
		sub	0ECh		; Nametable + #EC = Parte de abajo de la G
						; 이름표 + #EC = G의 맨 아래
		cp	2
		jr	nc, drawGameLogo4
		add	a, 0C7h		; Patron parte de abajo	de la G	de KING'S
						; G of KING'S의 패턴 바닥 부분
		call	WRTVRM

drawGameLogo4:
		scf
		ret

drawMenuEnd:
		ld	de, TXT_MainMenu
		call	WriteDataVRAM	; Imprime "KONAMI 1985" y "PUSH SPACE KEY"
								; "KONAMI 1985" 및 "PUSH SPACE KEY" 인쇄

		ld	de, GFX_PiramidLogo
		ld	hl, 3892h	; Coordenadas
						; 좌표
		ld	bc, 306h	; Alto x ancho
						; 높이 x 너비
		call	DEtoVRAM_NXNY
		xor	a
		ret


;----------------------------------------------------
; Muestra informacion pantalla:	marcador, vidas
; 정보 화면 표시: 마커, 생명
;----------------------------------------------------

renderHUD:
		call	drawPyramidNumber

renderMarcador:
		ld	de, TXT_Marcador ; "REST SCORE"
		call	WriteDataVRAM
		call	dibujaVidas
		jr	renderRecord

;----------------------------------------------------
; Actualiza la puntuacion y el record
;
; DE = Puntos a	sumar
; A los	10000 puntos vida extra
; Luego	cada 20000
;
; 점수 및 기록 업데이트
;
; DE = 추가할 포인트
; 10,000포인트 추가 수명
; 그럼 매 20000
;----------------------------------------------------

SumaPuntos:
		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		add	a, a
		ret	p		; Esta en modo demo, no	suma puntos
					; 데모 모드이며 포인트를 추가하지 않습니다.

		ld	hl, score_0000xx
		ld	a, (hl)
		add	a, e
		daa
		ld	(hl), a		; Actualiza unidades/decenas
						; 단위/십 업데이트

		ld	e, a
		inc	l
		ld	a, (hl)
		adc	a, d		; Suma el acarreo de la	anterior operacion
						; 이전 작업의 캐리 추가
		daa
		ld	(hl), a		; Actualiza centenas/unidades de millar
						; 수백/천 단위 업데이트

		ld	d, a
		inc	hl
		jr	nc, setRecord	; No han cambiado la decenas de	millar
							; 그들은 만 명을 바꾸지 않았다

		ld	a, (hl)
		add	a, 1		; Incrementa decenas de	millar x0000
						; 만 x0000 증가
		daa
		ld	(hl), a
		jr	nc, chkExtraLife ; Comprueba si	obtiene	una vida extra
							; 여분의 생명을 얻을 수 있는지 확인

		ld	bc, 9999h	; Maxima puntuacion posible
						; 가능한 최고 점수
		ld	(record_0000xx), bc
		ld	(record_0000xx+1), bc ;	Recors = 999999
		jr	renderRecord

chkExtraLife:
		ld	a, (extraLifeCounter)
		cp	(hl)
		jr	nc, setRecord

		push	de
		push	hl
		add	a, 2		; Cada 20000 puntos
						; 20000포인트마다
		daa
		jr	nc, chkExtraLife2
		ld	a, 0FFh

chkExtraLife2:
		ld	(extraLifeCounter), a ;	Siguiente multiplo de 10.000 en	el que obtendra	una vida extra
									; 추가 생명을 얻게 되는 10,000의 다음 배수
		call	VidaExtra	; Suma vida extra
							; 생명을 더하다
		pop	hl
		pop	de

setRecord:
		ld	a, (record_xx0000)
		ld	b, (hl)
		sub	b
		jr	c, setRecord2	; La puntuacion	es mayor que el	record actual. Actualiza el record
							; 점수가 현재 기록보다 높습니다. 기록 업데이트

		jr	nz, renderScore	; Es menor

		ld	hl, (record_0000xx)
		sbc	hl, de
		jr	nc, renderScore

setRecord2:
		ld	(record_0000xx), de
		ld	a, b
		ld	(record_xx0000), a

renderRecord:
		ld	de, record_xx0000
		ld	hl, 3811h	; Coordenadas /	Direccion VRAM
						; 좌표 / VRAM 주소
		call	renderNumber

renderScore:
		ld	hl, 3807h	; Coordenadas /	Direccion VRAM
		ld	de, score_xx0000

renderNumber:
		ld	b, 3		; Imprime 3 pares de numeros (cada byte	son dos	numeros)
						; 3쌍의 숫자 인쇄(각 바이트는 2개의 숫자임)

renderNumber2:
		ld	a, (de)

renderNumber3:
		push	bc
		call	AL_C__AH_B	; Copia	el nibble alto de A en B y el bajo en C
							; A에서 B로 높은 니블을 복사하고 C로 낮은 니블을 복사합니다.
		ld	a, b
		add	a, 10h		; Numero de patron que corresponde con el '0'
						; '0'에 해당하는 패턴 번호
		call	WRTVRM

		inc	hl		; Incrementa la	coordenada X
					; X 좌표를 증가시킵니다.
		ld	a, c
		add	a, 10h		; Numero de patron que corresponde con el '0'
		call	WRTVRM

		dec	de		; Siguiente pareja (byte)
					; 다음 쌍(바이트)
		inc	hl		; Siguiente posicion VRAM
					; 다음 VRAM 위치
		pop	bc
		djnz	renderNumber2
		ret


;----------------------------------------------------
; Copia	el nibble alto de A en B y el bajo en C
; A에서 B로 높은 니블을 복사하고 C로 낮은 니블을 복사합니다.
;----------------------------------------------------

AL_C__AH_B:
		push	af		; Copia	el nibble alto de A en B y el bajo en C
		rra
		rra
		rra
		rra
		and	0Fh
		ld	b, a
		pop	af
		and	0Fh
		ld	c, a
		ret

;----------------------------------------------------
;
; Borra	la pantalla
;
; Oculta los sprites y borra la	tabla de nombres
;
; 화면을 지우다
;
; 스프라이트를 숨기고 이름 테이블 지우기
;
;----------------------------------------------------

clearScreen:
		call	HideSprites
		ld	hl, 7800h	; Tabla	de nombres (#3800) VRAM	= 16K #0000-#3FFF
						; 이름 테이블(#3800) VRAM = 16K #0000-#3FFF
		ld	bc, 300h	; Name table size
		xor	a

;----------------------------------------------------
; Rellena la VRAM
; HL = Direccion VRAM
; A = Dato
; BC = Numero de bytes
;
; VRAM 채우기
; HL = VRAM 주소
; A = 데이터
; BC = 바이트 수
;----------------------------------------------------

setFillVRAM:
		call	setVDPWrite

fillVRAM:
		ex	af, af'

VRAM_write2:
		ex	af, af'
		exx
		out	(c), a
		exx
		ex	af, af'
		dec	bc
		ld	a, b
		or	c
		jr	nz, VRAM_write2
		ex	af, af'
		ret

;----------------------------------------------------
; Rellena BC bytes de VRAM con el dato (DE)
; 데이터(DE)로 VRAM의 BC 바이트 채우기
;----------------------------------------------------

fillVRAM_DE:
		ld	a, (de)
		inc	de
		jr	fillVRAM

;----------------------------------------------------
;
; Transfiere datos desde la RAM	a la VRAM
; HL = Direccion de destino en la VRAM
; DE = Origen
; BC = Numero de datos
;
; RAM에서 VRAM으로 데이터 전송
; HL = VRAM의 대상 주소
; DE = 원점
; BC = 데이터 번호
;
;----------------------------------------------------

DEtoVRAMset:
		call	setVDPWrite


;----------------------------------------------------
;
; Transfiere datos desde la RAM	a la VRAM
; DE = Origen
; BC = Numero de datos
;
; RAM에서 VRAM으로 데이터 전송
; DE = 원점
; BC = 데이터 번호
;
;----------------------------------------------------

DEtoVRAM:
		ld	a, (de)
		exx
		out	(c), a
		exx
		inc	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, DEtoVRAM
		ret


;----------------------------------------------------
; Carga	la fuente y rellena la tabla de	color
; 글꼴을 로드하고 색상표를 채웁니다.
;----------------------------------------------------

loadFont:
		ld	de, GFX_Font
		ld	hl, 2080h	; Pattern generator table addres (pattern 16)
						; 패턴 생성기 테이블 주소(패턴 16)
		call	UnpackPatterns

		ld	a, 0F0h		; Color	blanco sobre negro
						; 블랙에 화이트 컬러
		ld	hl, 80h		; Color	table address (tile 16)
						; 색상표 주소(타일 16)
		ld	bc, 180h	; Numero de bytes a rellenar
						; 채울 바이트 수
fillVRAM3Bank:
		ld	d, 3

fillVRAM3Bank2:
		push	bc
		push	de
		call	setFillVRAM	; Rellena la tabla de color
							; 색상표 채우기
		ld	de, 800h	; Siguiente banco
						; 다음 은행
		add	hl, de
		pop	de
		pop	bc
		dec	d
		jr	nz, fillVRAM3Bank2
		ret
;----------------------------------------------------
;
; Descomprime datos de la tabla	de patrones o de colores
; en los tres bancos de	la pantalla
;
; 화면의 세 뱅크에 있는 패턴 또는 색상표에서 데이터 압축을 풉니다.
;
;----------------------------------------------------

UnpackPatterns:
		ld	b, 3

setPatternDatax_:
		push	bc
		push	de
		call	unpackGFX
		ld	de, 800h	; Siguiente banco
						; 다음 은행
		add	hl, de
		pop	de
		pop	bc
		djnz	setPatternDatax_
		ret


;----------------------------------------------------
; (!?) Codigo no usado!!
; (!?) 코드를 사용하지 않음!!
;----------------------------------------------------
		exx
		ld	b, 3

loc_4504:
		exx
		push	bc
		push	de
		call	DEtoVRAMset
		ld	de, 800h
		add	hl, de
		pop	de
		pop	bc
		exx
		djnz	loc_4504
		ret

;----------------------------------------------------
; DE:
; +0 DW	direccion VRAM donde descomprimir
;
; +0 압축을 풀 DW VRAM 주소
;
;----------------------------------------------------

unpackGFXset:
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ex	de, hl		; HL = Direccion de la VRAM
						; HL = VRAM 주소
		inc	de
;---------------------------------------------------------------
; Interpreta los datos graficos
;
; DE = Datos a interpretar
; HL = VRAM address
;
; +0: Numero de	veces a	repetir	un dato
; +1: Dato a repetir
;
; Si el	bit7 del numero	de veces a repetir esta	activo:
; +0: Cantidad de bytes	a transferir a VRAM
; +1: Datos a transferir
;
; 0 = Fin de datos
;
; 그래픽 데이터 해석
;
; DE = 해석할 데이터
; HL = VRAM 주소
;
; +0: ​​​​데이터 반복 횟수
; +1: 반복할 데이터
;
; 반복할 횟수의 bit7이 활성인 경우:
; +0: ​​​​VRAM으로 전송할 바이트 수
; +1: 전송할 데이터
;
; 0 = 데이터 끝
;---------------------------------------------------------------


unpackGFX:
		call	setVDPWrite

unpackGFX2:
		ld	a, (de)
		and	7Fh
		ld	c, a
		ld	a, (de)
		inc	de
		jr	nz, unpackGFX3
		cp	c
		jr	nz, unpackGFXset ; Cambia a una	nueva posicion en la VRAM
							; VRAM에서 새 위치로 변경
		ret

unpackGFX3:
		ld	b, 0
		cp	c
		push	af
		call	nz, DEtoVRAM	; Transfiere desde DE a	VRAM (BC bytes)
								; DE에서 VRAM으로 전송(BC 바이트)
		pop	af
		call	z, fillVRAM_DE
		jr	unpackGFX2

;----------------------------------------------------
; Prepara el VDP para escritura
; 쓰기를 위한 VDP 준비
;----------------------------------------------------

setVDPWrite:
		ex	af, af'
		call	SETWR
		exx
		ld	a, (byte_6)
		ld	c, a
		exx
		ex	af, af'
		ret


;----------------------------------------------------
;(!?) Codigo no	usado
;(!?) 사용하지 않는 코드
;----------------------------------------------------
		call	SETRD		; Prepara el VDP para lectura
							; 읽을 수 있도록 VDP 준비
		exx
		ld	a, (byte_7)
		ld	c, a
		exx
		ret

;----------------------------------------------------
; Invierte un sprite
; HL = Direccion VRAM original
; DE = Direccion VRAM invertido
;
; 스프라이트 뒤집기
; HL = 원래 VRAM 주소
; DE = VRAM 주소 반전
;----------------------------------------------------

flipSprites:
		push	de

flipSprite2:
		ld	b, 10h

flipSprite3:
		call	InviertePatron
		inc	hl
		inc	e
		djnz	flipSprite3

		ld	a, e
		sub	20h
		ld	e, a
		bit	4, e
		jr	z, flipSprite2

		pop	de
		ld	a, 20h
		call	ADD_A_DE
		dec	c
		jr	nz, flipSprites
		ret

;----------------------------------------------------
; Invierte patrones
; HL = Direccion VRAM patrones originales
; DE = Direccion VRAM patrones invertido
; C = Numero de	patrones a invertir
;
; 반전 패턴
; HL = 원래 패턴 VRAM 주소
; DE = 패턴 VRAM 주소 반전
; C = 반전할 패턴의 수
;----------------------------------------------------

FlipPatrones:
		ld	b, 3		; Numero de bancos de tiles
						; 타일 ​​뱅크 수
flipPatron2:
		push	bc
		push	hl
		push	de

flipPatron3:
		ld	b, 8

flipPatron4:
		call	InviertePatron
		inc	hl
		inc	de
		djnz	flipPatron4
		dec	c
		jr	nz, flipPatron3
		pop	hl
		ld	de, 800h	; Distancia al siguiente banco
						; 다음 은행까지의 거리
		add	hl, de
		ex	de, hl
		pop	hl
		pop	bc
		djnz	flipPatron2
		ret

;----------------------------------------------------
; Invierte un byte
; In: A	= Byte a invertir
; Out: A = byte	invertido
;
; 바이트를 반전
; 입력: A = 반전할 바이트
; 출력: A = 반전된 바이트
;----------------------------------------------------

invierteByte:
		push	bc
		ld	c, a
		ld	b, 8

invierteByte2:
		rr	c
		rla
		djnz	invierteByte2
		pop	bc
		ret


;----------------------------------------------------
; Invierte un patron en	la VRAM
; HL = Direccion patron	original
; DE = Direccion patron	invertido
;
; VRAM에서 패턴 반전
; HL = 원래 패턴 주소
; DE = 패턴 방향 반전
;----------------------------------------------------

InviertePatron:
		call	RDVRM
		call	invierteByte
		ex	de, hl
		call	WRTVRM
		ex	de, hl
		ret


;----------------------------------------------------
; Inicializa el	hardware
; Silencia el PSG, borra la VRAM y pone	el modo	de video
;
; 하드웨어 초기화
; PSG 음소거, VRAM 지우기 및 비디오 모드 설정
;----------------------------------------------------

initHardware:
		ld	a, 10111000b
		call	SetPSGMixer

		ld	a, 20h		; Silencio
		call	setMusic

		ld	de, 0		; (!?) No tendr�a que ser HL? Aunque la proteccion anticopia use DE, la rutina "setFillVRAM" usa HL
						; (!?) HL이 아니어야 합니까? 복사 방지는 DE를 사용하지만 "setFillVRAM" 루틴은 HL을 사용합니다.
		ld	bc, 4000h
		xor	a
		call	VRAM_writeAC

;----------------------------------------------------
;
; Modo de video:
;
; Screen 2
; Sprites 16x16	unzoomed
; Pattern name table = #3800-#3AFF
; Pattern color	table =	#0000-#17FF
; Pattern generator table = #2000-#37FF
; Sprite atribute table	= #3b00-#3B7F
; Sprite generator table = #1800-#1FFF
; Background color = #E4 (Gris/Azul)
;
; 비디오 모드:
;
; 화면 2
; 확대되지 않은 16x16 스프라이트
; 패턴명 테이블 = #3800-#3AFF
; 패턴 색상표 = #0000-#17FF
; 패턴 생성기 테이블 = #2000-#37FF
; 스프라이트 속성 테이블 = #3b00-#3B7F
; 스프라이트 생성기 테이블 = #1800-#1FFF
; 배경 색 = #E4 (그레이 블루)
;----------------------------------------------------

SetVideoMode:
		ld	hl, VDP_InitData
		ld	d, 8
		ld	c, 0

setVideoMode2:
		ld	b, (hl)
		call	WRTVDP
		inc	hl
		inc	c
		dec	d
		jr	nz, setVideoMode2
		ret

VDP_InitData:	db 2
		db 0E2h
		db 0Eh
		db 7Fh
		db 7
		db 76h
		db 3
		db 0E4h


;----------------------------------------------------
;
; Actualiza el estado de los controles
; 컨트롤 상태 업데이트
;
;----------------------------------------------------

chkControls:
		ld	hl, controlPlayer ; bit	6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		bit	6, (hl)
		jr	nz, UpdateKeys	; No esta en modo demo
							; 데모 모드가 아닙니다.

		ld	a, (GameStatus)
		cp	5
		jr	nz, UpdateKeys	; No esta en modo de juego
							; 게임모드가 아닙니다

ReplaySavedMov:
		call	ControlProtaDemo ; Lee los movimientos grabados	de la demo
								; 데모의 녹음된 움직임 읽기
		jr	storeControls	; Actualiza el valor de	los controles
							; 컨트롤 값 업데이트

UpdateKeys:
		call	ReadKeys	; Lee el estado	de los cursores	y el joystick
							; 커서와 조이스틱의 상태 읽기

storeControls:
		ld	hl, KeyHold	; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha, #10 = Boton A, #20	=Boton B
						; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B

StoreKeyValues:
		ld	c, (hl)		; Lee valores anteriores
						; 이전 값 읽기
		ld	(hl), a		; Guarda los nuevos en KeyHold
						; KeyHold에 새 항목 저장
		xor	c		; Borra	las teclas que siguen pulsadas
					; 여전히 누르고 있는 키 지우기
		and	(hl)		; Se queda con las que se acaban de pulsar
						; 그것은 방금 눌린 것들과 함께 남아 있습니다.
		dec	hl
		ld	(hl), a		; Lo guarda en KeyTrigger
						; KeyTrigger에 저장
		ret



;---------------------------------------------------------------------------
; Lee el estado	de los cursores	y del joystick
; 0: Arriba
; 1: Abajo
; 2: Izquierda
; 3: Derecha
; 4: Boton A / Space
; 5: Boton B / Select
;
; 커서와 조이스틱의 상태 읽기
; 0: 위
; 1: 아래
; 2: 왼쪽
; 3: 오른쪽
; 4: A / 스페이스 버튼
; 5: B / 선택 버튼
;---------------------------------------------------------------------------

ReadKeys:
		ld	e, 8Fh
		ld	a, 0Fh		; I/O port B
		call	WRTPSG		; Write	PSG
		ld	a, 0Eh
		di
		call	RDPSG		; Lee el estado	del joystick
							; 조이스틱 상태 읽기
		ei
		cpl
		and	3Fh

		push	af
		ld	a, 7
		call	SNSMAT		;  Read	keyboard row
		cpl
		rrca
		and	20h
		ld	e, a		; SELECT

		ld	a, 8
		call	SNSMAT		;  Read	keyboard row
		cpl
		rrca
		rrca
		ld	b, a
		and	4
		or	e
		ld	c, a
		ld	a, b
		rrca
		rrca
		ld	b, a
		and	18h
		or	c
		ld	c, a
		ld	a, b
		rrca
		and	3
		or	c
		pop	bc
		or	b
		ret


;----------------------------------------------------
; Interpreta la	secuencia de pulsaciones grabada para la demo
; 데모용으로 녹음된 비트 시퀀스 재생
;----------------------------------------------------

ControlProtaDemo:
		ld	hl, KeyHoldCntDemo
		dec	(hl)		; decrementa tiempo de la pulsacion
						; 펄스 시간 감소
		ld	b, (hl)

		ld	hl, (keyPressDemo) ; Puntero a los controles grabados
								; 기록된 컨트롤에 대한 포인터
		ld	a, (hl)		; Controles pulsados
						; 컨트롤 누름

		push	af
		ld	a, b
		or	a
		jr	nz, controlDemo2 ; Aun sigue la	tecla apretada
							; 키가 여전히 눌려져 있습니다

		inc	hl
		ld	a, (hl)		; Tiempo que hay que mantener las nuevas pulsaciones
						; 새로운 맥동을 유지할 시간
		cp	0FFh		; Ha terminado la demo?
						; 데모가 끝났습니까?
		jr	nz, controlDemo1

		xor	a
		ld	(flagVivo), a	; Fin de la demo
							; 데모 끝
		jr	controlDemo2

controlDemo1:
		ld	(KeyHoldCntDemo), a ; Actualiza	el tiempo de pulsacion
								; 펄스 시간 업데이트
		inc	hl
		ld	(keyPressDemo),	hl ; Puntero a los controles grabados
								; 기록된 컨트롤에 대한 포인터

controlDemo2:
		pop	af
		ret
;----------------------------------------------------------------------------
;
; Funcion que comprueba	si se pulsa una	tecla mientras no se esta jugando
; Si se	pulsa, salta al	menu
; Si ya	estaba en el menu comienza una partida.
;
; 연주하지 않을 때 키가 눌렸는지 확인하는 기능
; 누르면 메뉴로 이동
; 메뉴에 이미 있었다면 게임을 시작하십시오.
;
;----------------------------------------------------------------------------

chkPushAnyKey:
		call	ReadKeys_AC	; (!?) Cuidado
							; (!?) 조심해
		ld	hl, KeyHold2
		call	StoreKeyValues
		or	a
		ret	z		; No se	ha pulsado ninguna tecla
					; 키를 누르지 않음

		push	af
		ld	a, 20h		; Silencio
		call	setMusic
		pop	af

		ld	b, a
		xor	a
		ld	(waitCounter), a
		ld	a, 1		; Status menu
		ld	hl, GameStatus
		cp	(hl)
		jr	z, StartGame_0	; Si esta en el	menu comienza una partida
							; 메뉴에 있으면 게임을 시작하십시오.

		ld	(hl), a		; Pone status de menu
						; 메뉴 상태 설정
		call	clearScreen
		call	setColor
		jp	SetUpMenu

StartGame_0:
		ld	a, b
		and	30h
		ret	z		; No ha	pulsado	el disparo 1 o 2
					; 샷 1 또는 2를 누르지 않았습니다.

		ld	hl, controlPlayer ; bit	6 = Prota controlado por el jugador
							; 비트 6 = 플레이어 제어 Prota
		set	6, (hl)		; Control manual
		ld	hl, 3		; Game start status
		ld	(GameStatus), hl ; Status parpadea PUSH	START
							; 상태 깜박임 PUSH START
		ret


;----------------------------------------------------
; Graficos de la fuente
; 글꼴 그래픽
;----------------------------------------------------
GFX_Font:	db 8Bh,	0, 1Ch,	22h, 63h, 63h, 63h, 22h, 1Ch, 0, 18h, 38h, 4, 18h, 0CEh, 7Eh
		db 0, 3Eh, 63h,	3, 0Eh,	3Ch, 70h, 7Fh, 0, 3Eh, 63h, 3, 0Eh, 3, 63h, 3Eh
		db 0, 0Eh, 1Eh,	36h, 66h, 66h, 7Fh, 6, 0, 7Fh, 60h, 7Eh, 63h, 3, 63h, 3Eh
		db 0, 3Eh, 63h,	60h, 7Eh, 63h, 63h, 3Eh, 0, 7Fh, 63h, 6, 0Ch, 18h, 18h,	18h
		db 0, 3Eh, 63h,	63h, 3Eh, 63h, 63h, 3Eh, 0, 3Eh, 63h, 63h, 3Fh,	3, 63h,	3Eh
		db 3Ch,	42h, 99h, 0A1h,	0A1h, 99h, 42h,	3Ch, 18h, 3Ch, 18h, 8, 10h, 27h, 0, 1
		db 7Eh,	4, 0, 0C1h, 1Ch, 36h, 63h, 63h,	7Fh, 63h, 63h, 0, 7Eh, 63h, 63h, 7Eh
		db 63h,	63h, 7Eh, 0, 3Eh, 63h, 60h, 60h, 60h, 63h, 3Eh,	0, 7Ch,	66h, 63h, 63h
		db 63h,	66h, 7Ch, 0, 7Fh, 60h, 60h, 7Eh, 60h, 60h, 7Fh,	0, 7Fh,	60h, 60h, 7Eh
		db 60h,	60h, 60h, 0, 3Eh, 63h, 60h, 67h, 63h, 63h, 3Fh,	0, 63h,	63h, 63h, 7Fh
		db 63h,	63h, 63h, 0, 3Ch, 5, 18h, 83h, 3Ch, 0, 1Fh, 4, 6, 8Bh, 66h, 3Ch
		db 0, 63h, 66h,	6Ch, 78h, 7Ch, 6Eh, 67h, 0, 6, 60h, 93h, 7Fh, 0, 63h, 77h
		db 7Fh,	7Fh, 6Bh, 63h, 63h, 0, 63h, 73h, 7Bh, 7Fh, 6Fh,	67h, 63h, 0, 3Eh, 5
		db 63h,	0A3h, 3Eh, 0, 7Eh, 63h,	63h, 63h, 7Eh, 60h, 60h, 0, 3Eh, 63h, 63h, 63h
		db 6Fh,	66h, 3Dh, 0, 7Eh, 63h, 63h, 62h, 7Ch, 66h, 63h,	0, 3Eh,	63h, 60h, 3Eh
		db 3, 63h, 3Eh,	0, 7Eh,	6, 18h,	1, 0, 6, 63h, 82h, 3Eh,	0, 4, 63h
		db 0A4h, 36h, 1Ch, 8, 0, 63h, 63h, 6Bh,	6Bh, 7Fh, 77h, 22h, 0, 63h, 76h, 3Ch
		db 1Ch,	1Eh, 37h, 63h, 0, 66h, 66h, 7Eh, 3Ch, 18h, 18h,	18h, 0,	7Fh, 7,	0Eh
		db 1Ch,	38h, 70h, 7Fh, 0, 3, 24h, 4, 0,	0

; Grafico del espacio en blanco
; 공백 그래픽
GFX_Space:	db 8
		db 0FFh
		db    0


;----------------------------------------------------
; Textos del marcador
; Formato:
; - Coordenadas/direccion VRAM (2 bytes)
; - Patrones
; - #FE	= Leer nuevas coordenadas y datos
; - #FF	= Fin
;
; 마커 텍스트
; 형식:
; - VRAM 좌표/주소(2바이트)
; - 패턴
; - #FE = 새 좌표 및 데이터 읽기
; - #FF = 끝
;----------------------------------------------------
TXT_Marcador:	dw 3818h
		db  32h, 25h, 33h, 34h,	20h ; REST
		db 0FEh


		dw 3801h
		db 33h,	23h, 2Fh, 32h, 25h, 20h	; SCORE
		db 0FEh


		dw 380Eh
		db 28h,	29h, 20h	; HI
		db 0FFh


;----------------------------------------------------
; Textos del menu principal
; "KONAMI 1985"
; "PUSH SPACE KEY"
;
; 메인 메뉴 텍스트
; "코나미 1985"
; "푸시 스페이스 키"
;----------------------------------------------------
TXT_MainMenu:	dw 39AAh
		db 1Ah,	2Bh, 2Fh, 2Eh, 21h, 2Dh, 29h, 0, 11h, 19h, 18h,	15h ; KONAMI 1985
		db 0FEh


		dw 3A49h
		db 30h,	35h, 33h, 28h, 0, 33h, 30h, 21h, 23h, 25h, 0, 2Bh, 25h,	39h ; PUSH SPACE KEY
		db 0FFh

;----------------------------------------------------
; Texto	"PLAY START"
;----------------------------------------------------
TXT_PLAY_START:	dw 3A49h
		db 0, 0, 30h, 2Ch, 21h,	39h, 0 ; PLAY


		db 33h,	34h, 21h, 32h, 34h, 0, 0 ; START
		db 0FFh

;----------------------------------------------------
; Mensaje de "GAME OVER"
; "게임 종료" 메시지
;----------------------------------------------------
TXT_GameOver:	dw 396Bh
		db  27h, 21h, 2Dh, 25h,	  0, 2Fh, 36h, 25h, 32h	; GAME OVER
		db 0FFh


TXT_Sofware:	dw 394Ah
		db 0Ch			; Longitud linea subrayado
						; 밑줄 길이
		db 7Ah			; Patron de subrayado
						; 밑줄 패턴
		db 16h			; Numero de espacios (para cuadrar SOFWARE debajo de la	raya)
						; 공백 수(줄 아래 SOFWARE에 맞도록)
		db 0			; Patron vacio
						; 빈 패턴
		db 88h			; Transferir 8 bytes a la posicion VRAM	actual
						; 현재 VRAM 위치로 8바이트 전송
		db 33h,	2Fh, 26h, 34h, 37h, 21h, 32h, 25h ; texto:SOFTWARE
		db 0			; Fin de los datos
						; 데이터의 끝

;----------------------------------------------------
; Texto	informacion "(C)KONAMI" "PYRAMID-"
;----------------------------------------------------
TXT_KONAMI_PYR:	dw 3AE1h
		db  1Ah			; (C)
		db 2Bh,	2Fh, 2Eh, 21h, 2Dh, 29h	; KONAMI
		db 0FEh			; Cambio de coordenadas
						; 좌표 변경

		dw 3AEBh		; Coordenadas
						; 좌표
		db 30h,	39h, 32h, 21h, 2Dh, 29h, 24h, 20h ; texto: PYRAMID-
		db 0FFh


;----------------------------------------------------
;
; Descomprime los patrones que forman el logo de Konami
; y los	colorea	de blanco
;
; Konami 로고를 구성하는 패턴의 압축을 풀고 흰색으로 칠하십시오.
;
;----------------------------------------------------

loadKonamiLogo:
		ld	a, 0Eh
		ld	(gameLogoCnt), a ; Filas que sube el logo
							; 위로 올라가는 행 로고

		ld	hl, 3AAAh	; Coordenadas iniciales	del logo
						; 로고의 초기 좌표
		ld	(CoordKonamiLogo), hl

		ld	de, GFX_KonamiLogo
		ld	hl, 6300h	; #2300	Pattern	generator table	= Patter #60
		call	UnpackPatterns

		ld	hl, 300h	; Direccion de los atributos de	color del logo
						; 로고 색상 속성의 방향
		ld	bc, 0D8h	; Tama�o
						; 크기
		ld	a, 0F0h		; Blanco
						; 하얀색
		jp	fillVRAM3Bank	; Colorea el logo
							; 색상 로고



;----------------------------------------------------
;
; Dibuja el logo de Konami y lo	desplaza hacia arriba
;
; El logo esta formado por tres	filas:
; - Parte superior de la "K"
; - Parte central del logo
; - Parte inferior
;
; Konami 로고를 그리고 위로 이동
;
; 로고는 세 개의 행으로 구성됩니다.
; - "K"의 상단
; - 로고 중앙 부분
; - 맨 아래
;----------------------------------------------------

dibujaLogo:
		ld	hl, (CoordKonamiLogo)
		ld	de, -20h
		add	hl, de
		ld	(CoordKonamiLogo), hl ;	Lo desplaza hacia arriba una fila
								; 한 행 위로 이동합니다.

		ld	a, 60h		; Primer patron	del logo de Konami
						; Konami 최초의 로고 패턴
		ld	b, 3		; Tres patrones	de la parte alta de la "K"
						; "K"의 상단에서 세 가지 패턴
		call	drawLogoRow	; Dibuja fila superior
							; 맨 위 행 그리기

		ld	bc, 0B0Ch
		call	drawLogoRow	; Dibuja fila central
							; 중간 행 그리기

		ld	b, c
		call	drawLogoRow	; Dibuja fila inferior
							; 맨 아래 행 그리기

		xor	a
		call	setFillVRAM	; Borra	rasto inferior
							; 지하 슬러지
		ld	hl, gameLogoCnt
		dec	(hl)		; Decrementa el	numero de iteraciones restantes
						; 남은 반복 횟수를 줄입니다.
		ret

;----------------------------------------------------
; Dibuja una fila del logo y desplaza el puntero a la siguiente	fila
;
; A = Patron inicial de	la fila
; B = Numero de	patrones a dibujar
;
; 로고의 행을 그리고 포인터를 다음 행으로 이동
;
; A = 초기 행 패턴
; B = 그릴 패턴의 수
;----------------------------------------------------

drawLogoRow:
		push	hl

drawLogoRow2:
		call	WRTVRM
		inc	hl
		inc	a
		djnz	drawLogoRow2
		pop	de
		ld	hl, 20h
		add	hl, de		; Siguiente fila del logo
						; 로고의 다음 행
		ret

;----------------------------------------------------
;
; Graficos del logo de Konami
;
; 코나미 로고 그래픽
;
;----------------------------------------------------
GFX_KonamiLogo:	db 0Fh,	0, 1, 1, 6, 0, 82h, 0FFh, 0FEh,	8, 0Fh,	84h, 0C3h, 0C7h, 0CFh, 0DFh
		db 3, 0FFh, 89h, 0FEh, 0FCh, 0F8h, 0F0h, 0E0h, 0C0h, 80h, 7, 7,	5, 0, 83h, 3
		db 0CFh, 0DFh, 5, 0, 83h, 0E1h,	0F9h, 7Dh, 5, 0, 83h, 0EFh, 0FFh, 0F7h,	5, 0
		db 83h,	7, 8Fh,	9Eh, 5,	0, 83h,	0F0h, 0F8h, 78h, 5, 0, 83h, 0F7h, 0FFh,	0FBh
		db 5, 0, 8Bh, 8Fh, 0DFh, 0F7h, 0Ch, 1Eh, 1Eh, 0Ch, 0, 1Eh, 9Eh,	9Eh, 8,	0Fh
		db 90h,	0FFh, 0FFh, 0DFh, 0CFh,	0C7h, 0C3h, 0C1h, 0C0h,	7, 87h,	0C7h, 0EFh, 0FFh, 0FFh,	0FFh
		db 0FCh, 4, 0DEh, 84h, 9Eh, 9Fh, 0Fh, 3, 5, 3Dh, 83h, 7Dh, 0F9h, 0E1h, 8, 0E3h
		db 90h,	0DCh, 0C0h, 0C7h, 0DEh,	0DCh, 0DEh, 0CFh, 0C3h,	3Ch, 7Ch, 0FCh,	3Ch, 3Ch, 7Ch, 0FCh
		db 0DEh, 8, 0F1h, 8, 0E3h, 8, 0DEh, 88h, 38h, 44h, 0BAh, 0AAh, 0B2h, 0AAh, 44h,	38h
		db 3, 0, 1, 0FFh, 4, 0,	0


;----------------------------------------------------
;
; Grafico del logo de King's Valley y piramide del menu
;
; King's Valley 로고 그래픽 및 메뉴 피라미드
;
;----------------------------------------------------
GFX_Menu:	db 0ACh, 0, 3, 7, 0, 1Fh, 3Fh, 7Fh, 0, 0, 3, 7,	0Fh, 0,	0, 0
		db 0FFh, 0, 0FFh, 0FFh,	0FFh, 0, 0, 1, 0FFh, 1,	3, 1, 0Eh, 3, 3Eh, 7
		db 0FCh, 0Fh, 0FCh, 0F8h, 1Fh, 0F0h, 0F0h, 0E0h, 3Fh, 7Fh, 0C0h, 0C0h, 80h, 4, 0FFh, 94h
		db 80h,	0C0h, 0E0h, 0, 0F8h, 0,	0FEh, 0, 0FFh, 0, 0, 0FFh, 0, 0, 0, 0FFh
		db 80h,	0, 0, 0F0h, 3, 0, 2, 0FFh, 3, 0, 4, 0FFh, 8Dh, 80h, 0, 0
		db 0, 0F8h, 0FCh, 0FEh,	0FFh, 3Fh, 6Fh,	37h, 17h, 0Fh, 9, 7, 97h, 0Fh, 1Fh, 0C7h
		db 83h,	7, 0Eh,	3Ch, 0F8h, 0F0h, 7Ch, 1Eh, 1Eh,	0Eh, 0Fh, 0Fh, 0Fh, 8Fh, 0C7h, 87h
		db 0Fh,	7, 0, 0Fh, 8, 7, 88h, 87h, 0EFh, 0CFh, 0, 80h, 0, 1Fh, 9Eh, 3
		db 0Fh,	6, 0Eh,	89h, 8Fh, 9Fh, 0, 0, 0,	78h, 0FCh, 0DEh, 8Eh, 7, 0Eh, 89h
		db 1Fh,	0BFh, 0, 0, 0, 0Fh, 1Fh, 38h, 30h, 4, 60h, 8Eh,	70h, 70h, 3Fh, 1Fh
		db 0Fh,	0, 0, 0, 0F9h, 0F3h, 0F3h, 71h,	70h, 71h, 3, 70h, 3, 0F0h, 0ADh, 0E0h
		db 0, 0, 3, 8Fh, 0DEh, 0DFh, 8Fh, 87h, 1, 0, 38h, 1Ch, 3Eh, 3Fh, 1Fh, 0Fh
		db 0, 0, 0F0h, 0FCh, 0Eh, 6, 0C0h, 0F0h, 0F8h, 7Ch, 1Ch, 1Eh, 3Eh, 0FEh, 0FCh, 0F8h
		db 7Fh,	0F1h, 7Bh, 11h,	7, 1Fh,	7, 7, 3, 3, 1, 1, 4, 0,	0A9h, 0C3h
		db 8Fh,	3Bh, 61h, 1, 3,	3, 86h,	86h, 0CCh, 0D8h, 0F8h, 0F0h, 0F0h, 60h,	60h, 8Fh
		db 0DBh, 0DFh, 87h, 8Eh, 0Eh, 1Fh, 1Eh,	38h, 30h, 30h, 74h, 7Ch, 7Ch, 3Ch, 18h,	0FEh
		db 0F3h, 77h, 3Eh, 7Ch,	0FCh, 9Eh, 1Eh,	1Eh, 3,	0Fh, 3,	7, 83h,	0Fh, 7,	3
		db 9, 1, 86h, 3, 87h, 8Ch, 0CDh, 0E7h, 0E0h, 6,	0C0h, 3, 0C3h, 88h, 0E1h, 0C0h
		db 8Eh,	3Fh, 0FFh, 0FFh, 0Fh, 7, 8, 3, 87h, 83h, 87h, 0CFh, 0C8h, 0CBh,	8Fh, 0C0h
		db 6, 80h, 3, 86h, 0AEh, 0C3h, 81h, 1Dh, 7Fh, 0FFh, 0FFh, 3Fh, 1Fh, 0Fh, 0Fh, 0Fh
		db 0Eh,	0Dh, 0Dh, 0Eh, 0Fh, 0Fh, 0Fh, 8Fh, 9Fh,	0BFh, 1Fh, 0FFh, 7, 1Eh, 38h, 60h
		db 0C0h, 18h, 7Ch, 0CCh, 0, 0, 1, 83h, 0FFh, 0FFh, 0FEh, 3Fh, 73h, 2Fh,	0Fh, 7
		db 3, 1, 1, 4, 0, 8Ch, 80h, 80h, 1, 3, 8Fh, 7Bh, 3, 87h, 0CEh, 0DCh
		db 0F8h, 0F8h, 6, 0F0h,	85h, 0F8h, 0FCh, 80h, 0C0h, 80h, 0Eh, 0, 84h, 60h, 70h,	3Fh
		db 3Fh,	3, 0, 85h, 70h,	70h, 0F0h, 0E0h, 0C0h, 3, 0, 0


;----------------------------------------------------
; Atributos de la piramide del menu
; 메뉴 피라미드의 속성
;----------------------------------------------------
ATTRIB_Menu:	db 1Ch,	0E0h, 88h, 0F0h, 0E0h, 0F0h, 0E0h, 0F0h, 0E0h
		db 0E0h, 0F0h, 3, 0E0h,	2, 0F0h, 3, 0E0h, 2Ch, 0F0h, 0

;----------------------------------------------------
;
; Colores del logo KING'S VALLEY
;
; KING'S VALLEY 로고 색상
;
;----------------------------------------------------
COLORES_LOGO:	db 3, 60h, 8Dh,	80h, 80h, 90h, 90h, 0A0h, 0B0h,	0E0h, 30h
		db 70h,	50h, 50h, 40h, 40h, 0


;----------------------------------------------------
;
; Tabla	de nombres de la piramide del menu
; 메뉴 피라미드의 이름 표
;
;----------------------------------------------------
GFX_PiramidLogo:db    0,   0, 93h, 96h,	  0,   0
		db    0, 90h, 94h, 97h,	98h,   0
		db  91h, 92h, 95h, 99h,	99h, 9Ah

;----------------------------------------------------
;
; Pulsaciones de teclas	de la demo
;
; 데모 키 입력
;
;----------------------------------------------------
DemoKeyData:	db    8, 98h
		db    6, 38h
		db    8, 68h
		db    5,   8
		db  14h, 80h
		db    4,   8
		db  14h, 48h
		db    8, 48h
		db    5, 30h
		db    8, 40h
		db    5, 30h
		db    8, 40h
		db    5, 90h
		db    9, 38h
		db    4,   8
		db  14h, 68h
		db    4,   8
		db  14h, 10h
		db    4,   8
		db  14h, 48h
		db    8, 48h
		db    5,0A0h
		db    9,   8
		db  18h, 40h
		db    8,   8
		db  18h, 90h
		db    9, 48h
		db    4, 58h
		db    8,   8
		db  18h, 80h
		db    6,0FFh


;----------------------------------------------------
;
; Logica del juego (jugando)
;
; 게임 논리(재생)
;
;----------------------------------------------------

tickGame:
		ld	hl, flagStageClear
		ld	a, (hl)
		or	a		; Ha cogido todas la gemas?
					; 보석을 모두 가져갔습니까?
		jr	z, tickGame2	; No

		ld	a, (musicCh1)
		ld	b, a
		ld	a, (musicCh2)
		or	b		; Esta sonando algo?
					; 뭔가 울리나요?
		jr	nz, tickGame2	; Si

		ld	(hl), a
		ld	a, 8Bh		; Ingame music
		call	setMusic	; Hace sonar de	nuevo la musica	del juego tras la fanfarria de fase completada
							; 스테이지 완료 팡파르 후 게임 내 음악을 다시 재생합니다.

tickGame2:
		call	updateSprites	; Actualiza los	sprites	RAM->VRAM
								; 스프라이트 RAM->VRAM 업데이트
		call	chkScroll	; Comprueba si el prota	se sale	de la pantalla e indica	que hay	que hacer scroll
							; 주인공이 화면을 떠나 스크롤해야 함을 나타내는지 확인하십시오.
		call	drawBrilloGemas	; Cambia el color del brillo de	las gemas y de la palanca de la	puerta
								; 보석의 반짝임과 문의 레버 색상 변경

		ld	a, (flagEntraSale) ; 1 = Entrando o saliendo de	la piramide. Ejecuta una logica	especial para este caso
							; 1 = 피라미드에 들어가거나 나가는 것. 이 경우에 대해 특수 논리 실행
		and	a		; Esta entrando	o saliendo de la piramide?
					; 당신은 피라미드에 들어가고 있습니까, 아니면 떠나고 있습니까?
		jp	nz, escalerasEntrada ; Ejecuta logica especial para este caso
								; 이 경우에 특수 논리 실행

		call	chkPause	; Comprueba si se pausa	el juego o ya esta pausado
							; 게임이 일시 중지되었거나 이미 일시 중지되었는지 확인합니다.
		call	AI_Momias	; Mueve	a las momias
							; 미라를 움직여라
		call	AI_Gemas	; Si se	coge una se borra de la	pantalla y del mapa
							; 잡히면 화면과 지도에서 삭제
		call	AI_Prota	; Logica del prota
							; 주인공의 논리
		call	AI_Cuchillos	; Logica de los	cuchillos
								; 칼의 논리
		call	chkCogeKnife	; Comprueba si el prota	coge un	cuchillo del suelo
								; 주인공이 땅에서 칼을 집는지 확인
		call	chkCogeGema	; Comprueba si el prota	coge una gema
							; 주인공이 보석을 가져가는지 확인
		call	AI_Salidas	; Logica de las	puertas	de la piramide
							; 피라미드 문의 논리
		call	MurosTrampa	; Logica de los	muros trampa que se cierran al pasar el	prota
							; 주인공이 지나가면 닫히는 함정 벽의 논리
		call	chkCogePico	; Comprueba si el prota	coge un	pico
							; 주인공이 곡괭이를 들고 있는지 확인
		call	chkTocaMomia	; Comprueba si el prota	toca a una momia
								; 주인공이 미라를 만지는지 확인
		call	spiningDoors	; Logica de las	puerta giratorias
								; 회전문 논리

; Comprueba si se suicida pulsando F2
; F2를 눌러 자살 여부를 확인하십시오.

		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
								; 비트 6 = 플레이어 제어 Prota
		bit	6, a
		ret	z		; Esta en modo demo, no	comprueba si se	suicida	pulsado	F2
					; 데모 모드이며 F2를 눌러 자살 여부를 확인하지 않습니다.

		ld	a, 6		; Si se	pulsa F2 se suicida
						; F2를 누르면 스스로 죽습니다.
		call	SNSMAT		;  Read	keyboard row
		cpl
		bit	6, a		; F2 key
		jr	z, doNothing2

		xor	a
		ld	(flagVivo), a
		inc	a
		ld	(flagMuerte), a
		ld	a, 1Dh		; Musica muerte
						; 죽음의 음악
		call	setMusic

doNothing2:
		ret

;-----------------------------------------------------------------------------------------------------------
;
; Actualiza los	atributos de los sprites RAM ->	VRAM
; Al prota y al	cacho de puerta	los pinta siempre en los mismos	planos
; A los	enemigos los cambia de plano para evitar que desaparezcan si coinciden mas de 5	sprites	en la misma Y
;
; 스프라이트 속성 업데이트 RAM -> VRAM
; 주인공과 문 조각은 항상 같은 평면에 그려져 있습니다.
; 5개 이상의 스프라이트가 동일한 Y에서 일치하는 경우 적들이 사라지는 것을 방지하기 위해 평면을 변경합니다.
;
;-----------------------------------------------------------------------------------------------------------

updateSprites:
		ld	de, sprAttrib	; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
							; RAM의 스프라이트 속성 테이블(Y, X, Spr, Col)
		ld	hl, 3B00h	; Tabla	de atributos de	los sprites
						; 스프라이트 속성 테이블
		ld	bc, 18h		; 6 sprites (6*4)
						; 6 스프라이트(6*4)
		call	DEtoVRAMset

		ld	hl, offsetPlanoSpr ; Contador que modifica el plano en el que son pintados los sprites,	asi se consigue	que parpaden en	vez de desaparecer
								; 스프라이트가 그려지는 평면을 수정하여 사라지지 않고 깜박이도록 하는 카운터
		inc	(hl)		; Incrementa el	desplazamiento de plano	de los enemigos
						; 적의 평면 변위 증가
		ld	a, (hl)
		and	3		; Rango	de 0-3 (4 enemigos max.)
					; 0-3 범위(최대 4명의 적)
		ld	c, a		; C = indice de	desplazamiento
						; C = 변위 지수
		add	a, a
		add	a, a		; x4 (sprite attribute size)
						; x4 (스프라이트 속성 크기)
		ld	de, enemyAttrib	; Tabla	de atributos de	los enemigos en	RAM
							; RAM에 있는 적의 속성 표
		call	ADD_A_DE	; Calcula el plano que le corresponde a	ese desplazamiento
							; 해당 변위에 해당하는 평면을 계산합니다.
		ld	hl, 3B18h	; Direccion VRAM de los	atributos de los sprites de los	enemigos
						; 적 스프라이트 속성의 VRAM 주소
		ld	b, 4		; Numero de enemigos/planos a rotar
						; 회전할 적/비행기 수

setSprAttrib2:
		push	bc
		ld	bc, 4
		call	DEtoVRAMset	; Actualiza los	atributos de un	sprite/momia
							; 스프라이트/미라의 속성 업데이트
		pop	bc
		ld	a, 4
		call	ADD_A_HL	; Siguiente momia
							; 다음 미라
		inc	c		; Incrementa el	indice de desplazamiento
					; 스크롤 속도 증가
		ld	a, c
		cp	4		; Comprueba si ha llegado al ultimo plano reservado para enemigos
					; 적에게 예약된 마지막 비행기에 도착했는지 확인하세요.
		jr	nz, setSprAttrib3

		ld	de, enemyAttrib	; Apunta al comienzo de	la tabla de atributos de los enemigos
							; 적 속성 테이블의 시작 부분을 가리킵니다.
		ld	c, 0		; Resetea el indice
						; 인덱스 재설정

setSprAttrib3:
		djnz	setSprAttrib2

		ld	de, unk_E0D8	; Attributos del resto de sprites del juego
							; 게임에서 나머지 스프라이트의 속성
		ld	hl, 3B28h
		ld	bc, 58h		; Attrib. size
		jp	DEtoVRAMset	; Actualiza VRAM
						; VRAM 업데이트


;----------------------------------------------------
; Comprueba si el prota	llega a	los limites laterales de la pantalla
; Si es	asi, indica que	hay que	realizar scroll	y quita	los sprites
; 주인공이 화면의 측면 한계에 도달했는지 확인
; 그렇다면 스크롤하여 스프라이트를 제거해야 함을 나타냅니다.
;----------------------------------------------------


chkScroll:
		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		rra
		ld	a, (ProtaX)
		jr	nc, chkScroll2
		cp	2		; Limite parte derecha
					; 오른쪽 한계
		ret	nc
		jr	c, chkScroll3

chkScroll2:
		cp	0F4h		; Limite parte izquierda
						; 왼쪽 한계
		ret	c

chkScroll3:
		ld	a, 20h
		ld	(waitCounter), a ; Numero de desplazamientos o tiles a moverse
							; 이동할 변위 또는 타일 수
		ld	a, 1
		ld	(flagScrolling), a ; Se	esta realizando	el scroll
								; 스크롤링 중입니다
		call	HideSprites	; Borra	sprites	dela VRAM
							; VRAM에서 스프라이트 지우기
		call	hideSprAttrib	; Borra	sprites	de la RAM
		ld	a, 9		; Scroll mode
		ld	(GameStatus), a
		pop	hl
		ret


;----------------------------------------------------
; Cambia el color de los destellos de las gemas
; y de la palanca de la	puerta
; 보석의 반짝임과 문의 레버의 색상을 변경합니다.
;----------------------------------------------------

drawBrilloGemas:
		ld	a, (timer)
		rra
		and	3		; Indice de color a usar
					; 사용할 색상 인덱스

		push	af
		ld	hl, coloresBrillo ; Colores de los destellos de	las gemas
							; 보석 스파클 색상
		ld	de, 288h	; Color	table address (destellos)
						; 색상표 주소(깜박임)
		ld	bc, 18h		; Numero de bytes (3 destellos por 8 bytes)
						; 바이트 수(8바이트당 3회 깜박임)
		call	chgColorBrillo	; Cambia el color de los destellos de las gemas
								; 보석의 반짝임 색상 변경
		pop	af

		ld	bc, 3		; Numero de bytes a cambiar
						; 변경할 바이트 수
		ld	de, 2E5h	; Color	table address de la parte inferior de la palanca de la puerta
						; 도어 레버 하단의 색상표 주소
		ld	hl, ColoresPalanca ; Colores de	la palanca de la puerta
								; 도어 레버 색상

chgColorBrillo:
		call	ADD_A_HL
		ld	a, (hl)
		ex	de, hl
		jp	fillVRAM3Bank

coloresBrillo:	db 10h,	0F0h, 0A0h, 0A0h
					; Colores de los destellos de las gemas
					; 보석 스파클 색상
ColoresPalanca:	db 16h,	0F6h, 0A6h, 0A6h
					; Colores de la	palanca	de la puerta
					; 도어 레버 색상


;----------------------------------------------------
;
; Comprueba si se pulsa	F1 para	pausar el juego
; Si se	pausa, muestra el texto	PAUSING	en la esquina inferior derecha del mapa
;
; F1을 눌러 게임을 일시 중지하는지 확인하십시오.
; 일시 중지된 경우 지도의 오른쪽 하단에 PAUSING이라는 텍스트가 표시됩니다.
;
;----------------------------------------------------

chkPause:
		ld	a, (controlPlayer) ; bit 6 = Prota controlado por el jugador
		bit	6, a
		ret	z		; Esta en modo demo
					; 데모 모드입니다

		ld	a, 6		; F3 F2	F1 CODE	CAPS GRAPH CTRL	SHIFT
		call	SNSMAT		;  Read	keyboard row
		cpl
		ld	hl, keyHoldMap
		call	StoreKeyValues
		bit	5, a		; keyTrigger F1
		inc	hl
		inc	hl
		ld	a, (hl)		; Flag que indica si esta pausado
						; 일시 중지 여부를 나타내는 플래그
		jr	nz, chkPause2	; Se ha	pulsado	F1
							; F1을 눌렀다
		and	a		; Esta pausado?
					; 일시 중지되어 있습니까?
		ret	z		; No

		call	blinkPausing	; Muestra el cartel de "PAUSING" parpadeando
								; "PAUSING" 표시가 깜박임을 나타냅니다.
		pop	hl
		ret

chkPause2:
		xor	1
		ld	(hl), a		; Invierte el flag de pausa
						; 일시 중지 플래그 반전
		and	a
		jr	z, erasePausing	; Se acaba de quitar la	pusa, borra el letrero
							; 일시 중지가 방금 제거되었습니다. 기호를 삭제하십시오.
		ret

blinkPausing:
		ld	a, (timer)
		ld	b, a
		and	7
		ret	nz		; El parpadeo dura 8 frames
					; 깜박임은 8프레임 동안 지속됩니다.

		bit	4, b		; Cada 8 frames	muestra	el texto o lo borra
						; 8 프레임마다 텍스트를 표시하거나 삭제합니다.
		ld	de, txtPAUSING
		jr	z, printPause

erasePausing:
		ld	de, eraseData

printPause:
		ld	hl, 3AF6h	; Coordenadas de pantalla
						; 화면 좌표
		ld	bc, 7
		jp	DEtoVRAMset


txtPAUSING:	db 30h,	21h, 35h, 33h, 29h, 2Eh, 27h
					; PAUSING



;----------------------------------------------------
;
; Logica del prota
;
; 주인공의 논리
;
;----------------------------------------------------

AI_Prota:
		ld	hl, setAttribProta ; Actualiza atributos de los	sprites	del prota
								; 주인공의 스프라이트 속성 업데이트
		push	hl		; Mete en la pila la funcion que actualiza los atributos del prota
						; 주인공의 속성을 업데이트하는 함수를 스택에 푸시합니다.
		ld	a, (protaStatus) ; Obtiene el estado actual del	prota
							; 주인공의 현재 상태 가져오기
		and	a
		jr	z, AI_Prota2	; Estado 0 = Andando
							; 상태 0 = 걷기

		cp	3
		jr	nz, AI_Prota3	; Estado 2 = Cayendo. No comprueba los controles
							; 상태 2 = 추락. 컨트롤을 확인하지 않음

AI_Prota2:
		ld	hl, protaControl ; 1 = Arriba, 2 = Abajo, 4 = Izquierda, 8 = Derecha, #10 = Boton A, #20 =Boton	B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
		ld	a, (KeyHold)	; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha, #10 = Boton A, #20	=Boton B
		ld	(hl), a		; Copia	los controles/teclas pulsados al control del prota
						; 누른 컨트롤/키를 주인공 컨트롤에 복사
		and	a
		jr	z, AI_Prota3	; No hay ninguna tecla pulsada
							; 누른 키가 없습니다

		rra
		rra
		and	3
		jr	z, AI_Prota3	; No esta pulsado ni DERECHA ni	IZQUIERDA
							; RIGHT 또는 LEFT를 누르지 않음

		inc	hl
		ld	(hl), a		; Sentido del prota
						; 주인공의 방향

AI_Prota3:
		ld	a, (protaStatus) ; Estado del prota
							; 주인공의 상태
		call	jumpIndex
		dw protaAnda		; 0 = Andar
		dw protaSalta		; 1 = Realiza el salto y comprueba si choca con	algo
		dw protaCayendo		; 2 = Cayendo
		dw protaEscaleras	; 3 = Mueve al prota por las escaleras y comprueba si llega al final de	estas
		dw protaLanzaKnife	; 4 = Anima al prota para hacer	la animacion de	lanzamiento. Al	terminar restaura el sprite y pasa al estado de	andar
		dw protaPicando		; 5 = Animacion	del prota picando y rompiendo los ladrillos
		dw protaGiratoria	; 6 = Pasando por una puerta giratoria
; 0 = 걷기
; 1 = 점프하고 무언가와 충돌하는지 확인
; 2 = 떨어지는
; 3 = 주인공을 계단 위로 이동시키고 계단 바닥에 도달했는지 확인
; 4 = 시작 애니메이션을 수행하기 위해 주인공을 애니메이션합니다. 완료되면 스프라이트를 복원하고 걷기 상태로 이동합니다.
; 5 = 벽돌을 자르고 부수는 주인공의 애니메이션
; 6 = 회전문 통과하기

;----------------------------------------------------
; Prota	status 0: Andar
; 주인공 상태 0: 걷기
;----------------------------------------------------

protaAnda:
		ld	a, (KeyTrigger)
		bit	4, a		; Acaba	de pulsar FIRE1	/ Boton	A?
						; 방금 FIRE1 / 버튼 A를 눌렀습니까?
		jr	z, protaAnda2	; No

		ld	a, (objetoCogido) ; #10	= Cuchillo, #20	= Pico
							; #10 = 칼, #20 = 곡괭이
		and	0F0h		; Tiene	algun objeto el	prota?
						; 주인공에게 물건이 있습니까?
		jp	z, setProtaSalta ; No, intenta saltar
							; 점프를 시도하지 마십시오

		cp	10h		; Es un	cuchillo?
					; 칼이야?
		jp	nz, chkProtaPica ; No, es un pico. Intenta hacer un agujero
							; 아니요, 절정입니다. 구멍을 만들려고
		jp	setLanzaKnife	; Lanza	el cuchillo
							; 칼을 던지다

protaAnda2:
		call	chkProtaCae	; Hay suelo bajo el prota?
							; 주인공 밑에 땅이 있나요?
		jp	c, setProtaCae	; No hay suelo
							; 땅이 없다

		xor	a
		ld	(modoSentEsc), a ; Si es 0 guarda en "sentidoEscalera" el tipo de escalera que se coge el prota. 0 = \, 1 = /
							; 0이면 주인공이 취하는 사다리의 종류를 "sentidoEscalera"에 저장합니다. 0 = \, 1 = /
		call	chkCogeEscalera	; Comprueba si coge una	escalera para subir o bajar
								; 그가 사다리를 타고 올라가거나 내려가는지 확인하십시오.
		ret	z		; si, la ha cogido
					; 예, 그가 가져갔습니다.

		ld	hl, protaControl ; 1 = Arriba, 2 = Abajo, 4 = Izquierda, 8 = Derecha, #10 = Boton A, #20 =Boton	B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
		ld	a, (hl)
		and	1100b		; Se queda solo	con los	controles DERECHA e IZQUIERDA
						; RIGHT 및 LEFT 컨트롤만 남습니다.
		jp	z, protaQuieto	; No se	mueve hacia los	lados
							; 옆으로 움직이지 않는다

		ld	hl, protaMovCnt	; Contador usado cada vez que se mueve el prota. (!?) No se usa	su valor
							; 주인공이 움직일 때마다 사용하는 카운터. (!?) 값이 사용되지 않습니다.
		inc	(hl)		; Incrementa el	contador de movimientos
						; 이동 카운터 증가

		call	chkChocaAndar
		jr	nc, protaAnda3	; No choca
		; 충돌하지 않는다

		ld	a, (hl)		; HL apunta al tile del	mapa contra el que ha chocado
						; HL은 충돌한 지도 타일을 가리킵니다.
		and	0F0h		; Se queda con el tipo de tile/familia
						; 타일/패밀리의 유형으로 유지됩니다.
		cp	50h		; Es una puerta	giratoria?
					; 회전문인가요?
		jr	nz, protaAnda5	; No

		ld	a, (hl)
		and	0Fh		; Tipo de tile de puerta giratoria
					; 회전문 타일 유형
		sub	1
		cp	2		; Ha choacado contra la	parte azul de la puerta?
					; 문의 파란색 부분과 충돌했나요?
		jr	c, protaAnda5	; No

		ld	hl, timerEmpuja	; Timer	usado para saber el tiempo que se empuja una puerta giratoria
							; 회전문을 누르는 시간을 알던 타이머
		inc	(hl)		; Incrementa tiempo de empuje
						; 푸시 시간 늘리기
		ld	a, 10h		; Tiempo necesario de empuje para que se mueva la puerta
						; 문이 움직이는 데 필요한 시간
		cp	(hl)
		jp	nz, protaAnda5	; Aun no ha empujado lo	suficiente
							; 그는 아직 충분히 멀리 밀지 않았다.

		ld	a, 6		; Estado: Pasando por una puerta giratoria
						; 상태: 회전문 통과
		ld	(protaStatus), a ; Actualiza el	estado del prota
							; 주인공 상태 업데이트
		ld	a, 20h
		ld	(accionWaitCnt), a ; Contador usado para controlar la animacion	y duracion de la accion	(lanzar	cuchillo, cavar, pasar puerta giratoria)
								; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)

		ld	a, 3		; Puerta giratoria
						; 회전문
		call	setMusic
		jp	chkGiratorias	; Identifia la puerta que esta empujando
							; 당신이 밀고있는 문을 식별
protaAnda3:
		xor	a
		ld	(timerEmpuja), a ; Resetea contador de empuje
							; 추력 카운터 재설정

protaAnda4:
		call	mueveProta	; Actualiza las	coordenadas del	prota
							; 주인공의 좌표 업데이트

protaAnda5:
		jp	calcFrame	; Actualiza el fotograma de la animacion
						; 애니메이션 프레임 업데이트

;----------------------------------------------------
; Actualiza los	atributos de los dos sprite del	prota en RAM
; segun	sus coordenadas
; 좌표에 따라 RAM에 있는 주인공의 두 스프라이트 속성 업데이트
;----------------------------------------------------

setAttribProta:
		ld	hl, ProtaY	; Actualiza atributos de los sprites del prota
						; 주인공 스프라이트의 속성 업데이트
		ld	c, (hl)		; Y prota
		inc	hl
		inc	hl		; X prota
		ld	b, (hl)		; BC = XY
		ld	a, (protaFrame)
		ld	hl, protaAttrib
		dec	c
		dec	c
		bit	0, a		; El frame es par o impar?
						; 프레임이 짝수인가요 홀수인가요?
		jr	z, setAttribProta2
		inc	c		; Los frames pares los mueve un	pixel hacia arriba
					; 프레임도 한 픽셀 위로 이동합니다.

setAttribProta2:
		ld	de, framesProta	; Sprite a usar	segun el frame
							; 프레임에 따라 사용할 스프라이트
		call	ADD_A_DE
		ld	a, (de)		; Numero de sprite
						; 스프라이트 번호
		ld	d, a
		call	setAttribProta3

setAttribProta3:			; Y
		ld	(hl), c
		inc	hl
		ld	(hl), b		; X
		inc	hl
		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
								; 1 = 왼쪽, 2 = 오른쪽
		rra			; En que sentido mira?
					; 어떤 방향으로 보십니까?
		ld	a, d
		jr	nc, setAttribProta4 ; Derecha
								; 오른쪽
		add	a, 60h		; Distancia a sprites girados a	la izquierda
						; 왼쪽으로 회전된 스프라이트까지의 거리

setAttribProta4:
		ld	(hl), a		; Sprite
		ld	a, d
		add	a, 4		; Siguiente sprite 16x16
						; 다음 스프라이트 16x16
		ld	d, a
		inc	hl		; Color
		inc	hl		; Atributos del	siguiente sprite
					; 다음 스프라이트의 속성
		ret


;----------------------------------------------------
; Pone el frame	del elemento segun su contador de movimientos
; Cada 4 movimientos se	incrementa en 1	el numero de frame
; El rango de valores es de 0 a	7
; 이동 카운터에 따라 요소의 프레임을 설정합니다.
; 4번 움직일 때마다 프레임 번호가 1씩 증가합니다.
; 값의 범위는 0에서 7까지입니다.
;----------------------------------------------------

calcFrame:
		ld	hl, protaMovCnt	; Contador usado cada vez que se mueve el prota. (!?) No se usa	su valor
							; 주인공이 움직일 때마다 사용하는 카운터. (!?) 값이 사용되지 않습니다.
calcFrame2:
		ld	a, (hl)
		rra
		rra
		and	7
		inc	hl
		ld	(hl), a
		ret

protaQuieto:
		xor	a
		ld	(accionWaitCnt), a ; Contador usado para controlar la animacion	y duracion de la accion	(lanzar	cuchillo, cavar, pasar puerta giratoria)
								; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		inc	a		; Pies juntos
					; 함께 발
		jr	setProtaFrame


		ld	a, 2		; (!?) Esto no se ejecuta nunca!
						; (!?) 이것은 실행되지 않습니다!

setProtaFrame:
		ld	(protaFrame), a
		ret


;----------------------------------------------------
; Numero de sprite a usar en cada frame	del prota
; 주인공의 각 프레임에서 사용할 스프라이트 수
;----------------------------------------------------
framesProta:	db    8
		db    0			; 1 = Pies juntos
		db  10h			; 2 = Saltando
		db    8			; 3 = Andando
		db    0			; 4 = Pies juntos
		db  10h			; 5 = Pies separados
		db    0			; 6 = Pies juntos
		db  10h			; 7 = Pies separados
		db  18h			; 8 = Frame 1 accion (cavando, lanzando)
		db  20h			; 9 = Frame 2 accion
						; 1 = 함께 발
						; 2 = 점프
						; 3 = 걷기
						; 4 = 함께 발
						; 5 = 피트 간격
						; 6 = 함께 발
						; 7 = 피트 간격
						; 8 = 프레임 1 작업(파기, 던지기)
						; 9 = 프레임 2 작업

;----------------------------------------------------
; Se ha	pulsado	el boton de salto
; El prota intenta saltar
; 점프 버튼을 눌렀다
; 영웅은 점프를 시도
;----------------------------------------------------

setProtaSalta:
		ld	hl, ProtaY
		ld	a, (hl)
		and	a
		ret	z		; No salta. El prota esta en la	parte superior de la pantalla, pegado arriba del todo
					; 점프하지 마십시오. 주인공은 화면 상단에 있으며 상단에 붙어 있습니다.

		call	chkSaltar	; Comprueba si puede saltar o hay algun	obstaculo que se lo impide
							; 그가 점프할 수 있는지 또는 그를 방해하는 장애물이 있는지 확인하십시오.
		ret	nc		; Choca	contra algo. No	puede saltar
					; 뭔가를 쳤다. 점프할 수 없다

		ex	de, hl
		ld	a, (hl)		; Puntero al mapa
						; 지도에 대한 포인터
		and	0F0h
		cp	10h		; Es una plataforma o muro?
					; 플랫폼인가, 벽인가?
		ret	z		; Si

setProtaSalta_:
		ld	a, (KeyHold)	; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha, #10 = Boton A, #20	=Boton B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
		ld	(sentidoEscalera), a ; Guarda el estado	de las teclas al saltar
								; 점프 시 키 상태 저장
		ld	hl, protaStatus	; Puntero a los	datos del prota
							; 주인공의 데이터에 대한 포인터
		jp	Salta

;----------------------------------------------------
; Prota	status 1: Saltar
; Actualiza sus	coordenadas y comprueba	si choca con al	al saltar
; Si choca, pasa al estado de cayendo
; 주인공 상태 1: 점프
; 좌표를 업데이트하고 점프할 때 충돌하는지 확인합니다.
; 부딪히면 넘어지는 상태가 된다.
;----------------------------------------------------

protaSalta:
		ld	hl, sentidoProta ; 1 = Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		call	doSalto		; Actualiza la posicion	del prota al saltar
							; 점프 시 주인공 위치 업데이트
		ld	hl, protaStatus	; Puntero a los	datos del prota
							; 주인공의 데이터에 대한 포인터
		push	hl
		pop	ix
		call	chkChocaSalto	; Comprueba si choca con algo en el salto
								; 점프에서 무언가에 부딪히는지 확인하십시오.
		ret	nz		; No ha	chocado	con nada
					; 아무것도 충돌하지 않았습니다

		ld	a, 3
		ld	(protaStatus), a ; (!?)	Para que pone esto! Seguido se cambia a	estatus	cayendo
							; (!?) 이걸 왜 넣어! 종종 떨어지는 상태로 변경됨
		jr	protaCayendo

;----------------------------------------------------
; El prota ha llegado al suelo
; Pone estado de andar/normal y	reproduce efecto de aterrizaje
; 영웅은 지상에 도달했습니다
; 걷기/정상 상태 설정 및 착지 효과 재생
;----------------------------------------------------

protaAterriza:
		ld	a, 2		; SFX choca suelo
						; sfx는 땅을 쳤다
		call	setMusic
		xor	a
		ld	(protaStatus), a ; Pone	estado de andar
							; 걷는 상태 설정
		ret


;----------------------------------------------------
; Pone al prota	en estado de caida
; 주인공을 타락의 상태에 빠트린다.
;----------------------------------------------------

setProtaCae:
		xor	a
		ld	(flagSetCaeSnd), a ; Si	es 0 hay que inicializar los datos del sonido de caida
								; 0이면 떨어지는 소리의 데이터 초기화가 필요하다
		ld	a, 1
		call	setMusic	; SFX caer

;----------------------------------------------------
; Prota	status 2: Caer
; Actualiza las	coordenadas del	prota debido a la caida
; Pone estado de caida
; Comprueba si llega al	suelo
; 주인공 상태 2: 추락
; 추락으로 인한 주인공의 좌표 업데이트
; 충돌 상태를 판단
; 땅에 닿았는지 확인
;----------------------------------------------------

protaCayendo:
		ld	hl, protaStatus	; Puntero al estado del	prota
							; 주인공의 상태를 가리키는 포인터
		call	cayendo		; Pone estado de cayendo y comprueba si	llega al suelo
							; 낙하 상태를 설정하고 지면에 닿는지 확인
		jp	nc, protaAterriza ; Ha llegado al suelo
								; 땅을 쳤다
		ret


;----------------------------------------------------
; Prota	status 3: Escaleras
; Mueve	al prota por las escaleras y comprueba si llega	al final
; Si llega al final pasa al estado de andar
; 주인공 상태 3: 계단
; 주인공을 계단으로 이동시키고 끝까지 도달했는지 확인하십시오.
; 끝에 도달하면 걷는 상태가 된다.
;----------------------------------------------------

protaEscaleras:
		ld	hl, protaControl ; 1 = Arriba, 2 = Abajo, 4 = Izquierda, 8 = Derecha, #10 = Boton A, #20 =Boton	B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
		ld	a, (hl)
		and	0Ch
		ret	z		; No esta pulsado DERECHA ni IZQUIERDA
					; RIGHT 또는 LEFT를 누르지 않았습니다.

		ld	b, 1		; Velocidad del	prota en las escaleras (mascara	aplicada al timer)
						; 계단 위 주인공의 속도(타이머에 적용된 마스크)
		xor	a
		ld	(quienEscalera), a ; (!?) Se usa esto? Quien esta en una escalera 0 = Prota. 1 = Momia
							; (!?) 이것은 사용됩니까? 사다리에 있는 사람 0 = 주인공. 1 = 미라
		call	andaEscalera	; Mueve	al prota por la	escalera y comprueba si	llega al final
								; 주인공을 사다리 위로 이동하고 그가 끝에 도달했는지 확인하십시오
		jr	z, protaEscaleras2 ;  Ha llegado al final de las escaleras
								; 당신은 계단의 바닥에 도달했습니다
		jp	calcFrame	; Actualiaza el	frame de la animacion
						; 애니메이션 프레임 업데이트

protaEscaleras2:
		xor	a		; Estado: andar
					; 상태: 도보
		jr	protaEscaleras3



		ld	a, 3		; (!?) Este codigo no se ejecuta nunca!
						; (!?) 이 코드는 실행되지 않습니다!
protaEscaleras3:
		ld	(protaStatus), a ; Esto	solo se	usa para poner al prota	en estado de andar al terminar una escalera
							; 사다리를 완성할 때 주인공을 걷는 상태로 만들 때만 사용합니다.
		ret

;----------------------------------------------------
; El prota lanza un cuchillo
; 칼을 던지는 주인공
;----------------------------------------------------

setLanzaKnife:
	IF	(VERSION2)
		xor	a
		ld	hl,ElemEnProceso
		ld	(hl),a
chkPuertaMov:
		push	hl
		ld	a,04
		call	getExitDat	; Obtiene puntero al estatus de la puerta que se est� procesando
							; 처리 중인 문의 상태에 대한 포인터 가져오기
		and	#F0		; Se queda con el status (nibble alto)
					; 상태 유지(높은 니블)
		cp	#30		; Se esta abriendo?
					; 개봉이야?
		pop	hl
		ret	z		; Impide lanzar el cuchillo mientras la puerta se abre para impedir que se corrompan los tiles al pasar el cuchillo sobre la puerta
					; 문이 열린 상태에서 칼을 던지는 것을 방지하여 칼을 문 위로 넘길 때 타일이 손상되는 것을 방지합니다.
		inc	(hl)
		ld	a,04		; Numero m�ximo de cuchillos
						; 칼의 최대 수
		cp	(hl)
		jr	nz,chkPuertaMov ; A�n quedan cuchillos por comprobar
							; 아직 확인해야 할 칼이 있다
	ENDIF

		xor	a
		ld	(lanzamFallido), a ; 1 = El cuchillo se	ha lanzado contra un muro y directamente sale rebotando
								; 1 = 칼이 벽에 부딪혀 바로 튕겨져 나옴

		ld	hl, sentidoProta ; 1 = Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		ld	a, (hl)
		inc	hl		; Apunta a la Y
					; Y를 가리킴
		rra
		ld	bc, 0FF00h	; X-1
		jr	c, setLanzaKnife2 ;  Lo	lanza a	la izquierda
							; 왼쪽으로 던져
		ld	b, 12h		; X+18

setLanzaKnife2:
		push	bc
		call	chkTocaMuro	; Lo esta intentando lanzar pegado a un	muro?
							; 벽에 던지려고 하는 건가요?
		pop	bc
		jr	z, setLanzaKnife4 ; Si,	asi no se puede	a no ser que haya un hueco un tile por encima
							; 예, 한 타일 위에 구멍이 없으면 할 수 없습니다.

	IF	(VERSION2)
		push	bc
		ld	a,(de)		; Tile del mapa contra el que ha chocado
						; 충돌한 지도의 타일
		call	chkKnifeChoca	; Comprueba el tipo de tile que es
								; 타일의 종류를 확인하십시오.
		pop	bc
		jr	z,setLanzaKnife4 ; Es un muro, cuchillo, gema o pico
							; 벽인가, 칼인가, 보석인가, 곡괭이인가
	ENDIF

setLanzaKnife3:
		ld	a, 15h
		ld	(accionWaitCnt), a ; Contador usado para controlar la animacion	y duracion de la accion	(lanzar	cuchillo, cavar, pasar puerta giratoria)
								; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		ld	a, 4
		ld	(protaStatus), a ; Cambia el estado del	prota a	"lanzando cuchillo"
							; 주인공의 상태를 "칼 던지기"로 변경
		jp	setFrameLanzar	; Pone fotograma de lanzar cuchillo
							; 투척 나이프 프레임 세트

; Comprueba si al lanzar un cuchillo contra un muro
; hay un hueco sobre este para que caiga el cuchillo
; Por ejemplo: el prota	esta en	un agujero pero	a los lados sobre su cabeza hay	sitio libre
; 칼을 벽에 던질 때 칼이 떨어질 구멍이 있는지 확인하십시오.
; 예: 주인공은 구멍에 있지만 머리 위 측면에는 여유 공간이 있습니다.

setLanzaKnife4:

	IF	(VERSION2)
		cp	#10		; Es un muro?
					; 벽이야?
		ret	nz		; No
	ENDIF

		dec	c		; El tile que esta una fila por	encima del prota
					; 주인공보다 한 행 위에 있는 타일
		ld	hl, ProtaX
		ld	a, (hl)		; X prota
		and	7
		cp	4		; En medio de un tile?
					; 타일 ​​한가운데?
		ret	nz		; No

		dec	hl
		dec	hl		; Apunta a la Y
					; Y를 가리킴
		call	chkTocaMuro	; Z = choca
							; Z = 충돌
		ld	a, c		; Tile comprobado
						; 타일 ​​체크
		or	a		; Es cero?
					; 제로인가요?
		ret	nz		; No esta libre
					; 그것은 무료가 아니다

		ld	hl, lanzamFallido ; 1 =	El cuchillo se ha lanzado contra un muro y directamente	sale rebotando
							; 1 = 칼이 벽에 부딪혀 바로 튕겨져 나옴
		inc	(hl)
		jr	setLanzaKnife3

;----------------------------------------------------
; Prota	status 4: El prota esta	lanzando un cuchillo
; Aqui llega el	prota con el frame 1 de	lanzar puesto
; Tras unas iteraciones	pasa al	frame 2	de la animacion
; Al terminar la animacion/espera, se restaura el sprite normal	(sin objeto en las manos) y el estado de andar
; 주인공 상태 4: 주인공이 칼을 던지고 있습니다.
; 여기 던질 프레임 1의 주인공이옵니다.
; 몇 번의 반복 후에 애니메이션의 프레임 2로 이동합니다.
; 애니메이션/대기가 끝나면 일반 스프라이트(손에 물건이 없는 상태)와 걷기 상태가 복원됩니다.
;----------------------------------------------------

protaLanzaKnife:
		ld	hl, accionWaitCnt ; Contador usado para	controlar la animacion y duracion de la	accion (lanzar cuchillo, cavar,	pasar puerta giratoria)
							; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		bit	4, (hl)		; Es menor de #10?
						; #10 미만인가요?
		jr	z, chkLanzaEnd

		dec	(hl)
		ld	a, (hl)
		and	0Fh		; Al llegar lanzaWaitCnt a #10 pone el segundo frame de	la animacion de	lanzar
					; launchWaitCnt가 #10에 도달하면 시작 애니메이션의 두 번째 프레임을 설정합니다.
		ret	nz

		ld	hl, IDcuchilloCoge ; Cuchillo que coge el prota
								; 주인공을 잡는 칼
		ld	a, (hl)
		inc	hl
		ld	(hl), a		; Cuchillo en proceso
						; 진행 중인 칼

		xor	a
		call	getKnifeData
		ld	(hl), 4		; Estado: lanzamiento
						; 상태: 릴리스

		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		and	3
		inc	hl
		ld	(hl), a		; Pone al cuchillo el mismo sentido que	tiene el prota
						; 그는 칼에 주인공이 가지고 있는 것과 같은 방향을 준다.

		ld	a, (lanzamFallido) ; 1 = El cuchillo se	ha lanzado contra un muro y directamente sale rebotando
								; 1 = 칼이 벽에 부딪혀 바로 튕겨져 나옴
		or	a		; Sale directamente rebotando contra el	muro?
					; 벽에 직접 튕겨서 나오나요?
		jr	z, setFrameLanzar2 ; Pone frame	2 del lanzamiento: brazo abajo
								; 발사의 프레임 2를 설정합니다. 팔을 아래로 내립니다.


; El cuchillo directamente sale	rebotando para caer sobre el muro que esta delante
; 칼이 직접 튀어나와 정면의 벽에 떨어집니다.

		dec	hl
		ld	(hl), 7		; estado: rebotando
						; 상태: 튀는
		inc	hl		; sentido
					; 방향
		inc	hl		; Y

		ld	de, ProtaY
		ld	a, (de)		; Y del	prota
		sub	8
		ld	(hl), a		; Y del	cuchillo 8 pixeles por encima del prota
						; 그리고 주인공보다 8픽셀 위의 칼날

		inc	hl		; X decimales
		inc	hl		; X cuchillo
					; X 나이프
		inc	de		; X decimales
		inc	de		; X prota
					; X 주인공

		ld	a, (de)		; X prota
		add	a, 4
		ld	(hl), a		; X del	cuchillo igual a X prota + 4
						; 칼의 X는 X 주인공 + 4와 같습니다.
		inc	hl
		inc	de
		ld	a, (de)		; Habitacion prota
						; 주인공 룸
		ld	(hl), a		; Habitacion cuchillo
						; 칼방

		ld	a, 4
		call	ADD_A_HL
		ld	(hl), 0

setFrameLanzar2:
		ld	a, 9		; Frame	2 de lanzar cuchillo (accion frame 2)
						; 프레임 2 투척 나이프(프레임 2 액션)
		jp	setFrameProta

setFrameLanzar:
		ld	a, 8		; Frame	de lanzar cuchillo (accion frame 1)
						; 칼 던지기 프레임(액션 프레임 1)

setFrameProta:
		ld	(protaFrame), a
		ret

;----------------------------------------------------
; Comprueba si termina el lanzamiento para restaurar el	sprite y el estado de andar
; 스프라이트 및 걷기 상태를 복원하기 위해 실행이 완료되었는지 확인하십시오.
;----------------------------------------------------

chkLanzaEnd:
		ld	hl, accionWaitCnt ; Contador usado para	controlar la animacion y duracion de la	accion (lanzar cuchillo, cavar,	pasar puerta giratoria)
		; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		dec	(hl)
		ret	nz

		xor	a
		ld	(protaStatus), a ; Pone	estado de andar
		; 걷는 상태 설정
		jr	quitaObjeto	; Carga	sprites	normales (sin objeto)
		; 일반 스프라이트 로드(객체 없이)


;----------------------------------------------------
; Status 5: Prota picando
; Animacion del	prota picando y	rompiendo los ladrillos
; 상태 5: 주인공 바이트
; 벽돌을 자르고 부수는 주인공의 애니메이션
;----------------------------------------------------

protaPicando:
		ld	hl, accionWaitCnt ; Contador usado para	controlar la animacion y duracion de la	accion (lanzar cuchillo, cavar,	pasar puerta giratoria)
							; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		dec	(hl)
		ld	a, (hl)
		and	0Fh
		jr	z, protaPicando3

		ld	a, (hl)
		bit	4, a
		ld	a, 9		; Frame	2 de la	accion de picar
						; 자르기 작업의 프레임 2
		jr	z, protaPicando2
		dec	a		; Frame	1 de la	accion de picar
					; 자르기 작업의 프레임 1

protaPicando2:
		jp	setProtaFrame

protaPicando3:
		ld	a, (hl)		; Contador de la accion	de picar
						; 곡괭이 동작 카운터
		bit	4, a		; Es multiplo de #20
						; #20의 배수입니다.
		ld	b, 4		; Frames con el	pico abajo
						; 곡괭이가 아래로 향하는 프레임
		jr	nz, protaPicando4

		ld	b, 8		; Frames con el	pico arriba
						; 곡괭이가 있는 프레임
		push	bc
		push	hl
		ld	hl, agujeroCnt	; Al comenzar a	pica vale #15
							; 곡괭이를 시작할 때 #15의 가치가 있습니다.
		dec	(hl)
		dec	(hl)
		dec	(hl)
		call	drawAgujero	; Dibuja la animacion de como se rompen	los ladrillos al picar y los borra del mapa
							; 벽돌을 깨물었을 때 벽돌이 깨지는 애니메이션을 그리고 지도에서 삭제하세요.
		pop	hl
		pop	bc

protaPicando4:
		ld	a, (hl)		; AccionWaitCnt
		and	0F0h
		or	b		; Numero de frames que se mantiene en la posicion actual
					; 현재 위치에 있는 프레임 수
		xor	10h
		ld	(hl), a

		ld	a, (agujeroCnt)	; Al comenzar a	pica vale #15
							; 곡괭이를 시작할 때 #15의 가치가 있습니다.
		and	a
		ret	nz		; No ha	terminado de hacer el agujero
					; 구멍 뚫기가 아직 끝나지 않았습니다.

		call	chkIncrust	; Comprueba que	al terminar el agujero el prota	no este	incrustado (?)
							; 구멍 끝에 주인공이 박혀있지 않은지(?)

		ld	a, 1
		call	setProtaFrame	; Pone frame con los pies juntos
								; 프레임과 발을 함께 연결
		xor	a
		ld	(protaStatus), a ; Restaura estado de andar
							; 보행 회복

;----------------------------------------------------
; Quita	el objeto que se tiene.
; Actualiza los	sprites	dependiendo de que se lleve en las manos
; 가지고 있는 개체를 제거합니다.
; 손에 있는 것에 따라 스프라이트 업데이트
;----------------------------------------------------

quitaObjeto:
		xor	a

cogeObjeto:
		ld	(objetoCogido),	a ; #10	= Cuchillo, #20	= Pico
							; #10 = 칼, #20 = 곡괭이
		jp	loadAnimation	; Actualiza los	sprites	del prota
							; 주인공의 스프라이트 업데이트


;----------------------------------------------------
; Prota	usa pico
; Comprueba si	el prota puede hacer un	agujero	con el pico
; Para ello tiene que estar sobre suelo	firme (plataforma de piedra)
; y que	debajo de la plataforma	no haya	una puerta giratoria
; Tambien comprueba que	sobre el lugar del agujero no haya un cuchillo o una gema
; 주인공는 곡괭이를 사용합니다.
; 주인공이 곡괭이로 구멍을 뚫을 수 있는지 확인
; 이렇게 하려면 단단한 바닥(돌 플랫폼) 위에 있어야 하며 플랫폼 아래에 회전문이 없어야 합니다.
; 또한 구멍 위치에 칼이나 보석이 없는지 확인하십시오.
;----------------------------------------------------

chkProtaPica:
		ld	hl, ProtaY
		call	chkPisaSuelo
		ret	nz		; El prota no esta sobre suelo firme
					; 주인공은 확고한 입장이 아니다
		dec	hl
		push	hl		; Apunta al sentido
						; 방향을 가리키다
		call	chkChocaAndar3
		pop	hl
		jr	nc, chkProtaPica2 ; No choca
								; 충돌하지 않는다

		ld	a, (hl)		; Sentido
						; 방향
		xor	3		; Invierte el sentido
					; 방향를 뒤집다
		ld	b, a		; Lo guarda en B para pasarselo	a la funcion
						; 함수에 전달하려면 B에 저장하십시오.
		push	hl
		call	chkChocaAndar4
		pop	hl
		jp	c, picaLateral	; Si esta atrapado en un agujero pica uno de los muros lateralmente
							; 구멍에 갇히면 벽 중 하나를 옆으로 물어뜯습니다.

chkProtaPica2:
		ld	e, (hl)		; Sentido
						; 방향
		inc	hl
		ld	a, (hl)		; Y prota
		add	a, 10h		; Le suma el alto del prota
						; 주인공의 키 추가
		ld	d, a		; Guarda en D la Y del suelo bajo los pies
						; 발 아래 땅의 Y를 D로 유지
		inc	hl
		inc	hl
		ld	a, (hl)		; X prota
		ld	bc, 10h		; Offset X: izquierda =	0, derecha = 16
						; 오프셋 X: 왼쪽 = 0, 오른쪽 = 16
		and	7
		cp	5		; Calcula la posicion relativa respecto	al tile
					; 타일에 대한 상대 위치를 계산합니다.
		jr	c, chkProtaPica3

	IF	(VERSION2)
		ld	b,#08
	ELSE
		ld	bc, 810h	; Offset: izquierda = 8, derecha = 16
						; 오프셋: 왼쪽 = 8, 오른쪽 = 16
	ENDIF

chkProtaPica3:
		ld	a, e		; Sentido
						; 방향
		rra
		ld	a, b		; Offset picando a la izquierda
						; 왼쪽 클릭 오프셋
		jr	c, chkProtaPica4
		ld	a, c		; Offset picando a la derecha
						; 오프셋 오른쪽으로 스냅

chkProtaPica4:
		add	a, (hl)		; Suma el desplazamiento a la X	del prota
						; 주인공의 X에 변위 추가
		ld	e, a
		and	0F8h
		ret	z		; Demasiado pegado a la	izquierda
					; 너무 왼쪽에 가깝다

		cp	0F8h
		ret	z		; Demasiado pegado a la	derecha
					; 오른쪽에 너무 가깝다

		ld	hl, agujeroDat	; Y, X,	habitacion
							; Y, X, 방
		push	hl
		ld	(hl), d		; Y agujero
		inc	hl
		inc	hl
		ld	(hl), e		; X agujero
		inc	de
		inc	hl
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
							; X 좌표의 상단 피라미드의 방을 나타냅니다.
		ld	(hl), a		; Habitacion del agujero
						; 구멍 방
		pop	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coordenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.
		and	0F0h		; Se queda con el tipo de tile
						; 그것은 타일의 종류와 함께 유지
		cp	10h		; Es una plataforma, ladrillo o	muro?
					; 플랫폼입니까, 벽돌입니까, 아니면 벽입니까?
		ret	nz		; No

		ld	a, (hl)
		and	0Fh		; Se queda con el tipo de ladrillo
					; 벽돌 유형으로 유지
		cp	4		; Es ladrillo de muro o	plataforma?
					; 벽 벽돌입니까 아니면 플랫폼입니까?

	IF	(VERSION2)
		jr	c,chkProtaPica4b
		cp	9		; Es un ladrillo de un muro trampa?
					; 벽돌은 함정 벽입니까?
		ret	nz
	ELSE
		ret	nc		; No
	ENDIF

chkProtaPica4b:
		ld	a, 60h		; Desplazamiento a una fila inferior
						; 낮은 행으로 이동
		call	ADD_A_HL
		ld	a, (hl)		; Tile del mapa	que esta por debajo del	anterior
						; 이전 타일 아래에 있는 맵의 타일
		and	0F0h		; Tipo de tile
						; 타일 ​​종류
		cp	50h		; Es una puerta	giratoria?
					; 회전문인가요?
		ret	z		; Si, aqui no se puede hacer un	agujero	(que nos cargamos la puerta!)
					; 예, 여기에 구멍을 만들 수 없습니다 (우리가 문을 죽일 것입니다!)


; Esta comprobacion evita que se haga un agujero debajo	de un cuchillo, pico o una gema
; 이 검사는 칼, 곡괭이 또는 보석 아래에 구멍이 뚫리는 것을 방지합니다.

		ld	bc, -0C0h	; Desplazamiento 2 filas mas arriba. Justo un tile por encima del suelo
						; 2행을 더 높게 오프셋합니다. 지상에서 단 하나의 타일
		add	hl, bc
		ld	a, (hl)		; Lee tile del mapa
						; 지도 타일 읽기
		and	0F0h		; Esta vacio?
						; 비어 있습니까?
		jr	z, chkProtaPica5+1 ; (!?) Esto salta y ejecuta "JR NZ,#4ED1" Claro que nunca sera NZ si salta siendo Z
								; (!?) 점프해서 "JR NZ,#4ED1" 실행 물론 Z로 점프하면 결코 NZ가되지 않습니다.

chkProtaPica5:
		cp	20h		; Es una escalera?
					; 사다리인가요?
		ret	nz		; Si, se puede hacer un	agujero	a los pies de una escalera
					; 네, 사다리 바닥에 구멍을 만들 수 있습니다.

		ld	hl, protaStatus	; Puntero al estado del	prota
							; 주인공의 상태를 가리키는 포인터
		ld	(hl), 5		; Estado: Picando
						; 상태: 클릭

		inc	hl
		inc	hl
		ld	a, (hl)		; Sentido del prota
						; 주인공의 방향
		rra
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		jr	nc, chkProtaPica7 ; Mira a la derecha
								; 오른쪽을 봐

		and	7		; Posicion relativa al tile
					; 타일을 기준으로 한 위치
		cp	5		; Esta en los 4	pixeles	derechos del tile?
					; 타일의 오른쪽 4픽셀에 있습니까?
		ld	a, (hl)		; X
		jr	c, chkProtaPica6 ; No
		add	a, 4		; Pasa al siguiente tile
						; 다음 타일로 이동
		and	0F8h		; Lo ajusta a la X del tile
						; 타일의 X로 설정
		add	a, 2		; Le suma 2
						; 2를 더하다

chkProtaPica6:
		ld	(hl), a		; Actualiza la X del prota
						; 주인공의 X 업데이트
		jr	setPicarStatus

; El prota esta	haciendo el agujero hacia la derecha
; 주인공은 오른쪽에 구멍을 만들고 있습니다

chkProtaPica7:
		and	7		; Posicion X relativa al tile
					; 타일을 기준으로 X 위치
		sub	1
		cp	3		; Esta en la parte derecha o izquierda del tile?
					; 타일의 왼쪽 또는 오른쪽에 있습니까?
		ld	a, (hl)
		jr	c, chkProtaPica8
		and	0FCh		; Ajusta la X del prota	a la X del tile
						; 주인공의 X를 타일의 X로 조정

chkProtaPica8:
		ld	(hl), a		; Actualiza la X del prota
						; 주인공의 X 업데이트

setPicarStatus:
		ld	a, 15h
		ld	(agujeroCnt), a	; Al comenzar a	pica vale #15
							; Pica를 시작할 때 #15의 가치가 있습니다.
		ld	a, 5
		ld	(protaStatus), a ; Pone	estado de picando
							; 클릭 상태를 넣는다.
		ret


;----------------------------------------------------
; Cuando el prota esta atrapado	entre dos muros	en vez de
; picar	en el suelo, pica en la	pared
;
; 주인공이 두 개의 벽 사이에 갇혔을 때 땅을 치지 않고 벽에 부딪힙니다.
;----------------------------------------------------

picaLateral:
		ld	de, agujeroDat	; Y, X,	habitacion
		inc	hl
		ld	a, (hl)		; Y del	prota
		ld	(de), a		; Y del	agujero
						; Y 구멍
		inc	hl
		inc	de
		inc	de
		inc	hl
		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
								; 1 = 왼쪽, 2 = 오른쪽
		rra
		ld	a, (hl)		; X del	prota
		jr	c, picaLateral2	; Va a pizar hacia la izquierda
							; 왼쪽으로 갈거야
		add	a, 10h		; Pica hacia la	derecha, asi que le suma a la X	el ancho del prota (16 pixeles)
						; 오른쪽을 클릭하여 X(16픽셀)에 주인공의 너비를 추가합니다.

picaLateral2:
		ld	(de), a		; X del	agujero
		and	0F8h
		ret	z		; Esta picando el muro izquierdo que delimita la habitacion
					; 방의 경계를 짓는 것은 왼쪽 벽을 깨물고 있다

		cp	0F8h
		ret	z		; Esta intentando picar	el muro	derecho	que delimita la	habitacion
					; 방을 가르는 오른쪽 벽을 물어뜯으려 하고 있어

		inc	hl
		inc	de
		ld	a, (hl)		; Habitacion prota
		ld	(de), a		; Habitacion agujero
		call	setPicarStatus	; Pone al prota	en estado de picar
								; 주인공을 가려움증 상태에 빠뜨립니다.

		ld	a, 2
		ld	(accionWaitCnt), a ; Contador usado para controlar la animacion	y duracion de la accion	(lanzar	cuchillo, cavar, pasar puerta giratoria)
								; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		ld	hl, ProtaY
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.

		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		rra
		jr	c, picaLateral3	; Izquierda
							; 왼쪽

		inc	hl
		inc	hl		; Apunta al tile que esta a la derecha del prota
					; 주인공의 오른쪽에 있는 타일을 가리킵니다.

picaLateral3:
		ld	a, (hl)		; Tile del mapa
						; 지도 타일
		and	0F0h
		cp	10h		; Es un	muro/plataforma?
					; 벽/플랫폼입니까?
		jr	z, picaLateral4	; Si


; Si a la altura de la cabeza del prota	no hay muro, comienza a	picar un tile mas abajo
; 주인공 머리 높이에 벽이 없으면 아래 타일을 자르기 시작합니다.

		ld	hl, agujeroDat	; Y, X,	habitacion
		ld	a, (hl)
		add	a, 8
		ld	(hl), a		; Desplaza el orgigen del agujero un tile mas abajo
						; 구멍의 원점을 한 타일 아래로 이동
		ld	a, 9		; Como solo va a picar un tile la duracion es la mitad
						; 타일에 맞을 뿐이므로 지속 시간은 반입니다
		ld	(agujeroCnt), a	; Al comenzar a	pica vale #15
							; Pica를 시작할 때 #15의 가치가 있습니다.

picaLateral4:
		ld	a, 45h		; SFX picar
		jp	setMusic


;----------------------------------------------------
; Status 6: Prota pasando por una puerta giratoria
; 상태 6: 회전문을 통과하는 주인공
;----------------------------------------------------

protaGiratoria:
		ld	a, (timer)
		and	1
		ret	nz		; Procesa uno de cada dos frames
					; 두 프레임 중 하나를 처리

		ld	hl, accionWaitCnt ; Contador usado para	controlar la animacion y duracion de la	accion (lanzar cuchillo, cavar,	pasar puerta giratoria)
							; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
		dec	(hl)		; Ha terminado de pasar	la puerta?
						; 문 통과를 마쳤습니까?
		jr	z, setProtaAndar ; si

		ld	hl, protaMovCnt	; Contador usado cada vez que se mueve el prota. (!?) No se usa	su valor
							; 주인공이 움직일 때마다 사용하는 카운터. (!?) 값이 사용되지 않습니다.
		inc	(hl)		; Incrementa contardor de movimiento y animacion
						; 움직임 및 애니메이션 카운터 증가
		jp	protaAnda4	; Mueve	y anima	al prota
						; 주인공 이동 및 애니메이션

setProtaAndar:
		ld	(protaStatus), a ; Pone	el estado 0 (andar) en el prota
							; 주인공에게 상태 0(걷기)을 둡니다.
		ret

;----------------------------------------------------
; Comprueba si el prota	esta incrustado	despues	de hacer un agujero con	el pico
; (Por si le baja un muro trampa?)
; 곡괭이로 구멍을 뚫어 주인공이 박혀 있는지 확인
; (트랩 벽이 무너지면?)
;----------------------------------------------------

chkIncrust:
		ld	hl, ProtaY
		ld	bc, 40Ch	; Offset X+4, Y+12
		call	chkIncrustUp
		ld	b, 4
		jr	nc, chkIncrust2

		ld	bc, 0B0Ch	; offset X+11, Y+12
		call	chkIncrustUp
		ret	c
		ld	b, 0

chkIncrust2:
		ld	hl, ProtaX
		ld	a, (hl)		; X prota
		add	a, b		; Le suma el desplazamiento
						; 변위 추가
		and	0FCh		; Ajusta la coordenada X del prota a multiplo de 4
						; prota의 X 좌표를 4의 배수로 설정합니다.
		ld	(hl), a		; Actualiza la X del prota
						; 주인공의 X 업데이트
		ret
;----------------------------------------------------
;
; Carga	los graficos y sprites del juego y
; crea copias invertidas de algunos de ellos
;
; 게임의 그래픽과 스프라이트를 로드하고 그 중 일부의 반전된 복사본을 만듭니다.
;
;----------------------------------------------------

loadGameGfx:
		ld	hl, statusEntrada
		ld	de, lanzamFallido ; 1 =	El cuchillo se ha lanzado contra un muro y directamente	sale rebotando
								; 1 = 칼이 벽에 부딪혀 바로 튕겨져 나옴
		ld	bc, 500h
		xor	a
		ld	(hl), a
		ldir			; Borra	RAM
						; RAM 지우기

		ld	hl, 2200h	; Destino = Patron #40 de la tabla
						; 대상 = 테이블의 패턴 #40
		ld	de, GFX_InGame
		call	UnpackPatterns

		ld	hl, 228h	; Tabla	de colores de los patrones del juego
						; 게임 패턴 컬러 차트
		ld	de, COLOR_InGame
		call	UnpackPatterns

		ld	hl, 2340h	; Origen = Patron #68 (Puerta)
						; 원천 = 패턴 #68(문)
		ld	de, 23B8h	; Destino = Patron #77
						; 대상 = 패턴 #77
		ld	c, 0Fh		; Numero de patrones a invertir
						; 반전할 패턴의 수
		call	FlipPatrones	; Invierte algunos graficos como las escaleras y las puertas
								; 계단 및 문과 같은 일부 그래픽 반전

		ld	de, COLOR_Flipped
		ld	hl, 3B8h
		call	UnpackPatterns	; Pone color a los patrones invertidos
								; 색상 반전 패턴

		ld	b, 6		; Numero de gemas
						; 보석의 수
		ld	hl, 2430h	; Destino = Patron #96 de la tabla (Gemas)
						; 대상 = 테이블 패턴 #96(보석)

UnpackGema:
		ld	de, GFX_GEMA
		push	hl
		push	bc
		call	UnpackPatterns
		pop	bc
		pop	hl
		ld	de, 8
		add	hl, de
		djnz	UnpackGema


		ld	de, COLOR_GEMAS
		ld	hl, 430h
		call	UnpackPatterns

		ld	de, GFX_SPRITES2
		call	unpackGFXset

		ld	de, GFX_MOMIA
		call	unpackGFXset

		ld	hl, 1940h	; Datos	GFX momia (Sprite generatos table address)
						; GFX 데이터 미라(Sprite 생성기 테이블 주소)
		ld	de, 1C50h	; Direccion SGT	de la momia invertida
						; 미라 SGT 주소가 역전됨
		ld	c, 3
		call	flipSprites

; Carga	los sprites que	corresponden al	estado del personaje
; Nada en las manos, llevando un cuchillo o llevando un	pico
; 캐릭터의 상태에 해당하는 스프라이트 로드
; 손에 아무것도 없고 칼을 들고 곡괭이를 들고

loadAnimation:
		ld	a, (objetoCogido) ; #10	= Cuchillo, #20	= Pico
							; #10 = 칼, #20 = 곡괭이
		rra
		rra
		rra
		and	1Eh
		ld	hl, IndexSprites
		call	getIndexHL_A
		ex	de, hl
		ld	hl, 1800h
		push	hl
		call	unpackGFXset
		pop	hl		; Recupera la direccion	de los sprites en VRAM
					; VRAM에서 스프라이트 주소 검색
		ld	de, 1B10h	; Destino sprites invertidos (#60-#61)
						; 대상 반전 스프라이트(#60-#61)
		ld	c, 0Ah		; Numero de sprites a invertir
						; 반전할 스프라이트 수
		jp	flipSprites



IndexSprites:	dw GFX_Prota
		dw GFX_ProtaKnife
		dw GFX_ProtaPico


		ld	hl, ProtaY	; (!?) Este codigo no se ejecuta nunca!
						; (!?) 이 코드는 실행되지 않습니다!

;----------------------------------------------------
; Comprueba si choca contra el suelo
; Out:
;   Z =	Ha chocado
;   C =	No ha chocado
;
; 땅에 닿았는지 확인
; 출력:
;   Z = 충돌했습니다
;   C = 충돌하지 않음
;----------------------------------------------------

chkChocaSuelo:
		push	hl
		dec	hl
		ld	a, (hl)		; Sentido
						; 방향
		inc	hl
		ld	bc, 50Fh	; Parte	inferior izquierda
						; 왼쪽 하단
		rra
		jr	c, chkChocaSuelo2 ; Va hacia la	izquierda
								; 왼쪽으로 간다
		ld	b, 0Bh		; Parte	inferior derecha
						; 오른쪽 아래 부분

chkChocaSuelo2:
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
								; 좌표에 해당하는 지도의 방향을 HL로 가져옵니다.
		pop	hl
		and	0F0h		; Se queda con la familia de tiles
						; 그는 타일 가족과 함께 있습니다.
		cp	10h		; Es una plataforma?
					; 플랫폼인가?
		ret	z		; Si, ha chocado
					; 네 충돌했습니다

		scf
		ret


;----------------------------------------------------
; Comprueba si hay suelo bajo los pies del prota
; Out:
;    Z = Hay suelo
;    C = No hay	suelo
;
; 주인공의 발 밑에 땅이 있는지 확인
; 출력:
;    Z = 접지가 있습니다
;    C = 접지 없음
;----------------------------------------------------

chkProtaCae:
		ld	hl, ProtaY

chkCae:
		call	chkPisaSuelo
		ret	z		; Esta pisando suelo
					; 땅을 밟고있다

		inc	hl
		inc	hl
		ld	a, (hl)		; X del	elemento
						; 요소의 X
		and	7
		cp	4		; Se encuentra en los 4	primeros pixeles de un tile?
					; 타일의 처음 4픽셀에 있습니까?
		ld	a, (hl)
		jr	nc, chkCae2	; Dependiendo del lado por el que se cae, mueve	el elemento 4 pixeles en esa direccion para separarlo de la plataforma
						; 어느 쪽에 착지하는지에 따라 해당 방향으로 항목을 4픽셀 이동하여 플랫폼에서 분리합니다.

		add	a, 4		; Desplaza el elemento 4 pixeles a la derecha
						; 요소를 오른쪽으로 4픽셀 이동

chkCae2:
		and	0FCh		; Ajusta la X a	multiplo de 4
						; X를 4의 배수로 설정
		ld	(hl), a		; Actualiza la X
						; X 업데이트
		scf
		ret

;----------------------------------------------------
; Comprueba si el elemento actual esta pisando suelo
; Tanto	el prota como las momias tienen	una altura de 16
; por lo que sumando 17	a su altura se miran lo	que hay	justo
; debajo de sus	pies
; Out:
;   DE = Puntero al tile del mapa
;    Z = Choca
;
; 현재 요소가 지상에 있는지 확인
; 주인공과 미라 모두 키가 16이므로 키에 17을 더하면 발 바로 아래에 있는 것이 보입니다.
; 출력:
;   DE = 지도 타일에 대한 포인터
;    Z = 충돌
;----------------------------------------------------

chkPisaSuelo:
		ld	bc, 611h	; Coordenadas X	+ 6, Y + 17
						; 좌표 X + 6, Y + 17
		call	chkTocaMuro	; Z = choca
							; Z = 충돌
		ret	z		; Esta sobre una plataforma
					; 플랫폼에 있습니다

		ld	bc, 0A11h	; X + 10, Y + 17

chkTocaMuro:
		push	hl		; Z = choca
						; Z = 충돌
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
								; 좌표에 해당하는 지도의 방향을 HL로 가져옵니다.
		ex	de, hl
		pop	hl

		dec	hl
		dec	hl
		dec	hl

		ld	b, (hl)		; Status
		inc	hl
		inc	hl
		inc	hl
		and	0F0h		; Se queda con la familia a la que corresponde el tile del mapa
						; 그는 지도 타일이 해당하는 가족과 함께 지냅니다.
		ld	c, a
		cp	10h		; Plataformas
					; 플랫폼
		ret	z		; Esta tocando una plataforma
					; 플랫폼을 만지고 있다

		ld	a, b		; Status
		cp	2		; Cayendo?
					; 넘어지다?
		ld	a, c		; Recupera el tipo de tile que toca
						; 닿는 타일의 유형을 검색합니다.
		jr	z, noTocaMuro

		cp	50h		; Puerta giratoria
					; 회전문
		ret

noTocaMuro:
		ld	a, c		; (!?) No hace falta
						; (!?) 불필요
		dec	b		; Set NZ
		ret

getMapOffset00:
		push	de		; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
						; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.
		push	bc
		ld	bc, 0
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
								; 좌표에 해당하는 지도의 방향을 HL로 가져옵니다.
		pop	bc
		pop	de
		ret

;----------------------------------------------------
; Obtiene el tile del mapa que hay en la coordenadas a
; las que apunta HL.
;
; In:
;  HL =	Puntero	a coordenadas (Y, X decimales, X, Habitacion)
;   B =	Offset X (puede	tener valores negativos)
;   C =	Offset Y
; Out:
;  HL =	Puntero	a la posicion del mapa de esas coordenadas
;   A =	Patron del mapa	que hay	en esas	coordenadas
;
; HL이 가리키는 좌표에서 지도 타일을 가져옵니다.
;
; 입력:
;  HL = 좌표 포인터(Y, X 소수, X, 방)
;   B = 오프셋 X(음수 값을 가질 수 있음)
;   C = 오프셋 Y
; 출력:
;  HL = 해당 좌표의 지도 위치에 대한 포인터
;   A = 해당 좌표에 있는 지도의 패턴
;----------------------------------------------------

getMapOffset:
		ld	a, (hl)		; Y
		add	a, c		; Le suma el desplazamiento Y para poder comprobar un punto determinado
					; del elemento distinto	de sus coordendas de origen
						; 요소의 원점 좌표 이외의 특정 지점을 확인할 수 있도록 Y 변위를 추가합니다.
		rra
		rra
		rra
		and	1Fh		; Ajusta la coordenada Y a patrones (/8)
					; Y 좌표를 패턴(/8)으로 설정

		ld	e, a
		ld	d, 0
		ex	de, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl		; x32

		push	bc
		ld	b, h
		ld	c, l
		add	hl, hl
		add	hl, bc		; x96 (#60) Tres pantallas en horizontal
						; x96(#60) 가로로 3개의 화면
		pop	bc

		ex	de, hl		; DE = Desplazamiento en el mapa correspondiente a la Y	(Y * 96)
					; HL = Datos del elemento (coordenadas)
					; DE = Y에 해당하는 맵의 오프셋(Y * 96)
					; HL = 요소 데이터(좌표)
		inc	hl		; Decimales X
					; 소수 X
		inc	hl
		ld	a, (hl)		; X
		inc	hl
		ld	h, (hl)		; Pantalla (0-2)
						; 디스플레이(0-2)
		ld	l, a		; HL = Coordenada X global (Pantalla + X local)
						; HL = 글로벌 X 좌표(화면 + 로컬 X)
		push	bc
		ld	c, b
		ld	b, 0
		bit	7, c		; Es negativo el offset	X?
						; 오프셋 X가 음수입니까?
		jr	z, getMapOff2	; No
		dec	b		; Convierte el valor en	negativo
					; 값을 음수로 변환

getMapOff2:
		add	hl, bc		; Offset X
		ld	a, l
		pop	bc
		srl	h
		rra
		srl	h
		rra
		srl	h
		rra
		ld	l, a		; Divide HL entre 8 para ajustar a patrones
						; 패턴에 맞게 HL을 8로 나눕니다.
		add	hl, de		; Le suma el desplazamiento Y calculado	anteriormente
						; 위에서 계산한 변위 Y를 더합니다.
		ld	de, MapaRAMRoot	; La primera fila del mapa no se usa (ocupada por el marcador).	Tambien	usado como inicio de la	pila
							; 지도의 첫 번째 행은 사용되지 않습니다(마커가 점유). 스택의 시작으로 사용됨
		add	hl, de		; Calcula puntero a la posicion	de mapa
						; 지도 위치에 대한 포인터 계산
		ld	a, (hl)		; Lee el contenido actual de esas coordenadas
						; 해당 좌표의 현재 내용 읽기
		ret

		scf			; (!?) Este codigo no se ejecuta nunca!
					; (!?) 이 코드는 실행되지 않습니다!
		ret

;----------------------------------------------------
; Comprueba si ha llegado al final de la escalera
; Out:
;   Z =	Ha llegado al final
;  NZ =	No ha llegado al final
;
; 사다리의 바닥에 도달했는지 확인하십시오.
; 출력:
;   Z = 끝에 도달했습니다
;  NZ = 끝에 도달하지 않음
;----------------------------------------------------

chkFinEscalera:
		ld	a, (hl)
		and	7
		ret	nz		; La Y no es multiplo de 8
					; Y는 8의 배수가 아닙니다.

		push	bc
		ld	bc, 810h	; Offset parte central abajo (8,16)
						; 아래 중앙 부분 오프셋(8,16)
		call	getMapOffset	; Obtiene el tile que esta en los pies
								; 발에 있는 타일을 가져옵니다.
		and	0F0h		; Se queda con la familia o tipo
						; 가족 또는 남자와 함께 숙박
		cp	10h		; Es una plataforma o incio de escalera?
					; 플랫폼인가, 계단의 시작인가?
		pop	bc
		ret	z		; Si

		and	a		; No
		ret

;----------------------------------------------------
; Comprueba si coge una	escalera
; Lo primero que se comprueba es si estan los controles	de ARRIBA o ABAJO pulsados
; Dependiendo de la posicion relativa X	respecto al tile del mapa se comprueba si sube a la derecha (0-3) o a la izquierda (4-7)
; Luego	se mira	el tile	que hay	en los pies del	personaje y se compara con el tipo de escalera anterior
; Out:
;    NZ	= No la	coge
;
; 그가 사다리를 가지고 있는지 확인하십시오.
; 가장 먼저 확인되는 것은 UP 또는 DOWN 컨트롤을 눌렀는지 여부입니다.
; 지도 타일에 대한 상대 위치 X에 따라 오른쪽(0-3) 또는 왼쪽(4-7)으로 올라가는지 확인합니다.
; 그런 다음 캐릭터의 발에 있는 타일을 보고 이전 유형의 사다리와 비교합니다.
; 출력:
;   NZ = 픽업하지 않음
;----------------------------------------------------

chkCogeEscalera:
		ld	hl, protaControl ; 1 = Arriba, 2 = Abajo, 4 = Izquierda, 8 = Derecha, #10 = Boton A, #20 =Boton	B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B

chkCogeEsc2:
		ld	a, (hl)		; Controles
						; 통제 수단
		and	3		; Arriba o abajo?
					; 위 또는 아래?
		jr	z, noCogeEscalera ; No

		rra
		jr	nc, chkBajaEscalera ; Abajo
								; 아래

		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		and	7
		jr	z, noCogeEscalera ; No esta "dentro" del tile de escalera
								; 계단 타일 "내부"가 아닙니다.

		sub	5		; Dependiendo de la posicion relativa X	respecto al tile del mapa se compruba si sube a	la derecha (0-3) o a la	izquierda (4-7)
					; 지도 타일에 대한 상대 위치 X에 따라 오른쪽(0-3) 또는 왼쪽(4-7)으로 올라가는지 확인합니다.
		ld	b, 22h		; Escaleras suben derecha
						; 오른쪽으로 올라가는 계단
		jr	c, chkCogeEsc3
		dec	b		; Escaleras suben izquierda
					; 계단은 왼쪽으로 올라간다

chkCogeEsc3:
		dec	hl
		dec	hl		; Apunta a la Y
					; Y를 가리킴
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.
		ld	a, 61h		; 3 pantallas +	1 (tile	abajo a	la derecha = Piernas del elemento)
						; 화면 3개 + 1개(오른쪽 하단 타일 = 요소의 다리)
		call	ADD_A_HL

		ld	a, (hl)		; Tile del mapa	que esta en las	piernas	del elemento
						; 요소의 다리에 있는 지도의 타일
		ld	c, a
		pop	hl		; Apunta a la Y
					; Y를 가리킴
		cp	b		; Es una escalera?
					; 사다리인가요?
		jr	z, chkSubeEsc2	; si

; Comprueba si hay un cuchillo sobre el	primer pelda�o de la escalera
; 사다리의 첫 번째 단에 칼이 있는지 확인하십시오.

		push	af
		ld	a, b
		add	a, 10h		; B = #32 o #31? (tiles	cuchillo sobre escalera)
						; B = #32 또는 #31? (사다리에 타일 칼)
		ld	b, a
		pop	af
		cp	b
		jr	nz, noCogeEscalera

chkSubeEsc2:
		and	1
		xor	1
		ld	b, a		; 1 = Escaleras	a la derecha, 0	= A la izquierda
						; 1 = 오른쪽 계단, 0 = 왼쪽 계단

		ld	a, (modoSentEsc) ; Si es 0 guarda en "sentidoEscalera" el tipo de escalera que se coge el prota. 0 = \, 1 = /
							; 0이면 주인공이 취하는 사다리의 종류를 "sentidoEscalera"에 저장합니다. 0 = \, 1 = /
		and	a
		jr	nz, chkSubeEsc3	; No guarda en sentidoEscalera el sentido de la	escalera
							; 사다리 방향의 계단 방향은 저장하지 않습니다.

		ld	a, b
		ld	(sentidoEscalera), a ; 0 = \, 1	= /
					; Tambien usado	para saber si el salto fue en vertical (guarda el estado de las	teclas en el momento del salto.
					; 또한 점프가 수직인지 확인하는 데 사용됩니다(점프 시 키의 상태를 저장합니다.

chkSubeEsc3:
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		dec	hl
		dec	hl		; Apunta a la Y
					; Y를 가리킴
		ld	de, distPeldano
		and	7		; Se queda con la X relativa del personaje respecto al tile de la escalera
					; 사다리의 타일에 대한 캐릭터의 상대적인 X를 유지합니다.
		call	ADD_A_DE
		ld	a, (de)		; Desplazamiento vertical
						; 수직 변위
		add	a, (hl)		; Se lo	suma a la Y
						; Y에 추가
		ld	(hl), a
		dec	hl
		dec	hl
		dec	hl
		ld	(hl), 3		; Status: subiendo o bajando escalera
						; 상태: 계단 오르기 또는 내리기

		xor	a
		cp	0		; Set Z, NC
		ret

;----------------------------------------------------
; Tabla	con las	distancias al primer pelda�o dependiendo
; de la	posicion del personaje respecto	al tile	del pelda�o
;
; 계단의 타일에 대한 캐릭터의 위치에 따른 첫 번째 계단까지의 거리 표
;----------------------------------------------------
distPeldano:	db 0
		db -1
		db -2
		db -3
		db -4
		db -3
		db -2
		db -1

noCogeEscalera:
		xor	a
		dec	a
		ret


;----------------------------------------------------
; Comprueba si hay escaleras para bajar	bajo los pies del personaje
; Out:
;    NC/Z = Baja escaleras
;
; 캐릭터 발 아래로 내려가는 계단이 있는지 확인
; 출력:
;    NC/Z = 아래층
;----------------------------------------------------

chkBajaEscalera:
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		and	7
		cp	4
		jr	nz, noCogeEscalera ; No	esta justo en la mitad del tile	de la escalera
								; 계단 타일의 중앙에 바로 있지 않습니다.

		dec	hl
		dec	hl
		push	hl		; Apunta a Y
						; Y를 가리키다
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표 맵에 대한 포인터를 HL에 가져옵니다.
		ld	a, 0C1h		; Fila de patrones por debajo del personaje, justo bajo	sus pies
						; #60 por fila * 2 (16 de altura) + 1 (8 pixeles) = justo bajo los pies
						; 캐릭터 아래, 발 바로 아래에 있는 일련의 패턴
						; 행당 #60 * 2(높이 16) + 1(8픽셀) = 발 바로 아래

		call	ADD_A_HL
		ld	a, (hl)		; Tile del mapa	bajo los pies
						; 발밑의 지도 타일
		ld	c, a
		pop	hl
		cp	16h		; Tile incio de	escaleras que bajan a la derecha
					; 오른쪽으로 내려가는 계단의 타일 시작
		jr	z, chkBajaEsc2

		cp	17h		; Tile inicio de escaleras que bajan a la izquierda
					; 왼쪽으로 내려가는 계단의 타일 시작
		jr	nz, noCogeEscalera

chkBajaEsc2:
		ld	a, (modoSentEsc) ; Si es 0 guarda en "sentidoEscalera" el tipo de escalera que se coge el prota. 0 = \, 1 = /
							; 0이면 주인공이 취하는 사다리의 종류를 "sentidoEscalera"에 저장합니다. 0 = 	\, 1 = /
		and	a
		jr	nz, chkBajaEsc3

		ld	a, c
		and	1		;  0 = \, 1 = /
		ld	(sentidoEscalera), a ; 0 = \, 1	= /
					; Tambien usado	para saber si el salto fue en vertical (guarda el estado de las	teclas en el momento del salto.
					; 또한 점프가 수직인지 확인하는 데 사용됩니다(점프 시 키의 상태를 저장합니다.

chkBajaEsc3:
		ld	a, (hl)		; Y
		add	a, 4
		ld	(hl), a		; Desplaza al personaje	4 pixeles hacia	abajo
						; 캐릭터를 4픽셀 아래로 이동
		dec	hl
		dec	hl
		dec	hl
		ld	(hl), 3		; Estado: Escaleras
						; 상태: 계단
		xor	a
		cp	0		; Set Z, NC
		ret

;----------------------------------------------------
; Comprueba si choca contra un muro o puerta giratoria al andar
; No hace la comprobacion si no	se pulsad DERECHA o IZQUIERDA
; Si la	X del elemento es multiplo de 8	comprueba si choca contra una puerta giratoria
; Si la	X esta en los 4	pixeles	de la derecha del tile comprueba los muros
; Out:
;    Z = No choca
;    C = Choca
;
; 걸을 때 벽이나 회전문에 부딪혔는지 확인
; RIGHT 또는 LEFT를 누르지 않았는지 확인하지 않습니다.
; 요소의 X가 8의 배수인 경우 회전문에 닿는지 확인합니다.
; X가 타일 오른쪽의 4픽셀에 있으면 벽을 확인하십시오.
; 출력:
;    Z = 충돌하지 않음
;    C = 충돌
;----------------------------------------------------

chkChocaAndar:
		ld	hl, protaControl ; 1 = Arriba, 2 = Abajo, 4 = Izquierda, 8 = Derecha, #10 = Boton A, #20 =Boton	B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B

chkChocaAndar2:
		ld	a, (hl)
		and	1100b		; Esta pulsado DERECHA o IZQUIERDA?
						; RIGHT 또는 LEFT를 눌렀습니까?
		ret	z		; No

		inc	hl

chkChocaAndar3:
		ld	b, (hl)		; Sentido
						; 방향

chkChocaAndar4:
		inc	hl		; Y
		ld	d, h
		ld	e, l
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.
		inc	de
		inc	de
		ld	a, (de)		; X
		and	7
		ld	c, 50h		; Puerta giratoria (tipo de tiles)
						; 회전문(타일식)
		jr	z, chkChocaAndar5 ; Es multiplo	de 8
								; 8의 배수이다.

		cp	4
		ld	c, 10h		; Plataformas (tipo de tiles)
						; 플랫폼(타일 유형)
		jr	nz, noChocaAndar

chkChocaAndar5:
		bit	0, b		; Sentido: 1 = Izquierda, 2 = derecha
						; 방향: 1 = 왼쪽, 2 = 오른쪽
		jr	nz, chkChocaAndar6 ; Va	a la izquierda
								; 왼쪽으로 간다

		inc	hl		; X tile mapa +	1
					; X 타일 맵 + 1
		and	a		; La coordenada	X del elemento es multiplo de 8
					; 요소의 X 좌표는 8의 배수입니다.
		jr	z, chkChocaAndar6

		inc	hl		; Incrementa en	1 la X del tile	del mapa a comprobar
					; 확인하고자 하는 지도의 타일의 X를 1만큼 증가

chkChocaAndar6:
		ld	a, (hl)		; Tile del mapa
						; 지도 타일
		and	0F0h		; Se queda con la familia o tipo de tile
						; 가족 또는 타일 유형과 함께 유지
		cp	c		; Es una puerta	giratoria o muro?
					; 회전문인가 벽인가?
		jr	z, chocaAndar	; Choca
							; 충돌하다

		ld	a, 60h		; Distancia al tile que	esta justo debajo (Y + 1)
						; 바로 아래 타일까지의 거리(Y + 1)
		call	ADD_A_HL
		ld	a, (hl)		; Obtiene tile del mapa
						; 지도 타일 가져오기
		and	0F0h		; Se queda con el tipo de tile
						; 그것은 타일의 종류와 함께 유지
		cp	c
		jr	nz, noChocaAndar ; No choca
							; 충돌하지 않는다

chocaAndar:
		scf
		ret

noChocaAndar:
		and	a
		ret



;----------------------------------------------------
;
; Sprite prota sin nada	en las manos
; 손에 아무것도 없는 주인공 스프라이트
;
;----------------------------------------------------
GFX_Prota:	db 0, 18h, 86h,	0, 1, 3, 0, 7, 8, 3, 0,	8Dh, 1,	2, 2, 1	; ...
		db 0, 0, 1, 0, 0C0h, 0E0h, 0, 0F0h, 8, 3, 0, 87h, 0C0h
		db 60h,	0, 0C0h, 0, 0, 0C0h, 3,	0, 8Ch,	3, 0, 3, 7, 3
		db 1, 0, 1, 1, 0, 1, 1,	4, 0, 93h, 0E0h, 0, 0F0h, 0E0h
		db 0F0h, 0C0h, 0, 80h, 0E0h, 0,	80h, 80h, 0, 0,	1, 3, 0
		db 7, 8, 3, 0, 3, 3, 2,	9, 3, 0, 85h, 0C0h, 0E0h, 0, 0F0h
		db 8, 3, 0, 87h, 0C0h, 0, 0C0h,	0C0h, 0, 0, 0E0h, 3, 0
		db 86h,	3, 0, 3, 7, 3, 1, 3, 0,	2, 6, 5, 0, 93h, 0E0h
		db 0, 0F0h, 0F0h, 0E0h,	0C0h, 0, 0E0h, 0, 0, 0C0h, 0C0h
		db 0, 0, 1, 3, 0, 7, 8,	3, 0, 2, 3, 2, 1, 89h, 0, 0Ch
		db 8, 0, 0C0h, 0E0h, 0,	0F0h, 8, 3, 0, 86h, 60h, 0C0h
		db 0C0h, 0C8h, 88h, 18h, 4, 0, 8Ch, 3, 0, 3, 7,	3, 1, 4
		db 0Ch,	4, 2, 7, 2, 4, 0, 8Bh, 0E0h, 0,	0F0h, 0F0h, 0E0h
		db 0C0h, 80h, 30h, 20h,	0, 70h,	1, 0, 0

;----------------------------------------------------
;
; Sprite prota con cuchillo
; 칼을 든 주인공 스프라이트
;
;----------------------------------------------------
GFX_ProtaKnife:	db 0, 18h, 86h,	0, 1, 3, 0, 7, 8, 3, 0,	8Ch, 1,	3, 3, 1	; ...
		db 0, 0, 1, 0, 0C0h, 0E4h, 0Ch,	0FCh, 4, 0Ch, 87h, 0D6h
		db 0F0h, 84h, 0CAh, 0, 0, 0C0h,	3, 0, 86h, 3, 0, 3, 7
		db 3, 1, 4, 0, 2, 1, 4,	0, 93h,	0E0h, 0, 0F0h, 0F0h, 0E0h
		db 0C0h, 8, 0Ch, 70h, 0, 80h, 80h, 0, 0, 1, 3, 0, 7, 8
		db 3, 0, 3, 3, 2, 9, 3,	0, 84h,	0C8h, 0D8h, 18h, 0F8h
		db 4, 18h, 87h,	7Ch, 0,	0D4h, 0C0h, 0, 0, 0E0h,	3, 0, 86h
		db 3, 0, 3, 7, 3, 1, 3,	0, 2, 6, 5, 0, 82h, 0E0h, 0, 3
		db 0E0h, 8Eh, 0C0h, 80h, 0F8h, 0, 0, 0C0h, 0C0h, 0, 0
		db 1, 3, 0, 7, 8, 3, 0,	2, 3, 2, 1, 92h, 0, 0Ch, 8, 0
		db 0C2h, 0E6h, 6, 0F6h,	0Eh, 6,	6, 0Fh,	60h, 0E5h, 0C0h
		db 0C8h, 88h, 18h, 4, 0, 8Ch, 3, 0, 3, 7, 3, 1,	4, 0Ch
		db 8, 2, 7, 2, 4, 0, 96h, 0E0h,	0, 0F0h, 0F0h, 0E0h, 0C0h
		db 9Eh,	18h, 0,	0, 70h,	0, 0, 0C0h, 0E1h, 77h, 30h, 3
		db 20h,	4, 2, 1, 3, 3, 3, 0, 91h, 0Eh, 0, 0C0h,	0E0h, 0
		db 0F0h, 88h, 50h, 20h,	0, 0E0h, 0C0h, 80h, 80h, 0, 0
		db 38h,	3, 0, 86h, 0Bh,	1Ch, 0Fh, 1Bh, 1Dh, 0Eh, 3, 0
		db 83h,	3, 7, 6, 4, 0, 8Ch, 0E0h, 0, 70h, 0A0h,	0C0h, 0E0h
		db 0, 0, 60h, 70h, 30h,	30h, 3,	0, 8Ah,	1, 3, 4, 8, 4
		db 0, 3, 2, 7, 3, 3, 0,	8Dh, 0Eh, 0, 0,	0C0h, 0E0h, 10h
		db 8, 10h, 20h,	40h, 0,	80h, 40h, 3, 0,	81h, 70h, 4, 0
		db 8Bh,	3, 7, 3, 1, 0, 1, 0, 4,	6, 6, 0Ch, 5, 0, 8Ch, 0E0h
		db 0F0h, 0E0h, 0C0h, 80h, 0E0h,	70h, 90h, 0E0h,	60h, 60h
		db 0, 0

;----------------------------------------------------
;
; Sprite prota con el pico
; 곡괭이가 있는 주인공 스프라이트
;
;----------------------------------------------------
GFX_ProtaPico:	db 0, 18h, 96h,	0, 1, 3, 0, 67h, 4, 18h, 0Ch, 6, 1, 3
		db 3, 1, 0, 0, 1, 0, 0C0h, 0E0h, 0, 0F0h, 8, 3,	0, 2, 0C0h
		db 8Fh,	80h, 0C0h, 0, 0, 0C0h, 0, 8, 10h, 3, 10h, 33h
		db 27h,	23h, 21h, 2, 3,	0, 2, 1, 4, 0, 96h, 0E0h, 0, 0F0h
		db 0F0h, 0E0h, 0C0h, 20h, 10h, 78h, 0, 80h, 80h, 0, 0
		db 1, 3, 0, 7, 60h, 20h, 8, 4, 3, 3, 2,	9, 3, 0, 85h, 0C0h
		db 0E0h, 0, 0F0h, 8, 3,	0, 95h,	0C0h, 0, 0C0h, 0C0h, 0
		db 0, 0E0h, 0, 0, 8, 1Bh, 10h, 13h, 17h, 63h, 41h, 40h
		db 0, 0, 6, 6, 5, 0, 97h, 0E0h,	0, 0F0h, 0F0h, 0E0h, 0C0h
		db 0, 0E0h, 0, 0, 0C0h,	0C0h, 0, 0, 1, 3, 0, 7,	48h, 80h
		db 18h,	0Eh, 3,	3, 1, 89h, 0, 0Ch, 8, 0, 0C0h, 0E0h, 0
		db 0F0h, 8, 3, 0, 86h, 60h, 0E8h, 0C0h,	0C8h, 88h, 18h
		db 3, 0, 8Dh, 10h, 33h,	20h, 23h, 67h, 0E3h, 81h, 84h
		db 8Ch,	8, 2, 7, 2, 4, 0, 8Bh, 0E0h, 0,	0F0h, 0F0h, 0E0h
		db 0C0h, 90h, 10h, 0, 0, 70h, 3, 0, 85h, 1, 3, 0, 7, 8
		db 3, 0, 3, 3, 3, 0, 91h, 0Eh, 0, 0, 0F0h, 10h,	0F0h, 10h
		db 10h,	0, 20h,	0A0h, 40h, 80h,	80h, 0,	0, 1Ch,	3, 0, 86h
		db 3, 0, 3, 0Fh, 7, 3, 3, 0, 93h, 3, 7,	6, 0, 10h, 0F8h
		db 4, 0E2h, 0, 0E0h, 0E0h, 0F0h, 0D0h, 40h, 80h, 60h, 60h
		db 30h,	18h, 3,	0, 9Eh,	1, 3, 4, 8, 4, 0, 3, 2,	7, 3, 0
		db 0, 8, 0Eh, 0, 0, 0C0h, 0E0h,	10h, 8,	10h, 20h, 80h
		db 40h,	0A0h, 50h, 18h,	8, 0, 60h, 4, 0, 8Bh, 3, 7, 3
		db 1, 0, 1, 0, 4, 6, 4,	4, 5, 0, 8Ch, 0E0h, 0F0h, 0E0h
		db 0C0h, 0, 80h, 40h, 0A2h, 0C2h, 42h, 46h, 0Ch, 0

;----------------------------------------------------
; Graficos de la momia
; 미라 그래픽
;----------------------------------------------------
GFX_MOMIA:	db 40h,	19h, 82h, 0, 3,	4, 7, 86h, 3, 3, 7, 4, 7, 7, 4
		db 3, 92h, 0, 0C0h, 0E0h, 40h, 0E0h, 0E0h, 0C0h, 80h, 0E0h
		db 80h,	60h, 80h, 80h, 0, 0, 80h, 0, 3,	4, 7, 8Eh, 3, 3
		db 7, 4, 7, 7, 1Fh, 1Eh, 11h, 1, 0, 0C0h, 0E0h,	40h, 3
		db 0E0h, 8Bh, 0C0h, 80h, 0E0h, 0B0h, 0C0h, 0C0h, 80h, 80h
		db 0C0h, 0, 3, 4, 7, 9Ah, 3, 3,	7, 6, 5, 1, 3, 7, 0Eh
		db 8, 0, 0C0h, 0E0h, 40h, 0E0h,	0, 0E0h, 0C0h, 0E0h, 78h
		db 48h,	0C0h, 0E8h, 0F8h, 18h, 0, 0

;----------------------------------------------------------------------------
;
; Sprites secundarios:
; Destello, muro, exploxion, cuchillo
;
; 보조 스프라이트:
; 플래시, 벽, 폭발, 칼
;----------------------------------------------------------------------------
GFX_SPRITES2:	db 0A0h, 1Eh, 2, 0, 8Dh, 20h, 0, 8, 4, 0, 0, 0B0h, 0, 0	; ...
		db 4, 8, 0, 20h, 3, 0, 8Dh, 82h, 0, 88h, 90h, 0, 0, 0Dh
		db 0, 0, 90h, 88h, 0, 82h, 0Ah,	0, 2, 44h, 85h,	7Eh, 10h
		db 10h,	7Eh, 44h, 18h, 0, 8, 0FFh, 10h,	0, 8Fh,	44h, 7Eh
		db 10h,	10h, 7Eh, 44h, 44h, 7Eh, 10h, 10h, 7Eh,	44h, 44h
		db 7Eh,	10h, 11h, 0, 10h, 0FFh,	12h, 0,	8Ch, 1,	0Ah, 1Fh
		db 1Fh,	0Fh, 17h, 3Fh, 1Fh, 7, 0Fh, 0Bh, 6, 4, 0, 8Ch
		db 80h,	0E0h, 0F0h, 0F0h, 0E0h,	0F0h, 0E8h, 0F8h, 0F8h
		db 0D0h, 0F0h, 0C0h, 6,	0, 87h,	2, 7, 3, 5, 7, 3, 1, 9
		db 0, 86h, 0C0h, 0A0h, 0F0h, 0D0h, 0E0h, 0A0h, 6, 0, 87h
		db 0C0h, 0E0h, 74h, 38h, 1Ch, 2Eh, 4, 19h, 0, 87h, 3, 7
		db 2Eh,	1Ch, 38h, 74h, 20h, 19h, 0, 87h, 40h, 0E8h, 70h
		db 38h,	5Ch, 0Eh, 6, 19h, 0, 87h, 2, 17h, 0Eh, 1Ch, 3Ah
		db 70h,	60h, 19h, 0, 0

;----------------------------------------------------------------------------
;
; Graficos del juego (plataformas, escaleras, cuchillo,	gemas...)
;
; 게임 그래픽(플랫폼, 계단, 칼, 보석...)
;----------------------------------------------------------------------------
GFX_InGame:	db 3, 0FEh, 81h, 0, 3, 0EFh, 83h, 0, 0FFh, 0FFh, 6, 0
		db 3, 0FFh, 5, 0, 84h, 80h, 0C1h, 63h, 0, 3, 0F7h, 82h
		db 0, 81h, 4, 0, 89h, 0C1h, 0E3h, 0, 0C0h, 0E0h, 74h, 38h
		db 1Ch,	28h, 6,	0, 92h,	5, 3, 7, 2, 0, 0, 60h, 0E0h, 0C0h
		db 80h,	0, 80h,	50h, 0E0h, 70h,	0B8h, 1Ch, 0Ch,	4, 0, 8Ch
		db 1, 0, 1, 3, 7, 6, 0,	0, 40h,	0E0h, 0C0h, 0A0h, 3, 0
		db 84h,	24h, 18h, 18h, 7Eh, 3, 18h, 88h, 20h, 18h, 0Ch
		db 0Ch,	1Ah, 33h, 61h, 0C0h, 26h, 0, 0A2h, 49h,	2Ah, 2
		db 1, 4, 2, 0, 6, 0, 0,	40h, 80h, 20h, 40h, 0, 60h, 0
		db 0, 0FFh, 80h, 0EEh, 0EEh, 80h, 0BBh,	0BBh, 80h, 0FFh
		db 1, 0EFh, 0EFh, 1, 0BBh, 0BBh, 1, 30h, 0, 82h, 7Eh, 81h
		db 3, 18h, 2, 3Ch, 85h,	18h, 7Eh, 0E7h,	0C3h, 0C3h, 3
		db 0E7h, 83h, 0FFh, 81h, 7Eh, 6, 0, 5, 0F0h, 83h, 0B0h
		db 10h,	0D0h, 4, 0Fh, 2, 0Eh, 84h, 8, 0Bh, 70h,	70h, 6
		db 0F0h, 8, 0Fh, 81h, 0FFh, 4, 0, 87h, 0FCh, 0F0h, 0C0h
		db 0FFh, 0FCh, 0F0h, 0C0h, 8, 0, 2, 1, 2, 0Fh, 2, 0, 3
		db 1Fh,	8Dh, 0FFh, 0, 0, 0FFh, 0, 0FFh,	0, 0, 0FFh, 0
		db 0, 0Ah, 0Ah,	4, 0Eh,	2, 0Ah,	2, 0E0h, 4, 0A0h, 2, 0E0h
		db 8, 3Fh, 8, 70h, 0B0h, 0FFh, 0DDh, 0DDh, 81h,	0F7h, 0F7h
		db 81h,	0DDh, 0DDh, 81h, 0F7h, 0F7h, 81h, 0DDh,	0DDh, 81h
		db 0F7h, 0F7h, 81h, 0DDh, 0DDh,	81h, 0F7h, 0FFh, 0Fh, 0Dh
		db 0Dh,	8, 0Fh,	0Fh, 8,	0Dh, 0Dh, 8, 0Fh, 0Fh, 8, 0Dh
		db 0Dh,	8, 0D0h, 10h, 70h, 70h,	10h, 0D0h, 0D0h, 10h, 3
		db 0Fh,	9Dh, 8,	0Dh, 0Dh, 8, 0Fh, 0F9h,	3, 0, 6Eh, 2Eh
		db 0, 0Eh, 6, 0F9h, 3, 0, 0F0h,	0, 0E0h, 0E0h, 0EFh, 0
		db 0EEh, 6Eh, 2Eh, 0, 0Eh, 6, 2, 3, 0, 85h, 0F0h, 0, 0E0h
		db 0E0h, 0EFh, 0


GFX_GEMA:	db 88h,	0, 3Ch,	7Eh, 0BFh, 9Fh,	0DFh, 7Eh, 3Ch,	0
;----------------------------------------------------
;
; Colores de los patrones del juego
;
; 게임 패턴 색상
;
;----------------------------------------------------
COLOR_InGame:	db 3, 0F0h, 5, 0A0h, 5,	0F0h, 3, 0A0h, 7, 0F0h,	4, 0A0h	; ...
		db 5, 0F0h, 5, 0A0h, 3,	0F0h, 5, 0A0h, 3, 0F0h,	5, 0A0h
		db 3, 0F0h, 4, 90h, 4, 60h, 20h, 0, 18h, 0A0h, 40h, 50h
		db 82h,	90h, 96h, 3, 0F6h, 3, 0A6h, 81h, 60h, 3, 6Ah, 4
		db 6Fh,	81h, 96h, 7, 90h, 81h, 3Eh, 4, 3Ah, 3, 30h, 81h
		db 3Eh,	3, 3Ah,	6, 30h,	8Eh, 3Eh, 3Fh, 3Fh, 3Eh, 3Fh, 3Fh
		db 3Eh,	3Fh, 3Eh, 3Fh, 3Fh, 3Eh, 3Fh, 3Fh, 5, 0EAh, 3
		db 0A0h, 81h, 0EAh, 7, 0A0h, 5,	0F0h, 83h, 0E0h, 0F0h
		db 0E0h, 3, 0F0h, 2, 0E0h, 0Bh,	0FEh
;----------------------------------------------------
; Colores de los patrones invertidos (el mismo que los normales)
; 반전 패턴 색상(일반과 동일)
;----------------------------------------------------
COLOR_Flipped:	db 8, 50h, 8, 0F0h, 8, 50h, 8, 0F0h, 38h, 30h, 82h, 0EAh
		db 0F9h, 6, 0F0h, 82h, 0EAh, 0EFh, 16h,	0F0h, 0

COLOR_GEMAS:	db 8, 40h, 8, 70h, 8, 0D0h, 8, 0A0h, 8,	20h, 8,	0E0h, 0	; ...

;--------------------------------------------------------------------------------------------------------
;
; Logica de los	cuchillos
;
; 칼의 논리
;--------------------------------------------------------------------------------------------------------

AI_Cuchillos:
		xor	a
		ld	(knifeEnProceso), a

AI_Cuchillos2:
		ld	hl, chkLastKnife
		push	hl		; Mete en la pila la rutina que	comprueba si se	han procesado todos los	cuchillos
						; 모든 나이프가 스택에서 처리되었는지 확인하는 루틴을 푸시합니다.

		xor	a		; Offset al status del cuchillo
					; 나이프 상태에 대한 오프셋
		call	getKnifeData	; Obtiene el indice del	cuchillo que se	esta procesando
								; 처리 중인 칼의 인덱스를 가져옵니다.
		call	jumpIndex

		dw initCuchillo		; 0 - Inicializacion del cuchillo. Guarda tile de fondo
		dw doNothing_		; 1 - Posado en	el suelo
		dw doNothing_		; 2 - Lo lleva el prota	en la mano
		dw doNothing_
		dw lanzaCuchillo	; 4 - Lanza un cuchillo
		dw movKnife		; 5 - Cuchillo por el aire
		dw knifeChoca		; 6 - Acaba de chocar el cuchillo
		dw knifeRebota		; 7 - Esta rebotando
		dw knifeCae		; 8 - Esta cayendo
	IF	(!VERSION2)
		dw updateKnifeAtt	; 9 - Actualiza	los atributos RAM del sprite del cuchillo
	ENDIF

		; 0 - 칼 초기화. 배경 타일 저장
		; 1 - 땅에 있다
		; 2 - 주인공이 손에 들고 있습니다.
		; 4 - 칼을 던지다
		; 5 - 공중의 칼
		; 6 - 그냥 칼을 치다
		; 7 - 튀는 중
		; 8 - 떨어지는 중

		; 9 - 나이프 스프라이트의 RAM 속성 업데이트

;----------------------------------------------------
; Knife	Status 0: Comprueba el tile que	tiene de fondo y lo guarda
; Si esta sobre	un pelda�o de escalera lo cambia por un	tile de	cuchillo especial que indica que hay escalera detras
; Pasa al siguiente estado (1)
;
; 나이프 상태 0: 배경 타일 확인 및 저장
; 사다리 가로대에 있는 경우 뒤에 사다리가 있음을 나타내는 특수 칼 타일로 변경됩니다.
; 다음 상태로 이동 (1)
;----------------------------------------------------

initCuchillo:
		xor	a
		call	getKnifeData	; Obtiene puntero a los	datos del cuchillo
								; 나이프 데이터에 대한 포인터 가져오기
		inc	(hl)		; Lo pasa al status 1
						; 상태 1로 전달합니다.
		inc	hl
		inc	hl		; Apunta a la Y	del cuchillo
					; 칼의 Y를 가리킴
		call	getMapOffset00	; Obtiene el tile del mapa sobre el que	esta el	cuchillo
								; 칼이 있는 지도의 타일을 가져옵니다.
		ex	de, hl
		ld	a, 0Ah		; Offset tile backup
						; 오프셋 타일 백업
		call	getKnifeData
		ld	a, (de)		; Tile que hay en el mapa RAM
						; RAM 맵에 있는 타일
		ld	b, a
		and	0F0h
		cp	30h		; Comprueba si se trata	de un cuchillo
					; 칼인지 확인
		jr	z, initCuchillo2
		ld	(hl), b		; Guarda el tile que hay detras	del cuchillo
						; 칼 뒤에 타일을 저장

initCuchillo2:
		ld	a, b
	IF	(VERSION2)
		sub	#31		; Cuchillo sobre pelda�o?
					; 가로대에 칼?
		cp	2		; Dos posibles direcciones de las escaleras (cuchillo sobre pelda�o hacia la derecha y sobre pelda�o a la izquierda)
					; 계단의 두 가지 가능한 방향(오른쪽 가로대와 왼쪽 가로대에 칼)
		ld	a,b
		jr	c,initCuchillo5

		ld	a,b		; (!?) No hace falta ponerlo! A ya es igual a B
					; (!?) 넣을 필요 없어요! A는 이미 B와 같다
		sub	#21		; Pelda�o de escalera que sube a la izquierda
					; 왼쪽으로 올라가는 계단
		cp	2		; Comprueba los dos tipos de pelda�o (derecha e izquierda)
					; 2종류의 렁(좌우) 확인
		jr	nc,initCuchillo4

		ld	a,b
	ELSE
		cp	31h		; Cuchillo sobre pelda�o?
					; 가로대에 칼?
		jr	z, initCuchillo6

		cp	21h		; Pelda�o escalera que sube a la izquierda
					; 왼쪽으로 올라가는 사다리
		jr	z, initCuchillo3

		cp	22h		; Pelda�o escalera que sube a la derecha
					; 오른쪽으로 올라가는 사다리
		jr	nz, initCuchillo4
	ENDIF
initCuchillo3:
		add	a, 10h		; Convierte el tile de cuchillo	en "cuchillo sobre pelda�o"
						; 칼 타일을 "장대 위의 칼"으로 변환합니다.
		jr	initCuchillo5

initCuchillo4:
		ld	a, 30h		; ID tile cuchillo suelo
						; ID 타일 그라운드 나이프

initCuchillo5:
		ld	(de), a		; Actualiza el mapa RAM
						; RAM 맵 업데이트
		xor	a
		call	getKnifeData
		ld	a, 4Bh		; Patron de cuchillo posado
						; 앉은 칼 패턴
		jp	drawTile

	IF	(!VERSION2)
initCuchillo6:
		ld	a, 31h
		jr	initCuchillo5
	ENDIF

doNothing_:
		ret

;--------------------------------------------------------------------------------------------------------
;
; Lanza	un cuchillo
; Reproduce sonido de lanzar
; Coloca el cuchillo en	las coordendas del prota
; Guarda los tiles del mapa sobre los que se pinta
;
; 칼을 던지다
; 던지는 소리를 재생
; 칼을 주인공의 좌표에 놓는다
; 그려진 지도의 타일을 저장합니다.
;--------------------------------------------------------------------------------------------------------

lanzaCuchillo:
		ld	a, 6
		call	setMusic	; Sonido lanzar
							; 소리 던지기

		ld	a, 6
		call	getKnifeData	; Obtiene puntero a la velocidad decimal
								; 소수 속도에 대한 포인터 가져오기
		ex	de, hl
		ld	hl, knifeDataInicio
		ld	bc, 0Bh
		ldir			; Inicializa los valores de este cuchillo
						; 이 칼의 값을 초기화

		call	knifeNextStatus	; Pasa al siguiente estado
								; 다음 상태로 이동
		inc	hl
		ld	de, sentidoProta ; 1 = Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
		ex	de, hl
		ld	a, (hl)		; Sentido del lanzamiento
						; 발사 방향
		ld	bc, 5
		ldir			; Copia	el sentido y coordenadas del prota
						; 주인공의 방향과 좌표를 복사

		dec	de
		dec	de		; Cuchillo X
		dec	hl
		dec	hl		; Prota	X
		ld	b, 8		; Desplazamiento X cuando se lanza a la	derecha
						; 오른쪽으로 캐스팅할 때 X 오프셋
		rr	a		; 1 = Izquierda, 2 = Derecha
					; 1 = 왼쪽, 2 = 오른쪽
		jr	nc, lanzaCuchillo2
		ld	b, 0		; Desplazamiento cuando	se lanza a la izquierda
						; 왼쪽으로 캐스팅할 때 오프셋

lanzaCuchillo2:
		ld	a, (hl)
		add	a, b		; Suma desplazamiento a	la X
						; X에 오프셋 추가
		and	0F8h		; Lo ajusta a patrones (multiplo de 8)
						; 패턴으로 설정합니다(8의 배수).
		set	2, a		; Le suma 4
						; 4 추가
		ld	(de), a		; Actualiza X del cuchillo
						; 칼의 업그레이드 X
		dec	de
		dec	de		; Y cuchillo
		ex	de, hl		; HL apunta a las coordenadas del cuchillo
						; HL은 칼의 좌표를 가리킵니다.
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표 맵에 대한 포인터를 HL에 가져옵니다.
		ex	de, hl
		ld	a, 0Ah		; Offset backup	fondo
						; 배경 오프셋 백업
		call	getKnifeData
		ex	de, hl
		ldi
		ldi			; Guarda tiles del mapa	sobre los que se pinta el cuchillo
					; 칼이 그려진 지도 타일 저장
		ret

;----------------------------------------------------
; Obtiene el frame del cuchillo	segun su posicion X en pantalla
; 화면의 X 위치에 따라 칼의 프레임을 가져옵니다.
;----------------------------------------------------

getFrameKnife:
		ld	a, 4		; Offset X cuchillo
		call	getKnifeData
		rra
		rra
		and	3		; Cambia el frame cada cuatro pixeles
					; 4픽셀마다 프레임 변경
		ld	de, framesCuchillo
		call	ADD_A_DE
		ld	a, (de)
		ret


;----------------------------------------------------
; Patrones usados para pintar el cuchillo
; 칼을 칠하는 데 사용되는 패턴
;----------------------------------------------------
framesCuchillo:	db 45h
					; Girando NO
		db 46h			; Girando NE
		db 48h			; Girando SE
		db 49h			; Girando SO
		db 4Bh			; Clavado en el	suelo
			; 북쪽으로 돌리다
			; 북동쪽으로 돌리다
			; 남동쪽으로 돌리다
			; 남쪽으로 돌리다
			; 땅에 못을 박았다

;--------------------------------------------------------------------------------------------------------
; Mueve	al cuchillo lanzado
; Comprueba si choca contra una	puerta giratoria
; Copia	y restaura el fondo sobre el que va pasando
;
; 던진 칼을 움직여
; 회전문을 두드렸는지 확인
; 통과하는 배경 복사 및 복원
;--------------------------------------------------------------------------------------------------------

movKnife:
		ld	a, 6		; Offset velocidad cuchillo
						; 오프셋 나이프 속도
		call	getKnifeData
		ld	e, (hl)
		inc	hl
		ld	d, (hl)		; DE = velocidad del cuchillo
						; DE = 나이프 속도
		ld	a, 3		; Offset X decimales
		call	getKnifeData
		call	mueveElemento	; Actualiza coordenadas	del cuchillo segun su velocidad
								; 속도에 따라 칼의 좌표 업데이트

		ld	a, d		; X cuchillo
		and	3
		ret	nz		; No es	multiplo de 4
					; 4의 배수가 아니다.

		ld	a, d
		and	7
		jr	z, movKnife3	; Es multiplo de 8
							; 8의 배수이다.

; Multiplo de 4
; 4의 배수

		ld	a, d
		cp	8
		ret	c		; Menor	de 8. Pegado al	limite izquierdo de la pantalla
					; 8개 미만. 화면 왼쪽 가장자리에 부착

		cp	252
		ret	nc		; Mayor	o igual	a 252. Pegado al limite	derecho	de la pantalla
					; 252 이상. 화면 오른쪽 가장자리에 부착

		call	getFrameKnife	; Obtiene frame	actual de la animacion del cuchillo
								; 칼 애니메이션의 현재 프레임 가져오기
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		call	drawTile	; Dibuja primer	tile del cuchillo
							; 첫 번째 칼 타일 그리기

	IF	(VERSION2)
		jr	nz,movKnife1	; Si no esta en pantalla no lo pinta
							; 화면에 없으면 그리지 마세요.
	ENDIF

		inc	a
		inc	hl
		call	WRTVRM		; segundo tile del cuchillo
							; 두 번째 칼 타일
movKnife1:
		ld	a, 1		; Offset sentido
						; 방향 오프셋
		call	getKnifeData
		push	hl		; Apunta al sentido
						; 방향을 가리키다
		ld	a, (hl)		; Sentido
						; 방향
		inc	hl		; Apunta a la Y
					; Y 를 가리키다
		push	af
		call	getMapOffset00	; Obtiene un puntero HL	a la posicion del cuchillo en el mapa RAM
								; RAM 맵에서 칼 위치에 대한 HL 포인터를 가져옵니다.
		pop	af
		rra
		jr	c, movKnife2	; Izquierda
							; 왼쪽
		inc	hl		; Tile de la derecha
					; 오른쪽 타일

; Restaura una puerta giratoria	si el cuchillo choca contra ella
; 칼에 맞으면 회전문을 복원합니다.

movKnife2:
		ld	a, (hl)		; Tile del mapa
						; 지도 타일
		and	0F0h		; Se queda con la familia o tipo de tile
						; 가족 또는 타일 유형과 함께 유지
		cp	50h		; Puerta giratoria
					; 회전문
		pop	hl		; Apunta al sentido
					; 방향을 가리키다
		ret	nz		; No ha	chocado	con una	puerta
					; 그는 문을 두드리지 않았다

		dec	hl		; Apunta al estado
					; 상태를 가리키다
		inc	(hl)		; Pasa al siguiente estado del cuchillo	(5)
						; 칼의 다음 상태로 이동 (5)
		push	hl
		ld	a, 0Ah		; Offset tile de fondo
						; 배경 오프셋 타일

		call	getKnifeData
		ex	de, hl
		pop	hl
		push	de
		call	getTileFromID
		call	drawTile	; Restaura el tile de fondo 1
							; 배경 타일 1을 복원합니다.
		pop	de
		ret	nz		; No esta en la	pantalla actual
					; 현재 화면에 없습니다

		inc	hl		; Siguiente posicion VRAM (ocupa dos tiles)
					; 다음 VRAM 위치(2개의 타일을 차지함)
		inc	de		; Siguiente tile backup	del cuchillo
					; 다음 칼 백업 타일
		ld	a, (de)
		call	getTileFromID	; Identifica tile que le corresponde
								; 해당 타일을 식별합니다.
		jp	WRTVRM		; Lo pinta
						; 페인트

; Multiplo de 8
; 8의 배수

movKnife3:
		ld	a, 1		;  Offset sentido
		call	getKnifeData
		push	hl
		pop	ix

		call	getFrameKnife	; Frame	que le corresponde al cuchillo
								; 칼에 해당하는 프레임
		ld	b, a

		xor	a
		call	getKnifeData	; Puntero a los	datos del cuchillo
								; 나이프 데이터에 대한 포인터

		ld	a, b		; Frame	del cuchillo
						; 칼 프레임
		call	drawTile

		ld	a, 2		; Offset Y
		call	getKnifeData
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.

		ld	a, (ix+0)	; Sentido
						; 방향
		inc	hl		; Tile de la derecha del cuchillo
					; 칼 오른쪽 타일
		rr	a
		push	af
		jr	nc, movKnife4	; Derecha
							; 오른쪽
		dec	hl
		dec	hl		; Tile de la izquierda
					; 왼쪽 타일

movKnife4:
		pop	af
		ld	a, (hl)		; Tile del mapa	de fondo
						; 배경 맵 ​​타일
		jr	nc, movKnife5	; Derecha
							; 오른쪽

		ld	d, (ix+0Ah)	; tile de fondo	2
						; 배경 타일 2
		ld	c, (ix+9)	; tile de fondo	1
						; 배경 타일 1
		ld	(ix+0Ah), c
		ld	(ix+9),	a	; Actualiza la copia de	los tiles de fondo
						; 배경 타일의 복사본 업데이트
		jr	movKnife6

movKnife5:
		ld	d, (ix+9)	; Tile backup 1
		ld	c, (ix+0Ah)	; Tile backup 2
		ld	(ix+9),	c
		ld	(ix+0Ah), a	; Actualiza la copia de	los tiles de fondo
						; 배경 타일의 복사본 업데이트

movKnife6:
		ld	b, (ix+4)	; Pantalla en la que esta el cuchillo (xHigh)
						; 칼이 있는 화면(xHigh)
		ld	a, (ProtaRoom)	; Pantalla del prota
							; 주인공 화면
		cp	b
		jr	nz, movKnife8	; No estan en la misma,	no hace	falta pintarlo
							; 그것들은 동일하지 않으며 페인트 할 필요가 없습니다.

		ld	a, d		; Tile de fondo	a restaurar
						; 복원할 배경 타일
		call	getTileFromID
		push	af
		ld	a, 2		; Offset Y
		call	getKnifeData
		ld	d, (hl)		; Y
		inc	hl
		inc	hl		; X
		ld	e, (hl)		; DE = YX
		call	coordVRAM_DE	; Obtiene puntero a la VRAM correspondiente a las coordenadas del cuchillo
								; 나이프 좌표에 해당하는 VRAM에 대한 포인터 가져오기

		dec	hl		; Puntero VRAM
					; VRAM 포인터
		ld	a, (ix+0)	; Sentido
						; 방향
		rra
		jr	nc, movKnife7	; Derecha
							; 오른쪽
		inc	hl
		inc	hl

movKnife7:
		pop	af
		call	WRTVRM		; Restaura fondo
							; 배경 복원

movKnife8:
		push	ix
		push	de
		call	chkKnifeMomia	; Comprueba si choca con una momia
								; 미라와 충돌하는지 확인
		pop	de
		pop	ix
		jr	nc, movKnife9	;  No ha chocado contra	una momia
							; 미라와 충돌하지 않았다

		xor	a
		call	getKnifeData
		jr	movKnife11

movKnife9:
		ld	a, 2		; Y
		call	getKnifeData
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표의 맵에 대한 포인터를 HL에 가져옵니다.
		dec	hl
		ld	a, (ix+0)	; Sentido
						; 방향
		rra
		jr	c, movKnife10	; Izquierda
							; 왼쪽
		inc	hl
		inc	hl

movKnife10:
		ld	a, (hl)
		ld	b, a
		pop	hl		; Y
		call	chkKnifeChoca	; Comprueba si el tile es una plataforma, cuchillo, pico o gema
							; 타일이 플랫폼, 칼, 곡괭이 또는 보석인지 확인하십시오.
		jr	nz, knifeNoChoca ; No choca contra nada
							; 그것은 아무것도 치지 않는다

		ld	a, b
		cp	40h		; Gemas
					; 보석
		jr	z, knifeNoChoca	; Contra las gemas no choca el cuchillo
							; 칼이 치지 않는 보석에 대하여

		dec	hl
		dec	hl		; Apunta al status
					; 지위를 노린다

movKnife11:
		inc	(hl)		; Pasa al siguiente estado del cuchillo: choca
						; 칼의 다음 상태로 이동: 충돌
		inc	hl
		ld	b, (hl)		; Sentido
						; 방향
		inc	hl
		inc	hl
		inc	hl

movKnife12:
		inc	hl
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
							; X 좌표의 상단 피라미드의 방을 나타냅니다.
		cp	(hl)		; esta en la misma pantalla el cuchillo	y el prota?
						; 칼과 주인공이 같은 화면에 있습니까?
		ret	nz		; No esta en la	pantalla actual. No se ve
					; 현재 화면에 없습니다. 본적이 없다

		ld	a, 5
		call	ADD_A_HL	; Puntero a los	tiles de backup	de fondo
							; 배경 백업 타일에 대한 포인터
		rr	b		; Sentido
					; 방향
		jr	nc, knifeRestaura ; Derecha
							; 오른쪽
		inc	hl

knifeRestaura:
		ld	a, (hl)		; Backup tile
		call	getTileFromID	; Obtiene patron que le	corresponde
								; 일치하는 패턴 가져오기
		call	coordVRAM_DE	; D = Y, E = X
		jp	WRTVRM		; Pinta	el patron en pantalla
						; 화면에 패턴 칠하기

knifeNoChoca:
		dec	hl
		ld	b, (hl)
		inc	hl
		inc	hl
		inc	hl
		xor	a
		cp	(hl)
		jr	z, movKnife12
		ld	a, 0F8h
		cp	(hl)
		jr	z, movKnife12
		ret

;----------------------------------------------------
;
; Cuchillo choca
; Pasa al estado de rebotando, invierte	el sentido y lo	mueve 4	pixeles	hacia atras
;
; 칼 충돌
; 튀는 상태로 이동하여 방향을 반전하고 4픽셀 뒤로 이동합니다.
;
;----------------------------------------------------

knifeChoca:
		call	knifeNextStatus	; Pasa al estado de rebotando
								; 튀는 상태로 이동
		inc	hl
		ld	a, (hl)
		xor	3
		ld	(hl), a		; Invierte el sentido
						; 방향를 뒤집다
		inc	hl
		inc	hl
		inc	hl
		rra
		ld	a, (hl)		; X
		jr	c, knifeChoca2	; Izquierda
							; 왼쪽
		add	a, 4

knifeChoca2:
		and	0F8h
		ld	(hl), a
		ld	a, 5
		call	ADD_A_HL
		ld	(hl), 0
		ret

;----------------------------------------------------
;
; Cuchillo rebotando
; Realiza una parabola que simula un rebote.
; Comprueba si choca contra algo mientras rebota.
; Al terminar pasa al siguiente	estado:	caer
;
; 튀는 칼
; 리바운드를 시뮬레이션하는 포물선을 만듭니다.
; 튀는 동안 무언가에 부딪히는지 확인하십시오.
; 완료되면 다음 상태인 추락으로 이동합니다.
;----------------------------------------------------

knifeRebota:
		ld	a, (timer)
		and	3
		jp	nz, updateKnifeAtt ; Actualiza las coordenadas 1 de cada 4 frames. El resto los	atributos del sprite
								; 4 프레임마다 좌표 1을 업데이트합니다. 나머지는 스프라이트의 속성

		ld	a, 1		; Offset sentido
		call	getKnifeData
		push	hl
		ld	a, (hl)		; Sentido
						; 방향
		inc	hl
		inc	hl
		inc	hl
		inc	(hl)		; Incrementa la	X
						; X 증가
		rra
		jr	nc, knifeRebota2 ; Derecha
							; 오른쪽

		dec	(hl)
		dec	(hl)		; Decrementa la	X (rebota hacia	la izquierda)
						; X 감소(왼쪽으로 바운스)

knifeRebota2:
		pop	hl
		call	chkPasaRoom	; Comprueba si pasa a otra habitacion
							; 다른 방으로 넘어가는지 확인

		ld	a, 9
		call	getKnifeData
		ld	a, (hl)		; Contador de movimiento
						; 이동 카운터

		ld	hl, parabolaKnife
		call	ADD_A_HL
		ld	b, (hl)		; Desplazamiento Y del rebote para simular una parabola
						; 포물선을 시뮬레이션하기 위한 바운스의 오프셋 Y

		ld	a, 2		; Y
		call	getKnifeData
		ld	a, (hl)		; Y del	cuchillo
						; 칼의 Y
		add	a, b		; Le suma el desplazamiento de la parabola
						; 포물선의 변위 추가
		ld	(hl), a		; Actualiza la Y del cuchillo
						; 칼의 Y 업데이트

		push	hl
		ld	bc, 408h	; Offset X+4, Y+8
		call	getMapOffset	; Lee tile del mapa
								; 지도 타일 읽기
		ld	a, (hl)		; Obtiene el tile que hay justo	debajo del cuchillo
						; 칼 바로 아래에 타일을 가져옵니다.
		call	chkKnifeChoca	; Comprueba si el tile es una plataforma, cuchillo, pico o gema
								; 타일이 플랫폼, 칼, 곡괭이 또는 보석인지 확인하십시오.
		pop	hl
		jr	nz, knifeRebota3 ; No choca con	nada
							; 어떤 것과도 충돌하지 않는다

		ld	a, b		; Tile del mapa
						; 지도 타일
		cp	41h		; Brillo gema izquierda
					; 왼쪽 보석 광택
		jr	z, knifeRebota3

		cp	42h		; Brillo gema derecha
					; 오른쪽 보석 광택
		jr	z, knifeRebota3

		and	0F0h
		cp	10h		; Es una plataforma, muro o ladrillo?
					; 플랫폼입니까, 벽입니까, 아니면 벽돌입니까?
		jr	nz, setReboteKnife ; Da	otro rebote para no caer sobre el objeto
								; 물체에 떨어지지 않도록 다시 바운스하십시오.

		jr	knifeEnd

knifeRebota3:
		ld	a, 7
		call	ADD_A_HL
		inc	(hl)		; Incrementa contador de movimiento
						; 이동 카운터 증가

		ld	a, (hl)
		cp	8		; Ha terminado la parabola del rebote? (8 frames)
					; 바운스 비유가 끝났습니까? (8 프레임)
		jp	z, knifeNextStatus ; Si, pasa a	estado de caer
								; 네, 떨어지는 상태가 됩니다.
		jp	updateKnifeAtt


;----------------------------------------------------
; Valores de la	parabola del rebote del	cuchillo
; 나이프 리바운드 포물선의 값
;----------------------------------------------------
parabolaKnife:	db -5
		db -2
		db -1
		db 0
		db 0
		db 1
		db 2
		db 5

;----------------------------------------------------
; Status cuchillo = Caer
; 칼 상태 = 추락
;----------------------------------------------------

knifeCae:
		ld	a, (timer)
		and	3
		jp	nz, updateKnifeAtt ; Actualiza las coordenadas 1 de cada 4 frames
								; 4 프레임마다 좌표 1 업데이트

		ld	a, 2		; Offset Y
		call	getKnifeData
		ld	a, (hl)		; Y del	cuchillo
		and	0FCh		; Lo ajusta a multiplo de 4
						; 4의 배수로 설정
		ld	(hl), a

		ld	d, (hl)		; (!?) Por que no hace un LD D,A
		ld	a, d
		and	3		; (!?) Si acaba	de hacer un AND	#FC como va a haber un NZ con un AND 3?
					; (!?) AND #FC만 하면 AND 3이 있는 NZ가 어떻게 될까요?
		jp	nz, caeKnife4

		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
								; HL이 가리키는 좌표 맵에 대한 포인터를 HL에 가져옵니다.
		ld	a, 60h		; Offset al tile que esta debajo del cuchillo
						; 칼 아래에 있는 타일에 오프셋
		call	ADD_A_HL
		ld	a, (hl)		; Tile del mapa	bajo el	cuchillo
						; 칼 아래 지도의 타일
		call	chkKnifeChoca	; Comprueba si el tile es una plataforma, cuchillo, pico o gema
								; 타일이 플랫폼, 칼, 곡괭이 또는 보석인지 확인하십시오.
		jp	nz, caeKnife4	; No choca con nada
							; 어떤 것과도 충돌하지 않는다

		ld	a, b
		cp	41h		; Brillo izquierdo
					; 왼쪽 밝기
		jp	z, caeKnife4

		cp	42h		; Brillo derecho
					; 오른쪽 밝기
		jp	z, caeKnife4	; Si cae sobre los brillos no pasa nada
							; 반짝이 위에 떨어지면 아무 일도 일어나지 않아

		and	0F0h
		cp	10h		; Es ladrillo?
					; 벽돌이야?
		jr	nz, setReboteKnife ; Rebota si cae sobre un obstaculo que no es	un brillo o ladrillo
								; 반짝이나 벽돌이 아닌 장애물에 떨어지면 튕깁니다.

knifeEnd:
		call	hideKnifeSpr
		xor	a
		call	getKnifeData

	IF	(VERSION2)
		jr	setReboteKnife2	; Apa�o para ahorrar un byte
							; 바이트 저장 수정
	ELSE
		ld	(hl), 0
		ret
	ENDIF
;----------------------------------------------------
; Reinicia el rebote del cuchillo
; 칼 바운스 재설정
;----------------------------------------------------

setReboteKnife:
		xor	a
		call	getKnifeData
		ld	(hl), 7		; Status 7 = Rebote
						; 상태 7 = 바운스
		ld	a, 9
		call	ADD_A_HL
setReboteKnife2:
		ld	(hl), 0		; Contador de movimiento/rebote	= 0
						; 이동/바운스 카운터 = 0
		ret

;----------------------------------------------------
; Le suma 4 a la Y del cuchillo	y lo ajusta a multiplo de 4
; 칼의 Y에 4를 더하고 4의 배수로 조정합니다.
;----------------------------------------------------

caeKnife4:
		ld	a, 2		; Y
		call	getKnifeData

	IF	(VERSION2)
		ld	a,(hl)
		add	a,4
	ELSE
		inc	(hl)
		inc	(hl)
		inc	(hl)
		inc	(hl)		; Y+4
		ld	a, (hl)
	ENDIF
		and	0FCh
		ld	(hl), a
		jp	updateKnifeAtt

;----------------------------------------------------
; Comprueba si el tile es una plataforma, gema,	cuchillo o gema
; Out:
;   Z =	Si es uno de esos elementos
;   B =	Tile de	entrada
;
; 타일이 플랫폼, 보석, 칼 또는 보석인지 확인하십시오.
; 출력:
;   Z = 해당 요소 중 하나인 경우
;   B = 입력 타일
;----------------------------------------------------

chkKnifeChoca:
		ld	b, a		; Comprueba si el tile es una plataforma, cuchillo, pico o gema
						; 타일이 플랫폼, 칼, 곡괭이 또는 보석인지 확인하십시오.
		and	0F0h
		cp	10h		; Plataformas
					; 플랫폼
		ret	z

		cp	30h		; Cuchillo
					; 칼
		ret	z

		cp	80h		; Pico
					; 곡괭이
		ret	z

		cp	40h		; Gemas
					; 보석
		ret


;----------------------------------------------------
; Actualiza los	atributos RAM del sprite del cuchillo
; 칼 스프라이트의 RAM 속성 업데이트
;----------------------------------------------------

updateKnifeAtt:
		ld	a, 5		; Offset pantalla en la	que esta el cuchillo
						; 칼이 있는 오프셋 화면
		call	getKnifeData
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
							; X 좌표의 상단 피라미드의 방을 나타냅니다.
		cp	(hl)
		jr	nz, hideKnifeSpr ; No esta en la pantalla actual, asi que lo oculta
							; 현재 화면에 없으니 숨기세요.

		dec	hl
		dec	hl
		dec	hl		; Y
		push	hl
		call	getKnifeAttib
		ex	de, hl
		pop	hl
		ld	a, (hl)		; Y
		ld	(de), a		; Atributo Y
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		inc	de
		ld	(de), a		; Atributo X
		inc	de
		ld	a, (timer)
		and	0Ch		; Se queda con 4 sprites de 16x16 (0, 4, 8, 12)
					; 16x16(0, 4, 8, 12)의 4개의 스프라이트가 남습니다.
		add	a, 0F0h		; Primer sprite	del cuchillo
						; 칼 퍼스트 스프라이트
		ex	de, hl
		ld	(hl), a		; Sprite del cuchillo
						; 칼 스프라이트
		inc	hl
		ld	(hl), 0Fh	; Color	blanco
						; 흰색
		ret

;----------------------------------------------------
; Comprueba si se han procesado	todos los cuchillos
; 모든 칼이 가공되었는지 확인
;----------------------------------------------------

chkLastKnife:
		ld	hl, knifeEnProceso
		inc	(hl)
		ld	a, (hl)
		inc	hl
		cp	(hl)
		jp	nz, AI_Cuchillos2
		ret

;----------------------------------------------------
; Quita	al cuchillo del	area visible
; 보이는 부분에서 칼을 빼주세요
;----------------------------------------------------

hideKnifeSpr:
		call	getKnifeAttib
		ld	(hl), 0E0h
		ret


;----------------------------------------------------
; Pasa el cuchillo al siguiente	estado
; 칼을 다음 상태로 넘기기
;----------------------------------------------------

knifeNextStatus:
		xor	a
		call	getKnifeData
		inc	(hl)
		ret


;----------------------------------------------------
; Obtiene puntero a los	datos del cuchillo actual
; In: A	= Offset a la variable de la estructura
; Out:
;   HL = Puntero a los datos del cuchillo (variable indicada en	A)
;    A = Valor de la variable
;
; 현재 칼 데이터에 대한 포인터 가져오기
; 입력: A = 구조 변수에 대한 오프셋
; 출력:
;   HL = 나이프 데이터에 대한 포인터(A에 표시된 변수)
;    A = 변수 값
;----------------------------------------------------

getKnifeData:
		push	bc
		ld	hl, knifesData	; 0 = Status (1	= suelo, 2 = Cogido, 4 = Lanzamiento?, 5= lanzado, 7 =Rebotando)
					; 1 = Sentido (1 = izquierda, 2	= Derecha)
					; 2 = Y
					; 3 = X	decimales
					; 4 = X
					; 5 = Habitacion
					; 6 = Velocidad	decimales
					; 7 = Velocidad	cuchillo
					; 8 = Velocidad	cambio habitacion
					; 9 = Contador movimiento
					; A = Tile backup 1 (fondo)
					; B = Tile backup 2 (guarda dos	tiles al lanzarlo)

					; 0 = 상태(1 = 땅, 2 = 잡힘, 4 = 시작?, 5= 던짐, 7 = 튕김)
					; 1 = 방향(1 = 왼쪽, 2 = 오른쪽)
					; 2 = 그리고
					; 3 = X 소수 자릿수
					; 4 = X
					; 5 = 방
					; 6 = 십진법 속도
					; 7 = 나이프 속도
					; 8 = 방 변경 속도
					; 9 = 이동 카운터
					; A = 타일 백업 1(백그라운드)
					; B = 타일 백업 2(시전 시 타일 2개 저장)
		call	ADD_A_HL
		ld	a, (knifeEnProceso)
		ld	b, a
		add	a, a
		call	getIndexX8_masB
		pop	bc
		ret


;----------------------------------------------------
; Calcula la direccion de la tabla de nombres a	la que apunta DE
; In:
;   D =	Y
;   E =	X
; Out:
;   HL = Puntero VRAM
;
; DE가 가리키는 이름 테이블의 주소를 계산합니다.
; 입력:
;   D = Y
;   E = X
; 출력:
;   HL = VRAM 포인터
;----------------------------------------------------

coordVRAM_DE:
		push	af		; D = Y, E = X
		ld	h, d
		ld	l, e
		ld	a, h
		rra
		rra
		rra
		rra
		rr	l
		rra
		rr	l
		rra
		rr	l
		and	3
		add	a, 38h		; Tabla	de nombre en #3800
						; #3800의 이름표
		ld	h, a
		pop	af
		ret


;----------------------------------------------------
; Obtiene un puntero a los atributos del cuchillo en proceso
; 처리 중인 칼의 속성에 대한 포인터 가져오기
;----------------------------------------------------

getKnifeAttib:
		ld	a, (knifeEnProceso)
		ld	hl, knifeAttrib
		jp	getMomiaAtrib2



;----------------------------------------------------
;
; Comprueba si el cuchillo choca contra	una momia
; Out:
;   NC,	Z = No ha chocado
;   C =	Ha chocado
;
; 칼이 미라를 치는지 확인하십시오.
; 출력:
;   NC, Z = 충돌하지 않음
;   C = 충돌
;----------------------------------------------------

chkKnifeMomia:
		ld	c, 0		; Primera momia	a procesar = 0
						; 처리할 첫 번째 미라 = 0

chkKnifeMomia2:
		ld	a, c		; Momia	a procesar
						; 처리할 미라
		call	getMomiaDat

		ld	a, (ix+ACTOR_STATUS) ; Status de la momia
								; 미라 상태
		cp	4		; Esta en el limbo, apareciendo	o explotando?
					; 림보에 있습니까, 나타나거나 폭발합니까?
		jr	c, chkKnifeMomia3

		cp	7		; Esta pensando?
					; 그는 생각하고 있습니까?
		jr	nz, chkKnifeMomia4 ; Esta en un	estado que no hay que comprobar	la colision
								; 충돌 확인이 필요 없는 상태입니다

chkKnifeMomia3:
		ld	a, 2		; Offset Y
		call	getKnifeData
		ld	d, (hl)		; Y
		inc	hl
		inc	hl
		ld	e, (hl)		; X
		inc	hl
		ld	a, (hl)		; habitacion
		cp	(ix+ACTOR_ROOM)
		jr	nz, chkKnifeMomia4 ; No	estan en la misma habitacion
								; 그들은 같은 방에 있지 않다

		push	bc
		ld	c, (ix+ACTOR_Y)	; Y momia
		ld	b, (ix+ACTOR_X)	; X momia
		ld	hl, areaSizeMomia
		call	chkArea
		pop	bc
		jr	c, chkKnifeMomia5

chkKnifeMomia4:
		inc	c
		ld	hl, numMomias
		ld	a, c
		cp	(hl)		; Ha comprobado	todas las momias?
						; 미라를 모두 확인하셨나요?
		jp	nz, chkKnifeMomia2
		and	a
		ret

chkKnifeMomia5:
	IF	(VERSION2)
		push	ix
		ld	de, 100h
		call	SumaPuntos
		ld	a, 8		; SFX explota momia
						; SFX 미라 폭발
		call	setMusic
		pop	ix
	ELSE
		ld	de, 100h
		call	SumaPuntos
		ld	a, 8		; SFX explota momia
		call	setMusic
	ENDIF
		ld	(ix+ACTOR_STATUS), 6 ; Estado: Destello
								; 상태: 플래시
		ld	(ix+ACTOR_CONTROL), 4 ;	Control: IZQUIERDA
								; 컨트롤: 왼쪽
		ld	a, (ix+ACTOR_Y)	; Y momia
		and	0F8h
		ld	(ix+ACTOR_Y), a	; Ajusta la Y a	multiplo de 8
							; Y를 8의 배수로 설정
		ld	(ix+ACTOR_TIMER), 22h ;	Timer
		scf
		ret


;----------------------------------------------------
; Area a comprobar el impacto del cuchillos
; 칼날의 충격을 확인하는 영역
;----------------------------------------------------
areaSizeMomia:	db 8, 18h
		db 8, 18h


;----------------------------------------------------
; Comprueba si el prota	coge un	cuchillo
; En caso de cogerlo, restaura en el mapa y en pantalla	el tile	sobre el que estaba el cuchillo
;
; 주인공이 칼을 집는지 확인
; 잡으면 맵과 화면에서 칼이 있던 타일을 복원해줍니다.
;----------------------------------------------------

chkCogeKnife:
		ld	a, (objetoCogido) ; #10	= Cuchillo, #20	= Pico
		and	a
		ret	nz		; Ya lleva algo

		ld	hl, knifeEnProceso
		ld	(hl), a
		inc	hl
		cp	(hl)
		ret	z		; No hay cuchillos en esta piramide

chkCogeKnife2:
		xor	a
		call	getKnifeData	; Datos	del cuchillo
		call	getLocationDE	; Comprueba si esta en la misma	habitacion que el prota
		jr	nz, chkCogeKnife3 ;  No	estan en la misma habitacion

		cp	1		; Esta en reposo en el suelo? (Status =	1)
		jr	nz, chkCogeKnife3 ; No,	comprueba el siguiente cuchillo

		call	chkAreaItem	; Comprueba si el prota	esta en	contacto con el	cuchillo
		jr	c, chkCogeKnife4 ; Si!

chkCogeKnife3:
		ld	hl, knifeEnProceso
		inc	(hl)
		ld	a, (hl)
		inc	hl
		cp	(hl)
		jr	nz, chkCogeKnife2
		ret

chkCogeKnife4:
		ld	a, (knifeEnProceso)
		ld	(IDcuchilloCoge), a ; Cuchillo que coge	el prota

		ld	a, 4		; SFX coge objeto
		call	setMusic

		ld	a, 10h		; Cuchillo
		call	cogeObjeto	; Carga	los sprites del	prota con el cuchillo

		xor	a
		call	getKnifeData
		inc	(hl)		; Pasa el cuchillo al siguiente	estado (2 = Lo lleva el	prota)

		ld	d, h
		ld	e, l
		push	hl
		ld	bc, 0Ah		; Offset tile backup del mapa
		add	hl, bc
		ld	b, (hl)		; Tile sobre el	que estaba el cuchillo
		pop	hl		; Apunta al estado

		inc	hl
		inc	hl		; Apunta a la Y
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ld	(hl), b		; Restaura el tile del mapa
		ld	h, d
		ld	l, e		; Recupe puntero a los datos del cuchillo (status)
		ld	a, b		; Tile del mapa
		call	getTileFromID	; Obtiene patron que le	corresponde al tile
		jp	drawTile	; Lo dibuja en pantalla


;----------------------------------------------------
; Obtiene las coordenadas del elemento y comprueba si esta en la misma habitacion que el prota
; In: HL = Puntero a Y,	X, habitacion
; Out:
;    Z = Esta en la habitacion del prota
;    D = Y
;    E = X
;
; 요소의 좌표를 가져와 주인공과 같은 방에 있는지 확인
; 입력: HL = Y, X, 방에 대한 포인터
; 출력:
;    Z = 주인공의 방에 있습니다.
;    D = Y
;    E = X
;----------------------------------------------------

getLocationDE:
		inc	hl

getLocationDE2:
		inc	hl

getLocationDE3:
		ld	d, (hl)		; Y
		inc	hl
		inc	hl
		ld	e, (hl)		; X
		inc	hl
		ld	b, a
		ld	c, (hl)		; Habitacion
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	c		; Esta en la misma pantalla que	el prota?
		ld	a, b
		ret


;----------------------------------------------------
; Dibuja un cuchillo
; In: HL = Puntero a status, sentido, Y, X, habitacion
;
; 칼을 뽑다
; 입력: HL = 상태, 방향, Y, X, 방에 대한 포인터
;----------------------------------------------------

drawTile:
		call	getLocationDE
		ret	nz		; No esta en la	habitacion visible

		call	coordVRAM_DE	; Pasa coordenadas en DE a direccion de	VRAM
	IF	(VERSION2)
		call	WRTVRM
		ld	b,1
		dec	b
		ret
	ELSE
		jp	WRTVRM		; Escribe un dato en la	VRAM
	ENDIF

;----------------------------------------------------
;
; Comprueba si el prota	coge una gema
;
; 주인공이 보석을 가져가는지 확인
;
;----------------------------------------------------

chkCogeGema:
		xor	a
		ld	(ElemEnProceso), a ; Empezamos por la primera gema

chkCogeGema2:
		xor	a
		call	getGemaDat	; Puntero a los	datos de la gema
		call	getLocationDE	; Esta en la pantalla del prota?
		jr	nz, chkCogeGema3

		and	0Fh		; A = Color de la gema
		jr	z, chkCogeGema3	; Color	0

		call	chkAreaItem	; Comprueba si el prota	esta tocando la	gema
		jr	nc, chkCogeGema3 ; No

		ld	de, 500h
		call	SumaPuntos	; Suma 500 puntos

		ld	a, 9		; SFX coger gema
		call	setMusic

		ld	a, 1		; Offset status
		call	getGemaDat
		ld	(hl), 2		; Status = Gema	cogida.	Hay que	borrarla

chkCogeGema3:
	IF	(VERSION2)
		call	chkLastGema2
		jr	nz,chkCogeGema2
		ret
	ELSE
		ld	hl, ElemEnProceso ; Usado para saber la	gema o puerta que se esta procesando
		inc	(hl)		; Siguiente gema
		ld	a, (hl)
		dec	hl		; Puntero a gemas totales en la	piramide
		cp	(hl)		; Quedan gemas por comprobar?
		jr	nz, chkCogeGema2
		ret
	ENDIF
;----------------------------------------------------
; Offset X al centro del objeto, ancho area a comprobar	(ancho prota)
; Offset Y al centro del objeto, alto area (parte superior del prota)
; Para colisiones con objetos se comprueba la parte superior del prota
; con el centro	superior del objeto
;
; X 오프셋을 개체 중심, 확인할 영역 너비(너비 비례)
; 객체의 중심에 Y 오프셋, 높이 영역(본체 상단)
; 물체와의 충돌의 경우 주인공의 상단이 물체의 상단 중앙에 대해 확인됩니다.
;----------------------------------------------------
itemHitArea:	db 5, 11h
		db 1, 9


;----------------------------------------------------
; Comprueba si el prota	coge un	pico
;
; 주인공이 곡괭이를 들고 있는지 확인
;----------------------------------------------------

chkCogePico:
		ld	a, (objetoCogido) ; #10	= Cuchillo, #20	= Pico
		and	a
		ret	nz		; Ya lleva algo


		ld	hl, numPicos
		ld	a, (hl)
		or	a
		ret	z		; No hay picos

		xor	a
		ld	(ElemEnProceso), a ; Comienza a	comprobar desde	el primer pico

	IF	(!VERSION2)
		inc	hl		; (!?) No se usa!
	ENDIF

chkNextPico:
		xor	a
		call	getPicoData	; Obtiene puntero a los	datos del pico
		call	getLocationDE2	; Comprueba si esta en la misma	habitacionq ue el prota
		jr	nz, chkLastPico	; No, pasa al siguiente	pico

		and	a		; Esta activo o	ya ha sido cogido?
		jr	z, chkLastPico	; No esta activo. Pasa al siguiente

		call	chkAreaItem	; Comprueba si el prota	toca el	pico
		jr	nc, chkLastPico	; No, pasa al siguiente

		ld	a, 4		; SFX Coger objeto
		call	setMusic

		xor	a
		call	getPicoData	; Puntero a los	datos del pico

		ld	(hl), 0		; Marca	pico como usado	(lo desactiva)
		push	hl
		inc	hl		; Apunta a la Y
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL

		xor	a
		ld	(hl), a		; Borra	el pico	del mapa
		pop	hl
		dec	hl
		call	drawTile	; Borra	el pico	de la pantalla

		ld	a, (ElemEnProceso) ; Usado para	saber la gema o	puerta que se esta procesando
		ld	(idxPicoCogido), a ; Indice del	pico cogido por	el prota
		ld	a, 20h		; Pico
		jp	cogeObjeto	; Carga	los sprites del	prota llevando el pico

chkLastPico:
		ld	hl, ElemEnProceso ; Usado para saber la	gema o puerta que se esta procesando
		inc	(hl)
		ld	a, (numPicos)
		cp	(hl)
		jr	nz, chkNextPico
		ret

;----------------------------------------------------
; Obtiene un puntero a los datos del pico en proceso
;
; 처리 중인 피크 데이터에 대한 포인터 가져오기
;----------------------------------------------------

getPicoData:
		ld	a, (ElemEnProceso) ; Usado para	saber la gema o	puerta que se esta procesando
		ld	hl, picosData	; Datos	de los picos
		ld	b, a
		jp	getIndexX4_masB


;----------------------------------------------------
; Comprueba si el prota	toca a una momia
; La momia tiene que estar viva	y en un	estado activo
; Si el	prota o	la momia esta en una escalera, ambos tendran que estar en escaleras para que se	compruebe la colision
;
; 주인공이 미라를 만지는지 확인
; 미라는 살아 있고 활동적인 상태여야 합니다.
; 주인공이나 미라가 사다리 위에 있는 경우 충돌을 확인하려면 둘 다 사다리 위에 있어야 합니다.
;----------------------------------------------------

chkTocaMomia:
		ld	c, 0		; Comienza por la primera momia

chkNextMomia:
		ld	a, c
		call	getMomiaDat	; Obtiene puntero a los	datos de la momia
		ld	hl, (pMomiaProceso) ; Puntero a	los datos de la	momia en proceso
		ld	a, (hl)
		cp	4		; Esta andando,	saltando, cayendo o en unas escaleras?
		jr	c, chkTocaMomia2 ; Si

		cp	7		; Esta pensando?
		jr	nz, chkLastACTOR_ ; No,	pasa a la siguiete momia

chkTocaMomia2:
		ld	a, (protaStatus) ; Status del prota
		ld	b, a
		cp	3		; Esta en unas escaleras?
		jr	z, chkTocaMomia3 ; si

		ld	a, (hl)		; Status de la momia
		cp	3		; Esta la momia	en unas	escaleras?
		jr	nz, chkTocaMomia4 ; No

chkTocaMomia3:
		ld	a, b
		cp	(hl)		; Estan	ambos en unas escaleras?
		jr	nz, chkLastACTOR_ ; No,	entonces no se comprueba si se tocan

chkTocaMomia4:
		ld	a, (ProtaRoom)	; Habitacion en	la que esta el prota
		cp	(ix+ACTOR_ROOM)	; Habitacion en	la que esta la momia
		jr	nz, chkLastACTOR_ ; No estan en	la misma habitacion

		ld	d, (ix+ACTOR_Y)	; Y momia
		ld	e, (ix+ACTOR_X)	; X momia
		ld	hl, mummyHitArea
		call	chkTocaProta	; Comprueba si el prota	toca a la momia
		jr	c, momiaMataProta ; Si,	se tocan. El prota muere

chkLastACTOR_:
		inc	c		; Siguiente momia
		ld	hl, numMomias	; Numero de momias de la piramide
		ld	a, c
		cp	(hl)		; Ha comprobado	todas las momias?
		jp	nz, chkNextMomia ; No

		and	a
		ret

momiaMataProta:
		ld	a, 1Dh		; Musica muere prota
		call	setMusic
		xor	a
		ld	(flagVivo), a	; Mata al prota
		ret


;----------------------------------------------------
; Offset X al centro de	la momia, ancho	del area a comprobar (ancho prota)
; Offset Y al centro de	la momia, alto del area	(alto prota)
; Para colisiones con momias se	comprueba el area total	del prota
; con el centro	de la momia
;
; X를 미라 중심으로 오프셋, 확인할 영역의 너비(너비 비례)
; 미라 중심에 Y 오프셋, 면적 높이(주인공 높이)
; 미라와의 충돌의 경우 미라 중심으로 주인공의 전체 면적을 확인합니다.
;----------------------------------------------------
mummyHitArea:	db 5, 0Ah
		db 8, 10h


;----------------------------------------------------
; Comprueba si el prota	esta tocando las coordenadas
; del objeto DE
;
; 주인공이 DE 객체의 좌표를 만지고 있는지 확인하십시오.
;----------------------------------------------------

chkAreaItem:
		ld	hl, itemHitArea

chkTocaProta:
		push	bc
		ld	a, (ProtaY)
		ld	c, a
		ld	a, (ProtaX)
		ld	b, a
		call	chkArea
		pop	bc
		ret

;----------------------------------------------------
; Comprueba si las coordendas DE estan dentro de una
; determinada area
;
; DE indica las	coordenadas del	punto a	comprobar
; E = X	punto
; D = Y	punto
; A DE se le aplica un desplazamiento para indicar que
; punto	exacto del elemento se quiere comprobar	(por ejemplo el	centro de una momia)
;
; BC incia las coordenadas del area a comprobar
; B = X	area
; C = Y	area
; El Tama�o del	area viene indicado por	HL+1 y HL+3

; HL:
; +0 = Offset X1
; +1 = Ancho area
; +2 = Offset Y1
; +3 = Alto area
;
; DE 좌표가 특정 영역 내에 있는지 확인
;
; DE는 확인할 점의 좌표를 나타냅니다.
; E = X 포인트
; D = Y 포인트
; DE에 오프셋을 적용하여 검사할 요소의 정확한 지점(예: 미라의 중심)을 나타냅니다.
;
; BC는 확인할 영역의 좌표를 초기화합니다.
; B = X 영역
; C = Y 영역
; 영역의 크기는 HL+1 및 HL+3으로 표시됩니다.

; HL:
; +0 = 오프셋 X1
; +1 = 면적 너비
; +2 = 오프셋 Y1
; +3 = 높은 지역
;
;----------------------------------------------------

chkArea:
		ld	a, b		; X area
		sub	e		; X punto
		sub	(hl)		; Offset X del punto
		inc	hl
		add	a, (hl)		; Ancho	del area
		jr	nc, chkArea2	; No esta dentro

		ld	a, c		; Y area
		sub	d		; Y punto
		inc	hl
		sub	(hl)		; Offset Y del punto
		inc	hl
		add	a, (hl)		; Alto del area

chkArea2:
		ret

;----------------------------------------------------
;
; Mueve	el scroll 4 posiciones dependiendo del sentido del protagonista
;
; Si ha	movido una pantalla completa o cambia el 'flagScrolling' termina.
;
; 주인공의 센스에 따라 스크롤을 4단 이동
;
; 전체 화면을 이동하거나 변경하면 'flagScrolling'이 종료됩니다.
;
;----------------------------------------------------

tickScroll:
		ld	hl, waitCounter
	IF	(VERSION2)
		ld	a,(hl)
		sub	4
		ld	(hl),a
	ELSE
		dec	(hl)
		dec	(hl)
		dec	(hl)
		dec	(hl)		; Mueve	el scroll 4 posiciones
		ld	a, (hl)
	ENDIF
		cp	0FCh
		ret	z		; Ha llegado al	final

		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
		rra
		ld	a, (hl)
		jr	c, tickScroll2
		sub	20h
		neg

tickScroll2:
		call	tickScroll3
		ld	a, (flagScrolling)
		and	a
		ret	z
		scf
		ret

tickScroll3:
		ld	b, a		; Desplazamiento relativo a la habitacion actual
		ld	hl, ProtaRoom	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
		cp	3
		jr	nz, tickScroll4
		ld	a, 1

tickScroll4:
		add	a, (hl)
		cp	3
		ld	a, 20h
		jr	z, tickScroll5
		xor	a

tickScroll5:
		add	a, b
		ld	de, MapaRAM
		call	ADD_A_DE	; Aplica desplazamiento


;----------------------------------------------------
; Dibuja la habitacion actual
; In:
;  DE =	Puntero	al mapa	de la habitacion
;
; 현재 방 그리기
; 입력:
;  DE = 룸 맵에 대한 포인터
;----------------------------------------------------

drawRoom:
		ld	hl, 3820h	; Segunda fila de la pantalla (la primera esta reservada para el marcador)
		call	setVDPWrite
		ld	b, 16h		; Numero de filas (alto	en tiles)

drawRoom2:
		push	bc
		push	de
		ld	b, 20h		; Numero de columnas (ancho en tiles)

drawRoom3:
		ld	a, (de)		; ID tile
		call	getTileFromID
		exx
		out	(c), a
		exx
		inc	de
		djnz	drawRoom3

		pop	de
		ld	a, 60h		; Desplazamiento a la siguiente	fila (3*32)
		call	ADD_A_DE
		pop	bc
		djnz	drawRoom2	; Dibuja siguiente fila
		ret

;----------------------------------------------------
;
; Obtiene el patron/tile que corresponde al "ID" del mapa
; In:  A = Map ID
; Out: A = Tile	ID
;
; 지도의 "ID"에 해당하는 패턴/타일 가져오기
; 입력: A = 지도 ID
; 출력: A = 타일 ID
;
;----------------------------------------------------

getTileFromID:
		push	hl
		ld	c, a
		rra
		rra
		rra
		and	1Eh		; El nibble alto indica	el grupo de tiles
		ld	hl, indexTiles
		call	getIndexHL_A
		ld	a, c
		and	0Fh		; El nibble bajo indica	el indice dentro del grupo
		call	ADD_A_HL
		ld	a, (hl)		; Obtiene el patron que	corresponde con	ese ID del mapa
		pop	hl
		ret



indexTiles:	dw tilesNULL
		dw tilesPlataforma	; #10
		dw tilesEscalera	; #20
		dw tilesCuchillo	; #30
		dw tilesGemas		; #40
		dw tilesGiratoria	; #50
		dw tilesSalida		; #60
		dw tilesSalida2		; #70
		dw tilePico		; #80

	IF	(!VERSION2)
		dw byte_5DC3		; #90 (!?) Estos bloques no se usan!
		dw byte_5DC4		; #A0
		dw byte_5DC6		; #B0
		dw byte_5DC7		; #C0
	ENDIF
		dw tilesAgujero		; #D0

tilesNULL:	db    0
		db    0

tilesPlataforma:db    0
		db    0			; Vacio
		db 40h
		db 40h			; Ladrillo
		db 41h			; Limite inferior
		db 73h			; Inicio de escalera que baja hacia la derecha (parte izquierda)
		db 74h			; Inicio de escalera que baja hacia la derecha (Parte derecha)
		db 83h			; Inicio de escalera que baja hacia la izquierda (parte	derecha)
		db 82h			; Inicio de escalera que baja hacia la izquierda (parte	izquierda)
		db 40h			; Ladrillo completo muro trampa
		db 42h			; Ladrillo simple muro trampa
		db 43h			; Ladrillo semiroto 1
		db 44h			; Ladrillo semiroto 2
		db 44h


tilesEscalera:	db 75h
		db 76h			; Pelda�os bajan derecha
		db 85h
		db 84h			; Pelda�os bajan izquierda


tilesCuchillo:	db 4Bh
		db 4Bh
		db 4Bh			; Cuchillo suelo


tilesGemas:	db 51h
					; Brillo superior
		db 52h			; Brillo gema izquierda
		db 53h			; Brillo gema derecha
		db 86h			; Gema azul oscuro
		db 87h			; Gema azul claro
		db 88h			; Gema magenta
		db 89h			; Gema amarilla
		db 8Ah			; Gema verde
		db 8Bh			; Gema gris


tilesGiratoria:	db 68h
		db 69h			; Puerta giratoria izquierda->derecha
		db 78h
		db 77h			; Puerta giratoria derecha->izquierda


tilesSalida:	db 6Ch
		db 7Bh
		db 6Dh
		db 7Ch
		db 6Eh
		db 7Dh
		db 63h			; Interior superior amarillo salida 1
		db 64h			; Interior superior amarillo salida 2
		db 65h
		db 66h
		db 67h			; Escaleras
		db 6Fh			; Ladrillos cerrandose
		db 5Fh
		db 60h
		db 7Eh
		db 70h


tilesSalida2:	db 71h
		db 80h
		db 7Fh
		db 72h
		db 61h
		db 62h
		db 81h
		db 5Ch			; Palanca abajo
		db 5Dh			; Palanca arriba
		db 5Eh			; Parte	inferior palanca

tilePico:	db 4Ch

	IF	(VERSION2)
tilesAgujero:	db	#4e
	ELSE

byte_5DC3:	db 4Eh

byte_5DC4:	db 4Fh
		db 50h

byte_5DC6:	db 0

byte_5DC7:	db 0

tilesAgujero:	db 43h
		db 44h			; Ladrillo semiroto2
	ENDIF


halfMap1:	db 0C0h, 0, 80h, 0, 80h, 0, 81h, 0FFh, 0FFh, 0,	80h, 0,	80h, 0,	0FFh, 0C0h, 80h, 0, 80h, 0, 80h, 0, 9Fh, 0FFh, 80h, 0, 80h, 0, 80h, 0, 80h, 0, 8Fh, 0F0h, 80h, 3, 80h, 0, 0F0h,	0, 0FCh, 0, 0FFh, 0FFh
		db 0C0h, 0, 80h, 0, 80h, 0, 0FFh, 0FFh,	0C0h, 0, 0C0h, 0, 0C0h,	0FFh, 0F8h, 0FFh, 80h, 0Fh, 80h, 0Fh, 80h, 0F1h, 80h, 0F1h, 80h, 0Fh, 80h, 0Fh,	80h, 0FFh, 80h,	0FFh, 80h, 0F8h, 0FCh, 0F8h, 80h, 0FFh,	80h, 0,	80h, 0,	80h, 0
		db 0C0h, 0, 80h, 0, 80h, 0, 0FFh, 0F8h,	80h, 0,	80h, 0,	0FCh, 0, 80h, 0, 80h, 0FFh, 80h, 0FFh, 0FFh, 0FFh, 80h,	0FFh, 80h, 0F0h, 80h, 0F0h, 0FFh, 0FFh,	80h, 0,	80h, 0,	80h, 0,	0FFh, 0FFh, 80h, 0, 80h, 0, 80h, 0
		db 0C0h, 0, 80h, 0, 80h, 0, 0FFh, 0FFh,	0C0h, 0, 0C0h, 0, 0C0h,	0, 0FFh, 0F0h, 80h, 0, 80h, 0, 0F0h, 0,	80h, 0,	80h, 0,	80h, 0,	0FFh, 0FFh, 0FFh, 80h, 80h, 80h, 80h, 80h, 9Ch,	0FFh, 80h, 0, 80h, 0, 0F0h, 0

halfMap2:	db 0, 0, 0, 0, 0, 0, 0FFh, 0C0h, 0, 0, 0, 0Fh, 0FEh, 0,	0C0h, 0, 0C0h, 0, 0FFh,	0FFh, 0, 0, 0, 0, 0, 0,	0, 0, 0FFh, 0F0h, 0, 0,	0, 0, 0Fh, 0FFh, 0, 0, 0, 0, 0,	0, 0Fh,	0FFh
		db 0, 0, 0, 0, 0, 0, 0FFh, 0, 3, 0C0h, 3, 0FFh,	0, 80h,	0, 80h,	0F0h, 80h, 0F0h, 0FFh, 0F0h, 0,	0F0h, 0, 0F0h, 0, 0F3h,	0F0h, 0F0h, 0, 0, 0, 0,	0, 0, 1Fh, 0FFh, 80h, 0, 0, 0, 0, 1, 0FFh
		db 0, 0, 0, 0, 0, 0, 0,	0, 0, 0, 3, 0FFh, 0FCh,	0, 0FCh, 0, 0FCh, 0, 0FCh, 0FFh, 0, 0FCh, 0, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0FCh, 0, 0FCh, 0, 0,	0, 0, 7Fh, 0FFh, 0C0h, 0, 0, 0,	0, 0, 0Fh

halfMap3:	db 0, 0, 0, 0, 0, 0, 0,	0, 0, 0, 0FFh, 0FCh, 0,	0, 0, 0, 0, 0, 0FFh, 0FFh, 0, 0, 0, 0, 3Ch, 0Fh, 0, 3Fh, 0, 0FFh, 3, 0F1h, 0Fh,	0F1h, 0FFh, 0FFh, 0, 0,	0, 0, 0, 0, 0FFh, 0FFh
		db 0, 0, 0, 0, 0, 0, 0,	0Fh, 0,	0F0h, 0FFh, 0, 0, 0, 0,	1Fh, 1,	0F8h, 0FFh, 0F8h, 0Fh, 0FFh, 0Ch, 0, 0Ch, 0, 0Ch, 0, 0Fh, 0FFh,	3, 0FFh, 0, 3, 0F0h, 3,	3, 0F0h, 0, 0, 0, 0, 0FFh, 0FFh
		db 0, 0, 0, 0, 0, 0, 1,	0FFh, 1, 0, 0FFh, 0, 0,	1Fh, 0,	0, 0, 0, 0F0h, 0, 3, 0FFh, 0, 0, 0, 0, 0, 0, 7,	0FFh, 0, 0, 0, 0, 0FCh,	0, 0, 0FFh, 0, 0, 0, 0,	0FFh, 0F8h

halfMap4:	db 0, 3, 0, 1, 0, 1, 0,	1, 7, 0FFh, 0, 1, 0, 1,	0, 1, 0, 1, 0FFh, 0FFh,	0, 1, 0, 1, 0, 1, 0, 1,	0, 1, 0, 1, 0, 1, 0FFh,	0FFh, 0, 1, 0, 1, 0, 1,	0FFh, 0FFh
		db 0, 3, 0, 1, 0, 1, 0FFh, 0FFh, 0, 1, 0, 1, 0FFh, 0F1h, 0, 1, 0, 1, 0,	1, 0FFh, 0FFh, 0, 1, 0,	1, 0, 1, 0, 1, 0, 1, 3Fh, 0FFh,	0, 1, 0, 1, 0, 1, 0, 1,	0FFh, 0FFh
		db 0, 3, 0, 1, 0, 1, 0FFh, 0F1h, 0, 21h, 0, 21h, 0FFh, 0F9h, 0,	11h, 0,	11h, 0,	11h, 0FFh, 0F1h, 0, 11h, 0, 11h, 0, 11h, 0FFh, 0F1h, 0,	11h, 0,	11h, 0,	11h, 0FFh, 91h,	0, 1Fh,	0, 1Fh,	0, 1Fh
		db 0, 3, 0, 1, 0, 1, 0FFh, 81h,	0, 0FFh, 0, 1, 0, 1, 3,	0FFh, 0, 1, 0, 1, 0, 1,	0FFh, 0F9h, 0, 1, 0, 1,	0, 1, 0, 1, 0Fh, 0F1h, 0C0h, 1,	0, 1, 0, 0Fh, 0, 3Fh, 0FFh, 0FFh

;----------------------------------------------------
;
; Mapas: Piramides 1-15
;
; 지도: 피라미드 1-15
;
;----------------------------------------------------
MapStage1:	db 0, 33h, 0FFh, 0FFh, 0FFh, 48h, 78h, 24h, 2, 48h, 48h	; ...
		db 0, 48h, 0B0h, 2, 4, 70h, 18h, 18h, 31h, 18h,	0E0h, 42h
		db 0A0h, 10h, 54h, 78h,	0D0h, 1, 80h, 78h, 0, 0, 0, 8
		db 30h,	28h, 30h, 0C9h,	50h, 28h, 50h, 0C9h, 78h, 41h
		db 78h,	0B0h, 0A0h, 50h, 0A0h, 0A1h



MapStage2:	db 0, 11h, 21h,	30h, 0FFh, 0FFh, 70h, 30h, 18h,	78h, 0D1h
		db 34h,	3, 18h,	0D0h, 0, 30h, 88h, 4, 60h, 61h,	1, 5, 55h
		db 50h,	90h, 77h, 60h, 0B8h, 88h, 18h, 49h, 69h, 30h, 61h
		db 43h,	68h, 51h, 3, 10h, 38h, 0A0h, 0C0h, 18h,	0D1h, 7
		db 10h,	0B8h, 40h, 18h,	40h, 0C8h, 80h,	70h, 90h, 8, 48h
		db 69h,	90h, 0D1h, 2, 2, 20h, 76h, 2, 28h, 46h,	2, 78h
		db 79h,	80h, 91h, 0Dh, 30h, 41h, 50h, 30h, 60h,	0D1h, 78h
		db 51h,	80h, 0E0h, 0A0h, 50h, 0A8h, 91h, 40h, 13h, 40h
		db 0D2h, 80h, 93h, 0A0h, 22h, 0A0h, 52h, 0A0h, 0B3h



MapStage5:	db 2, 30h, 0FFh, 0FFh, 0A0h, 68h, 68h, 78h, 0E0h, 44h
		db 2, 10h, 0B8h, 3, 80h, 38h, 0, 4, 30h, 18h, 0D8h, 87h
		db 50h,	48h, 79h, 50h, 78h, 48h, 68h, 70h, 1, 0A0h, 80h
		db 5, 18h, 0F0h, 38h, 10h, 78h,	10h, 90h, 0E8h,	0A8h, 8
		db 0, 1, 0A0h, 18h, 0Ah, 28h, 19h, 40h,	99h, 48h, 28h
		db 68h,	28h, 80h, 0A9h,	88h, 28h, 88h, 51h, 0A0h, 0A0h
		db 0A0h, 0C9h, 0A8h, 31h



MapStage4:	db 0, 10h, 20h,	30h, 38h, 51h, 38h, 0FFh, 98h, 0D8h, 58h
		db 0FFh, 2, 10h, 18h, 0, 78h, 0D9h, 1, 6, 30h, 30h, 10h
		db 52h,	80h, 78h, 77h, 98h, 10h, 48h, 18h, 0E1h, 61h, 78h
		db 51h,	53h, 80h, 69h, 3, 68h, 0B0h, 18h, 0A9h,	80h, 0B9h
		db 9, 40h, 38h,	40h, 90h, 50h, 78h, 68h, 28h, 18h, 0F1h
		db 58h,	29h, 70h, 0B9h,	90h, 11h, 90h, 0E9h, 1,	0, 28h
		db 22h,	0, 10h,	28h, 98h, 30h, 41h, 40h, 0D1h, 50h, 50h
		db 68h,	89h, 78h, 40h, 80h, 0D0h, 0A0h,	48h, 0A8h, 89h
		db 40h,	1Bh, 40h, 0ABh,	58h, 1Bh, 58h, 62h, 80h, 9Bh, 0A0h
		db 2Ah,	0A0h, 0CBh



MapStage3:	db 3, 33h, 0FFh, 0FFh, 60h, 28h, 28h, 48h, 0B0h, 41h, 2	; ...
		db 8, 90h, 0, 60h, 10h,	2, 5, 34h, 18h,	0D8h, 47h, 50h
		db 0E0h, 78h, 48h, 10h,	86h, 88h, 58h, 75h, 0A8h, 18h
		db 2, 30h, 0B0h, 78h, 0A0h, 3, 10h, 8, 20h, 10h, 58h, 8
		db 0, 1, 78h, 80h, 7, 30h, 19h,	30h, 0C9h, 50h,	90h, 50h
		db 0C9h, 68h, 50h, 78h,	0C8h, 0A0h, 89h



MapStage6:	db 2, 11h, 22h,	32h, 0FFh, 0FFh, 80h, 58h, 74h,	80h, 0A1h
		db 54h,	3, 10h,	0C0h, 2, 78h, 0E0h, 1, 40h, 39h, 0, 6
		db 33h,	20h, 0D8h, 48h,	40h, 0D8h, 56h,	58h, 58h, 70h
		db 68h,	68h, 64h, 28h, 0E1h, 75h, 48h, 91h, 2, 0A8h, 8
		db 68h,	29h, 0Ah, 10h, 8, 38h, 8, 58h, 8, 60h, 78h, 78h
		db 30h,	98h, 40h, 58h, 39h, 68h, 0C9h, 90h, 0E1h, 0A8h
		db 0E1h, 1, 2, 58h, 7Eh, 2, 0A0h, 18h, 80h, 0A0h, 10h
		db 28h,	19h, 38h, 60h, 38h, 71h, 48h, 28h, 60h,	0C1h, 68h
		db 11h,	88h, 11h, 0A0h,	0C9h, 0A8h, 58h, 28h, 6Ah, 48h
		db 0ABh, 68h, 52h, 68h,	0B3h, 88h, 5Ah,	0A0h, 3Bh, 0A8h
		db 0A2h



MapStage8:	db 0, 12h, 22h,	31h, 0FFh, 0FFh, 0A0h, 98h, 78h, 98h, 0D1h
		db 91h,	3, 18h,	0B0h, 4, 98h, 0E0h, 2, 60h, 71h, 0, 5
		db 30h,	58h, 0A0h, 45h,	80h, 70h, 57h, 18h, 18h, 79h, 40h
		db 11h,	83h, 68h, 59h, 4, 10h, 70h, 78h, 58h, 48h, 0B1h
		db 88h,	41h, 7,	40h, 20h, 40h, 0E0h, 68h, 28h, 20h, 31h
		db 38h,	69h, 38h, 0B1h,	90h, 0B1h, 1, 2, 58h, 36h, 3, 48h
		db 50h,	70h, 0A1h, 78h,	21h, 0Ch, 30h, 11h, 50h, 38h, 78h
		db 40h,	0A0h, 48h, 0A8h, 0C1h, 28h, 0CAh, 48h, 4Bh, 48h
		db 93h,	78h, 0E2h, 0A0h, 2Ah, 0A0h, 93h, 0A8h, 6Ah



MapStage11:	db 3, 32h, 0FFh, 0FFh, 0A0h, 38h, 0C4h,	0A0h, 98h, 0A4h	; ...
		db 2, 20h, 0A0h, 2, 0A0h, 78h, 3, 5, 52h, 28h, 0E0h, 68h
		db 30h,	58h, 86h, 68h, 58h, 40h, 90h, 0E8h, 35h, 0A0h
		db 10h,	1, 68h,	38h, 4,	38h, 0B8h, 58h,	8, 58h,	98h, 0A8h
		db 0E0h, 2, 2, 78h, 62h, 2, 78h, 9Ah, 0, 0Ah, 28h, 88h
		db 30h,	41h, 48h, 11h, 48h, 99h, 68h, 20h, 68h,	79h, 68h
		db 0B8h, 88h, 79h, 0A8h, 60h, 0A8h, 0C0h



MapStage7:	db 3, 30h, 0FFh, 0FFh, 60h, 48h, 64h, 78h, 0D0h, 84h, 2	; ...
		db 10h,	0A8h, 2, 28h, 18h, 0, 5, 30h, 18h, 0D8h, 45h, 30h
		db 48h,	69h, 48h, 10h, 52h, 88h, 20h, 71h, 88h,	58h, 2
		db 10h,	70h, 80h, 0E8h,	3, 10h,	8, 18h,	0F0h, 58h, 30h
		db 0, 0, 8, 30h, 31h, 40h, 0E0h, 68h, 11h, 68h,	69h, 80h
		db 91h,	88h, 68h, 0A0h,	0D8h, 0A8h, 31h



MapStage9:	db 1, 32h, 40h,	0B8h, 88h, 0FFh, 0A0h, 20h, 0A8h, 0FFh
		db 1, 20h, 90h,	2, 4, 61h, 48h,	50h, 42h, 68h, 98h, 57h
		db 80h,	18h, 74h, 88h, 50h, 2, 30h, 18h, 88h, 88h, 6, 10h
		db 0D8h, 48h, 0D0h, 58h, 68h, 58h, 70h,	58h, 0A8h, 98h
		db 78h,	0, 0, 7, 28h, 58h, 28h,	0B8h, 48h, 89h,	68h, 0C0h
		db 88h,	0A0h, 0A8h, 59h, 0A8h, 0C0h



MapStage10:	db 2, 12h, 20h,	31h, 0FFh, 0FFh, 0A0h, 70h, 0B8h, 98h
		db 0B1h, 94h, 3, 78h, 90h, 3, 18h, 49h,	3, 98h,	91h, 4
		db 6, 41h, 40h,	88h, 53h, 68h, 18h, 37h, 68h, 68h, 64h
		db 10h,	0E1h, 75h, 40h,	11h, 86h, 58h, 71h, 3, 0A8h, 8
		db 48h,	0E9h, 80h, 69h,	6, 10h,	10h, 30h, 0E8h,	58h, 8

	IF	(VERSION2)
		db 78h,	28h, 30h, 31h, 38h, 0B1h, 0, 3,	0A0h, #18, 38h	; Muro trampa con coordenadas (#18, #a0) Al coger el cuchillo de abajo a la izquierda
	ELSE
		db 78h,	28h, 30h, 31h, 38h, 0B1h, 0, 3,	0A0h, 21h, 38h	; Muro trampa mal puesto en (#120,#a0) Hay que hacer un par de agujeros bajo la escalera para que aparezca.
	ENDIF

		db 21h,	40h, 0E1h, 0Dh,	38h, 40h, 40h, 0C9h, 48h, 20h
		db 88h,	40h, 0A8h, 38h,	0A8h, 0C1h, 28h, 0CAh, 40h, 4Ah
		db 48h,	93h, 58h, 1Bh, 78h, 9Bh, 0A0h, 2Ah, 0A0h, 0E2h



MapStage15:	db 1, 31h, 40h,	0B8h, 0E2h, 0FFh, 78h, 18h, 18h, 0FFh
		db 2, 20h, 90h,	0, 78h,	10h, 3,	6, 30h,	30h, 18h, 45h
		db 40h,	60h, 69h, 58h, 68h, 78h, 78h, 60h, 61h,	80h, 48h
		db 34h,	88h, 70h, 2, 28h, 0C0h,	0A8h, 10h, 6, 10h, 8, 10h
		db 0F0h, 28h, 40h, 48h,	40h, 50h, 70h, 68h, 0D8h, 0, 0
		db 8, 28h, 68h,	28h, 0A9h, 48h,	98h, 48h, 0E0h,	78h, 0B9h
		db 0A0h, 0B8h, 0A8h, 30h, 0A8h,	51h



MapStage12:	db 3, 10h, 21h,	31h, 0FFh, 0FFh, 60h, 0A0h, 0B4h, 70h
		db 0E1h, 0D4h, 3, 18h, 0E0h, 2,	28h, 50h, 4, 98h, 89h
		db 0, 6, 30h, 40h, 98h,	45h, 48h, 10h, 69h, 88h, 20h, 78h
		db 18h,	49h, 71h, 68h, 39h, 54h, 80h, 71h, 3, 68h, 0D0h
		db 88h,	31h, 10h, 0A1h,	8, 10h,	0F1h, 20h, 10h,	20h, 48h
		db 68h,	40h, 0A0h, 18h,	38h, 91h, 88h, 59h, 0A0h, 0F1h

	IF	(VERSION2)
		db 2, 0, 38h, 0AAh, 2, 58h, 5Eh, 1, 98h, #e9, 0Ch, 30h		; Mueve el muro trampa 8 pixeles a la derecha (!?) Estaba mejor en el original
	ELSE
		db 2, 0, 38h, 0AAh, 2, 58h, 5Eh, 1, 98h, 0E1h, 0Ch, 30h		; Muro trampa en (#1e0, #98) Aparece al coger el pico de abajo a la derecha
	ENDIF

		db 29h,	40h, 0D0h, 68h,	19h, 80h, 0C0h,	88h, 71h, 0A0h
		db 0C1h, 0A8h, 70h, 28h, 0BBh, 48h, 0AAh, 78h, 0B3h, 0A0h
		db 52h,	0A0h, 0BBh



MapStage13:	db 2, 33h, 0FFh, 0FFh, 80h, 18h, 0C8h, 70h, 0C8h, 0E4h
		db 2, 28h, 0D0h, 3, 80h, 60h, 1, 5, 30h, 18h, 0D8h, 42h
		db 28h,	28h, 57h, 50h, 68h, 68h, 58h, 50h, 74h,	68h, 68h
		db 1, 0A8h, 40h, 8, 10h, 8, 20h, 8, 38h, 10h, 58h, 8, 78h
		db 30h,	88h, 0D0h, 98h,	8, 98h,	50h, 0,	0, 0Ah,	28h, 11h
		db 30h,	0B0h, 48h, 28h,	50h, 0D1h, 68h,	19h, 78h, 0A0h
		db 88h,	48h, 0A0h, 0A9h, 0A8h, 20h, 0A8h, 68h



MapStage14:	db 1, 12h, 21h,	33h, 0FFh, 98h,	71h, 0F1h, 38h,	0D8h, 0D8h
		db 0FFh, 2, 0A0h, 80h, 3, 20h, 10h, 2, 6, 30h, 48h, 50h
		db 43h,	68h, 50h, 68h, 88h, 80h, 81h, 38h, 49h,	44h, 68h
		db 49h,	57h, 88h, 49h, 2, 0A8h,	48h, 80h, 89h, 0Ch, 10h
		db 8, 10h, 10h,	10h, 18h, 10h, 68h, 28h, 0A0h, 30h, 10h
		db 58h,	60h, 40h, 40h, 10h, 0B1h, 30h, 31h, 48h, 69h, 68h
		db 0A9h, 1, 0, 80h, 0A2h, 0, 0Bh, 28h, 68h, 30h, 19h, 0A8h
		db 30h,	0A8h, 0C9h, 30h, 6Bh, 30h, 0C3h, 40h, 13h, 50h
		db 0CBh, 78h, 0C2h, 0A0h, 2Ah, 0A0h, 8Bh

;----------------------------------------------------
; Marca	la piramide como pasada
; HL = Piramides pasadas
; DE = Mascara de la piramide actual
;
; 피라미드를 과거로 표시
; HL = 과거 피라미드
; DE = 현재 피라미드의 마스크
;----------------------------------------------------

setPiramidClear:
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		ld	a, b
		or	d
		ld	(hl), a
		dec	hl
		ld	a, c
		or	e
		ld	(hl), a
		ret


;----------------------------------------------------
; Devuelve en DE el bit	activo que corresponde a la piramide actual
;
; 현재 피라미드에 해당하는 활성 비트를 DE로 반환
;----------------------------------------------------

calcBitMask:
		ld	de, 1		; Devuelve en DE el bit	activo que corresponde a la piramide actual
		ld	a, (piramideActual)
		ld	b, a

calcBitMask2:
		dec	b
		ret	z
		sla	e
		rl	d
		jr	calcBitMask2

;----------------------------------------------------
; AI Gemas
;----------------------------------------------------

AI_Gemas:
		xor	a		; Empezamos por	la primera
		ld	(ElemEnProceso), a ; Usado para	saber la gema o	puerta que se esta procesando

nextGema:
		xor	a
		call	getGemaDat	; Obtiene puntero a los	datos de la gema en proceso
		inc	hl
		ld	a, (hl)		; Status
		call	jumpIndex
		dw gemaDoNothing
		dw gemaDoNothing
		dw gemaCogida		; 2 = Borra la gema de la pantalla y del mapa e	incrementa el numero de	gemas cogidas
		dw gemaDoNothing	; 3 = Inactiva

gemaDoNothing:
		jp	chkLastGema


;----------------------------------------------------
; Borra	la gema	y los brillos tanto de la pantalla como	del mapa
; Incrementa el	numero de gemas	cogidas
; Indica a los cuchillos que tienen que	actualizar el fondo sobre el que estan
;
; 화면과 지도 모두에서 보석과 반짝이를 제거합니다.
; 수집한 보석의 수를 늘립니다.
; 나이프에 배경을 업데이트해야 한다고 알려줍니다.
;----------------------------------------------------

gemaCogida:
		xor	a
		call	getGemaDat	; Obtiene puntero a los	datos de la gema en proceso
		ld	a, (hl)
		and	0F0h
		ld	(hl), a		; Desactiva gema del mapa

		inc	hl
		inc	(hl)		; Pasa al siguiente estado

		inc	hl
		ld	a, (hl)		; Y
		sub	8
		ld	d, a		; Coordenada Y del brillo de arriba de la gema
		inc	hl
		inc	hl
		ld	e, (hl)		; X
		call	coordVRAM_DE	; Obtiene direccion de la VRAM de esas coordenadas en la tabla de nombres
		xor	a		; Tile vacio
		call	WRTVRM		; Borra	el brillo superior

		ld	bc, 1Fh		; Distancia al brillo de la izquierda (tile de abajo a la izquierda)
		add	hl, bc
		ld	de, eraseData	; Tiles	vacios
		ld	bc, 103h	; Ancho	de 3 tiles
		call	DEtoVRAM_NXNY	; Borra	de la pantalla el brillo de la izquierda, la gema y el brillo de la derecha

		ld	a, 2		; Offset variable Y
		call	getGemaDat
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ld	de, eraseData
		call	putBrillosMap	; Borra	los brillos del	mapa

		ld	hl, gemasCogidas
		inc	(hl)		; Incrementa el	numero de gemas	cogidas

		call	knifeUpdateBack	; Fuerza a los cuchillos a actualizar el tile de fondo sobre el	que estan
					; Podia	estar sobre el brillo de la gema y ahiora que se ha quitado hay	que actualizarlo
		jp	chkLastGema

;----------------------------------------------------
; Valores iniciales del	cuchillo al lanzarse
; Velocidad decimal, velocidad X...
;
; 던질 때 칼의 초기 값
; 소수 속도, X 속도...
;----------------------------------------------------
knifeDataInicio:db    0
		db    2			; Velocidad del	cuchillo

eraseData:	db 0, 0, 0
		db 0, 0, 0
		db 0, 0, 0


;----------------------------------------------------
; Patrones usados para dibujar como se hace un agujero con el pico
; Para calcular	el indice se suma a esta lista el valor	del contador de	animacion
; Este contador	se decrementa de 3 en 3	y empieza en #15
; El primer valor que se usa es	#12 (tile = #43)
; La animacion es #43, #44, 0, #43, #44, 0, 0
;
; 곡괭이로 구멍을 만드는 방법을 그리는 데 사용되는 패턴
; 인덱스를 계산하려면 이 목록에 애니메이션 카운터 값을 추가하십시오.
; 이 카운터는 3에서 3으로 감소하고 #15에서 시작합니다.
; 사용된 첫 번째 값은 #12(타일 = #43)입니다.
; 애니메이션은 #43, #44, 0, #43, #44, 0, 0입니다.
;----------------------------------------------------
tilesAnimCavar:	db 0
		db 0, 0, 0
		db 0, 0, 44h
		db 0, 0, 43h
		db 0, 0, 0
		db 0, 0, 44h
		db 0, 0, 43h

;----------------------------------------------------
; Comprueba si ha procesado todas las gemas
;
; 모든 보석을 처리했는지 확인하십시오.
;----------------------------------------------------
	IF	(VERSION2)

chkLastGema:
		call	chkLastGema2	; Se han procesado todas las gemas?
		ret	z		; Si
		jp	nextGema	; No, sigue con otra
chkLastGema2:
		ld	hl, ElemEnProceso ; Usado para saber la	gema o puerta que se esta procesando
		inc	(hl)		; Siguiente gema
		ld	a, (hl)
		dec	hl
		cp	(hl)		; Ha procesado todas?
		ret
	ELSE

chkLastGema:
		ld	hl, ElemEnProceso ; Usado para saber la	gema o puerta que se esta procesando
		inc	(hl)		; Siguiente gema
		ld	a, (hl)
		dec	hl
		cp	(hl)		; Ha procesado todas?
		ret	z		; Si, termina
		jp	nextGema	; No, procesa la siguiente
	ENDIF

;----------------------------------------------------
; Devuelve en HL el puntero a los datos	de la gema y en	A la variable indicada
; In:
;   A =	Offset a la variable de	la estructura
; Out:
;  HL =	Puntero	a la variable indicada de la gema en proceso
;   A =	Valor de la variable
;
; HL에 보석 데이터에 대한 포인터를 반환하고 A에 표시된 변수를 반환합니다.
; 입력:
;   A = 구조 변수에 대한 오프셋
; 출력:
;  HL = 처리 중인 보석의 표시된 변수에 대한 포인터
;   A = 변수 값
;----------------------------------------------------


getGemaDat:
		ld	hl, datosGemas	; 0 = Color/activa. Nibble alto	indica el color. El bajo si esta activa	(1) o no (0)
					; 1 = Status
					; 2 = Y
					; 3 = decimales	X
					; 4 = X
					; 5 = habitacion
					; 6-8 =	0, 0, 0
		call	ADD_A_HL
		ld	a, (ElemEnProceso) ; Usado para	saber la gema o	puerta que se esta procesando

getIndexX9:
		ld	b, a

getIndexX8_masB:
		add	a, a

getIndexX4_masB:
		add	a, a
		add	a, a
		add	a, b
		call	ADD_A_HL
		ld	a, (hl)
		ret
;----------------------------------------------------
;
; Envia	a la VRAM los datos apuntados por DE.
; B = Alto
; C = Ancho
;
; DE가 가리키는 데이터를 VRAM으로 보냅니다.
; B = 높음
; C = 너비
;
;----------------------------------------------------

DEtoVRAM_NXNY:
		push	bc
		ld	b, 0
		call	DEtoVRAMset
		ld	a, 20h		; Siguiente fila (incrementa coordenada	Y)
		call	ADD_A_HL
		pop	bc
		djnz	DEtoVRAM_NXNY
		ret


;----------------------------------------------------
; Pone en el mapa los destellos	de una gema
; HL = Puntero a la posicion de	la gema	en el mapa
; DE = Puntero a patrones para brillos
;
; 보석의 반짝임을 지도에 표시
; HL = 지도상의 보석 위치에 대한 포인터
; DE = 하이라이트 패턴에 대한 포인터
;----------------------------------------------------


putBrillosMap:
		ld	bc, -60h	; Tama�o de una	fila del mapa (3 pantallas de 32 tiles)
		add	hl, bc		; Fila superior
		ex	de, hl
		ldi			; Pone brillo superior de la gema
		ld	bc, 5Eh		; Distancia al brillo de la izquierda
		ex	de, hl
		add	hl, bc
		ex	de, hl
		ld	c, 3
		ldir			; Copia	brillo de la izquierda,	espacio, brillo	de la derecha
		ex	de, hl
		ret

;----------------------------------------------------------------
;
; Logica de las	puertas	de entrada y salida de la piramide
;
; La puerta por	la que se entra	en la piramide tiene status 1 (#10)
; Las puertas por las que se sale tienen status	0 si no	se ha pasado previamente la piramide
; Si ya	se habian cogido las gemas, las	puertas	tienen status 8	(#80)
; Comprueba si se han cogido todas las gemas
; Anima	las puertas al entrar y	salir de la piramide
; Comprueba si se toca la palanca que abre la salida al	terminar una fase
; Si la	piramide ya se ha visitado, no oculta la salida
;
; 피라미드 입구와 출구의 논리
;
; 피라미드로 들어가는 문은 상태 1(#10)입니다.
; 이전에 피라미드를 통과하지 않은 경우 나가는 문은 상태 0입니다.
; 보석을 이미 가져간 경우 문 상태는 8(#80)입니다.
; 보석을 모두 가져갔는지 확인
; 피라미드에 들어가고 나갈 때 문 애니메이션
; 페이즈 종료 시 출구를 여는 레버가 터치되었는지 확인
; 피라미드는 이미 방문한 적이 있는 경우 출구를 숨기지 않습니다.
;
;----------------------------------------------------------------

AI_Salidas:
		xor	a
		ld	(ElemEnProceso), a ; Usado para	saber la gema o	puerta que se esta procesando
		ld	(puertaCerrada), a ; Vale 1 al cerrarse	la salida

chkNextExit:
		ld	hl, chkLastExit	; Comprueba si ya ha comprobado	las cuatro salidas
		push	hl		; Mete esta funcion en la pila para que	se ejecute al salir

		xor	a
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		inc	a		; Es #ff su estatus?
		ret	z		; No existe esa	salida

		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; Status de la puerta
		rra
		rra
		rra
		rra
		and	0Fh		; El nibble alto indica	el status. El bajo se usa como contador	de animacion o substatus
		call	jumpIndex


		dw chkAllGemas		; 0 = Comprueba	si se han cogido todas las gemas
		dw paintEntrada		; 1 = Dibuja la	puerta de entrada a la piramide
		dw chkOpenExit		; 2 = Comprueba	si toca	la palanca que abre la puerta
		dw openCloseExit	; 3 = Abriendo salida
		dw chkSalePiram		; 4 = Puerta abierta. Espera a que salga de la piramide
		dw openCloseExit	; 5 = Cerrando salida
		dw doNothing3		; 6 = No hace nada. Mantiene la	puerta esperando a la cortinilla
		dw finAnimEntrar	; 7 = Quita o deja la puerta dependiendo de si ya ha estado en la piramide
		dw paintCerrada		; 8 = La puerta	permanece visible y cerrada

;----------------------------------------------------------------
;
; Comprueba si se han cogido todas las gemas de	la fase
;
; Esta comprobacion la hace cada puerta	existente (normalmente la de entrada y	la de salida)
; Con lo que ambas puertas pasan a estado 1 al pasarse la fase.
;
; Cuando se cogen todas:
; - se marca la	fase como terminada
; - suena la musica de "stage clear"
; - quita las puertas giratorias
; - pasa la puerta al status 1 (#10)
;
; 단계의 모든 보석을 가져갔는지 확인하십시오.
;
; 이 검사는 각 기존 도어(일반적으로 입력 및 출력)에서 수행됩니다.
; 이 단계를 통과하면 두 문이 상태 1로 이동합니다.
;
; 모두 잡혔을 때:
; - 단계가 완료된 것으로 표시됩니다.
; - "무대 클리어" 음악 재생
; - 회전문 제거
; - 문을 상태 1(#10)로 전달
;----------------------------------------------------------------

chkAllGemas:
		ld	hl, gemasCogidas ; Comprueba si	ha cogido todas	la gemas
		ld	a, (hl)		; Gemas	recogidas
		inc	hl
		cp	(hl)		; Numero de gemas que hay en esta piramide
		ret	nz		; No las ha cogido todas

		ld	a, 1
		ld	(flagStageClear), a

		ld	a, 94h
		call	setMusic	; Musica de "stage clear"

		call	quitaGiratorias	; Quita	las puerta giratorias
		ld	a, 4		; Offset al byte de status de la puerta
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		ld	(hl), 10h	; Status = #10

doNothing3:
		ret


;----------------------------------------------------------------
;
; Dibuja la puerta abierta si se esta entrando en la piramide
; o cerrada si acaba de	aparecer tras coger las	gemas
; Pasa la puerta al status 2 (#20) que comprueba si el prota toca la palanca que abre la puerta
;
; 피라미드에 들어가는 경우 문을 열고 보석을 가져온 직후에 나타난 경우 닫힌 문을 그립니다.
; 문을 여는 레버에 주인공이 닿았는지 확인하는 상태 2(#20)로 문을 전달
;
;----------------------------------------------------------------

paintEntrada:
		ld	a, (GameStatus)
		cp	4		; Esta entrando	en la piramide?
		push	af
		ld	a, 2		; Frame	salida abierta
		jr	z, paintEntrada2
		pop	af

paintCerrada:
		push	af
		xor	a		; Frame	salida cerrada

paintEntrada2:
		call	getAnimExit	; Devuelve en DE un puntero a los tiles	que forman la salida
		ld	a, 4		; Offset al estado de la puerta
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		ld	(hl), 20h	; Cambia el estado a #20
		call	drawPuerta	; En DE	se pasa	el puntero a los tiles que forman la salida
		pop	af
		ret	z		; Esta entrando	en la piramide (animacion bajar	escaleras)

;----------------------------------------------------
; Fuerza a los cuchillos para que guarden el fondo sobre el que	estan
; Asi se evita que se corrompa el fondo	mientras se abre o cierra una puerta
; o cuando se coge una gema
;
; 칼이 있는 바닥을 강제로 저장합니다.
; 이것은 문을 열거나 닫거나 보석을 집는 동안 배경이 손상되는 것을 방지합니다.
;----------------------------------------------------

knifeUpdateBack:
		ld	hl, knifeEnProceso ; Indica a los cuchillos que	hay en el suelo	que guarden el tile de fondo sobre el que estan
		ld	(hl), 0
		inc	hl
		ld	b, (hl)		; Numero de cuchillos de la fase

status0Knife2:
		xor	a		; Offset status	cuchillo
		call	getKnifeData
		ld	a, (hl)		; Status
		dec	a		; Es igual a 1 (en reposo)
		jr	nz, status0Knife3
		ld	(hl), a		; Lo pasa a 0

status0Knife3:
		ld	hl, knifeEnProceso
		inc	(hl)		; Siguiente cuchillo
		djnz	status0Knife2
		ret

;----------------------------------------------------------------
; Comprueba si toca la palanca que abre	la salida
; El prota tiene que estar saltando y tocando la palanca con la	parte superior de su cuerpo (mano?)
; Al abrir la puerta esta pasa al estado 3 (#30) = Abriendo la puerta
;
; 출구를 여는 레버에 닿는지 확인
; 주인공은 점프해서 상체(손?)로 레버를 터치해야 합니다.
; 문이 열리면 상태 3(#30) = 문 열림
;----------------------------------------------------------------

chkOpenExit:
		ld	a, (protaStatus) ; Estado del prota
		cp	1		; Esta saltando?
		ret	nz		;  No

		call	chkSameScreenS	; Comprueba si la salida esta en la pantalla del prota
		ret	nz		; No

		ld	a, d		; Y
		sub	8		; Y - 8
		ld	d, a
		ld	a, e		; X
		sub	10h		; X - 16
		ld	e, a
		push	hl
		ld	hl, palancaArea
		call	chkTocaProta	; Comrpeuba si el prota	toca la	palanca
		pop	hl
		ret	nc		; No toca la palanca que abre la puerta

		ld	a, 1
		ld	(flagStageClear), a

		ld	a, 14h
		ld	(timer), a
		inc	hl
		ld	(hl), 30h	; Estado de abriendo la	puerta
		jr	openCloseExit2


;----------------------------------------------------------------
;
; Abre o cierra	la puerta de la	piramide
;
; Al terminar de abrirse tras accionar la palanca:
; - pasa al estado 4 = Espera a	que el prota salga de la piramide
;
; Al terminar de cerrarse:
; - cuando se entra en la piramide pasa	al estado 7 (#70) = puede dejar	la puerta cerrada si ya	se han cogido las gemas	o quitarla si aun no esta pasada la fase
; - cuando se sale pasa	al estado 6 (#60) = espera a la	cortinilla negra
;
; 피라미드의 문을 열거나 닫습니다.
;
; 레버를 활성화한 후 열기가 끝나면:
; - 상태 4로 이동 = 주인공이 피라미드에서 나올 때까지 기다립니다.
;
; 종료 완료 시:
; - 피라미드에 들어갈 때 상태 7(#70)이 됩니다. = 보석을 이미 가져간 경우 문을 닫은 상태로 두거나 단계가 아직 통과하지 않은 경우 제거할 수 있습니다.
; - 종료 시 상태 6(#60)으로 이동 = 검은색 커튼을 기다립니다.
;
;----------------------------------------------------------------

openCloseExit:
		ld	a, (timer)
		and	1Fh
		ret	nz		; Procesa uno de cada 32 frames. Espera	0.5s aprox.

openCloseExit2:
		call	knifeUpdateBack	; Indica a los cuchillos que hay en el suelo que guarden el tile de fondo sobre	el que estan
		ld	a, 4		; Offset al status de la puerta
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		inc	(hl)		; Incrementa el	substatus de la	puerta

		ld	a, (hl)		; Contador de animacion
		and	0Fh
		cp	4		; Ha terminado la animacion de abrir o cerrar?
		jr	nz, openCloseExit5 ; Aun no

		ld	a, (GameStatus)
		cp	4		; Esta entrando	en la piramide?
		jr	nz, openCloseExit3 ; No, esta saliendo.

		ld	(hl), 70h	; Estado puerta: Ha terminado de cerrarse. Mira	si hay que dejarla o quitarla
		jr	openCloseExit4

openCloseExit3:
		ld	a, (hl)		; Status puerta
		add	a, 10h		; Pasa al siguiente estado
		ld	(hl), a		; Si se	esta abriendo para salir, tras accionar	la palanca, pasa al estado 4
					; Si se	ha cerrado tras	salir, pasa al estado 6, que deja la puerta cerrada esperando a	la cortinilla

openCloseExit4:
		ld	hl, puertaCerrada ; Vale 1 al cerrarse la salida
		inc	(hl)
		ret

openCloseExit5:
		ld	a, (hl)		; Status
		and	0F0h
		cp	50h		; Esta cerrando	la puerta?
		ld	a, (hl)
		jr	nz, abreSalida	; No, se esta abriendo

		and	0Fh		; Se queda con el contador de la animacion
		sub	4
		neg			; Los subestados van de	0 a 3 al cerrar

abreSalida:
		and	0Fh
		dec	a
		cp	1
		jr	nz, pintaSalida

		push	af
		ld	a, 8Dh		; SFX abriendo/cerrando	puerta
		call	setMusic	; Musica que suena al abrirse o	cerrarse la puerta (si esta entrando no	se oye porque tiene preferencia	la que ya esta sonando)
		pop	af

pintaSalida:
		call	getAnimExit	; Devuelve en DE un puntero a los tiles	que forman la salida
		jp	drawPuerta


;----------------------------------------------------------------
;
; Puerta abierta y lista para que el prota salga de la piramide
; Espera a que toque las escaleras para	salir
; Dependiendo por la puerta por	la que se sale,	se toma	una direccion (norte, sur, este	u oeste)
; La puerta/direccion por la que se entra en la	piramide es la opuesta a la que	se ha salido en	la anterior
; (Ej: Si se sale por la puerta	norte de una piramide, se entra	por la sur de la siguiente)
; Pone 4 sprites en parejas solapadas (16x32) para dibujar la parte derecha de la puerta y que el prota	pase por detras
;
; 문이 열리고 주인공이 피라미드에서 나올 준비가 되었습니다.
; 내가 나가기 위해 계단을 밟을 때까지 기다려
; 나가는 문에 따라 방향(북쪽, 남쪽, 동쪽 또는 서쪽)으로 이동합니다.
; 피라미드로 들어가는 문/방향은 이전 피라미드에서 나온 문/방향과 반대입니다.
; (예: 피라미드의 북쪽 문으로 나가면 다음 피라미드의 남쪽으로 들어갑니다.)
; 4개의 스프라이트를 겹치는 쌍(16x32)으로 넣어 문의 오른쪽 부분을 그리고 주인공이 뒤에 지나가도록 그립니다.
;
;----------------------------------------------------------------

chkSalePiram:
		call	chkSameScreenS	; Comprueba si la salida esta en la pantalla del prota
		ret	nz		; La puerta no esta en la misma	habitacion que el prota
; DE = YX

		ld	hl, salidaArea
		call	chkTocaProta
		ret	nc		; No ha	entrado	en la salida

		call	quitaMomias	; Oculta las momias

		exx
		ld	a, 4		; Offset status	puerta
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		ld	(hl), 50h	; Cambia el status a 5 (#50) = Cerrando	puerta

		inc	hl
		ld	bc, 2
		ld	de, piramideDest
		ldir			; Copia	la piramide de destino y la puerta por la que se entra (flecha del mapa)
		exx

		ld	a, (ElemEnProceso) ; Usado para	saber la gema o	puerta que se esta procesando
		inc	a
		cp	1		; Arriba?
					; 위?
		jr	z, setFlechaSalida

		dec	a
		add	a, a
		cp	6
		jr	nz, setFlechaSalida
		ld	a, 8

setFlechaSalida:
		ld	(puertaSalida),	a ; 1 =	Arriba,	2 = Abajo, 4 = Izquierda, 8 = Derecha


; Pone los sprites de la parte derecha de la puerta que	tapan al prota al entrar por las escaleras

		ld	hl, sprAttrib	; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
		ld	a, 10h
		add	a, e		; X + 16
		ld	e, a
		ld	a, d
		sub	11h
		ld	d, a		; Y - 17

		ld	b, 2		; 16x32	Dos sprites consecutivos en Y

setSprPuerta:
		ld	c, 2		; 2 sprites solapados

setSprPuerta2:
		ld	(hl), d		; Y del	sprite
		inc	hl
		ld	(hl), e		; X del	sprite
		inc	hl
		inc	hl
		inc	hl		; Puntero a los	atributos del siguiente	sprite
		dec	c
		jr	nz, setSprPuerta2 ; Segundo sprite solapado

		ld	a, d
		add	a, 10h
		ld	d, a		; Y = Y	+ 16
		djnz	setSprPuerta

		ld	a, 20h
		call	setMusic	; Silencio

		xor	a
		ld	(statusEntrada), a ; Status de la entrada a 0 =	Saliendo en la piramide
		inc	a
		ld	(flagEntraSale), a ; 1 = Entrando o saliendo de	la piramide. Ejecuta una logica	especial para este caso
		inc	a
		ld	(sentidoProta),	a ; Sentido a la derecha
		pop	hl
		pop	hl
		ret

;----------------------------------------------------
;
; Al entrar en una piramide nueva, quita la puerta
; Si ya	ha estado la deja para poder salir
;
; 새로운 피라미드에 들어갈 때 문을 제거하십시오
; 그가 이미 있었다면 떠날 수 있도록 떠난다.
;
;----------------------------------------------------

finAnimEntrar:
		call	chkPiramPasada	; Comprueba si la piramide en la que entra ya ha estado
		push	af
		ld	a, 4		; Offset status
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		pop	af
		ld	(hl), 0		; Estado que oculta la puerta y	comprueba si se	cogen todas las	gemas
		jr	z, borraSalida

		ld	(hl), 20h	; Estado que deja la puerta visible y espera a que el prota toque la palanca para abrirla
		ret

borraSalida:
		ld	de, eraseData
		jr	drawPuerta

;----------------------------------------------------
; Obtiene un puntero a la estructura de	la salida que se esta procesando
; 처리 중인 출력의 구조에 대한 포인터를 가져옵니다.
;----------------------------------------------------

getExitDat:
		ld	hl, pyramidDoors ; Obtiene un puntero a	la salida que se esta procesando
		call	ADD_A_HL
		ld	a, (ElemEnProceso) ; Usado para	saber la gema o	puerta que se esta procesando
		jp	getHL_Ax7	; Devuelve HL +	A*7 y A=(HL)

chkLastExit:
		ld	hl, ElemEnProceso ; Comprueba si ya ha comprobado las cuatro salidas
		inc	(hl)
		ld	a, 4
		cp	(hl)
		jp	nz, chkNextExit
		ret


;----------------------------------------------------
; Dibuja una puerta de salida/entrada
; In:
;  DE =	Tiles que forman la puerta
;
; 출구/입구 문 그리기
; 입력:
;  DE = 문을 형성하는 타일
;----------------------------------------------------

drawPuerta:
		xor	a
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		ld	bc, 0F0F8h	; Offset X-16, Y-8
		push	de
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
		pop	de
		ex	de, hl
		push	hl

		ld	b, 3		; Alto en patrones de la puerta

drawPuerta2:
		push	bc
		ld	bc, 5		; Ancho	en patrones de la puerta
		ldir

		ld	a, 5Bh		; Desplazamiento a la fila inferior de la puerta en el mapa RAM
		call	ADD_A_DE
		pop	bc
		djnz	drawPuerta2

		xor	a
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		dec	hl
		call	getLocationDE2	; Esta en la misma pantalla que	el prota? (se ve?)
		pop	hl
		ret	nz		; No hace falta	pintarla

		push	hl
		call	coordVRAM_DE	; Calcula puntero a la tabla de	nombres	de las coordenadas en DE
		pop	de
		ld	bc, -22h
		add	hl, bc

		ld	b, 3		; Patrones alto

drawPuerta3:
		ld	c, 5		; Patrones ancho

drawPuerta4:
		push	bc
		ld	a, (de)		; Tile de la puerta
		call	getTileFromID	; Obtiene patron que le	corresponde
		call	WRTVRM		; Lo dibuja en pantalla
		inc	hl
		inc	de
		pop	bc
		dec	c
		dec	c
		inc	c
		jr	nz, drawPuerta4

		ld	a, 1Bh		; Distancia en VRAM a la fila inferior de la puerta (#20 - 5)
		call	ADD_A_HL
		djnz	drawPuerta3
		ret


;----------------------------------------------------
; Comprueba si la salida esta en la habitacion actual
; y obtiene sus	coordenadas.
; Out:
;  D = Y
;  E = X
;
; 출구가 현재 방에 있는지 확인하고 좌표를 가져옵니다.
; 출력:
;  D = Y
;  E = X
;----------------------------------------------------

chkSameScreenS:
		xor	a		; Comprueba si la salida esta en la pantalla del prota
		call	getExitDat	; Obtiene un puntero a la salida que se	esta procesando
		dec	hl
		jp	getLocationDE2



;----------------------------------------------------
; Devuelve en DE un puntero a los patrones que forman
; el framde la puerta indicado en A
;
; A에 표시된 문의 프레임을 형성하는 패턴에 대한 포인터를 DE로 반환합니다.
;----------------------------------------------------

getAnimExit:
		add	a, a		; Devuelve en DE un puntero a los tiles	que forman la salida
		ld	hl, idxAnimExit
		call	getIndexHL_A
		ex	de, hl
		ret


;----------------------------------------------------
; Offset X coordenada palanca, ancho del prota a comprobar
; Offset Y palanca, alto del prota a comprobar
;
; Solo comprueba la parte de arriba del	prota. Asi parece que le da con	la mano	al saltar
;
; 오프셋 X 좌표 레버, 확인할 주인공 너비
; 오프셋 Y 레버, 확인할 전면 높이
;
; 주인공 캐릭터의 상단을 확인하십시오. 그래서 점프할 때 손으로 때리는 것 같다.
;----------------------------------------------------
palancaArea:	db 8, 10h
		db 3, 5

;----------------------------------------------------
; Punto	que se comprueba para saber si se ha salido de la piramide
;
; 피라미드를 떠났는지 확인하는 포인트
;----------------------------------------------------
salidaArea:	db 1, 2
		db 4, 6

idxAnimExit:	dw animExitClosed	; ...
		dw animExitClosing
		dw animExitOpen

animExitClosed:	db  77h,   0, 60h, 61h,	  0
		db  79h,   0, 62h, 63h,	  0
		db    0,   0, 64h, 65h,	  0

animExitClosing:db  78h, 6Bh, 6Ch, 6Dh,	6Eh
		db  79h, 6Fh, 70h, 71h,	72h
		db    0, 73h, 74h, 75h,	76h

animExitOpen:	db  78h, 60h, 66h, 67h,	61h
		db  79h, 62h,	0, 68h,	63h
		db    0, 64h, 69h, 6Ah,	65h


;----------------------------------------------------
; Logica de los	muros trampa
; Cuando la trampa no se ha activado se	comprueba si el	prota pasa por la posicion de esta para	activarla
; Una vez activada, se busca un	techo desde el que comienza a cerrarse el muro.
; El muro baja de 4 en 4 pixeles por lo	que pinta ladrillos completos o	solo la	parte de arriba	dependiendo de su posicion
; Si choca contra un objeto, se	detiene	hasta que puede	continuar
; Si choca contra un muro, se da por terminada la trampa
;
; 함정 벽 논리
; 함정이 활성화되지 않았을 때, 주인공이 함정을 활성화하기 위해 자신의 위치를 ​​통과하는지 확인합니다.
; 활성화되면 벽이 닫히기 시작하는 천장이 검색됩니다.
; 벽은 4x4픽셀 아래로 내려가므로 위치에 따라 전체 벽돌 또는 상단 부분만 페인트합니다.
; 물체에 부딪히면 계속할 수 있을 때까지 멈춥니다.
; 벽에 부딪히면 함정이 끝난다.
;----------------------------------------------------

MurosTrampa:
		ld	hl, muroTrampProces
		ld	(hl), 0		; Empieza por el primero :P
		inc	hl
		ld	a, (hl)		; Numero de muros trampa de la piramide
		or	a
		ret	z		; No hay ninguno

chkNextTrampa:
		ld	hl, chkLastMuro
		push	hl		; Guarda en la pila la rutina que comprueba si ya se han procesado todos los muros trampa

		xor	a
		call	getMuroDat
		and	a		; Esta activado	este muro trampa?
		jp	z, chkActivaTrampa ; No	comprueba si el	prota lo activa

		dec	a
		ret	nz		; Este muro ya se ha cerrado por completo

		ld	a, (timer)
		and	1Fh
		ret	nz		; El muro se mueve cada	#20 iteraciones

		inc	hl
		ld	a, (hl)		; Y muro
		add	a, 4		; Se mueve 4 pixeles hacia abajo
		ld	(hl), a		; Actualiza Y del muro
		and	7		; Su Y es multiplo de 8? (pinta	medio ladrillo o uno entero?)
		ld	c, 19h		; Map ID ladrillo completo
		jr	nz, murosTrampa2

		inc	c		; Map ID ladrillo simple (4 pixeles alto)

murosTrampa2:
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ex	de, hl
		pop	hl
		ld	a, (hl)		; Y del	muro
		and	7		; Ha bajado un tile completo o medio?
		jr	nz, murosTrampa3 ; Medio

		ld	a, (de)		; Tile del mapa
		and	a		; Esta vacio?
		jr	nz, trampaChoca	; No, comprueba	con lo que choca

murosTrampa3:
		call	drawTrampa
		ld	hl, protaStatus	; Datos	del prota
		ld	a, (hl)		; Status prota
		or	a		; Esta realizando alguna accion	especial?
		ret	nz		; Si

		ld	hl, ProtaY
		ld	bc, 500h	; Offset X+5, Y+0
		call	chkAplastaMuro	; Comprueba si el muro aplasta al prota
		jr	c, trampaMataProta ; Si, lo aplasta

		ld	b, 0Bh		; Offset X+11, Y+0
		call	chkAplastaMuro	; Comprueba si aplasta al prota
		ret	nc		; No

trampaMataProta:
		ld	a, 1Dh		; Musica muere prota
		call	setMusic
		xor	a
		ld	(flagVivo), a	; Mata al prota
		ret

;----------------------------------------------------
; Comprueba si el muro choca contra una	plataforma o contra un objeto
; Si choca contra un objeto se detiene hasta que este desaparece
; Si choca contra una plataforma, se da	por terminada la trampa
;
; 벽이 플랫폼이나 물체에 부딪히는지 확인하십시오.
; 물체에 부딪히면 사라질 때까지 멈춥니다.
; 플랫폼에 닿으면 트랩이 종료됩니다.
;----------------------------------------------------

trampaChoca:
		ld	a, (de)		; Tile del mapa

	IF	(VERSION2)
		cp	1
		jr	z,trampaLimite
	ENDIF

		and	0F0h		; Se queda con la familia/grupo
		cp	10h		; Es una plataforma o muro?
		jr	z, trampaLimite	; Si

	IF	(!VERSION2)
		inc	hl		; (!?) Si incrementa HL	pasa a los decimales de	X. Deberia quedarse en la Y,
	ENDIF

		ld	a, (hl)		; Y muro
		sub	4		; Decrementa 4 su Y, con lo que	detiene	su avance (deja	de bajar)
		ld	(hl), a		; Actualiza la Y
		ret

;----------------------------------------------------
; Si el	muro choca contra el limite inferior de	la pantalla pinta el tile de ladrillo "limite inferior"
; Si choa contra una plataforma	o muro,	pinta el tile de ladrillo normal
;
; 벽이 화면의 하단 가장자리에 닿으면 "하단 가장자리" 벽돌 타일을 칠합니다.
; 플랫폼이나 벽에 부딪히면 일반 벽돌 타일을 칠합니다.
;----------------------------------------------------

trampaLimite:
		dec	hl		; Apunta al status del muro
		inc	(hl)		; Pasa al siguiente status = Muro cerrado por completo
		inc	hl		; Apunta a la Y
		ld	a, (de)		; Map ID con el	que ha chocado
		cp	14h		; Limite inferior de la	pantalla?
		ld	c, 13h		; Tile de ladrillo normal
		jr	nz, drawTrampa_

		inc	c		; Tile de limite inferior de la	pantalla

drawTrampa_:
	IF	(!VERSION2)
		call	drawTrampa	; (!?) Para que	pone un	CALL y luego un	RET?
		ret
	ENDIF
drawTrampa:
		ld	a, c
		ld	(de), a		; Modifica el tile del mapa
		push	hl		; Apunta a la Y
		call	getTileFromID	; Obtiene el patron que	le corresponde a ese tile del mapa
		dec	hl
		dec	hl		; Apunta a la Y	menos 2	bytes, necesario para que "drawTile" recoja las coordenadas
		call	drawTile	; Dibuja el patron en pantalla
		pop	hl
		ret


;----------------------------------------------------
; Comprueba si el prota	activa un muro trampa
; Cuando el prota pasa por la posicion de la trampa esta se activa
; En ese momento se hace una busqueda vertical desde esa posicion
; hasta	que se encuentra un muro o el limite superior de la pantalla
; Ese punto es el que se toma como inicio del muro que se cierra
;
; 주인공이 함정벽을 발동하는지 확인
; 주인공이 함정의 위치를 ​​지날 때 발동
; 그 순간 그 위치에서 벽이나 화면의 상한선을 찾을 때까지 수직 탐색을 한다.
; 그 점은 닫히는 벽의 시작점으로 간주되는 점입니다.
;----------------------------------------------------

chkActivaTrampa:
		inc	hl
		ld	d, h
		ld	e, l
		inc	hl
		inc	hl
		ld	c, (hl)		; X trampa
		inc	hl
		ld	b, (hl)		; Habitacion trampa
		ld	hl, (ProtaX)
		and	a
		sbc	hl, bc
		ret	nz		; El prota no esta en la misma X que la	trampa

		ld	a, (de)		; Y trampa
		ld	hl, ProtaY
		cp	(hl)
		ret	nz		; No estan en la misma Y

		ld	h, d
		ld	l, e
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ld	b, 0

trampaTecho:
		push	hl		; Puntero a la posicion	en el mapa de la trampa
		push	de		; Puntero a la Y de la trampa
		and	a
		ld	de, MapaRAM
		sbc	hl, de		; Se sale del mapa por arriba?
		pop	de
		jr	c, trampaOrigen	; Si, tomamos esta posicion como inicio	del muro trampa

		pop	hl
		ld	a, (hl)		; Tile del mapa	en el que esta la trampa
		and	a		; Esta vacio?
		jr	nz, trampaOrigen2 ; No

		inc	b
		ld	a, l
		sub	60h		; distancia a la fila superior del mapa
		ld	l, a
		jr	nc, trampaTecho2 ; No hay acarreo en la	resta

		dec	h		; Resta	el acarreo a HL

trampaTecho2:
		jr	trampaTecho	; Sigue	buscando donde poner el	origen del muro	que se cierra

trampaOrigen:
		pop	hl
		ld	(hl), 12h	; Map ID ladrillo/muro

trampaOrigen2:
		ld	a, b
		add	a, a
		add	a, a
		add	a, a		; Numero de tiles de distancia hasta el	techo *	8
	IF	(!VERSION2)
		sub	4
	ENDIF
		ld	b, a
		ex	de, hl

		ld	a, (hl)		; Y de la trampa
		sub	b		; Le resta la distacia en pixeles al techo u origen de la trampa
		ld	(hl), a
		dec	hl		; Apunta al status de la trampa
		inc	(hl)		; La trampa pasa al estado 1 = Bajando muro

	IF	(!VERSION2)
		xor	a
		ld	(timer), a	;(!?) Para que sirve?
	ENDIF
		ret

;----------------------------------------------------
; Obtiene un puntero a los datos del muro trampa en proceso
;
; 처리 중인 트랩 월 데이터에 대한 포인터 가져오기
;----------------------------------------------------

getMuroDat:
		ld	hl, muroTrampaDat ; Y, decimales X, X, habitacion
		call	ADD_A_HL
		ld	a, (muroTrampProces)
		ld	b, a
		jp	getIndexX4_masB

chkLastMuro:
		ld	hl, muroTrampProces
		inc	(hl)		; Siguiente muro
		ld	a, (hl)		; Muro actual
		inc	hl
		cp	(hl)		; Numero de muro totales
		jp	nz, chkNextTrampa
		ret



;----------------------------------------------------
; Comprueba si el prota	es aplastado por un muro trampa
; In:
;   BC = Offset	XY a la	cabeza del prota
; Out:
;   Carry = Es aplastado
;
; 주인공이 함정 벽에 짓눌렸는지 확인
; 입력:
;   BC = 주인공의 머리에 XY 오프셋
; 출력:
;   Carry = 찌그러졌다
;----------------------------------------------------

chkAplastaMuro:
		push	bc
		call	chkTocaMuro	; Z = choca
		ld	a, (de)		; Tile del mapa
		sub	19h		; #19 =	Ladrillo completo muro trampa, #1A = Ladrillo simple muro trampa
		cp	2		; Es uno de esos dos tiles del muro trampa?
		pop	bc
		ret



;----------------------------------------------------
; Dibuja la animacion de como se rompen	los ladrillos al picar
; y borra del mapa RAM los rotos. Comprueba si lo que va a picar es una	platarforma.
; Para llevar el control de la animacion se usa	"agujeroCnt"
; Esta variable	tiene un valor inicial y se decrementa en 3 a cada
; golpe	del pico. Sus valores son #12, #0F, #0C, #09, #06, #03
; y los	tiles de la animacion son #44 (semiroto), #43 (roto), #00 (vacio), #44,	#43, #00
;
; RAM 맵에서 깨진 벽돌을 자르고 삭제할 때 벽돌이 어떻게 부서지는지 애니메이션을 그립니다. 물릴 것이 플랫폼인지 확인하십시오.
; 애니메이션을 제어하려면 "holeCnt"를 사용하십시오.
; 이 변수는 초기 값을 가지며 각 피크 히트에서 3씩 감소합니다. 값은 #12, #0F, #0C, #09, #06, #03이고 애니메이션 타일은 #44(반썩음), #43(깨짐), #00(빈), #44, #43 , #00
;----------------------------------------------------

drawAgujero:
		ld	hl, agujeroCnt	; Al comenzar a	pica vale #15
		ld	a, (hl)
		and	a
		ret	z		; Ha terminado de hacer	el agujero

		ld	a, (hl)
		cp	12h		; Es el	primer golpe de	pico?
		inc	hl
		jr	z, drawAgujero2	; Si, no hace falta incrementar	la Y del agujero

		inc	(hl)
		inc	(hl)
		inc	(hl)		; Incrementa la	Y del agujero en 3

drawAgujero2:
		ld	b, a
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ex	de, hl
		pop	hl
		ld	a, b
		cp	9
		jr	nz, drawAgujero3

		ld	a, (de)		; Lee tile del mapa que	se va a	picar
		call	AL_C__AH_B	; Copia	el nibble alto de A en B y el bajo en C
		ld	a, b		; se queda con el nibble alto, que es la familia de tiles o tipo
		cp	1		; es una plataforma?
		jr	nz, endAgujero	; No, finaliza el agujero. Esto	no se puede picar

		ld	a, c
		cp	4		; Es plataforma	o vacio? (Map IDs #10-#13 = #00	(tile vacio), #00, #40 (tile ladrillo),	#40)
		jr	c, drawAgujero3

		cp	9		; Map ID #19 = Tile #40
		jr	nz, endAgujero

; Comprueba si hay que borrar el ladrillo picado del mapa de la	RAM

drawAgujero3:
		dec	hl
		ld	a, (hl)		; agujeroCnt
		inc	hl
		cp	0Ch		; Valor	de la animacion	en el momento de romper	totalmente el ladrillo de arriba
		jr	z, drawAgujero4	; Quita	el ladrillo del	mapa

		cp	3		; Valor	de la animacion	en el momento de romper	totalmente el ladrillo de abajo
		jr	nz, drawAgujero5

drawAgujero4:
	IF	(VERSION2)
		ld	a,1
	ELSE
		xor	a
	ENDIF
		ld	(de), a		; Borra	tile del mapa RAM

drawAgujero5:
		ld	a, (agujeroCnt)	; Al comenzar a	pica vale #15
		ld	de, tilesAnimCavar ; Tiles usados en la	animacion del agujero
		call	ADD_A_DE	; Calcula indice
		ld	a, (de)		; Tile de la animacion (ladrillo semiroto, roto	o vacio)
		dec	hl
		dec	hl		; Apunta a la Y	del agujero
		call	drawTile	; Dibuja en pantalla el	tile de	la animacion del agujero
		ld	a, 45h		; SFX Pico
		jp	setMusic

endAgujero:
		xor	a
		ld	(agujeroCnt), a	; Al comenzar a	picar vale #15
		ret


;----------------------------------------------------
; Puertas giratorias
; Si estan en movimiento la anima (5 frames)
; Dependiendo del sentido de giro hara la animacion hacia un lado o el otro
;
; 회전문
; 움직이는 경우 애니메이션을 적용합니다(5개 프레임).
; 회전 방향에 따라 애니메이션을 한쪽으로 또는 다른 쪽으로 만듭니다.
;----------------------------------------------------

spiningDoors:
		ld	hl, doorGiraData ; 0 = Status (bit 0 = Girando,	bits 2-1 = altura + 2)
					; 1 = Y
					; 2 = X	decimal
					; 3 = X
					; 4 = Habitacion
					; 5 = Sentido giro
					; 6 = Contador giro
		ld	a, (numDoorGira)
		ld	b, a
		or	a
		ret	z		; No hay puertas giratorias en esta piramide

spiningDoors2:
		bit	0, (hl)		; Esta girando esta puerta?
		jr	nz, spiningDoors3 ; Si

		ld	de, 7		; Tama�o de la estructura de cada puerta giratoria
		add	hl, de		; Puntero a la siguiente puerta
		djnz	spiningDoors2
		ret

spiningDoors3:
		ld	a, (timer)
		and	7
		ret	nz		; La puerta solo se mueve cada 8 frames

		push	hl
		pop	ix
		ld	a, (ix+SPINDOOR_TIMER) ; Counter
		inc	(ix+SPINDOOR_TIMER) ; Incrementa contador
		cp	5		; Ha girado completamente?
		jr	z, spiningDoorEnd ; Si,	desactiva giro en puerta

		add	a, a
		add	a, a
		add	a, a		; x8 (patrones de la tabla que ocupa cada frame	de giro	de la puerta)
		ld	b, a
		ld	a, (ix+SPINDOOR_SENT) ;	Sentido	del giro
		cp	8		; Gira a la derecha o a	la izquierda?
		ld	a, b
		jr	z, spiningDoor4

		ld	a, 20h		; Invierte la animacion	para el	giro a la izquierda
		sub	b

spiningDoor4:
		ld	de, tilesGiroDoor
		call	ADD_A_DE

		ld	c, 2		; Altura por defecto y ancho fijo
		ld	a, (ix+SPINDOOR_STATUS)
		srl	a		; Se queda con la altura
		add	a, c		; Altura base +	altura extra
		ld	b, a		; B = Altura puerta
		ld	h, (ix+SPINDOOR_X) ; X
		ld	l, (ix+SPINDOOR_Y) ; Y

		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	(ix+SPINDOOR_ROOM) ; Esta la puerta en la misma	habitacion que el prota?
		ret	nz		; No

		call	coordVRAM_HL	; Obtiene direccion VRAM de la tabla de	nombres	a donde	apunta HL
		jp	DEtoVRAM_NXNY	; Dibuja puerta	en la pantalla

spiningDoorEnd:
		res	0, (ix+SPINDOOR_STATUS)	; Quita	flag de	girando
		ld	a, 1100b
		xor	(ix+SPINDOOR_SENT) ; Invierte sentido de la puerta
		ld	(ix+SPINDOOR_SENT), a ;	Actualiza sentido de la	puerta

;----------------------------------------------------
; Pone un apuerta giratoria en el mapa
;
; 지도에 회전문을 놓으십시오.
;----------------------------------------------------

putGiratMap:
		push	ix		; Pone puerta giratoria	en el mapa
		pop	hl
		inc	hl
		push	hl
		pop	de
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		dec	de
		ld	a, (de)		; Los bits 2-1 indican la altura extra
		rra
		and	3
		add	a, 2		; Le a�ade la altura minima de la puerta (2)
		ld	b, a		; Altura de la puerta
		ld	a, 5
		call	ADD_A_DE
		ld	a, (de)		; Sentido de giro
		bit	2, a
		ld	a, 50h		; Map ID puerta	izquierda
		jr	z, putGiratMap2
		inc	a
		inc	a		; Map ID puerta	derecha

putGiratMap2:
		ld	c, a

putGiratMap3:
		ld	(hl), c		; Parte	izquierda de la	puerta giratoria
		inc	hl
		inc	c
		ld	(hl), c		; Parte	derecha
		ld	a, 5Fh		; Offset a la fila inferior del	mapa
		call	ADD_A_HL
		dec	c
		djnz	putGiratMap3	; Repite tantas	veces como alta	sea la puerta
		ret


;----------------------------------------------------
; Comprueba cual es la puerta que esta empujando el prota
;
; 주인공이 어떤 문을 밀고 있는지 확인
;----------------------------------------------------

chkGiratorias:
		xor	a
		ld	(GiratEnProceso), a

chkGiratorias2:
		xor	a
		call	getGiratorData
		push	hl
		inc	hl		; Apunta a la Y
		add	a, a
		add	a, a
		and	11000b
		add	a, (hl)		; Y puerta
		ld	d, a

		ld	a, (sentidoProta) ; 1 =	Izquierda, 2 = Derecha
		rra
		ld	a, 8		; 8 pixeles a la derecha
		jr	c, chkGiratorias3 ; A la izquierda
		neg			; 8 pixeles a la izquierda

chkGiratorias3:
		inc	hl
		inc	hl
		add	a, (hl)		; X puerta
		ld	e, a

		ld	hl, ProtaY
		ld	a, (hl)		; Y prota
		inc	hl
		inc	hl
		ld	l, (hl)		; X Prota
		ld	h, a
		and	a
		sbc	hl, de		; Resta	las coordenadas	del prota y las	de la puerta
		pop	hl		; Recupera status puerta
		jr	nz, chkLastGirat

		set	0, (hl)		; Activa el bit	0 del estado de	la puerta
		ld	a, 6
		call	ADD_A_HL
		ld	(hl), 0
		ret

chkLastGirat:
		ld	hl, GiratEnProceso
		inc	(hl)
		ld	a, (hl)
		inc	hl
		cp	(hl)
		jr	nz, chkGiratorias2
		ret


;----------------------------------------------------
; Obtiene en HL	el puntero a los datos de la puerta giratoria en proceso
; Out:
;   A =	Estado
;
; 진행 중인 회전문의 데이터에 대한 포인터를 HL에 가져옵니다.
; 출력:
;   A = 상태
;----------------------------------------------------


getGiratorData:
		ld	hl, doorGiraData ; 0 = Status (bit 0 = Girando,	bits 2-1 = altura + 2)
					; 1 = Y
					; 2 = X	decimal
					; 3 = X
					; 4 = Habitacion
					; 5 = Sentido giro
					; 6 = Contador giro
		call	ADD_A_HL
		ld	a, (GiratEnProceso)

getHL_Ax7:
		ld	b, a		; Devuelve HL +	A*7 y A=(HL)
		sla	b
		add	a, b
		sla	b
		add	a, b
		call	ADD_A_HL
		ld	a, (hl)
		ret

;----------------------------------------------------
;
; Quita	las puertas giratorias del mapa
; Si estan en la misma habitacion que el prota las borra de la pantalla
;
; 지도에서 회전문 제거
; 주인공과 같은 방에 있다면 화면에서 삭제
;
;----------------------------------------------------

quitaGiratorias:
		xor	a
		ld	hl, numDoorGira
		cp	(hl)
		ret	z		; No hay puertas giratorias

		ld	(GiratEnProceso), a ; Empieza por la primera
		inc	hl

quitaGiratoria2:
		push	hl
		ld	a, (hl)		; Tama�o de la puerta giratoria
		rra
		and	3
		add	a, 2
		ld	b, a		; Altura en patrones
		push	bc
		inc	hl
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ld	c, 0
		call	putGiratMap3
		pop	hl
		call	getLocationDE3	; Comprueba si la puerta esta en la misma pantalla que el prota
		pop	bc
		ld	c, 2
		jr	nz, quitaGiratoria3 ; No lo esta
		call	coordVRAM_DE	; D = Y, E = X
		ld	de, eraseData
		call	DEtoVRAM_NXNY	; Borra	la puerta de la	pantalla

quitaGiratoria3:
		pop	hl
		ld	de, 7
		add	hl, de
		exx
		ld	hl, GiratEnProceso
		inc	(hl)		; Incrementa el	contador de puerta giratoria en	proceso
		ld	a, (hl)
		inc	hl
		cp	(hl)		; Ha comprobado	todas las puertas giratorias?
		exx
		jr	nz, quitaGiratoria2
		ret


;----------------------------------------------------
; Calcula la direccion de la tabla de nombres a	la que apunta HL
; In:
;   H =	X
;   L =	Y
; Out:
;  HL =	Direccion VRAM de la tabla de nombres
;
; HL이 가리키는 이름 테이블의 주소 계산
; 입력:
;   H = X
;   L = 예
; 출력:
;  HL = VRAM 이름 테이블 주소
;----------------------------------------------------

coordVRAM_HL:
		push	de
		ex	de, hl
		ld	a, d
		ld	d, e
		ld	e, a
		call	coordVRAM_DE	; D = Y, E = X
		pop	de
		ret


;----------------------------------------------------
; Patrones usados para pintar una puerta giratoria en movimiento
; Tiene	5 posiciones posibles y	una altura maxima de 32	pixeles	(4 patrones)
; El ancho es de 16 pixeles (2 patrones)
;
; 움직이는 회전문을 그리는 데 사용되는 패턴
; 5개의 가능한 위치와 최대 32픽셀(4개 패턴)의 높이가 있습니다.
; 너비는 16픽셀(2 패턴)입니다.
;----------------------------------------------------
tilesGiroDoor:	db 68h,	69h, 68h, 69h, 68h, 69h, 68h, 69h
		db 6Ah,	6Bh, 6Ah, 6Bh, 6Ah, 6Bh, 6Ah, 6Bh ; Azul/Blanco	girado ->
		db 54h,	55h, 54h, 55h, 54h, 55h, 54h, 55h ; Muro azul
		db 7Ah,	79h, 7Ah, 79h, 7Ah, 79h, 7Ah, 79h ; Blanco/azul	girado <-
		db 78h,	77h, 78h, 77h, 78h, 77h, 78h, 77h ; Blanco/azul


;----------------------------------------------------
;
; Descomprime la piramide actual y sus elementos:
; Plataformas, salidas,	momias, gemas, cuchillos,
; picos, puertas giratorias, muros trampa y escaleras
;
; 현재 피라미드와 해당 요소의 압축을 풉니다.
; 플랫폼, 출구, 미라, 보석, 칼, 곡괭이, 회전문, 함정 벽 및 계단
;
;----------------------------------------------------

setupStage:
		xor	a
		ld	(flagMuerte), a
		ld	(UNKNOWN), a	; (!?) Se usa?
		call	BorraMapaRAM
		inc	a
		ld	(flagVivo), a
		call	hideSprAttrib	; Limpia los atributos de los sprites (los oculta)

		ld	hl, piramideDest
		ld	a, (hl)
		dec	hl
		ld	(hl), a		; Piramide actual igual	a la de	destino
		call	ChgStoneColor	; Cada 4 fases cambia el color de las piedras

		ld	hl, indexPiramides ; Indice de las piramides
		ld	a, (piramideActual)
		dec	a
		add	a, a
		call	getIndexHL_A	; Obtiene el puntero al	mapa de	la piramide actual
		ex	de, hl
		ld	b, 4
		ld	ix, MapaRAMRoot	; La primera fila del mapa no se usa (ocupada por el marcador).	Tambien	usado como inicio de la	pila

unpackMap:
		ld	a, (de)
		push	bc
		push	de
		ld	hl, indexHalfMap
		ld	c, a
		rra
		rra
		rra
		and	1Eh
		call	getIndexHL_A
		ld	a, c
		and	0Fh
		push	hl
		ld	h, 0
		ld	l, a
		add	hl, hl
		add	hl, hl		; x4
		ld	d, h
		ld	e, l
		add	hl, hl
		add	hl, hl		; x16
		ld	b, h
		ld	c, l
		add	hl, hl		; x32
		add	hl, bc		; x48
		ld	b, h
		ld	c, l
		pop	hl
		add	hl, bc
		and	a
		sbc	hl, de		; x44
		push	ix
		pop	de
		exx
;
; Descomprime un cacho de mapa
; 22 filas x 16	columnas (media	pantalla)
; Cada bit indica si hay ladrillo o esta vacio
;
; 맵 청크 22행 x 16열 압축 풀기(절반 화면)
; 각 비트는 벽돌이 있는지 또는 비어 있는지 여부를 나타냅니다.
;
		ld	b, 16h		; Numero de filas por pantalla (22)

unpackMap2:
		exx
		ld	b, 2		; Dos bytes

unpackMap3:
		push	bc
		ld	b, 8		; Ocho bits
		ld	c, (hl)

unpackMap4:
		rl	c		; Rota el byte para mirar si el	bit esta a 0 o a 1
		ld	a, 0		; Tile vacio
		jr	nc, unpackMap5
		ld	a, 12h		; Tile ladrillo

unpackMap5:
		ld	(de), a		; Pone el tile en el buffer del	mapa
		inc	de
		djnz	unpackMap4

		inc	hl		; Siguiente byte (8 tiles)
		pop	bc
		djnz	unpackMap3

		ld	a, 50h		; Distancia a la siguiente fila. Hay tres pantallas en horizontal
		call	ADD_A_DE
		exx
		djnz	unpackMap2

		exx
		ld	bc, 10h		; Distancia a la segunda mitad de la pantalla
		add	ix, bc
		pop	de
		pop	bc
		ld	a, (de)
		inc	de
		and	0F0h
		cp	30h
		jr	z, getDoors
		djnz	unpackMap


;----------------------------------------------------
; Comprueba las	puertas	de salida de la	piramide
; Si la	Y (primer byte)	es #FF la salida no existe
; La puerta por	la que se entra	a la piramide la pone a	status #10 (1)
; Si ya	se han cogido las gemas	de esta	piramide mantiene las puertas visibles y cerradas (status #80)
; Si no	se han cogido, deja la puerta en status	0 (comprobando si se cogen todas las gemas)
;
; 피라미드의 출구 문을 확인하십시오
; Y(첫 번째 바이트)가 #FF이면 출력이 존재하지 않습니다.
; 피라미드에 들어가는 문은 상태 #10(1)입니다.
; 이 피라미드의 보석을 이미 가져간 경우에는 문이 계속 표시되고 닫힙니다(상태 #80).
; 가져가지 않았다면 문을 상태 0으로 둡니다(모든 보석을 가져갔는지 확인)
;----------------------------------------------------

getDoors:
		ld	hl, numPuertas
		ld	(hl), 4		; Maximo numero	de puertas que puede haber
		inc	hl
		ex	de, hl
		exx
		ld	b, 0		; Contador de salidas

getNextDoor:
		exx
		ld	a, (hl)		; Y de la puerta
		inc	a		; Es #FF (Existe esta salida?)
		jr	nz, getDoors3	; Si, existe

		dec	a
		ld	(de), a		; Marca	salida como no disponible
		inc	hl
		ld	a, 7		; Tama�o de la estructura de cada salida
		call	ADD_A_DE	; DE apunta al buffer de la siguiente salida
		jr	chkLastDoor	; Comprueba si ya se han procesado todas las puertas

getDoors3:
		call	transfCoords	; Transfiere coordenadas desde HL a DE (Y, X)

		ld	a, (puertaEntrada)
		srl	a
		cp	4
		jr	nz, getDoors4
		dec	a

getDoors4:
		exx
		cp	b		; Esta puerta es por la	que se entra en	la piramide?
		exx
		ld	a, 10h		; Status: Dibuja la puerta de entrada
		jr	z, getDoors6

		push	de
		call	chkPiramPasada	; Comprueba si la piramide ya ha sido pasada para dejar	o quitar la puerta de salida
		ld	a, 0		; Quita	la puerta y deja el estado que comprueba si se cogen todas las gemas
		jr	z, getDoors5
		ld	a, 80h		; Mantiene la puerta cerrada visible

getDoors5:
		pop	de

getDoors6:
		ld	(de), a		; Status de la puerta
		inc	de
		ld	a, (hl)
		call	AL_C__AH_B	; Copia	el nibble alto de A en B y el bajo en C
		ld	a, b
		ld	(de), a		; Piramide a la	que lleva esta puerta
		inc	de
		ld	a, c
		ld	(de), a		; Direccion de la flecha del mapa / puerta de entrada /	direccion de la	salida
		inc	de
		inc	hl

chkLastDoor:
		exx
		inc	b
		ld	a, 4		; Numero maximo	de salidas
		cp	b
		jr	nz, getNextDoor	; Aun quedan puertas por comprobar



;----------------------------------------------------
;Actualiza momias de la	piramide
;
; 피라미드 미라 업데이트
;----------------------------------------------------
		exx
		ld	a, (hl)
		ld	(numMomias), a
		inc	hl
		ld	b, a
		add	a, a
		add	a, b		; 3 bytes por momia (y,	x, tipo)
		ld	b, 0
		ld	c, a
		ld	de, momiasPiramid ; Datos de las momias	que hay	en la piramide actual: y, x (%xxxxx--p), tipo
		ldir


;----------------------------------------------------
; Actualiza gemas
;
; 보석 업데이트
;----------------------------------------------------
		ld	de, gemasTotales
		ld	a, (hl)		; Numero de gemas de la	piramide
		ldi
		inc	de
		ld	b, a		; Numero de gemas

readGemas:
		push	bc
		ld	a, (hl)		; Color
		and	0F0h
		or	1		; Activa gema
		ld	(de), a		; Tipo / color de la gema

		inc	hl
		inc	de
		ld	a, 1
		ld	(de), a		; Status 1

		inc	de
		call	transfCoords	; Transfiere coordenadas desde HL a DE (Y, X)
		inc	de
		inc	de
		inc	de		; 9 bytes por gema
		pop	bc
		djnz	readGemas


		push	hl
		xor	a
		ld	(ElemEnProceso), a ; Empezamos a pintar	las gemas desde	la primera

putNextGema:
		xor	a
		call	getGemaDat	; Puntero a la gema en proceso
		call	chkPiramPasada	; Hay que poner	las gemas de esta piramide o ya	se han cogido antes?
		jr	z, putNextGema2	; Hay que ponerlas

		ld	a, (hl)
		and	0F0h
		ld	(hl), a		; Desactiva gema
		inc	hl
		ld	(hl), 3		; Status 3 de la gema
		jr	chkLastGema_

putNextGema2:
		inc	hl
		inc	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		push	hl
		ld	de, brillosGema	; Patrones que forman los destellos de la gema
		call	putBrillosMap	; Pone los destellos de	la gema	en el mapa

		xor	a
		call	getGemaDat
		call	AL_C__AH_B	; Copia	el nibble alto de A en B y el bajo en C
		ld	a, b		; Color	de la gema
		add	a, 40h		; Map ID gemas
		pop	hl
		ld	(hl), a		; Pone gema

chkLastGema_:
		ld	hl, ElemEnProceso ; Usado para saber la	gema o puerta que se esta procesando
		inc	(hl)		; siguiente gema
		ld	a, (hl)
		dec	hl
		cp	(hl)		; Numero total de gemas
		jr	nz, putNextGema	; Faltan gemas por procesar
		pop	hl



;----------------------------------------------------
; Actualiza cuchillos
;
; 칼 업데이트
;----------------------------------------------------
		ld	de, numKnifes
		ld	a, (hl)		; Numero de cuchillos
		ld	(de), a		; Actualiza el numero de cuchillos de la piramide
		inc	hl
		inc	de
		or	a
		jr	z, getPicos	; No hay ninguno

		ld	b, a

setKnifeCoords:
		push	bc
		inc	de
		inc	de
		call	transfCoords	; Transfiere coordenadas desde HL a DE (Y, X)
		ld	a, 0Bh
		call	ADD_A_DE
		pop	bc
		djnz	setKnifeCoords

;----------------------------------------------------
; Actualiza picos
;
; 곡괭이 업데이트
;----------------------------------------------------

getPicos:
		ld	de, numPicos
		ld	a, (hl)		; Numero de picos
		ld	(de), a		; Actualiza el numero de picos de esta piramide
		inc	de
		inc	hl
		and	a
		jr	z, getGiratorias ; No hay picos

		ld	b, a		; Numero de picos

getPicos2:
		push	bc
		ld	a, 1
		ld	(de), a		; Status = 1
		inc	de
		call	transfCoords	; Transfiere coordenadas desde HL a DE (Y, X)
		pop	bc
		djnz	getPicos2

		push	hl
		ld	hl, numPicos
		ld	b, (hl)		; Numero de picos que hay en el	mapa
		inc	hl
		inc	hl		; Apunta a la Y	del pico

getPicos3:
		push	bc
		push	hl
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL
		ld	(hl), 80h	; Pone pico en el mapa
		pop	hl
		ld	a, 5
		call	ADD_A_HL	; Pasa datos del pico para apuntar a las coordenadas del siguiente
		pop	bc
		djnz	getPicos3
		pop	hl


;----------------------------------------------------
; Actualiza puertas giratorias
;
; 회전문 업데이트
;----------------------------------------------------

getGiratorias:
		ld	a, (hl)		; Numero de puertas giratorias
		inc	hl
		ld	de, numDoorGira
		ld	(de), a		; Actualiza numero de puertas giratorias de la piramide
		or	a
		jr	z, getMuroTrampa ; No hay puertas giratorias

		inc	de
		ld	b, a

getGiratorias2:
		push	bc
		ldi			; Altura puerta	(luego se divide entre 2 y se le suma 2)
		ldi			; Y
		inc	de		; Pasa decimales X

		ld	a, (hl)		; Coordenada X
		and	0F8h		; bits 7-3
		ld	(de), a		; X ajustada a patrones

		inc	de
		ld	a, (hl)
		rra
		rra			; bit 2
		and	1
		ld	(de), a		; Habitacion

		inc	de
		ld	a, (hl)
		rla
		rla			; bits 0-1
		and	0Ch
		ld	(de), a		; Sentido de giro
		inc	de
		inc	de
		inc	hl
		pop	bc
		djnz	getGiratorias2

		push	hl
		ld	ix, doorGiraData ; 0 = Status (bit 0 = Girando,	bits 2-1 = altura + 2)
					; 1 = Y
					; 2 = X	decimal
					; 3 = X
					; 4 = Habitacion
					; 5 = Sentido giro
					; 6 = Contador giro

getGiratorias3:
		call	putGiratMap	; Pone puerta giratoria	en el mapa
		ld	de, 7
		add	ix, de
		ld	hl, GiratEnProceso
		inc	(hl)
		ld	a, (hl)
		inc	hl
		cp	(hl)		; Comprueba si estan todas puestas
		jr	nz, getGiratorias3 ; Aun quedan	puertas	giratorias por poner en	el mapa
		pop	hl


;----------------------------------------------------
; Actualiza muros trampa
;
; 트랩 벽 업데이트
;----------------------------------------------------

getMuroTrampa:
		ld	de, numMuroTrampa ; Numero de muros trampa que hay en la piramide
		ld	a, (hl)
		ldi			; Copia	el numero de muros trampa que hay en esta piramide
		or	a
		jr	z, getStairs	;  No hay muros	trampa

		ld	b, a

getMuroTrampa2:
		push	bc		; Numero de muros trampa
		inc	de
		call	transfCoords	; Transfiere coordenadas desde HL a DE (Y, X)
		pop	bc
		djnz	getMuroTrampa2


;----------------------------------------------------
; Procesa escaleras
;
; 계단 처리
;----------------------------------------------------

getStairs:
		ex	de, hl
		ld	a, (de)		; Numero de escaleras
		ld	b, a
		inc	de
		and	a
		ret	z		; No hay escaleras

getStairs2:
		push	bc
		ld	hl, escaleraData
		ex	de, hl
		push	de
		ldi			; Y escalera

		xor	a
		ld	(de), a		; Decimales X

		inc	de
		ld	a, (hl)		; X
		and	0F8h
		ld	(de), a		; Ajusta la X a	multiplo de 8

		ld	a, (hl)		; Bit 0	= Sentido. Bit 1 = Habitacion
		and	1
		ld	b, a		; Sentido
						; 방향

		inc	de
		ld	a, (hl)
		rra
		and	1
		ld	(de), a		; Habitacion

		pop	de		; Datos	escaleras
		ex	de, hl
		push	de
		call	getMapOffset00	; Obtiene en HL	el puntero al mapa de las coodenadas apuntada por HL

getStairs3:
		ld	a, (hl)		; Hay algo en ese lugar	del mapa?
		and	a
		jr	nz, getStairs5	; Si, la escalera ha llegado a una plataforma

		ld	c, 20h
		call	putPeldanoMap
		and	a		; Sentido?
					; 방향?
		push	bc
		ld	bc, -62h	; Desplazamiento a la fila superior del	mapa si	la escalera que	sube hacia la izquierda
		jr	z, getStairs4
		inc	bc
		inc	bc		; Hacia	la derecha

getStairs4:
		add	hl, bc
		pop	bc
		jr	getStairs3

getStairs5:
		ld	c, 15h
		call	putPeldanoMap	; Pone pelda�o especial	de inicio/fin escalera
		pop	de
		inc	de
		pop	bc
		djnz	getStairs2
		ret

putPeldanoMap:
		ld	a, b		; Sentido
						; 방향
		and	a
		jr	z, putPeldanoMap2
		inc	c
		inc	c		; Pelda�os hacia la izquierda

putPeldanoMap2:
		ld	(hl), c
		inc	c
		inc	hl
		ld	(hl), c
		ret



;----------------------------------------------------
;
; Pinta	la pantalla, los sprites, cuchillos y coloca las momias
;
; 화면, 스프라이트, 칼을 칠하고 미라를 배치하세요.
;----------------------------------------------------

setupRoom:
		ld	a, 1
		ld	(flagScrolling), a
		ld	a, (ProtaRoom)	; Habitacion del prota (xHigh)
		add	a, a
		add	a, a
		add	a, a
		add	a, a
		add	a, a		; x32 (ancho de	una pantalla)
		ld	de, MapaRAM
		call	ADD_A_DE	; DE = Puntero a la pantalla en	la que se encuentra el prota (puede haber 3 en horizontal)
		call	drawRoom	; Dibuja la habitacion en la que se encuentra el prota
		call	updateSprites	; Pone los sprites
		call	AI_Cuchillos	; Pone los cuchillos
		xor	a
		ld	(momiaEnProceso), a

initMomias:
		call	initMomia
		ld	hl, momiaEnProceso
		inc	(hl)
		ld	a, (hl)
		dec	hl
		cp	(hl)		; Se han procesado todas las momia?
		jr	nz, initMomias
		ret


;----------------------------------------------------
;
; Inicializa la	momia en proceso
;
; Pasa los datos de la momia a su estructura
; Pone el estado 4 que es el de	aparecer
; Fija su velocidad y color dependiendo	del tipo de momia
; El tipo de momia se ve incrementado por el numero de veces que se ha terminado el juego
;
; 진행 중인 미라 초기화
;
; 미라에서 구조로 데이터 전달
; 그것은 나타날 상태 4를 넣습니다.
; 미라의 종류에 따라 속도와 색상을 설정합니다.
; 미라 유형은 게임이 끝난 횟수만큼 증가합니다.
;----------------------------------------------------

initMomia:
		call	getMomiaProcDat
		push	ix
		pop	hl		; Puntero a la estructura de la	momia
		ld	(hl), 4		; Accion momia aparecer
		inc	hl
		inc	hl
		inc	hl
		ld	de, momiasPiramid ; Datos de las momias	que hay	en la piramide actual: y, x (%xxxxx--p), tipo
		ld	a, (momiaEnProceso)
		ld	c, a
		add	a, a
		add	a, c		; x3
		call	ADD_A_DE
		ex	de, hl		; HL apunta a la definicion de momia

	IF	(VERSION2)
		call	transfCoords	; Transfiere coordenadas de la momia
	ELSE
		ldi			; Copia	la Y

		inc	de		; Pasa decimales X

		ld	a, (hl)
		and	0F8h		; Ajusta la coordenada X a multiplo de 8
		ld	(de), a		; X

		inc	de
		ld	a, (hl)
		and	1
		ld	(de), a		; Habitacion de	inicio (xHigh)

		inc	de
		inc	hl
	ENDIF

		ld	a, (hl)		; Tipo de momia
		ld	c, a
		ld	a, (numFinishGame) ; Numero de veces que se ha terminado el juego
		add	a, c		; Suma al tipo de momia	las veces que se ha terminado el juego
		cp	5		; Comprueba si se sale del rango de tipos de momias existentes
		jr	c, initMomia2

		ld	a, 4		; Tipo de momia	mas inteligente

initMomia2:
		ld	c, a		; Tipo de momia
		ex	de, hl
		ld	de, tiposMomia	; Caracteristicas de cada tipo de momia	(color y velocidad)
		call	ADD_A_DE
		ld	a, (de)
		ld	b, a
		and	0F0h		; El nibble alto indica	la velocidad de	la momia
		ld	(hl), a		; Velocidad

		ld	a, 0Ah
		call	ADD_A_HL
		ld	(hl), 10h	; Timer	(tiempo	que tarda en aparecer)
		inc	hl
		inc	hl
		inc	hl
		ld	(hl), c		; Tipo de momia
		inc	de
		call	getMomiaAtrib	; Attributos del sprite	de la momia
		inc	hl
		inc	hl
		inc	hl
		ld	a, b
		call	AL_C__AH_B	; Copia	el nibble alto de A en B y el bajo en C
		ld	(hl), c		; Color
		ret

;----------------------------------------------------
; Tipos	de momia
; Nibble bajo =	Color
; Nibble alto =	Velocidad
;
; 미라 유형
; 낮은 니블 = 색상
; 높은 니블 = 속도
;----------------------------------------------------
tiposMomia:	db 5Fh
		db 59h
		db 0A4h
		db 0A8h
		db 0BAh

;----------------------------------------------------
; Get index HL,	A
;
; In: HL = Index pointer
;      A = Index
; Out: HL = (HL	+ A)
;
; 인덱스 HL, A 가져오기
;
; 입력: HL = 인덱스 포인터
;       A = 인덱스
; 출력: HL = (HL + A)
;----------------------------------------------------

getIndexHL_A:
		call	ADD_A_HL
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		ret


;----------------------------------------------------
; Comprueba si la piramide actual ya ha	sido terminada
; Out: NZ = Pasada
;	Z = No pasada
;
; 현재 피라미드가 이미 완료되었는지 확인하십시오.
; 출력: NZ = 통과
;   Z = 통과되지 않음
;----------------------------------------------------

chkPiramPasada:
		ld	bc, (PiramidesPasadas) ; Cada bit indica si la piramide	correspondiente	ya esta	pasada/terminada
		push	bc
		call	calcBitMask	; Devuelve en DE el bit	activo que corresponde a la piramide actual
		pop	bc
		ld	a, b
		and	d
		ld	b, a
		ld	a, c
		and	e
		add	a, b
		ret


;----------------------------------------------------
; Transfiere coordenadas desde HL a DE (Y, X)
; In:
;   HL = Y, X (XXXXXxxP) X = Coordenada	X, P = Pantalla
;
; HL에서 DE(Y, X)로 좌표 전송
; 입력:
;   HL = Y, X(XXXXXxxP) X = X 좌표, P = 화면
;----------------------------------------------------

transfCoords:
		ldi			; Copia	coordenada Y
		inc	de		; Pasa los decimales de	la X
		ld	a, (hl)
		and	0F8h		; Ajusta coordenada X a	multiplos de 8 (patrones)
		ld	(de), a		; Guarda coordenada X

		inc	de		; Apunta al segundo byte de la coordenada X (habitacion)
		ld	a, (hl)		; Vuelve a leer	la coordenada X
		and	1		; Se queda con el bit 0	(!?) Solo pueden ponerse la gemas en la	pantalla 0 o 1
		ld	(de), a		; Interpreta el	bit 0 como pantalla de destino (coordenada + 256*bit0)
		inc	de
		inc	hl
		ret



;----------------------------------------------------
; Mapas	de las piramides
;
; 피라미드 지도
;----------------------------------------------------
indexPiramides:	dw MapStage1
		dw MapStage2
		dw MapStage3
		dw MapStage4
		dw MapStage5
		dw MapStage6
		dw MapStage7
		dw MapStage8
		dw MapStage9
		dw MapStage10
		dw MapStage11
		dw MapStage12
		dw MapStage13
		dw MapStage14
		dw MapStage15

indexHalfMap:	dw halfMap1
		dw halfMap2
		dw halfMap3
		dw halfMap4


;----------------------------------------------------
; Patrones que forman el destello de las gemas
; 보석의 반짝임을 구성하는 패턴
;----------------------------------------------------
brillosGema:	db 40h			; Superior
		db 41h			; Izquierda
						; 왼쪽
		db 0			; Espacio para la gema
		db 42h			; Derecha
						; 오른쪽


;----------------------------------------------------
; Borra	el mapa	de la RAM
; RAM에서 맵 지우기
;----------------------------------------------------

BorraMapaRAM:
		ld	hl, MapaRAM
		ld	de,  MapaRAM+1
		ld	bc, 8A0h
		ld	(hl), 14h
		ldir
		ret

;----------------------------------------------------
;
; Cambia el color de los ladrillos cada	4 fases
;
; 4단계마다 벽돌 색상 변경
;
;----------------------------------------------------

ChgStoneColor:
		ld	a, (piramideActual)
		dec	a
		rra
		rra
		and	3
		ld	hl, ColoresPiedra
		call	getIndexX9
		ex	de, hl
		ld	hl, 200h	; Destino = Patron #40 (Piedras/ladrillos)
		ld	b, 5		; Numero de patrones a pintar

ChgStoneColor2:
		push	bc
		push	de
		push	hl
		call	UnpackPatterns
		pop	hl
		ld	de, 8
		add	hl, de
		pop	de
		pop	bc
		djnz	ChgStoneColor2
		ret

;----------------------------------------------------
; Colores de los ladrillos
; Formato: numero de filas, color
;
; 벽돌색
; 형식: 행 수, 색상
;----------------------------------------------------
ColoresPiedra:	db    2,0A0h,	2, 60h,	  2,0A0h,   2, 60h,   0
		db    2, 40h,	2, 70h,	  2, 40h,   2, 70h,   0
		db    2, 60h,	2,0A0h,	  2, 60h,   2,0A0h,   0
		db    2,0C0h,	2,0B0h,	  2,0C0h,   2, 30h,   0


;----------------------------------------------------
;
; Logica del prota en las escaleras cuando entra o sale	de la piramide
; Comprueba si las sube	o las baja y actualiza las coordenadas del prota
; Si sale, comprueba si	hay que	dar un bonus
;
; 피라미드에 들어가거나 나올 때 계단에 있는 주인공의 논리
; 업로드 또는 다운로드가 되는지 확인하고 주인공의 좌표를 업데이트 합니다.
; 나오면 보너스를 줘야하는지 확인
;
;----------------------------------------------------

escalerasEntrada:
		ld	a, (statusEntrada) ; Status del	prota en las escaleras de la entrada/salida
		call	jumpIndex

		dw entraSale		; Subiendo o bajando por las escaleras
		dw quietoFinEsc		; Ha llegado al	final de las escaleras.	Espera un rato
		dw chkBonusStage	; Comprueba si hay que dar un bonus por	pasarse	la piramide
		dw haSalido		; Ha salido de la piramide. Pasa al pergamino

entraSale:
		ld	hl, protaMovCnt	; (!?) Donde se	usa HL?
		ld	a, (timer)
		and	3
		ret	nz		; Procesa una de cada cuatro iteraciones

		ld	hl, 1E0h
		ld	(protaSpeed), hl ; Velocidad X mientras	entra en la piramide
		call	mueveProta	; Actualiza la posicion	del prota

		ld	a, (GameStatus)
		cp	4		; Entrando o saliendo de la piramide?
		jr	nz, salePiramide

		ld	hl, ProtaY
		inc	(hl)		; Incrementa la	Y del prota
		ld	a, (hl)
		and	7		; Ha terminado de bajar	las escaleras? (solo baja 1 tile)
		jr	nz, animProta	; Siguiente frame de la	animacion del prota

		ld	a, 1
		ld	(protaFrame), a	; Pone frame de	quieto
		call	setAttribProta	; Actualiza atributos de los sprites del prota
		jr	finEntraSale

salePiramide:
		ld	hl, ProtaY
		dec	(hl)		; Decrementa la	Y del prota
		inc	hl
		inc	hl
		ld	a, (hl)		; X prota
		add	a, 8
		ld	hl, puertaXspr	; X sprite puerta (parte derecha)
		cp	(hl)		; Esta medio cuerpo del	prota tapado por la puerta derecha?
		jr	c, animProta	; No

		call	hideSprAttrib	; Oculta todos los sprites (prota, puerta derecha...)
		jr	finEntraSale

animProta:
		ld	hl, protaFrame
		inc	(hl)		; siguiente frame
		and	7		; rango	0-7
		ld	(hl), a
		jp	setAttribProta	; Actualiza atributos de los sprites del prota

finEntraSale:
		ld	bc, 0A8h
		ld	(protaSpeed), bc ; El byte bajo	indica la parte	"decimal" y el alto la entera
		ld	b, 4		; Numero de sprites a quitar
		call	hideSprAttrib2	; Oculta los sprites de	la puerta

		ld	hl, statusEntrada ; Status del prota en	las escaleras
		inc	(hl)		; Pasa al siguiente estado: quieto al pie de las escaleras

		ld	a, 20h
		ld	(timer), a
		ret


;----------------------------------------------------
; El prota ha llegado al final de las escaleras
; al entrar o al salir de la piramide
;
; 피라미드에 들어가거나 나올 때 주인공이 계단의 바닥에 도달했습니다.
;----------------------------------------------------

quietoFinEsc:
		call	AI_Salidas
		ld	a, (puertaCerrada) ; Vale 1 al cerrarse	la salida
		or	a
		ret	z		; La puerta no se ha cerrado aun

		ld	a, (GameStatus)
		cp	4		; Entrando o saliendo de la piramide?
		jr	z, estaDentro	; Entrando

		ld	a, 20h		; Silencio
		call	setMusic

		ld	hl, statusEntrada
		inc	(hl)		; Pasa al siguiente estado de las escaleras: comprueba si hay que dar un bonus por pasarse la fase

		xor	a
		ld	(ElemEnProceso), a ; Usado para	saber la gema o	puerta que se esta procesando
		ret


;----------------------------------------------------
; Ya esta dentro de la piramide	y la puerta se ha cerrado.
; Pasa al siguiente substado que inicia	la fase
;
; 그것은 이미 피라미드 안에 있고 문이 닫혀 있습니다.
; 단계를 시작하는 다음 하위 상태로 이동
;----------------------------------------------------

estaDentro:
		ld	a, 28h
		ld	(waitCounter), a
		ld	hl, subStatus
		inc	(hl)		; Inicia la fase
		ret

;----------------------------------------------------
;
; Comprueba si hay que dar un bonus por	pasarse	la piramide
; Si ya	se ha pasado no	hay bonus
;
; 피라미드 통과에 대한 보너스가 있는지 확인하십시오.
; 이미 통과한 경우에는 보너스가 없습니다.
;
;----------------------------------------------------

chkBonusStage:
		ld	hl, waitCounter
		dec	(hl)
		ret	p

		call	chkPiramPasada
		jr	nz, chkBonusStage2 ; Ya	se la habia pasado

		ld	de, 2000h
		call	SumaPuntos	; Bonus	de 2000	puntos
		ld	a, 8Fh		; Bonus	stage clear
		call	setMusic

chkBonusStage2:
		ld	hl, statusEntrada
		inc	(hl)		; Pasa al siguiente estado

		ld	a, 70h
		ld	(waitCounter), a ; Tiempo que espera antes de finalizar	el proceso de salida

		call	calcBitMask	; Devuelve en DE el bit	activo que corresponde a la piramide actual
		ld	hl, PiramidesPasadas ; Cada bit	indica si la piramide correspondiente ya esta pasada/terminada
		jp	setPiramidClear	; Marca	la piramide actual como	pasada


;----------------------------------------------------
; Vida extra
; Suma una vida	y reproduce un SFX para	indicarlo
;
; 보너스 라이프
; 생명을 추가하고 SFX를 재생하여 표시
;----------------------------------------------------

VidaExtra:
		ld	hl, Vidas
		inc	(hl)		; Incrementa el	numero de vidas

		ld	a, 8Ah		; SFX vida extra
		call	setMusic
		jp	dibujaVidas

;----------------------------------------------------
; Ha salido de la piramide
;
; 피라미드에서 나왔다
;----------------------------------------------------

haSalido:
		ld	hl, timer
		ld	a, (hl)
		and	3		; (!?) Para que	hace esto sin o	vale para nada?

		inc	hl
		dec	(hl)		; Decrementa waitCounter
		ret	nz		; Aun hay que esperar a	que termine la fanfarria de "se salio de la piramide"

		xor	a
		ld	(flagEntraSale), a ; Continua con la logica normal del juego

		ld	a, 8		; Status = Stage clear
		ld	(GameStatus), a
		ret


;----------------------------------------------------
; Inicializa los sprites del prota y de	la puerta de entrada
; Coloca al prota en la	parte superior derecha de las escaleras	e indica color de ropa y piel
; Cambia el estado de la puerta	a "cerrandose"
; Coloca los sprites que forman	la hoja	derecha	de la puerta que solapa	al prota
; Cuatro sprites en total (dos parejas solapadas)
;
; 주인공의 스프라이트와 출입문 초기화
; 계단 우측 상단에 주인공을 배치하고 의복과 피부색을 표시
; 문 상태를 "닫힘"으로 변경
; 주인공과 겹치는 문의 오른쪽 잎사귀를 형성하는 스프라이트를 배치
; 총 4개의 스프라이트(겹치는 두 쌍)
;----------------------------------------------------

setSprDoorProta:
		ld	de, sprAttrib	; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
		ld	hl, attribDoor	; Atributos de las puertas de la entrada
		ld	bc, 10h		; 4 sprites * 4	bytes
		ldir

		ld	a, 0Eh
		ld	(protaColorRopa), a ; Color gris para la ropa y	casco del prota
		ld	a, 6
		ld	(ProtaColorPiel), a ; Color naranja para la piel

		ld	a, (puertaEntrada) ; Puerta por	la que se esta entrando	(direccion)
		srl	a		; Los valores son 1,2,4,8
		cp	4
		jr	nz, initDoorProta2
		dec	a		; Convierte numero de bit a decimal

initDoorProta2:
		ld	hl, pyramidDoors ; Y (FF = Desactivado)
					; X decimales
					; X
					; Habitacion
					; Status (Nibble alto =	Status,	Nibble bajo = contador)
					; Piramide destino
					; Direccion por	la que se entra	/ Flecha del mapa
		call	getHL_Ax7	; Obtiene puntero a los	datos de la puerta por la que se entra

		push	hl
		ld	de, ProtaY
		ld	a, (hl)		; Y centro puerta
		sub	8
		ld	(de), a		; Coloca al prota 8 pixeles mas	arriba
		inc	de
		inc	hl
		ldi			; X decimales

		ld	a, (hl)		; X centro puerta
		add	a, 8
		ld	(de), a		; Coloca al prota 8 pixeles a la derecha

		inc	de
		inc	hl
		ldi			; Misma	habitacion para	la puerta y para el prota

		ld	bc, 5
		ld	hl, protaDataDoor
		ldir			; Pone valores por defecto al iniciar una fase

		call	setAttribProta	; Actualiza los	atributos RAM de los sprites del prota segun sus coordenadas y sentido

		ld	a, (puertaEntrada)
		srl	a
		cp	4
		jr	nz, initDoorProta3 ; Guarda el indice de puerta	por la que se entra a la piramide
		dec	a		; Convierte numero de bit a decimal

initDoorProta3:
		ld	(ElemEnProceso), a ; Guarda el indice de puerta	por la que se entra a la piramide
		ld	a, 4		; Status
		call	getExitDat	; Obtiene un puntero al	estado de la puerta
		ld	(hl), 50h	; Estado de cerrando puerta

		pop	hl		; Puntero a la puerta
		ld	d, (hl)		; Coordenada Y central de la puerta
		inc	hl
		inc	hl
		ld	e, (hl)		; Coordenada X central de la puerta

		ld	hl, sprAttrib	; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
		ld	a, 16
		add	a, e
		ld	e, a		; Suma 16 a la X de la puerta

		ld	a, d
		sub	17
		ld	d, a		; Resta	17 a la	Y de la	puerta

		ld	b, 2

initDoorProta4:
		ld	c, 2		; Son dos sprites solapados para conseguir color de fondo y de tinta

initDoorProta5:
		ld	(hl), d		; Y
		inc	hl
		ld	(hl), e		; X
		inc	hl		; El sprite ya ha sido indicado	antes mediante 'attribDoor'
		inc	hl		; El color tambien ha sido indicado por	'atribDoor'
		inc	hl		; Apunta a los atributos del siguiente sprite
		dec	c
		jr	nz, initDoorProta5 ; Siguiente sprite solapado


		ld	a, d		; Y del	primer cacho de	puerta
		add	a, 16		; Desplaza el alto del sprite (16 pixeles)
		ld	d, a
		djnz	initDoorProta4	; Pone el siguiente par	de sprites debajo del anterior

		xor	a
		ld	(statusEntrada), a ; Subestado de la puerta por	la que entra en	la piramide
		inc	a
		ld	(sentidoProta),	a ; 1 =	Izquierda, 2 = Derecha
		ret


;----------------------------------------------------
; Valores iniciales de las siguientes variables	al
; comenzar una fase
;
; Velocidad X decimales,
; Velocidad X entero,
; Velocidad X habitacion,
; Contador movimiento,
; Frame
;
; 단계 시작 시 다음 변수들의 초기 값
;
; 소수 X 속도,
; 정수 X 속도,
; 방 X 속도,
; 이동 카운터,
; 프레임
;----------------------------------------------------
protaDataDoor:	db 0C8h, 0, 0, 1, 1


;----------------------------------------------------
; Attributos de	la puerta de entrada
; x, y,	sprite,	color
;
; 문 속성 x, y, 스프라이트, 색상
;----------------------------------------------------
attribDoor:	db 0E0h,0B0h,0D8h,   1	; Dibujo ladrillos
		db 0E0h,0B0h,0DCh,   3	; Relleno ladrillos
		db 0E0h,0B0h,0E0h,   1	; Dibujo ladrillos
		db 0E0h,0B0h,0E4h,   3	; Relleno


;----------------------------------------------------
; AI Momias
; Inteligencia de las momias
; Dependiendo del tipo de momia, estas dudan mas o menos al tomar una decision
; y van	mas rapidas o lentas por las escaleras.
; Itentan acercarse al prota y se aseguran de no aparecer por sorpresa por un lado de la pantalla cuando el prota esta cerca del borde
;
; AI 미라
; 미라의 지능
; 미라의 종류에 따라 결정을 내릴 때 다소 주저하고 계단을 더 빨리 또는 느리게 내려갑니다.
; 그들은 주인공에게 더 가까이 다가가려고 노력하고 주인공이 가장자리에 가까울 때 화면 측면으로 몰래 들어오지 않도록 합니다.
;----------------------------------------------------

AI_Momias:
		xor	a		; Empieza por la primera momia :)
		ld	(momiaEnProceso), a

nextMomia:
		call	getMomiaProcDat	; Obtiene puntero a la momia en	proceso
		exx
		ld	h, d
		ld	l, e
		ld	b, (hl)		; Status de la momia
		inc	hl
		ld	a, (hl)		; Sentido (1 = izquierda, 2 = derecha)
		srl	a
		srl	a
		inc	hl
		ld	(hl), a		; Controles. Dependiendo del sentido "aprieta" DERECHA o IZQUIERDA
		ld	a, b		; Estado de la momia
		exx


		ld	hl, updateMomiaAtr ; Actualiza los atributos RAM de la momia
		push	hl		; Guarda esta funcion en la pila para ejecutarla al terminar el	proceso	actual


		call	jumpIndex	; Dependiendo del estado de la momia salta a una de las	siguientes funciones


		dw momiaAnda		; 0 = Anda y comprueba si se cae o decide saltar. Al finalizar pasa al estado de pensar
		dw momiaSaltando	; 1 = Procesa salto
		dw momiaCayendo		; 2 = Momia cayendo. Al	llegar al suelo	pasa al	estado de andar
		dw momiaEscaleras	; 3 = Mueve a la momia por las escaleras y comprueba si	llega al final de las mismas
		dw momiaLimbo		; 4 = Espera un	tiempo antes de	pasar al siguiente estado (aparecer)
		dw momiaAparece		; 5 = Proceso de aparicion de la momia mediante	una nube de polvo
		dw momiaSuicida		; 6 = Anda hacia la derecha y explota
		dw momiaPiensa		; 7 = Mira a los lados y decide	como acercarse al prota
		dw momiaDesaparece

;----------------------------------------------------
; Momia	anda
; Si el	timer de la momia es 0 pasa al estado de pensar	y fija cuantas veces dudara antes de decidirse
; Cuando la momia choca	contra un muro se incrementa su	nivel de stress.
; Cada vez que consigue	andar un rato sin chocarse, el nivel de	stress disminuye.
; Cuando se estresa mucho, la momia acaba explotando.
; De esta forma	se evita que se	quede trabada en un agujero o en una ruta sin salida
;
; 미라 산책
; 미라의 타이머가 0이면 생각상태로 들어가 몇 번을 망설일지 설정하고 결정한다.
; 미라가 벽에 부딪히면 스트레스 수준이 높아집니다.
; 그가 잠시 동안 충돌하지 않고 걸을 때마다 스트레스 수준이 감소합니다.
; 너무 스트레스를 받으면 미라가 폭발합니다.
; 이렇게 하면 구멍이나 막다른 길에 끼는 것을 방지할 수 있습니다.
;----------------------------------------------------

momiaAnda:
		ld	a, (ix+ACTOR_TIMER)
		or	a		; Esta andando?
		jr	nz, momiaAnda2	; si

		ld	(ix+ACTOR_STATUS), 7 ; Estado: Pensando
		ld	a, (ix+ACTOR_TIPO) ; Tipo de momia
		ld	de, vecesDudaMomia
		call	ADD_A_DE
		ld	a, (de)		; Segun	el tipo	de momia, duda o mira mas tiempo a los lados
		ld	(ix+ACTOR_TIMER), a ; Veces que	mira a los lados
		ret

momiaAnda2:
		ld	a, (timer)
		and	0Fh
		jr	nz, momiaAnda3

		dec	(ix+ACTOR_TIMER) ; Cada	16 iteraciones decrementa el tiempo de andar

momiaAnda3:
		pop	hl		; Saca de la pila la rutina que	actualiza los atributos	de la momia
		call	evitaSorpresa	; Evita	que una	momia aparezca por un lateral cuando el	prota esta cerca

		ld	hl, updateMomiaAtr ; Funcion que actualiza los atributos RAM del sprite	de la momia
		push	hl		; Guarda la funcion en la pila para ejecutar al	terminar el proceso

		ld	a, (ix+ACTOR_CONTROL) ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		bit	4, a		; Boton	A:Orden	de saltar
		jp	nz, tryToJump	; Salta	si no hay obstaculos

		push	ix		; Datos	momia
		pop	hl


		inc	hl
		push	hl		; Pointer a los	controles de la	momia
		inc	hl
		inc	hl		; Apunta a la coordenada Y
		call	chkCae		; Comprueba si tiene suelo bajo	los pies
		pop	hl
		jp	c, momiaSinSuelo ; Se va a caer	o decide saltar

		push	hl		; Puntero a los	controles (+#01)
		ld	a, 1		; Las momias no	actualizan la variable "sentidoEscalera" del prota
		ld	(modoSentEsc), a ; Si es 0 guarda en "sentidoEscalera" el tipo de escalera que se coge el prota. 0 = \, 1 = /
		call	chkCogeEsc2	; Comprueba si comienza	a subir	o bajr por una escalera
		pop	hl
		jp	z, setSentEsc	; Ha cogido unas escaleras

		call	chkChocaAndar2	; Comprueba si choca contra un muro o puerta giratoria

		push	af
		ld	a, ACTOR_STRESS	; Contador de veces que	choca (stress)
		call	getVariableMomia
		pop	af

		ld	a, (hl)		; Numero de veces que ha chocado
		jr	nc, momiaDecStress ; No	choca contra un	muro o puerta giratoria. Decrementa numero de decisiones

; La momia ha chocado con un muro
; Si el	numero de veces	que ha chocado casi consecutivamente es	9, la momia explota
; De esta forma	se evita que se	quede trabada en un agujero o en una ruta sin salida
		and	0F0h
		add	a, 1Fh		; Incrementa el	stress de la momia
		ld	(hl), a
		cp	0AFh
		jr	nz, momiaHaChocado

momiaVanish:
		ld	(ix+ACTOR_STATUS), 8 ; Estado: momia explota y desaparece
		ld	(ix+ACTOR_CONTROL), 4 ;	Va a la	izquierda
		ld	(ix+ACTOR_TIMER), 22h
		ret

momiaDecStress:
		cp	0F0h
		jr	z, momiaUpdate	; Si el	contado	de stress es 0 no lo decrementa

		ld	a, (timer)
		and	1Fh
		jr	nz, momiaUpdate	; Solo lo decrementa cada #20 iteraciones

		dec	(hl)		; Decrementa el	stress de la momia
		jr	nz, momiaUpdate	; (!?) Para que?

;----------------------------------------------------
; Actualiza la posicion	y frame	de la momia
; 미라의 위치와 프레임 업데이트
;----------------------------------------------------

momiaUpdate:
		ld	e, (ix+ACTOR_SPEEDXDEC)
		ld	d, (ix+ACTOR_SPEED_X) ;	DE = Velocidad de la momia
		ld	a, 4		; Offset X decimal
		call	getVariableMomia ; Obtiene puntero a la	X con decimales	de la momia
		call	mueveElemento	; Actualiza sus	coordenadas al sumarle la velocidad
		call	momiaCalcFrame	; Actualiza si es necesario el frame de	la animacion
		ret

;----------------------------------------------------
; Tras chocar contra un	muro la	momia salta o se da la vuelta
; Si es	la mas tonta y se queda	entre dos muro se para a pensar
;
; 벽에 부딪힌 후 미라가 점프하거나 돌아갑니다.
; 그녀가 가장 멍청하고 두 벽 사이에 있으면 생각을 멈춘다.
;----------------------------------------------------

momiaHaChocado:
		dec	hl
		ld	a, (hl)		; Tipo de momia
		or	a		; Es la	mas tonta? =0
		jr	nz, saltaOVuelve ; No

		call	getYMomia
		dec	hl
		ld	a, (hl)		; Sentido
						; 방향
		xor	3		; Invierte derecha/izquierda
		ld	b, a		; Cambia el sentido del	movimiento (la gira)
		call	chkChocaAndar4	; Tambien choca	por el otro lado?
		jr	nc, saltaOVuelve ; No choca


; La momia tonta (blanca) se queda atrapada entre dos muros

		ld	(ix+ACTOR_TIMER), 0FFh
		ld	(ix+ACTOR_STATUS), 7 ; Estado de pensar
		ret

;----------------------------------------------------
; La momia salta si puede. Si no, se da	la vuelta
; 미라는 그가 할 수 있으면 점프합니다. 그렇지 않으면 뒤집어진다.
;----------------------------------------------------

saltaOVuelve:
		call	getYMomia
		cp	8
		jr	c, daLaVuelta	; Esta muy arriba, da la vuelta

		call	chkSaltar	; Puede	saltar?	(No tiene nada encima ni delante)
		jp	c, momiaSetSalta ; Salta

daLaVuelta:
		ld	a, (ix+ACTOR_CONTROL) ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		xor	0Ch		; Cambia de direccion
		ld	(ix+ACTOR_CONTROL), a ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		ret

;----------------------------------------------------
; Incrementa el	contador de movimientos	y actualiza el numero de frame
; 이동 카운터를 늘리고 프레임 수를 업데이트합니다.
;----------------------------------------------------

momiaCalcFrame:
		ld	a, 0Ah		; Offset a contador de movimientos
		call	getVariableMomia
		inc	(hl)		; Incrementa el	numero de movimientos
		jp	calcFrame2	; Actualiza el numero de frame (0-7) segun  el numero de movimientos acumulados

;----------------------------------------------------
; Guarda el sentido de las escaleras dentro de la estructura de	la momia
; In:
;   C =	tile mapa (escaleras)
;
; 미라 구조물 내부의 계단 감각을 살리다
; 입력:
;   C = 타일 맵(계단)
;----------------------------------------------------

setSentEsc:
		ld	a, (ix+ACTOR_CONTROL) ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		rra			; Pasa control ARRIBA al carry
		ld	a, c
		ld	b, 8		; Control: DERECHA
		jr	nc, setSentEsc2	; No tiene ARRIBA apretado

		ld	b, 4		; Control: IZQUIERDA
		xor	1

setSentEsc2:
		and	1
		ld	(ix+ACTOR_SENT_ESC), a ; Sentido en el que van las escaleras. 0	= \  1 = /
		and	a
		ld	a, b
		jr	z, setSentEsc3
		xor	0Ch		; Cambia sentido del movimiento

setSentEsc3:
		ld	(ix+ACTOR_CONTROL), a ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		ret

;----------------------------------------------------
; Numero de veces que duda (mira a los lados) cada momia
; cuando esta decidiendo el siguiente movimiento
;
; 다음 행동을 결정할 때 각 미라가 주저하는 횟수(옆을 쳐다본다)
;----------------------------------------------------
vecesDudaMomia:	db    3
		db    3
		db    0
		db    0
		db    3


;----------------------------------------------------
; Actualiza los	atributos RAM de una momia
; Su posicion y	frame. La oculta si esta en otra habitacion
;
; 미라의 RAM 속성 업그레이드
; 당신의 위치와 프레임. 다른 방에 있으면 숨김
;----------------------------------------------------

updateMomiaAtr:
		ld	c, (ix+ACTOR_Y)
		ld	b, (ix+ACTOR_X)
		call	getMomiaAtrib

		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	(ix+ACTOR_ROOM)
		jr	nz, hideMomia	; No estan en la misma habitacion

		dec	c
		dec	c		; Y = Y	- 2
		ld	a, (ix+ACTOR_FRAME)
		push	af
		rra			; Si el	frame es par, mueve la momia un	poco hacia arriba
		jr	c, updateMomiaAt2
		inc	c

updateMomiaAt2:
		pop	af
		ld	de, framesMomia
		call	ADD_A_DE
		ld	a, (de)
		ld	d, a		; Frame
		ld	(hl), c		; Coordenada Y
		inc	hl
		ld	(hl), b		; Coordenada X
		inc	hl
		ld	a, (ix+ACTOR_SENTIDO) ;	1 = Izquierda, 2 = Derecha
		rra
		ld	a, d
		jr	nc, setFrameMomia
		add	a, 60h		; Desplazamiento a sprites invertidos

setFrameMomia:
		ld	(hl), a
		jr	chkLastMomia	; Comprueba si faltan momias por procesar

hideMomia:
		ld	(hl), 0E0h	; Oculta el sprite (Y =	#E0)

chkLastMomia:
		ld	hl, momiaEnProceso ; Comprueba si faltan momias	por procesar
		inc	(hl)
		ld	a, (hl)
		dec	hl
		cp	(hl)		; Ha procesado todas las momias?
		ret	nc		; Si, termina
		jp	nextMomia

framesMomia:	db 2Ch			; Pie atras
		db 28h			; Pies juntos
		db 30h			; Pies separados
		db 2Ch			; Pie atras
		db 28h			; Pies juntos
		db 30h			; Pies separados
		db 28h			; Pies juntos
		db 30h			; Pies eparados
		db 0E8h			; Nube grande
		db 0ECh			; Nube peque�a
		db 0D4h			; Destello

;----------------------------------------------------
; Intenta saltar
; Salta	si no esta muy arriba y	no hay obstaculos
;
; 점프를 시도
; 높이가 높지 않고 장애물이 없으면 점프
;----------------------------------------------------

tryToJump:
		call	getYMomia
		ld	a, (hl)
		cp	8
		ret	c
		call	chkSaltar
		ret	nc


;----------------------------------------------------
; Pone estado de salto
; Guarda puntero a los valores de desplazamientos Y del	salto
;
; 점프 상태 설정
; 점프의 Y 오프셋 값에 대한 포인터 저장
;----------------------------------------------------

momiaSetSalta:
		push	ix
		pop	hl		; Datos	momia

Salta:
		ld	(hl), 1		; Status = Saltar
		inc	hl
		res	4, (hl)		; Quita	"Boton A" del estado de las teclas del elemento

		ld	a, 0Ah
		call	ADD_A_HL
		ld	(hl), 2		; Frame	2 = Piernas separadas
		inc	hl
		ld	de, valoresSalto
		ld	(hl), e
		inc	hl
		ld	(hl), d		; Guarda puntero a los valores del salto

		inc	hl
		ld	(hl), 0		; Salto	subiendo (1 = cayendo)
		ret

;----------------------------------------------------
; Momia	saltando
; Actualiza las	coordenadas de la momia	y comprueba si choca
; contra algo para quitar el estado de salto y
; poner	el de andar o caida.
;
; 점프 미라
; 미라의 좌표를 업데이트하고 점프 상태를 제거하고 걷거나 넘어지는 것으로 돌아가기 위해 무언가와 충돌하는지 확인하십시오.
;----------------------------------------------------

momiaSaltando:
		call	getYMomia	; Obtiene puntero a los	datos de la momia
		dec	hl
		push	hl
		push	ix
		call	doSalto		; Procesa el salto

		pop	ix
		pop	hl
		call	chkPasaRoom	; Comprueba si pasa a otra habitacion
		push	ix
		pop	hl		; Puntero a estructura de la momia

	IF	(VERSION2)
		inc	hl
		xor	a
		cp	1
		call	chkChocaSalto1
	ELSE
		call	chkChocaSalto	; Choca	con algo al saltar?
	ENDIF
		jr	z, momiaCayendo	; Si, quita estado de salto y pone el de caida (si no hay suelo) o de andar (si	hay suelo)
		ret


;----------------------------------------------------
; Comprueba si el elemento llega a los limites de la pantalla
; y pasa de habitacion
; Out:
;   Z =	Pasa a otra habitacion
;  NZ =	No pasa
;
; 요소가 화면의 한계에 도달하고 방에서 통과하는지 확인
; 출력:
;   Z = 다른 방으로 이동
;  NZ = 실패
;----------------------------------------------------

chkPasaRoom:
		ld	a, (hl)		; Sentido
						; 방향
		inc	hl
		inc	hl
		inc	hl		; Apunta a la X
		ld	b, 0		; Limite izquierdo = 0
		rra			; Derecha o izquierda?
		jr	nc, chkPasaRoom2
		dec	b		; Limite derecho = 255

chkPasaRoom2:
		ld	a, b		; Limite
		cp	(hl)		; Lo compara con la X del elemento
		inc	hl
		ret	nz		; No ha	llegado	al limite de la	habitacion

		inc	(hl)		; Pasa a la habitacion de la derecha
		and	a
		ret	z

		dec	(hl)
		dec	(hl)		; Pasa a la habitacion de la izquierda
		ret

;----------------------------------------------------
; Cuando la momia llega	al borde de una	plataforma
; puede	saltar o dejarse caer
;
; 미라는 플랫폼 가장자리에 도달하면 점프하거나 떨어질 수 있습니다.
;----------------------------------------------------

momiaSinSuelo:
		ld	a, (ix+ACTOR_TIPO)
		and	a
		jr	z, momiaCayendo	; Momia	mas tonta. Nunca salta

		cp	3
		jr	z, momiaCayendo

		ld	a, (ix+ACTOR_POS_RELAT)	; 0 = A	la misma altura	(o casi), 1 = Momia por	encima,	2 = Por	debajo
		cp	1		; La momia esta	por encima del prota?
		jr	z, momiaCayendo	; Si, se deja caer para	bajar

		call	getYMomia	; Obtiene la Y de la momia
		ld	a, (hl)		; (!?) No hace falta
		cp	8		; Esta muy cerca de la parte de	arriba?
		jr	c, momiaCayendo	; No salta

; Va a saltar
		call	chkSaltar	; Tiene	espacio	para saltar?
		jp	c, momiaSetSalta ; si, salta


;----------------------------------------------------
; Procesa la caida de la momia y comprueba si llega al suelo
; Al llegar al suelo pone el estado de andar
;
; 미라의 낙하를 처리하고 지면에 닿는지 확인
; 지면에 닿으면 걷는 상태로 설정
;----------------------------------------------------


momiaCayendo:
		push	ix
		pop	hl
		call	cayendo		; Incrementa la	Y y comprueba si choca contra el suelo
		jp	nc, setMomiaAndar ; No esta cayendo, pone estado de andar
		ret

momiaEscaleras:
		push	ix
		pop	hl
		inc	hl
		ld	a, (hl)		; Controles
		and	0Ch
		ret	z		; No va	ni a la	derecha	ni a la	izquierda

		ld	a, (ix+ACTOR_TIPO)
		ld	de, pausaEscalera
		call	ADD_A_DE
		ld	a, (de)		; Masca	aplicada al timer para ralentizar el movimiento	de la momia en la escalera
		ld	b, a
		ld	a, 1
		ld	(quienEscalera), a ; (!?) Se usa esto? Quien esta en una escalera 0 = Prota. 1 = Momia
		ld	(quienEscalera), a ; (!?) Para que lo pone dos veces?
		call	andaEscalera
		jr	z, setMomiaPensar ; Ha llegado al final	de la escalera
		call	momiaCalcFrame
		ret

setMomiaPensar:
		ld	(ix+ACTOR_TIMER), 0 ; Al poner el timer	a 0 y el estado	de andar se consigue pasar al estado de	pensar en la siguiente iteracion

setMomiaAndar:
		xor	a
		jr	setMomiaStatus



		ld	a, 3		; (!?) Este codigo no se ejecuta nunca!

setMomiaStatus:
		ld	(ix+ACTOR_STATUS), a
		ret

;----------------------------------------------------
; Frames que los tipos de momia	se paran en cada paso
; que dan por las escaleras
; 0 = Muy rapido, 3 = lento
;
; 미이라가 계단을 올라갈 때마다 멈추는 프레임
; 0 = 매우 빠름, 3 = 느림
;----------------------------------------------------
pausaEscalera:	db    3
		db    0
		db    1
		db    0
		db    3

;----------------------------------------------------
; Estado por defecto de	la momia al empezar una	partida
; Espera un tiempo antes de aparecer
; El timer vale	#10 para que no	aparezca nada mas empezar
;
; 게임 시작 시 미라의 기본 상태
; 잠시만 기다려주세요
; 타이머는 시작하자마자 나타나지 않도록 #10의 가치가 있습니다.
;----------------------------------------------------

momiaLimbo:
		pop	hl		; Saca de la pila la funcion que actualiza los atributos de la momia (no es visible)
		ld	a, (timer)
		and	1
		jp	nz, chkLastMomia ; Procesa solo	una de cada dos	iteraciones

		dec	(ix+ACTOR_TIMER)
		jp	nz, chkLastMomia ; Aun falta tiempo para que aparezca

		inc	(ix+ACTOR_STATUS) ; Siguiente estado de	la momia: Aparece
		ld	(ix+ACTOR_TIMER), 82h

		ld	a, 87h		; SFX aparece momia
		call	setMusic
		jp	chkLastMomia	; Comprueba si faltan momias por procesar

;----------------------------------------------------
; Proceso de aparicion de una momia
; Decrementa el	tiempo de aparicion. Al	llegar al final	pasa al	estado 0
; Si faltan menos de 8 iteraciones muestra la momia con	las piernas abiertas mirando a la izquierda
; Cada 32 frames anima la nube que indica que va a aparecer una	momia
;
; 미라가 출현하는 과정
; 스폰 시간을 줄입니다. 끝에 도달하면 상태 0이 됩니다.
; 8회 미만의 반복이 누락된 경우 왼쪽을 향한 다리를 벌린 미라를 표시합니다.
; 32개의 프레임마다 미라가 나타날 것임을 나타내는 구름에 애니메이션 효과를 줍니다.
;----------------------------------------------------

momiaAparece:
		ld	(ix+ACTOR_CONTROL), 8 ;	Mirando	a la derecha
		dec	(ix+ACTOR_TIMER) ; Decrementa el tiempo	de aparicion
		jp	z, setMomiaViva	; Ha llegado al	final

		ld	a, (ix+ACTOR_TIMER)
		cp	7		; Falta	poco para que vuelva a la vida?
		jr	c, momiaOpenLegs ; Muestra la momia con	las piernas separadas

		ld	b, a
		and	1Fh
		ret	nz		; No han pasado	32 iteraciones

		bit	5, b
		ld	a, 8		; Frame	nube grande
		jr	z, setMomiaFrame

		inc	a		; Frame	nube peque�a

setMomiaFrame:
		ld	(ix+ACTOR_FRAME), a
		ret

setMomiaViva:
		call	setMomiaAndar

momiaOpenLegs:
		ld	(ix+ACTOR_FRAME), 2 ; Piernas separadas
		ret

momiaSuicida:
		ld	(ix+ACTOR_CONTROL), 8 ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		dec	(ix+ACTOR_TIMER)
		ld	a, (ix+ACTOR_TIMER)
		ld	b, a		; (!?) Donde se	unsa B?
		jr	z, mataMomia
		and	1Fh
		ret	nz

		ld	a, 0Ah		; Frame	destello desaparecer
		ld	(ix+ACTOR_FRAME), a
		ret

mataMomia:
		call	quitaMomia
		pop	hl
		jp	chkLastMomia	; Comprueba si faltan momias por procesar


;----------------------------------------------------
; Manda	una momia al limbo.
; Quita	su sprite de la	pantalla.
; Tras explotar	una momia se va	al limbo un rato
;
; 미라를 림보로 보냅니다.
; 화면에서 스프라이트를 제거합니다.
; 미라를 폭발시킨 후 잠시 림보 상태가 됩니다.
;----------------------------------------------------

quitaMomia:
		call	getMomiaAtrib
		ld	(hl), 0E0h	; Y = #E0. Quita momia de la pantalla
		ld	(ix+ACTOR_STATUS), 4 ; Limbo
		ld	(ix+ACTOR_TIMER), 80h
		ld	(ix+ACTOR_FRAME), 9
		ret

;----------------------------------------------------
; Obtiene un puntero a los atributos RAM de la momia en	proceso
; HL = Puntero
;
; 처리 중인 미라의 RAM 속성에 대한 포인터를 가져옵니다.
; HL = 포인터
;----------------------------------------------------

getMomiaAtrib:
		ld	a, (momiaEnProceso)
		ld	hl, enemyAttrib

getMomiaAtrib2:
		add	a, a
		add	a, a
		jp	ADD_A_HL

getYMomia:
		ld	a, 3		; Coordenada Y

;----------------------------------------------------
; Devuelve el valor A de la estructura de la momia actual
; In: A	= Valor	a leer
; Out: A = Valor leido
;
; 현재 미라 구조의 값 A를 반환합니다.
; 입력: A = 읽을 값
; 출력: A = 읽은 값
;----------------------------------------------------

getVariableMomia:
		ld	hl, (pMomiaProceso) ; Puntero a	los datos de la	momia en proceso
		call	ADD_A_HL
		ld	a, (hl)
		ret


;----------------------------------------------------
; La momia piensa que hacer
; Mira a los lados tantas veces	como vale TIMER
; In:
;    IX	= Datos	momia
;
; 미라는 무엇을 해야하는지 생각합니다.
; TIMER 가치만큼 옆을 봐
; 입력:
;    IX = 미라 데이터
;----------------------------------------------------

momiaPiensa:
		ld	a, (ix+ACTOR_TIMER) ; Veces que	duda
		or	a
		jr	z, momiaPiensa2	; Ya se	lo ha pensado

		cp	0E0h
		jr	z, momiaUnknown

		ld	(ix+ACTOR_FRAME), 2 ; Frame piernas separadas
		and	3
		ld	(ix+ACTOR_SENTIDO), a ;	Sentido	en el que mira

		ld	a, (timer)
		and	1Fh
		ret	nz		; Permanece 32 frames en esa postura

		dec	(ix+ACTOR_TIMER) ; Decrementa las veces	que mira a los lados
		ret	nz		; Aun tiene que	pensarselo un poco mas

momiaPiensa2:
		call	momiaDecide	; Toma una decision para acercarse al prota
		ld	(ix+ACTOR_STATUS), 0 ; Estado: andar
		ret

; (!?) Para que	sirve esto?

momiaUnknown:
		ld	a, (ix+ACTOR_CONTROL) ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		xor	1100b
		ld	(ix+ACTOR_CONTROL), a ;	Invierte el sentido de la momia
		rra
		rra
		and	3
		ld	(ix+ACTOR_SENTIDO), a ;	1 = Izquierda, 2 = Derecha

		call	getYMomia
		ld	bc, 0FCh	; X+15,Y+12
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
		ld	b, a		; (!?) Guarda el tile del mapa en B. Para que?
		and	0F0h		; Se queda con la familia o tipo de tile
		cp	10h
		jp	nz, tryToJump	; Salta	si no hay un muro/plataforma en	su parte inferior derecha

		call	getYMomia
		ld	bc, 10FCh	; X+16,	Y-4
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas
		ld	b, a		; (!?) Para que	lo guarda en B?
		and	0F0h
		cp	10h
		jp	nz, tryToJump	; salta	si no hay un muro/plataforma en	su parte superior derecha
		jp	momiaVanish

momiaDesaparece:
		ld	(ix+ACTOR_CONTROL), 8 ;	Anda a la derecha

		dec	(ix+ACTOR_TIMER) ; Decrementa el tiempo	de exploxion

		ld	a, (ix+ACTOR_TIMER)
		ld	b, a
		jr	z, quitaACTOR_	; Ha terminado el tiempo. La momia desaparece

		and	1Fh
		ret	nz		; No es	multiplo de #20

		ld	(ix+ACTOR_FRAME), 0Ah ;	Destello desaparece
		ret

quitaACTOR_:
		call	quitaMomia	; Quita	el sprite de la	pantalla y manda la momia al limbo (estado 4)
		ld	(ix+ACTOR_TIMER), 0FFh
		call	initMomia
		pop	hl
		jp	chkLastMomia	; Comprueba si faltan momias por procesar


;----------------------------------------------------
; Evita	que una	momia aparezca por un lateral cuando el	prota esta cerca
; Si una momia se encuentra cerca del lateral de una
; habitacion contigua, y el prota esta en el lateral adyacente
; se cambia el sentido de la momia para	que no aparezca	'por sorpresa'
; y sin	tiempo a reaccionar para poder esquivarla
;
; 주인공이 가까이 있을 때 옆에서 미라가 나타나는 것을 방지
; 옆방 옆에 미라가 있고 옆방에 주인공이 있을 경우 미라의 방향을 바꿔서 '놀라게' 나타나지 않게 하고 반응할 시간 없이 회피 가능
;----------------------------------------------------

evitaSorpresa:
		exx			; DE = Puntero estructura momia
		ld	hl, 6		; Offset a la variable 'room'
		add	hl, de
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		ld	b, (hl)		; B = Habitacion momia
		cp	(hl)		; Comprueba si la momia	esta en	la habitacion actual
		jr	z, evitaSorpresa6 ; si

		dec	hl
		ld	a, (hl)		; X momia
		ld	c, 50h
		cp	c
		jr	c, evitaSorpresa2 ; La X de la momia es	menor de #50

		ld	c, 0B0h
		cp	c
		jr	c, evitaSorpresa6 ; La X de la momia es	menor de #B0. No se encuentra cerca de los bordes laterales

		inc	b
		inc	b

evitaSorpresa2:
		dec	b
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	b		; Se encuentra en el lateral cercano a la habitacion en	la que esta el prota?
		jr	nz, evitaSorpresa6 ; No

		xor	a
		sub	c
		ld	c, a
		cp	50h
		ld	a, (ProtaX)
		jr	z, evitaSorpresa5

		cp	c
		jr	c, evitaSorpresa6

evitaSorpresa3:
		inc	hl
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	(hl)		; Habitacion de	la momia
		ld	a, 8		; Cambia el sentido hacia la derecha
		jr	c, evitaSorpresa4

		ld	a, 4		; Cambia el sentido hacia la izquierda

evitaSorpresa4:
		ld	h, d
		ld	l, e		; Puntero a la estructura de la	momia
		inc	hl
		ld	(hl), a		; Sentido en el	que anda la momia
		exx
		ret

evitaSorpresa5:
		cp	c
		jr	c, evitaSorpresa3

evitaSorpresa6:
		exx
		ret


;----------------------------------------------------
; La momia toma	una decision
; Busca	al prota y se mueve hacia el
;
; 미라는 결정을 내린다
; 주인공을 찾아 그에게로 이동
;----------------------------------------------------

momiaDecide:
		ld	a, 5
		ld	(ix+ACTOR_TIMER), a

		call	buscaCercanias	; Mira si hay escaleras	para subir o bajar en las cercanias (5 tiles a cada lado)
		call	buscaProta	; Comprueba la posicion	de la momia relativa al	prota
		and	a
		jr	z, momiaDecide2	; A la misma altura

		dec	a
		jr	z, setOrdenBajar ; La momia esta por encima

		dec	a
		jr	z, setOrdenSubir ; La momia esta por debajo

momiaDecide2:
		ld	a, (ProtaRoom)	; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
		cp	(ix+ACTOR_ROOM)
		jr	nz, momiaDecide3 ; estan en habitaciones distintas

		ld	a, (ProtaX)
		cp	(ix+ACTOR_X)	; Compara la X del prota con la	X de la	momia

momiaDecide3:
		ld	a, 8		; Control: Anda	a la DERECHA
		jr	nc, momiaDecide4 ; El prota esta a la derecha

		ld	a, 4		; Control: anda	a la IZQUIERDA

momiaDecide4:
		ld	(ix+ACTOR_CONTROL), a ;	Fija la	direccion que debe seguir la momia para	acercarse al prota

		ld	c, a
		ld	hl, ProtaY
		call	getMapOffset00	; Obtiene puntero a la posicion	del mapa del prota
		ex	de, hl
		call	getYMomia
		call	getMapOffset00	; Obtiene puntero a la posicion	del mapa de la momia


; Comprueba si entre la	momia y	el prota hay algun obstaculo
; De ser asi, intentara	subir o	bajar de donde se encuentra

		ld	b, 20h		; Ancho	de la habitacion

momiaDecide5:
		and	a
		push	hl		; Mapa momia
		sbc	hl, de
		pop	hl
		ret	z		; Ha llegado a la posicion del prota en	la busqueda

		ld	a, (hl)		; Tipo de tile
		and	0F0h		; Se queda con la familia
		cp	10h		; Es una plataforma o muro?
		jr	z, momiaDecide7	; Si

		dec	hl		; Tile de la izquierda del mapa
		bit	2, c		; Sentido en el	que se mueve la	momia
		jr	nz, momiaDecide6 ; Va a	la izquierda

		inc	hl
		inc	hl		; Tile de la derecha

momiaDecide6:
		djnz	momiaDecide5
		ret

momiaDecide7:
		ld	a, i		; Valor	aleatorio
		rra
		or	c		; Sentido en el	que se mueve la	momia
		rra
		call	c, setOrdenSubir

setOrdenBajar:
		ld	hl, ordenBajar
		ld	a, (hl)		; Se mueve hacia la escaleras mas lejanas (dentro del radio de busqueda) que bajan
		and	a

momiaSetControl:
		ret	z
		ld	(ix+ACTOR_CONTROL), a ;	1 = Arriba, 2 =	Abajo, 4 = Izquierda, 8	= Derecha
		ret

setOrdenSubir:
		ld	hl, ordenSubir
		ld	a, (hl)		; Controles para dirigirse a la	escalera mas lejana (dentro del	radio de busqueda) que sube
		and	a
		jr	momiaSetControl


;----------------------------------------------------
; Calcula la posicion relativa de la momia respecto al prota
; Out: A y B
;   0 =	Estan casi a la	misma altura
;   1 =	La momia esta por encima
;   2 =	La momia esta por debajo
;
; 주인공에 대한 미라의 상대적 위치 계산
; 출력: A와 B
;   0 = 거의 같은 높이에 있습니다.
;   1 = 미라가 위에 있음
;   2 = 미라가 아래에 있습니다.
;----------------------------------------------------

buscaProta:
		ld	b, 0
		ld	de, ProtaY
		call	getYMomia	; Obtiene la Y de la momia
		ld	a, (protaStatus) ; 0 = Normal
					; 1 = Salto
					; 2 = Cayendo
					; 3 = Escaleras
					; 4 = Lanzando un cuhillo
					; 5 = Picando
					; 6 = Pasando por un apuerta giratoria
		cp	3		; Escaleras?
		jr	z, buscaProta2

		ld	a, (de)		; Y del	prota
		sub	(hl)		; Le resta la Y	de la momia
		ld	c, a
		sub	10
		add	a, 18
		jr	c, buscaProta3	; Estan	casi a la misma	altura

buscaProta2:
		inc	b
		ld	a, (de)		; Y del	prota
		sub	(hl)		; Y de la momia
		jr	nc, buscaProta3	; La momia esta	por encima
		inc	b		; La momia esta	por debajo

buscaProta3:
		ld	a, b
		ld	(ix+ACTOR_POS_RELAT), a	; 0 = A	la misma altura	(o casi), 1 = Momia por	encima,	2 = Por	debajo
		ret


;----------------------------------------------------
; Busca	en las cercanias de la momia para ver si hay
; escaleras que	suben, bajan o un muro
; Dependiendo de lo que	encuentre guardara las ordenes de subir	o bajar
;
; 올라가는 계단, 내려가는 계단, 벽이 있는지 확인하기 위해 미라 주변을 검색합니다.
; 찾은 항목에 따라 올라가거나 내려가는 명령을 저장합니다.
;----------------------------------------------------

buscaCercanias:
		ld	b, 4
		ld	hl, ordenSubir

buscaCercanias2:
		ld	(hl), 0
		inc	hl
		djnz	buscaCercanias2	; Borra	ordenes	de subir o bajar anteriores

		push	ix		; Datos	momia
		pop	hl

		inc	hl
		ex	af, af'
		ld	a, (hl)		; Controles: Sentido en	el que va
		ex	af, af'

		inc	hl
		inc	hl
		push	hl		; Y
		call	buscaCercanias3	; Busca	primero	en el sentido actual
		pop	hl
		ex	af, af'
		xor	0Ch		; Invierte sentido para	buscar en el contrario al que va
		ex	af, af'

buscaCercanias3:
		call	getYMomia
		ld	bc, 8		; (!?) Con poner 'ld c,8' bastaria
		ld	b, c		; Punto	central	de la momia
		call	getMapOffset	; Obtiene en HL	la direccion del mapa que corresponde a	las coordenadas

		ex	af, af'
		dec	hl		; Tile a la izquierda de la momia
		bit	2, a		; Va a la izquierda?
		jr	nz, buscaCercanias4 ; Si, va a la izquierda

		inc	hl
		inc	hl		; Tile a la derecha de la momia

buscaCercanias4:
		ex	af, af'
		ld	b, 0		; contador de desplazamientos X	en la busqueda

buscaCercanias5:
		ex	af, af'
		dec	hl		; desplaza la busqueda un tile a la izquierda
		bit	2, a		; Va a la izquierda?
		jr	nz, buscaCercanias6 ; si, va a la izquierda

		inc	hl
		inc	hl		; desplaza la busqueda un tile a la derecha

buscaCercanias6:
		ex	af, af'
		ld	a, (hl)		; tile del mapa
		and	0F0h		; se queda con la familia o tipo de tile
		cp	10h		; es un	muro o plataforma?
		ret	z		; si

		cp	20h		; Es una escalera?
		jr	z, buscaCercanias7 ; Ha	encontrado una escalera

		cp	30h		; Es un	cuchillo?
		jr	nz, buscaCercanias8

		ld	a, (hl)
		cp	30h		; Es un	cuchillo clavado en el suelo?
		jr	z, buscaCercanias8

buscaCercanias7:
		ld	c, 1		; Orden	subir
		ld	de, distSubida
		call	guardaOrden

buscaCercanias8:
		push	hl
		ld	a, 60h		; Ancho	de las 3 habitaciones
		call	ADD_A_HL	; Apunta a la fila inferior (yTile+1)
		ld	a, (hl)		; lee el tile del mapa
		ld	c, a
		pop	hl
		and	0F0h		; Se queda con el tipo de tile
		jr	z, momiaBaja	; Esta vacio

		ld	a, c		; Tile del mapa
		and	0Fh
		cp	5		; Escaleras que	bajan?
		call	nc, momiaBaja	; Si, da orden de bajar

		inc	b
		ld	a, 5
		cp	b		; Ha buscado ya	5 posiciones en	una direccion?
		jr	nz, buscaCercanias5
		ret

momiaBaja:
		ld	c, 2		; Orden	bajar
		ld	de, distBajada

guardaOrden:
		ld	a, (de)
		cp	b
		ret	nc		; La orden existente tiene mas prioridad (va a las escaleras mas lejanas?)

		ld	a, b
		ld	(de), a		; Distancia a las escaleras
		dec	de
		ex	af, af'
		push	af
		and	0FCh		; Mantiene el sentido de la busqueda
		or	c		; A�ade	orden de subir o bajar
		ld	(de), a		; Guarda la orden
		pop	af
		ex	af, af'
		ret

;----------------------------------------------------
; Obtiene datos	de la momia en proceso
; Out:
; IX = Datos momia
; (pMomiaData) = Puntero datos momia
;
; 처리 중인 미라로부터 데이터 획득
; 출력:
; IX = 미라 데이터
; (pMomiaData) = 미라 데이터 포인터
;----------------------------------------------------

getMomiaProcDat:
		ld	hl, momiaEnProceso
		ld	a, (hl)

getMomiaDat:
		ld	b, a
		sla	b
		ld	a, b
		sla	b
		add	a, b
		sla	b
		sla	b
		add	a, b		; x22
		exx
		ld	hl, momiaDat	; Estructuras de las momias
		call	ADD_A_HL
		push	hl
		ld	(pMomiaProceso), hl ; Puntero a	los datos de la	momia en proceso
		pop	ix
		ex	de, hl
		exx
		ret


;----------------------------------------------------
;
; Actualiza las	coordenadas de un elemento segun su velocidad X
; In:
;  DE =	velocida. D = Parte entera, E =	Parte decimal
; Out:
;  A,D = Coordenada X
;  E = Decimales X
;
; 속도 X에 따라 요소의 좌표를 업데이트합니다.
; 입력:
;  DE = 속도. D = 정수 부분, E = 소수 부분
; 출력:
;  A,D = X 좌표
;  E = 소수 X
;----------------------------------------------------


mueveProta:
		ld	hl, ProtaXdecimal ; 'Decimales' usados en el calculo de la X. Asi se consiguen velocidades menores a 1 pixel
		ld	de, (protaSpeed) ; El byte bajo	indica la parte	"decimal" y el alto la entera

mueveElemento:
		push	ix
		push	hl
		push	hl
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		pop	ix
		ld	b, (ix+2)	; Habitacion
		ld	c, (ix+5)	; Desplazamiento habitacion
		ld	a, (ix-2)	; Sentido del movimiento
		rra
		jr	nc, mueveElemento2 ; Va	hacia la derecha
		ld	a, c
		cpl
		ld	c, a
		ld	a, d
		cpl
		ld	d, a
		ld	a, e
		cpl
		ld	e, a
		inc	de

mueveElemento2:
		add	hl, de		; Suma desplazamiento
		ld	a, b		; Habitacion actual
		adc	a, c		; Suma desplazamiento X	alto, por si ha	cambiado de habitacion
		ld	b, a
		ld	a, (ix+1)	; Coordenada X
		ex	de, hl
		pop	hl
		ld	(hl), e		; X decimales
		inc	hl
		ld	(hl), d		; X
		ld	(ix+2),	b	; Room
		pop	ix
		ret


;----------------------------------------------------
; Comprueba si puede realizar un salto mirando si hay
; techo	sobre el elemento, si el salto es solamente vertical
; Si es	con desplazamiento, comprueba si tienen	un muro	delante
; (y si	el techo es mazizo?)
; Out:
;   NC = No puede saltar
;
; 점프가 수직 인 경우에만 요소 위에 천장이 있는지 확인하여 점프를 수행 할 수 있는지 확인합니다.
; 스크롤하는 경우 앞에 벽이 있는지 확인하십시오.
; (그리고 지붕이 단단한 경우?)
; 출력:
;   NC = 점프할 수 없음
;----------------------------------------------------

chkSaltar:
		push	hl
		dec	hl
		dec	hl
		ld	a, (hl)		; Controles del	elemento
		pop	hl
		cp	10h		; Salto	vertical sin desplazamiento lateral?
		jr	z, chkChocaTecho ; Si, solo comprueba que no tenga techo sobre la cabeza

;---------------------------------------
; El salto es con desplazamiento lateral
; Comprueba si tiene un	muro delante
;
; 점프는 측면 이동입니다
; 앞에 벽이 있는지 확인
;---------------------------------------
		call	chkChocaTecho
		ret	nc		; Ha chocado

		dec	hl
		ld	a, (hl)		; Sentido
						; 방향
		inc	hl
		ld	bc, 304h	; Offset para la parte superior	izquierda
		rr	a
		jr	c, chkIncrustUp	; Izquierda
							; 왼쪽

		ld	b, 0Ch		; Offset X parte derecha

chkIncrustUp:
		push	bc
		call	chkTocaMuro	; Z = choca
		pop	bc		; Recupera offset coordendas de	choque
		jr	z, chkTechoMazizo ; Ha chocado

		call	chkTocaY_8	; Decrementa en	8 el offset Y y	comprueba si choca
		ret	z

		scf
		ret

chkTechoMazizo:
		call	chkTocaY_8	; Decrementa en	8 el offset Y y	comprueba si choca
		ret	z		; Choca

		call	chkTocaY_8	; Decrementa en	8 el offset Y y	comprueba si choca
		ret	z		; Choca

		ld	b, 8		; Parte	central	X del elemento
		call	chkTocaMuro	; Z = choca
		ret	z		; Choca

		scf			; No choca
		ret

;----------------------------------------------------
; Comprueba si choca mientras salta
; Out: Carry = No choca
;
; 점프 중 충돌 여부 확인
; 출력: 캐리 = 충돌하지 않음
;----------------------------------------------------

chkChocaTecho:
		ld	bc, 4FEh
		call	chkTocaMuro	; Z = choca
		ret	z

		ld	bc, 0AFEh
		call	chkTocaMuro	; Z = choca
		ret	z

		scf			; No choca
		ret

chkTocaY_8:
		ld	a, c		; Decrementa en	8 el offset Y y	comprueba si choca
		sub	8
		ld	c, a
		push	bc
		call	chkTocaMuro	; Z = choca
		pop	bc
		ret


;----------------------------------------------------
; Comprueba si choca con algo mientras salta, ya sea mientras
; sube o mientras cae
; Out:
;   Z =	Ha chocado con algo al saltar. Termina el salto
;
; 점프 중, 상승 중 또는 낙하 중 무언가에 부딪히는지 확인하십시오.
; 출력:
;   Z = 점프하는 동안 무언가와 충돌했습니다. 점프를 끝내다
;----------------------------------------------------

chkChocaSalto:
		inc	hl
		ld	a, (sentidoEscalera) ; Valor de	los controles en el momento del	salto. As� se sabe si fue un salto vertical
		cp	10h		; Boton	A apretado? (Hold jump)
chkChocaSalto1:
		inc	hl
		ld	d, (hl)		; Sentido
						; 방향
		inc	hl
		jr	z, chkChocaCae	; Esta apretado.

		ld	a, (ix+ACTOR_X)
		and	7
		cp	4		; Esta en medio	de un tile?
		jr	nz, chkChocaCae	; No

;------------------------------
; Comprueba si choca por arriba
; 위에서 충돌하는지 확인하십시오.
;------------------------------
		ld	a, d		; Sentido
						; 방향
		rra
		ld	bc, 300h	; Offset superior izquierdo
		jr	c, chkChocaSalto2 ; Va a la izquierda
		ld	b, 0Ch		; Offset derecho

chkChocaSalto2:
		push	de
		call	chkTocaMuro	; Z = choca
		pop	de
		jr	z, ajustaPasillo ; Comprueba si	se ha encajado en un pasillo (muro por arriba y	por abajo)

;----------------------------------------
; Comprueba si choca con la parte central
; 중앙부와 충돌 여부 확인
;----------------------------------------

chkChocaSalto3:
		ld	a, d		; Sentido
						; 방향
		ld	bc, 308h	; Offset central izquierdo
		rra
		jr	c, chkChocaSalto4 ; Va a la izquierda
		ld	b, 0Ch		; Offset derecho

chkChocaSalto4:
		push	de
		call	chkTocaMuro	; Conca	con la parte central?
		pop	de
		jr	z, setFinSalto	; Si, termina el salto

;------------------------------------------
; Comprueba si choca con la parte de abajo
; 바닥과 충돌하는지 확인
;------------------------------------------

		ld	a, d		; Sentido
						; 방향
		rra
		ld	bc, 30Eh	; Offset inferior izquierdo
		jr	c, chkChocaSalto5 ; Va a la izquierda
		ld	b, 0Ch		; Derecho

chkChocaSalto5:
		call	chkTocaMuro	; Z = choca
		jr	z, setFinSalto	; Si, termina el salto

chkChocaCae:
		ld	a, (ix+ACTOR_JUMPSENT) ; 0 = Subiendo, 1 = Cayendo
		and	a		; Esta subiendo	o cayendo?
		jr	z, setNZ	; Subiendo

		call	chkChocaSuelo	; Comprueba si choca con el suelo mientras cae
		jp	c, chkLlegaSuelo ; No ha chocado

setFinSalto:
		ld	a, (hl)		; Y
		and	0F8h
		ld	(hl), a		; Ajusta la coordenada Y a multiplo de 8 descartando los valores menores de 8

		xor	a
		and	a		; Set Z, fin del salto
		ret

; Comprueba si ha llegado al nivel del suelo

chkLlegaSuelo:
		call	chkPisaSuelo
		jr	z, setFinSalto	; Si, esta en el suelo

setNZ:
		xor	a
		cp	1		; Set NZ
		ret

;----------------------------------------------------
; Se llama a esta funcion si al	saltar ha chocado con algo por la parte	superior
; Comprueba si bajo los	pies hay suelo y ajusta	la Y en	ese caso
; 점프가 위에서 무엇인가와 충돌하면 이 함수가 호출됩니다.
; 발 밑에 그라운드가 있는지 확인하고 그 경우 Y를 조정하십시오.
;----------------------------------------------------

ajustaPasillo:
		ld	a, d		; Sentido
						; 방향
		ld	bc, 314h	; Offset medio tile por	debajo del elemento (izquierda)
		rra
		jr	c, ajustaPasillo2
		ld	b, 0Ch		; Derecha
						; 오른쪽

ajustaPasillo2:
		push	de
		call	chkTocaMuro	; Z = choca
		pop	de
		jr	z, setFinSalto	; Y

		jr	chkChocaSalto3


;----------------------------------------------------
; Salto
; Si se	esta ejecutando	el ending, los valores del salto se multiplican	x4
; Dependiendo de la direccion que este pulsada,	salta a	la derecha o a la izquierda
; Recorre la tabla de desplazamientos hasta llegar al final. Entonces
; indica que hay que recorrerla	al reves para caer de la misma forma que se subio
; Si llega al final nuevamente (inicio), cae a velocidad maxima	y continua asi
;
; 도약
; 엔딩이 달리고 있다면 점프값이 4배가 된다
; 누르는 방향에 따라 오른쪽이나 왼쪽으로 점프
; 끝에 도달할 때까지 변위 테이블을 통해 이동합니다. 그런 다음 그것은 당신이 오른 것과 같은 방식으로 떨어지기 위해 그것을 거꾸로 통과해야 함을 나타냅니다.
; 다시 끝(시작)에 도달하면 최대 속도로 떨어지고 이렇게 계속
;----------------------------------------------------

doSalto:
		ld	a, (GameStatus)
		cp	0Ah		; Status = Final del juego (ending)?
		jr	z, doSalto2	; Si, esta en el final del juego

		xor	a		; No esta en el	final del juego.
		ld	(waitCounter), a ; Lo pone a cero para no multiplicar los calores del salto x4

doSalto2:
		push	hl
		push	hl
		ld	a, 0Ah
		call	ADD_A_HL
		ld	e, (hl)
		inc	hl
		ld	d, (hl)		; DE = Puntero a los desplazamientos del salto
		inc	hl
		ld	b, (hl)		; Sentido del salto: Subiendo o	bajando?
		pop	hl
		pop	ix
		dec	hl

		ld	a, (hl)		; Teclas pulsadas
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		and	0Ch		; Se queda solo	con derecha e izquierda
		jr	z, doSalto3

		dec	(hl)		; Decrementa la	X
		bit	2, a		; Izquierda = 4
		jr	nz, doSalto3

		inc	(hl)		; Derecha = 8
		inc	(hl)		; Incrementa la	X

doSalto3:
		ld	a, (de)		; Desplazamiento Y del salto
		inc	a		; Ha llegado al	final de la tabla?
		jr	z, saltoCaeMax	; Si, cae a la maxima velocidad

		dec	a		; Restaura el valor de desplazamiento
		ld	c, a		; Lo guarda en C

		ld	a, (waitCounter)
		dec	a
		dec	a
		ld	a, c
		jr	nz, chkSaltoSubBaj ; Salta si waitCounter no es	2

		add	a, a
		add	a, a		; Multiplica el	desplazamiento x4

chkSaltoSubBaj:
		dec	b
		inc	b		; Sube o cae?
		jr	nz, saltoUpdate	; Sube
		neg			; Cae, asi que pasa el valor a negativo

saltoUpdate:
		call	saltoUpdateY	; Actualiza la coordenada Y del	elemento que esta saltando
		inc	de		; Siguiente posicion de	la lista de desplazamientos

		ld	a, b		; Sentido del salto
		and	a		; Sube o cae?
		jr	z, saltoUpdate3	; Sube

		dec	de		; Recorre la lista hacia atras

saltoUpdate2:
		dec	de

saltoUpdate3:
		ld	(ix+0Ah), e
		ld	(ix+0Bh), d	; Guarda puntero a los desplazamientos del salto
		ld	a, (de)
		cp	0FEh		; Ha llegado al	final de la tabla? (Punto mas alto del salto)
		ret	nz		; No

		ld	(ix+0Ch), 1	; Cambia el sentido del	salto. Comienza	a caer
					; Para ello recorre la misma lista hacia atras
		jr	saltoUpdate2	; Decrementa el	puntero	para dejarlo en	un valor valido

saltoCaeMax:
		ld	a, 4

saltoUpdateY:
		dec	hl
		dec	hl
		add	a, (hl)
		ld	(hl), a
		ret

;----------------------------------------------------
; Desplazamientos aplicados a la Y del elemento	cuando salta
;
; 점프할 때 요소의 Y에 적용된 오프셋
;----------------------------------------------------
		db 0FFh			; Fin del salto. Cae a maxima velocidad
valoresSalto:	db 4
		db    2
		db    2
		db    2
		db    1
		db    1
		db    2
		db    0
		db    1
		db    1
		db    0
		db    0
		db -2			; Final	de la tabla. Comienza la caida

;----------------------------------------------------
; Pone estado de cayendo
; Actualiza coordenada Y debido	a la caida y comprueba si choca	contra el suelo
; Out:
;   C =	Cae
;  NC =	Esta sobre suelo
;
; 떨어지는 상태를 둔다
; 추락으로 인한 Y좌표 업데이트 및 지면에 닿는지 확인
; 출력:
;   C = 추락
;  NC = 지상에 있다
;----------------------------------------------------

cayendo:
		ld	(hl), 2		; Estado de cayendo
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; Y
		and	0FCh
		ld	(hl), a		; Ajusta la Y a	multiplo de 4

		push	hl
		call	chkCae
		pop	hl
		ret	nc		; Esta pisando algo

		ld	a, (hl)		; Y
		add	a, 4		; Incrementa la	Y en 4
		and	0FCh
		ld	(hl), a		; Ajusta la Y a	multiplo de 4

		xor	a
		sub	1		; Set Carry
		ret


;----------------------------------------------------
; Mueve	a un personaje por las escaleras
; Out:
;    Z = Ha llegado al final de	las escaleras
;
; 캐릭터를 계단 위로 이동
; 출력:
;    Z = 계단 바닥에 도달했습니다.
;----------------------------------------------------

andaEscalera:
		ld	a, (timer)
		and	b		; Mascara para ralentizar la velocidad en las escaleras
		ret	nz

		inc	hl
		ld	c, (hl)		; Sentido
						; 방향
		inc	hl
		inc	hl
		inc	hl
		ld	a, (hl)		; X
		dec	hl
		dec	hl		; Apunta a la Y
		and	3
		jr	nz, andaEscalera2 ; La X no es multiplo	de 4

		push	hl		; Apunta a la Y
		call	chkFinEscalera	; Comprueba si llega al	final de la escalera
		pop	hl
		ret	z		; Si, ha llegado al final

andaEscalera2:
		ld	a, c		; Sentido
						; 방향
		inc	hl
		inc	hl
		inc	(hl)		; Incrementa la	X
		rra
		jr	nc, andaEscalera3 ; Va a la derecha
		dec	(hl)
		dec	(hl)		; Decrementa la	X. Va a	la izquierda

andaEscalera3:
		push	hl
		ld	a, 0Ah
		call	ADD_A_HL	; Apunta al sentido de las escaleras (+#0f)
		ld	a, (hl)
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		inc	(hl)		; Contador de movimiento
		pop	hl		; Apunta a la X

		add	a, c		; Sentido escalera + sentido movimiento
		ld	b, 1		; Baja
		bit	0, a
		jr	z, andaEscalera4
		ld	b, -1		; Sube

andaEscalera4:
		dec	hl
		dec	hl		; Apunta a la Y
		ld	a, (hl)		; Y
		add	a, b		; Suma desplazamineto vertical
		ld	(hl), a		; Actualiza la coordenada Y dependiendo	del sentido de la escalera y hacia donde se mueve

		xor	a
		cp	1		; Set NZ
		ret


;----------------------------------------------------
; Muestra el final del juego
; 게임의 끝을 보여주세요
;----------------------------------------------------

ShowEnding:
		push	bc
		call	updateSprites
		pop	bc
		djnz	showEnding2

		ld	hl, protaEndingDat ; Datos preparados para el ending (el prota sale de la piramide, anda a la izquierda	y salta)
		ld	de, protaStatus	; Destino: estructura del prota
		ld	bc, 0Ch		; Numero de datos a copiar
		ldir

		call	setAttribProta	; Actualiza atributos de los sprites del prota
		ld	hl, controlsEnding ; Izquierda,	Izquierda+Salto
		ld	(keyPressDemo),	hl ; Puntero a los controles grabados
		ld	a, 88h
		ld	(KeyHoldCntDemo), a

nextSubStatus_:
		jp	NextSubStatus


controlsEnding:	db 4, 1Bh
		db 14h,	0FFh		; Izquierda, Izquierda+Salto

;----------------------------------------------------
; Anda hasta el	centro de la pantalla y	salta
; 화면 중앙으로 이동하여 점프
;----------------------------------------------------

showEnding2:
		djnz	showEnding3
		call	ReplaySavedMov	; Reproduce movimientos	grabados del ending (andar izquierda y saltar)
		call	AI_Prota	; Mueve	y anima	al prota
		ld	a, (flagVivo)
		and	a
		ret	nz		; Se ha	terminado la demo

		call	setProtaSalta_	; Salta

		ld	hl, sentidoProta ; 1 = Izquierda, 2 = Derecha
		ld	(hl), a		; (!?) A = #3F No parece que tenga un valor puesto a proposito
		dec	a		; #3E?
		dec	hl
		ld	(hl), a		; ProntaControl
		ld	a, 2
		ld	(waitCounter), a
		jr	nextSubStatus_

;----------------------------------------------------
; Espera a que termine el salto
; 점프가 끝날 때까지 기다리십시오.
;----------------------------------------------------

showEnding3:
		djnz	showSpecialBonus
		call	AI_Prota	; Mueve	y anima	al prota
		ld	a, (flagSalto)	; 0 = Saltando,	1 = En el suelo
		or	a
		ret	z		; Aun no ha terminado el salto
		jr	nextSubStatus_

;----------------------------------------------------
; Muestra texto	de CONGRATULATIONS, SPECIAL BONUS y suma 10.000	puntos
; 축하 텍스트, 특별 보너스 표시 및 10,000포인트 추가
;----------------------------------------------------

showSpecialBonus:
		djnz	waitEnding
		call	VidaExtra	; Suma una vida	extra
		call	specialBonus	; Muestra texto	de CONGARTULATIONS, SPECIAL BONUS y suma 10.000	puntos
		ld	a, 0D0h
		ld	(waitCounter), a
		jr	nextSubStatus_

;----------------------------------------------------
; Espera un rato mientras esta el texto	en pantalla
; Pasa a estado	"Stage clear"
; 텍스트가 화면에 표시되는 동안 잠시 기다리십시오.
; "스테이지 클리어" 상태로 전환
;----------------------------------------------------

waitEnding:
		djnz	setupEnding
		ld	hl, waitCounter
		dec	(hl)
		ret	nz

		ld	a, 8		; status: Stage	clear
		ld	(GameStatus), a
		ret

;----------------------------------------------------
; Prepara todo para mostrar el final
; - Oculta los sprites y muestra la cortinilla
; - Carga los sprites del porta	con el pico
; - Pone la musica del juego
; - Borra todo el mapa RAM
;
; 끝을 보여주기 위해 모든 것을 준비
; - 스프라이트를 숨기고 와이프 표시
; - 곡괭이로 캐리어 스프라이트를 로드하세요.
; - 게임의 음악을 넣어
; - 모든 RAM 맵 지우기
;----------------------------------------------------

setupEnding:
		call	hideSprAttrib	; Oculta los sprites
		call	drawCortinilla	; Dibuja la cortinilla
		ret	p		; No ha	terminado con la cortinilla

		ld	a, 20h
		call	cogeObjeto	; Hace que el prota lleve el pico

		ld	a, 8Bh		; Ingame music
		call	setMusic

		call	BorraMapaRAM
		ld	hl, MapaRAMRoot	; La primera fila del mapa no se usa (ocupada por el marcador).	Tambien	usado como inicio de la	pila
		ld	de,  MapaRAMRoot+1 ; La	primera	fila del mapa no se usa	(ocupada por el	marcador). Tambien usado como inicio de	la pila
		ld	bc, 720h
		ld	(hl), 0		; Tile vacio
		ldir

		ld	hl, 2480h	; VRAM address pattern generator table = Pattern #90
		ld	de, endingTiles
		call	UnpackPatterns

		ld	hl, 480h	; VRAM address color table = pattern #90
		ld	de, endingColors
		call	UnpackPatterns

		ld	hl, 391Fh	; VRAM address name table = Posicion pico piramide grande derecha
		ld	c, 90h
		xor	a
		call	drawHalfPiram

		ld	hl, 3A03h	; VRAM address name table = Posicion vertice izquierdo piramide	mediana	izquierda
		ld	c, 92h
		call	drawHalfPiram

		ld	hl, 3A2Bh	; VRAM address name table = Posicion vert. izq.	piramide peque�a central
		call	drawHalfPiram

		ld	hl, 3A04h	; VRAM address name table = Posicion vertice superior lado derecho piramide mediana izquierda
		ld	c, 94h
		inc	a		; Lado derecho de las piramides
		call	drawHalfPiram

		ld	hl, 3A2Ch	; VRAM address name table = Posicion vertice superior lado derecho piramide peque�a central
		call	drawHalfPiram

		ld	de, tilesEndDoor ; Patrones que	forman la puerta de la piramide	grande
		ld	bc, 302h	; Alto = 3 tiles, ancho	= 2 tiles
		ld	hl, 3A1Eh	; VRAM address name table = Posicion de	la puerta
		call	DEtoVRAM_NXNY	; Dibuja la puerta en pantalla

		ld	a, 96h		; Patron suelo de arena
		ld	hl, 3A60h	; VRAM address name table = Suelo
		ld	bc, 20h		; Ancho	de la pantalla
		call	setFillVRAM	; Dibuja el suelo
		call	renderMarcador

		ld	de, starsLocations
		ld	b, 6		; Numero de estrellas en el cielo

drawStars:
		ld	a, (de)		; Byte bajo de la direccion VRAM tabla de nombres (semicoordenada) de la estrella
		ld	l, a
		ld	h, 39h		; Byte alto de la direccion VRAM de la tabla de	nombres
		ld	a, 97h		; Patron estrella
		call	WRTVRM		; Dibuja la estrella
		inc	de		; Siguiente estrella
		djnz	drawStars

nextSubstatus2:
		ld	hl, subStatus
		inc	(hl)
		ret

;----------------------------------------------------
; Dibuja media piramide	(triangulo rectangulo)
; Pinta	la piramide desde la altura del	vertice	hasta que llega	al suelo, incrementando	el ancho en cada linea
; In:
;  HL =	VRAM address name table
;   C =	Patron diagonal	piramide / o \.	(C+1)= Patron relleno
;   A =	Lado de	la piramide que	pinta (0 = izquierdo, 1	= derecho)
;
; 반 피라미드(직각 삼각형)를 그립니다.
; 정점의 높이에서 지면에 도달할 때까지 피라미드를 페인트하여 각 선의 너비를 늘립니다.
; 입력:
;  HL = VRAM 주소 이름 테이블
;   C = 대각선 피라미드 패턴 / 또는 \. (C+1)= 채워진 패턴
;   A = 페인트하는 피라미드의 측면(0 = 왼쪽, 1 = 오른쪽)
;----------------------------------------------------

drawHalfPiram:
		ld	b, 0		; Contador del ancho de	la fila	actual de la piramide

chkVertice:
		push	hl		; Guarda direccion VRAM	del eje	de la piramide
		push	bc		; Guarda el ancho de la	linea actual de	la piramide
		dec	b
		inc	b		; Es cero el ancho? (Es	el vertice superior?)
		jr	z, drawVertice	; Coloca el vertice de la piramide

drawRelleno:
		ex	af, af'         ; Guarda la direccion de pintado
		ld	a, c		; Tile de arista / o \
		inc	a		; Lo pasa a tile de relleno
		call	WRTVRM		; Tile de relleno de la	piramide
		ex	af, af'         ; Recupera la direccion de pintado
		dec	hl		; Se mueve un patron a la izquierda
		and	a		; Lado de la piramide que tiene	que pintar?
		jr	z, drawRelleno2

		inc	hl
		inc	hl		; Se mueve un patron a la derecha

drawRelleno2:
		djnz	drawRelleno	; Aun faltan patrones por pintar de la fila actual de la piramide

drawVertice:
		pop	bc		; Recupera el ancho actual de la fila de la piramide
		inc	b		; Incrementa contador del ancho	de la piramide
		ex	af, af'         ; Guarda la direccion de pintado indicada en A
		ld	a, c		; Vertice de la	piramide / patron diagonal
		call	WRTVRM		; Dibuja el patron en pantalla
		ex	af, af'         ; Recupera la direccion de pintado

		pop	hl		; Recupera la direccion	VRAM del eje central de	la piramide
		ld	de, 20h		; Distancia al tile inferior
		add	hl, de		; Coloca puntero VRAM un tile mas abajo
		push	hl		; Guarda direccion VRAM	del eje	central
		and	a
		ld	de, 3A80h	; VRAM address name table por debajo de	la linea del suelo
		sbc	hl, de		; Comprueba si ya se ha	pintado	la piramide hasta el suelo
		pop	hl
		jr	c, chkVertice	; Continua pintando otra fila de la piramide

		ret


;----------------------------------------------------
; Tiles	usados para dibujar el escenario final
; Tiles:
;   - Lateral dcho. ladrillo, relleno ladrillo (piramide cercana)
;   - Lateral dcho. arenisca, relleno arenisca (piramide lejana)
;   - Lateral izdo. arenisca oscura, relleno arenisca oscura
;   - Arena del	suelo
;   - Estrella del cielo
;
; 최종 단계를 그리는 데 사용되는 타일
; 타일:
; - 오른쪽. 벽돌, 벽돌 채우기(근처 피라미드)
; - 오른쪽. 사암, 사암 채우기(먼 피라미드)
; - 왼쪽. 어두운 사암, 어두운 사암 채우기
; - 땅 모래
; - 스카이 스타
;----------------------------------------------------
endingTiles:	db 88h,	0, 2, 6, 0, 0Fh, 2Fh, 6Fh, 0, 3, 0FEh, 81h, 0
		db 3, 0EFh, 88h, 0, 1, 3, 7, 0Fh, 1Fh, 3Fh, 7Fh, 9, 0FFh
		db 87h,	80h, 0C0h, 0E0h, 0F0h, 0F8h, 0FCh, 0FEh, 9, 0FFh
		db 87h,	55h, 0AAh, 55h,	0AAh, 66h, 99h,	66h, 8,	0, 81h
		db 0C0h, 0

;----------------------------------------------------
; Tabla	de colores de los tiles	de fondo anteriores
; 이전 배경 타일의 색상 표
;----------------------------------------------------
endingColors:	db 88h,	60h, 60h, 0A0h,	0A0h, 60h, 60h,	0A0h, 0A0h, 2
		db 60h,	2, 0A0h, 2, 60h, 2, 0A0h, 10h, 80h, 10h, 60h, 4
		db 8Ah,	4, 6Ah,	8, 50h,	0


;----------------------------------------------------
; Patrones que forman la puerta	de la piramide del final del juego
; 게임 종료 시 피라미드의 문을 형성하는 패턴
;----------------------------------------------------
tilesEndDoor:	db 63h,	64h, 0,	65h, 66h, 67h

;----------------------------------------------------
; Bytes	bajos de la direccion VRAM de la tabla de nombres donde	se pintan las estrellas
; El byte alto es fijo = #39
; 별이 그려진 이름 테이블의 VRAM 주소의 낮은 바이트
; 상위 바이트 고정 = #39
;----------------------------------------------------
starsLocations:	db 9, 16h, 38h,	67h, 74h, 8Eh, 0A9h


;----------------------------------------------------
; Datos	del prota para el ending
; Status, Control, sentido, Y, decimales, X, habitacion, speed decimales, speed	X, Speed room, movCnt, frame
; Andar, izquierda, izquierda, Y=#88, 0, X=#F0,	0, spd=#C0
; 엔딩의 주인공 데이터
; 상태, 제어, 방향, Y, 소수, X, 방, 속도 소수, 속도 X, 속도 방, movCnt, 프레임
; 걷기, 왼쪽, 왼쪽, Y=#88, 0, X=#F0, 0, spd=#C0
;----------------------------------------------------
protaEndingDat:	db 0, 4, 1, 88h, 0, 0F0h, 0, 0C0h, 0, 0, 0, 0


;----------------------------------------------------
; Setup	pergamino
; 양피지 설정
;----------------------------------------------------

setupPergamino:
		call	hideSprAttrib
		ld	de, gfxMap	; Patrones del pergamino con el	mapa de	piramides
		ld	hl, 2600h	; VRAM address pattern #C0
		call	UnpackPatterns	; Descomprime los patrones en VRAM

		ld	de, colorTableMap ; Tabla de color de los patrones del mapa
		ld	hl, 600h	; VRAM address color table pattern #C0
		call	UnpackPatterns	; Descomprime tabla de colores

		ld	de, gfxSprMapa	; Sprites usados en el mapa (silueta piramide y	flechas)
		call	unpackGFXset	; Descomprime sprites

		xor	a
		ld	(statusEntrada), a
		ld	(timerPergam2),	a ; Se usa para	hacer una pausa	tras terminar de sonar la musica del pergamino al llegar al GOAL

		ld	a, 91h		; Musica pergamino
		call	setMusic

		ld	a, (piramideActual)
		call	setPiramidMap	; Coloca la silueta para resaltar la piramide actual

		ld	a, (puertaSalida) ; Direccion de la salida de la piramide
		ld	de, numSprFlechas ; Numero de sprites de las flechas

setFlechaMap:
		push	de
		srl	a
		cp	4
		jr	nz, setFlechaMap2
		dec	a		; Convierte valores 1,2,4,8 en 0,1,2,3

setFlechaMap2:
		push	af
		add	a, a
		ld	hl, offsetFlechas
		call	ADD_A_HL
		ld	de, attrPiramidMap ; Atributos del sprite usado	para resaltar una piramide en el mapa (silueta)
		ld	bc, attrFlechaMap ; Atributos de la flecha del mapa
		ld	a, (de)		; Y de la piramide
		add	a, (hl)		; Le suma el desplazamiento que	le corresponde a la flecha
		ld	(bc), a		; Y de la flecha
		inc	hl
		inc	de
		inc	bc
		ld	a, (de)		; X de la piramide
		add	a, (hl)		; Le suma el desplazamiento
		ld	(bc), a		; X de la flecha
		inc	bc
		pop	af		; Recupera la direccion	de la flecha
		pop	de		; Puntero al numero de sprite que corresponde cada direccion
		call	ADD_A_DE
		ld	a, (de)		; Sprite que corresponde a la direccion	de salida
		ld	(bc), a		; Sprite de la flecha
		ret

;----------------------------------------------------
;
; Coloca la flecha en la casilla "GOAL" del mapa
;
; 지도의 "목표" 상자에 화살표를 놓습니다.
;
;----------------------------------------------------

setFlechaGoal:
		ld	hl, attrPiramidMap ; Atributos del sprite usado	para resaltar una piramide en el mapa (silueta)
		push	hl
		ld	(hl), 97h
		inc	hl
		ld	(hl), 7Bh
		ld	a, 1		; Flecha por arriba
		call	setFlechaInvert
		pop	hl
		ld	(hl), 0C3h
		ret

;----------------------------------------------------
;
; Actualiza las	coordenadas y los sprites del mapa de piramides
; Sprites: flecha y silueta de piramide
;
; 피라미드 맵의 좌표와 스프라이트 업데이트
; 스프라이트: 화살표와 피라미드 실루엣
;
;----------------------------------------------------

setDestinoMap:
		ld	a, (piramideDest)
		call	setPiramidMap
		ld	a, (puertaEntrada)

setFlechaInvert:
		ld	de, numSprFlechInv
		jr	setFlechaMap

;----------------------------------------------------
;
; Logica del mapa de piramides
;
; 피라미드 지도 논리
;
;----------------------------------------------------

tickPergamino:
		ld	a, (timer)
		and	7		; 8 colores de animacion
		ld	hl, coloresFlecha ; Colores usados para	resaltar la flecha y piramide en el mapa
		call	ADD_A_HL
		ld	a, (hl)
		ld	(colorPiramidMap), a ; Color del outline de la piramide	en el mapa
		ld	(colorFlechaMap), a ; Color de la flecha que indica a que piramide vamos en el mapa
		call	updateSprites

		call	chkPause	; Comprueba si se pulsa	F1 en el mapa

		ld	hl, piramideActual
		ld	a, (hl)
		inc	hl
		sub	(hl)
		ld	hl, statusEntrada
		inc	(hl)
		cp	0Eh		; Ultima piramide?
		ld	a, (hl)
		jr	z, setEndingStat

		cp	58h		; Ciclos que muestra la	flecha de salida
		jr	z, setDestinoMap

		cp	0E0h		; Ciclos que muestra la	flecha de entrada
		ret	nz

		inc	a
		ld	(flagEndPergamino), a ;	1 = Ha terminado de mostar el pergamino/mapa
		ret

setEndingStat:
		cp	58h		; Hay que cambiar la posicion de la flecha al destino?
		jr	z, setFlechaGoal ; Coloca la flecha sobre GOAL

		ld	a, (MusicChanData)
		or	a
		ret	nz		; Aun suena musica

		ld	hl, timerPergam2 ; Se usa para hacer una pausa tras terminar de	sonar la musica	del pergamino al llegar	al GOAL
		ld	a, (hl)
		inc	(hl)
		cp	80h
		ret	nz		; Hace una pausa al terminar de	sonar la musica

		ld	hl, numFinishGame ; Numero de veces que	se ha terminado	el juego
		inc	(hl)		; Incrementa el	numero de veces	que se ha terminado el juego

		xor	a
		inc	hl
		ld	(hl), a
		ld	d, h
		ld	e, l
		inc	de
		ld	bc, 0Ah
		ld	a, c		; A = Status #A
		ldir			; Borra	10 bytes de variables desde numFinishedGame

		call	setGameStatus	; Pone status #A = Ending
		jp	ResetSubStatus	; (!?) Ya lo hace en la	anterior llamada

;----------------------------------------------------
; Muestra texto	de "CONGRATULATIONS" "SPECIAL BONUS"
; Y suma 10.000	puntos
; "축하합니다" "특별 보너스" 텍스트 표시
; 그리고 10,000포인트 추가
;----------------------------------------------------

specialBonus:
	IF	(VERSION2)
		ld	de, TXT_ENDING
		call	unpackGFXset
		ld	de, 5000h
		push	de
		call	SumaPuntos
		pop	de
		jp	SumaPuntos
	ELSE
		ld	de, TXT_ENDING
		call	unpackGFXset
		ld	de, 5000h
		call	SumaPuntos
		ld	de, 5000h
		jp	SumaPuntos
	ENDIF

;----------------------------------------------------
; Pone las coordenadas de la silueta de	la piramide actual
; 현재 피라미드의 실루엣 좌표를 넣어
;----------------------------------------------------

setPiramidMap:
		dec	a
		add	a, a
		ld	hl, coordPiramMap
		call	ADD_A_HL
		ld	de, attrPiramidMap ; Atributos del sprite usado	para resaltar una piramide en el mapa (silueta)
		ldi			; Y
		ldi			; X
		ex	de, hl
		ld	(hl), 0E4h	; Sprite de la silueta de la piramide
		ret

;----------------------------------------------------
; Graficos del pergamino con el	mapa de	piramides
; 피라미드 지도가 있는 양피지 그래픽
;----------------------------------------------------
gfxMap:		db 0A0h, 1, 3, 7, 0Fh, 1Fh, 3Fh, 0Fh, 3, 80h, 0C0h, 0E0h
		db 0F0h, 0F8h, 0FCh, 0F0h, 0C0h, 1, 3, 7, 0Fh, 1Fh, 3Fh
		db 0Fh,	3, 80h,	0C0h, 0E0h, 0F0h, 0F8h,	0FCh, 0F0h, 0C0h
		db 5, 0, 81h, 0FFh, 0Fh, 80h, 81h, 0FFh, 7, 0, 81h, 0FFh
		db 7, 0, 81h, 0FFh, 0Ah, 1, 8, 3, 8, 0C0h, 0A3h, 0FFh
		db 38h,	49h, 81h, 9Dh, 49h, 38h, 0FFh, 0FFh, 0E1h, 13h
		db 12h,	13h, 12h, 0E2h,	0FFh, 0FFh, 0C8h, 68h, 28h, 0E8h
		db 28h,	2Fh, 0FFh, 1, 3, 7, 0Fh, 1Fh, 3Fh, 7Fh,	7Fh, 0F0h
		db 0F9h, 0FDh, 7, 0FFh,	3, 0DFh, 91h, 0CBh, 89h, 80h, 0
		db 81h,	0D1h, 0F3h, 0F3h, 0FBh,	0FFh, 0FFh, 0Fh, 1Fh, 3Fh
		db 3Fh,	7Fh, 7Fh, 5, 0FFh, 8Ah,	0F7h, 0F3h, 0D7h, 83h
		db 85h,	0F8h, 0F8h, 0F0h, 0FAh,	0FEh, 5, 0FFh, 4, 7Fh
		db 7, 3Fh, 7, 7Fh, 4, 3Fh, 0Bh,	0Fh, 0Dh, 1Fh, 4, 80h
		db 0Ch,	0C0h, 3, 0F0h, 0Ch, 0E0h, 0Bh, 0F0h, 6,	0E0h, 6
		db 80h,	4, 0, 7, 80h, 0Ch, 0C0h, 7, 80h, 6, 0, 4, 80h
		db 2, 0C0h, 0

colorTableMap:	db 5, 8Fh, 3, 6Fh, 5, 9Fh, 8, 8Fh, 83h,	61h, 6Fh, 6Fh
		db 5, 9Fh, 83h,	81h, 8Fh, 8Fh, 30h, 1Fh, 11h, 6Fh, 6, 4Fh
		db 2, 6Fh, 6, 4Fh, 2, 6Fh, 6, 4Fh, 81h,	6Fh, 8,	0E0h, 78h
		db 0F0h, 48h, 0F0h, 0


;----------------------------------------------------
; Sprites usados en el mapa de piramides
; Silueta piramide, flecha arriba, derecha, abajo, izquierda
; 피라미드 맵에 사용된 스프라이트
; 피라미드 실루엣, 위쪽, 오른쪽, 아래쪽, 왼쪽 화살표
;----------------------------------------------------
gfxSprMapa:	dw 1F20h		; Direccion VRAM sprite	#E4
		db 88h,	6, 9, 10h, 20h,	40h, 0C0h, 30h,	0Fh, 0Ah, 0, 85h
		db 80h,	40h, 20h, 30h, 0C0h, 9,	0, 84h,	10h, 38h, 7Ch
		db 0FEh, 3, 38h, 32h, 0, 87h, 10h, 18h,	0FCh, 0FEh, 0FCh
		db 18h,	10h, 3,	38h, 84h, 0FEh,	7Ch, 38h, 10h, 32h, 0
		db 87h,	10h, 30h, 7Eh, 0FEh, 7Eh, 30h, 10h, 80h

		dw #3867
		db 91h		; Transfiere #11 patrones
		db 20h, 0,	30h, 39h, 32h, 21h, 2Dh, 29h, 24h, 1Bh, 33h,	0, 2Dh,	21h, 30h, 0, 20h	; Text: "- Pyramid's Map -"


		; Tabla de nombres del pergamino
		db 4Fh, 0, 85h, 0CFh, 0D0h
		db 1, 1, 0D2h, 4, 1, 88h, 0D0h,	0D3h, 1, 1, 1, 0D2h, 0D0h
		db 0D5h, 0Fh, 0, 81h, 0D8h, 10h, 1, 81h, 0DCh, 0Eh, 0
		db 92h,	0DBh, 1, 0C0h, 0C3h, 0C7h, 0C7h, 0C2h, 0C3h, 0C7h
		db 0C7h, 0C2h, 0C3h, 0C7h, 0C8h, 1, 1, 1, 0DFh,	0Eh, 0
		db 81h,	0D9h, 0Ch, 1, 85h, 0C9h, 1, 1, 1, 0E0h,	0Eh, 0
		db 92h,	0DAh, 1, 1, 0C4h, 0C7h,	0C2h, 0C3h, 0C7h, 0C7h
		db 0C7h, 0C2h, 0C3h, 0C7h, 0C2h, 0C1h, 1, 1, 0E1h, 0Eh
		db 0, 84h, 0D7h, 1, 1, 0C5h, 0Dh, 1, 81h, 0DDh,	0Eh, 0
		db 3, 1, 89h, 0C6h, 0C2h, 0C3h,	0C7h, 0C7h, 0C2h, 0C3h
		db 0C7h, 0C8h, 5, 1, 81h, 0E2h,	0Eh, 0,	81h, 0D6h, 0Ah
		db 1, 81h, 0C9h, 5, 1, 81h, 0E3h, 0Eh, 0, 8Dh, 0D8h, 1
		db 0C4h, 0C2h, 0C3h, 0C7h, 0C2h, 0C3h, 0C7h, 0C7h, 0C7h
		db 0C2h, 0C1h, 4, 1, 81h, 0E4h,	0Eh, 0,	83h, 0DBh, 1, 0C5h
		db 0Eh,	1, 81h,	0DFh, 0Eh, 0, 92h, 0D9h, 1, 0C6h, 0C7h
		db 0C7h, 0C7h, 0C2h, 0C3h, 0C7h, 0C2h, 0C3h, 0C7h, 0C7h
		db 0C2h, 0C1h, 1, 1, 0E0h, 0Eh,	0, 81h,	0DAh, 0Ch, 1, 85h
		db 0C9h, 1, 1, 1, 0DEh,	0Eh, 0,	81h, 0D7h, 8, 1, 89h, 0C4h
		db 0C7h, 0C7h, 0C7h, 0C2h, 0C1h, 1, 1, 0E5h, 0Eh, 0, 7
		db 1, 85h, 0CAh, 0CCh, 0CDh, 0CEh, 0CBh, 5, 1, 81h, 0E6h
		db 0Eh,	0, 84h,	0D6h, 0D1h, 0D4h, 0D1h,	4, 1, 8Ah, 0D4h
		db 1, 1, 1, 0D1h, 0D1h,	1, 1, 0D1h, 0E7h, 0

coloresFlecha:	db 1, 6, 6, 0Ah, 0Ah, 6, 6, 6	; Colores usados para resaltar la flecha y piramide en el mapa


;----------------------------------------------------
;
; Coordenadas en pantalla de las piramides del mapa
; Y, X
;
; 지도상의 피라미드의 화면 좌표
; Y, X
;----------------------------------------------------
coordPiramMap:	db 3Fh,	4Ah
		db 3Fh,	6Ah
		db 3Fh,	8Ah
		db 4Fh,	0A2h
		db 4Fh,	8Ah
		db 4Fh,	62h
		db 5Fh,	5Ah
		db 5Fh,	7Ah
		db 6Fh,	92h
		db 6Fh,	6Ah
		db 6Fh,	52h
		db 7Fh,	6Ah
		db 7Fh,	82h
		db 7Fh,	0A2h
		db 8Fh,	0A2h

offsetFlechas:	db 0F9h, 2
		db 8, 2
		db 0F9h, 0F1h
		db 0F9h, 4

;----------------------------------------------------
; Numero de sprites de las flechas
; 화살 스프라이트의 수
;----------------------------------------------------
numSprFlechas:	db 0E8h
		db 0F0h			; Abajo
						; 아래
		db 0F4h			; Izquierda
						; 왼쪽
		db 0ECh			; Derecha
						; 오른쪽

;----------------------------------------------------
; Numero de sprites de las flechas invertidas
; 거꾸로 된 화살표의 스프라이트 수
;----------------------------------------------------
numSprFlechInv:	db 0F0h
		db 0E8h			; Arriba
						; 위
		db 0ECh			; Derecha
						; 오른쪽
		db 0F4h			; Izquierda
						; 왼쪽


TXT_ENDING:
		dw #38c9		; Direccion VRAM
		db 8Fh
		db 23h,	2Fh, 2Eh, 27h, 32h, 21h, 34h, 35h, 2Ch,	21h, 34h, 29h, 2Fh, 2Eh, 33h 	; "CONGRATULATIONS"
		db #2e, 0									; Rellena #2e patrones
		db 90h			; Transfiere #10 patrones
		db 33h, 30h, 25h, 23h, 29h, 21h, 2Ch, 0, 22h, 2Fh, 2Eh, 35h, 33h, 0, 0, 11h 	; "SPECIAL BONUS  1"

		db    4, 10h									; "0000"
		db    0										; Fin

;----------------------------------------------------
;
; Set music
; In:
;   A =	Numero de musica o efecto
;
; 세트 음악
; 입력:
;   A = 음악 또는 효과의 수
;----------------------------------------------------

setMusic:
	IF	(VERSION2)
		di
		call	SetMusic_
		ei
		ret
	ELSE
		di
		push	hl
		push	de
		push	bc
		push	af
		push	ix
		call	SetMusic_
		pop	ix
		pop	af
		pop	bc
		pop	de
		pop	hl
		ei
		ret
	ENDIF

SetMusic_:
		ld	c, a
		and	3Fh
		ld	b, 2		; Canales a usar
		ld	hl, musicCh1
		cp	0Bh		; Es una efecto	de sonido de los que suenan mientras suena la musica principal?
		jr	c, setSFX

		cp	11h		; Es una musica	que suena en solitario y usa los 3 canales?
		jr	c, setMus

		inc	b		; Usa los 3 canales
		jr	setMus

setSFX:
		dec	b		; Solo usa 1 canal
		ld	hl, musicCh3	; El canal 3 es	el que reproduce los efectos de	sonido

setMus:
		ld	a, (hl)		; Musica que esta sonando en este canal
		and	3Fh		; Descarta bits	de configuracion y se queda solo con el	numero de musica
		ld	e, a		; E = Sonido actual
		ld	a, c
		and	3Fh		; A = Sonido que se quiere reproducir
		cp	e		; Tiene	mas prioridad el que esta sonando o el nuevo?
		ret	c		; El que esta sonando tiene mas	prioridad

		add	a, a
		ld	de, MusicIndex-2
		call	ADD_A_DE	; Obtiene puntero a los	datos de la musica o efecto que	hay que	reproducir
		dec	hl
		dec	hl

setChanData:
		push	hl
		pop	ix
		ld	(hl), 1		; Contador de la duracion de la	nota
		inc	hl
		ld	(hl), 1		; Duracion por defecto de la nota
		inc	hl
		ld	(hl), c		; Musica que esta reproduciendo	el canal

		inc	hl
		ld	a, (de)
		ld	(hl), a		; Byte bajo del	puntero	a los datos de la musica/efecto
		inc	hl
		inc	de
		ld	a, (de)
		ld	(hl), a		; Byte alto del	puntero

		ld	(ix+9),	0
		ld	a, 0Ah
		call	ADD_A_HL	; Apunta al siguiente canal
		inc	de
		djnz	setChanData
		ret

;----------------------------------------------------
; Pattern loop
; Comando = #FE	xx
;  xx =	Numero de veces	a repetir el pattern musical
;  FF =	Loop infinito
;
; 패턴 루프
; 명령 = #FE xx
;  xx = 음악 패턴 반복 횟수
;  FF = 무한 루프
;----------------------------------------------------

patternLoop:
		inc	hl		; Parametro del	comando	loop
		ld	a, (ix+MUSIC_CNT_LOOP) ; Veces que se ha reproducido un	pattern
		inc	a		; Incrementa el	numero de veces	que ha sonado el pattern
		cp	(hl)		; Ha sonado tantas veces como se indica?
		jr	z, omiteLoop

		jp	m, setMusPattern ; Es un loop infinito?
		dec	a		; No incrementa	el numero de veces que ha sonado

setMusPattern:
		ld	(ix+MUSIC_CNT_LOOP), a ; Veces que se ha reproducido un	pattern
		inc	hl
		ld	a, (hl)		; Direccion baja del pattern
		ld	(ix+MUSIC_ADD_LOW), a
		inc	hl
		ld	a, (hl)		; Direccion alta del pattern
		ld	(ix+MUSIC_ADD_HIGH), a
		jr	contProcessSnd	; Interpretar el pattern

omiteLoop:
		inc	hl
		inc	hl		; Descarta direccion del loop
		xor	a
		ld	(ix+MUSIC_CNT_LOOP), a ; Inicializa contador de	repeticiones del pattern
		call	incMusicPoint

contProcessSnd:
		inc	(ix+MUSIC_CNT_NOTA) ; Este comando no modifica la duracion de la nota
		jp	processSndData

;----------------------------------------------------
; Alterna entre	el tono	o ruido	del canal 3
; In:
;   C =	Canal en proceso 1, 3, 5 (1-3)
;   D:
;    1 = Activa	tono canal 3 y desactiva ruido
;    0 = Desactiva tono	canal 3	y activa ruido
;
; 채널 3 톤 또는 노이즈 간 전환
; 입력:
;   C = 진행 중인 채널 1, 3, 5(1-3)
;   D:
;    1 = 채널 3 톤 활성화 및 노이즈 비활성화
;    0 = 채널 3 톤 비활성화 및 노이즈 활성화
;----------------------------------------------------

switchCh3OnOff:
		ld	a, c
		cp	5		; Es el	canal 3?
		ret	nz		; No

		dec	d
		jr	z, toneOnCh123

		ld	a, 10011100b
		jr	SetPSGMixer	; Desactiva el tono del	canal 3	y activa el ruido

toneOnCh123:
		ld	a, 10111000b	; Activa los 3 canales de sonido y apaga los de	ruido

SetPSGMixer:
		ld	(mixerValuePSG), a
		ld	e, a
		ld	a, 7
		jp	WRTPSG


;----------------------------------------------------
; Actualiza el driver de sonido
; 사운드 드라이버 업데이트
;----------------------------------------------------

updateSound:
		ld	a, (mixerValuePSG)
		call	SetPSGMixer	; Fija el estado de los	canales	del PSG

		ld	c, 1
		ld	ix, MusicChanData
		exx
		ld	b, 3		; Numero de canales
		ld	de, 0Eh		; Channel data size

updateSound2:
		exx
		ld	a, (ix+MUSIC_ID) ; Musica que esta reproduciendo el canal

		push	af
		dec	a		; Es el	sonido de caer?
		call	z, updateSfxCaer
		pop	af

		or	a		; Esta sonando algo?
		call	nz, processSndData ; si

		inc	c
		inc	c		; Siguiente canal
		exx
		add	ix, de		; Apunta a los datos del siguiente canal
		djnz	updateSound2	; Reproduce siguiente canal
		ret

updateSfxCaer:
		ld	a, c
		cp	5
		ret	c		; No es	el canal 3

		ld	hl, caidaSndDat	; Este byte y los dos anteriores controlan la frecuencia del sonido de caida
		ld	de, caidaSndData
		ld	a, (flagSetCaeSnd) ; Si	es 0 hay que inicializar los datos del sonido de caida
		cp	1
		jr	c, initCaeSndDat ; Inicializa valores del sonido de caida

		ld	a, 8
		add	a, (hl)		; Incrementa frecuencia	del sonido de caida
		ld	(hl), a
		dec	hl
		jr	nc, setFrqCaePoint ; Guarda el puntero a la frecuencia de caida

		inc	(hl)		; Si hay acarreo, incrementa frecuencia	byte alto

setFrqCaePoint:
		dec	hl
		ld	(ix+MUSIC_ADD_LOW), l
		ld	(ix+MUSIC_ADD_HIGH), h
		ret

initCaeSndDat:
		push	bc
		ex	de, hl
		ld	bc, 4
		lddr

		ex	de, hl
		pop	bc
		inc	hl
		inc	hl
		inc	hl
		jr	setFrqCaePoint



		db    1			; Quita	"flagSetCaeSnd"
		db 21h
		db 0B0h
caidaSndData:	db 61h

processSndData:
		bit	6, a
		ld	d, 1
		call	z, switchCh3OnOff

		ld	a, (ix+MUSIC_ID)
		or	a
		jp	m, loc_7C2D

		dec	(ix+MUSIC_CNT_NOTA) ; Decrementa contador duracion nota
		ret	nz		; No hay que actualizar	la nota, sigue sonando la anterior

nextNote:
		ld	l, (ix+MUSIC_ADD_LOW)
		ld	h, (ix+MUSIC_ADD_HIGH) ; Puntero a los datos de	la musica
		ld	a, (hl)		; Dato
		cp	0FEh		; Hay que hacer	un loop	de un pattern?
		jp	z, patternLoop	; Si

		jr	nc, endMusic	; #FF =	Fin de los datos

		bit	7, (ix+MUSIC_ID)
		jp	nz, setNote

; Duracion nota: #2x (x	= duracion)
		and	0F0h		; Se queda con el comando (nibble alto)
		cp	20h		; Comando: Cambiar duracion de la nota?
		ld	a, (hl)		; Vuelve a leer	el dato
		jr	nz, loc_7BC7

		and	0Fh		; Se queda con la duracion (nibble bajo)
		ld	(ix+MUSIC_DURAC_NOTA), a ; Cambia la duracion de la nota
		inc	hl
		ld	a, (hl)		; Lee el siguiente dato

loc_7BC7:
		ld	b, a
		and	0F0h
		cp	10h
		jr	nz, loc_7BEA

		ld	a, (hl)
		and	1Fh
		ld	e, a
		inc	hl
		bit	4, (hl)
		ld	b, (hl)
		jr	nz, loc_7BDC

		ld	a, e
		sub	10h
		ld	e, a

loc_7BDC:
		res	4, b
		dec	hl
		ld	a, 6		; Noise	generator
		call	WRTPSG
		ld	d, 0
		call	switchCh3OnOff
		inc	hl

loc_7BEA:
		bit	6, (ix+MUSIC_ID)
		jr	z, loc_7BF7

		ld	a, (hl)		; (!?) No se usa el valor
		call	incMusicPoint
		ld	a, b
		jr	setDuracion

loc_7BF7:
		and	0F0h
		ld	b, a
		xor	(hl)
		ld	d, a		; Frecuencia (high)
		inc	hl
		ld	e, (hl)		; Frecuencia (low)
		call	incMusicPoint
		ex	de, hl
		call	setFreq
		ld	a, b
		rrca
		rrca
		rrca
		rrca

setDuracion:
		ld	h, a
		ld	e, (ix+MUSIC_DURAC_NOTA) ; Valor de la duracion	de la nota
		ld	(ix+MUSIC_CNT_NOTA), e ; Contador de la	duracion de la nota
		ld	a, (ix+0Ch)
		add	a, e
		ld	(ix+8),	a
		jr	setVolume

endMusic:
		xor	a
		ld	(ix+MUSIC_CNT_LOOP), a ; Veces que se ha reproducido un	pattern
		ld	(ix+0Bh), a
		ld	d, 1
		call	switchCh3OnOff
		xor	a
		ld	(ix+MUSIC_ID), a ; Ninguna musica sonando
		ld	h, a		; Volumen 0
		jr	setVolume

loc_7C2D:
		dec	(ix+MUSIC_CNT_NOTA) ; Decrementa duracion contador nota
		jp	z, nextNote	; Fin nota

		dec	(ix+8)
		ld	a, (ix+8)
		cp	(ix+MUSIC_CNT_NOTA)
		jr	nz, loc_7C47

		ld	e, a
		ld	a, (ix+0Dh)
		cp	e
		ld	a, e
		jr	nc, decVolume
		ret

loc_7C47:
		dec	(ix+8)

decVolume:
		ld	a, (ix+MUSIC_VOLUME)
		dec	a
		ret	m		; El volumen era 0
		ld	(ix+MUSIC_VOLUME), a
		ld	h, a

;----------------------------------------------------
; Fija el volumen de un	canal del PSG
; In:
;   C =	Canal 1-3 (1,3,5)
;   H =	Volumen
;
; PSG 채널의 볼륨 설정
; 입력:
;   C = 채널 1-3(1,3,5)
;   H = 볼륨
;----------------------------------------------------

setVolume:
		ld	a, c
		rrca
		add	a, 88h
		ld	e, h
		jp	WRTPSG

setNote:
		ld	a, (hl)
		and	0F0h
		cp	0D0h		; Comando #D = Tempo
		ld	a, (hl)
		jr	nz, loc_7C6A

		and	0Fh
		ld	(ix+MUSIC_TEMPO), a
		inc	hl
		ld	a, (hl)

loc_7C6A:
		cp	0F0h
		jr	c, loc_7C7F

		and	0Fh
		ld	(ix+MUSIC_VOLUME_CH), a	; Volumen canal
		inc	hl
		ld	a, (hl)
		ld	(ix+0Ch), a
		inc	hl
		ld	a, (hl)
		ld	(ix+0Dh), a
		inc	hl
		ld	a, (hl)

loc_7C7F:
		cp	0E0h
		jr	c, loc_7C94

		and	0Fh
		bit	3, a
		jr	z, changOctave

		ld	(ix+0Bh), a
		inc	hl
		jr	setNote

changOctave:
		ld	(ix+MUSIC_OCTAVA), a ; Octava?
		inc	hl
		ld	a, (hl)		; Nota+duracion

loc_7C94:
		and	0Fh		; Nibble bajo =	duracion
		ld	b, a
		ld	a, (ix+MUSIC_TEMPO)
		jr	z, setDuracionNota

incDuracionNota:
		add	a, (ix+MUSIC_TEMPO)
		djnz	incDuracionNota

setDuracionNota:
		ld	(ix+MUSIC_DURAC_NOTA), a

		ld	a, (hl)
		call	incMusicPoint
		and	0F0h
		rrca
		rrca
		rrca
		rrca
		ld	b, a
		sub	0Ch
		jr	z, defaultVolume

		ld	a, (ix+MUSIC_VOLUME_CH)	; Volumen canal

defaultVolume:
		ld	(ix+MUSIC_VOLUME), a
		call	setDuracion

		ld	a, b
		ld	hl, freqNotas
		call	ADD_A_HL

		ld	l, (hl)		; Frecuencia
		ld	h, 0

		ld	a, (ix+MUSIC_OCTAVA) ; Octava?
		or	a
		jr	z, setOctave

		ld	b, a

addOctave:
		add	hl, hl
		djnz	addOctave

setOctave:
		ld	a, (ix+0Bh)
		or	a
		jr	z, setFreq
		inc	hl		; Chorus?

; C = Canal 1,3,5 (1-3)
; HL = Frecuencia

setFreq:
		ld	a, c		; Registro PSG de la frecuencia	del canal (high)
		ld	e, h
		call	WRTPSG
		ld	a, c
		dec	a		; Registro frecuencia (low)
		ld	e, l
		jp	WRTPSG

incMusicPoint:
		inc	hl
		ld	(ix+MUSIC_ADD_LOW), l
		ld	(ix+MUSIC_ADD_HIGH), h
		ret

;----------------------------------------------------
; Frecuencias de las notas (segunda octava)
; 음 주파수(두 번째 옥타브)
;----------------------------------------------------
freqNotas:	db 6Ah
		db 64h
		db 5Fh
		db 59h
		db 54h
		db 50h
		db 4Bh
		db 47h
		db 43h
		db 3Fh
		db 3Ch
		db 38h

MusicIndex:
		dw SFX_Dummy		; 1 - Caer
		dw SFX_Dummy		; 2 - Choca suelo
		dw SFX_PuertaGir	; 3 - Puerta giratoria
		dw SFX_Coger		; 4 - Coge objeto:cuchillo o pico
		dw SFX_Picar		; 5 - Sonido del pico
		dw SFX_Lanzar		; 6 - Larzar cuchillo
		dw SFX_Momia		; 7 - Aparece una momia
		dw SFX_Hit		; 8 - Explota momia al golpearla con cuchillo
		dw SFX_Gema		; 9 - Coger gema
		dw SFX_VidaExtra	; 10 - Vida extra

		dw MUS_Ingame		; 11 - Musica ingame
		dw MUS_Ingame2

		dw MUS_CloseDoor	; 13 - Puerta cerrandose
		dw MUS_CloseDoor2

		dw MUS_SalirPiram	; 15 - Campanilla al salir de la piramide
		dw MUS_SalirPiram2

		dw MUS_Mapa		; 17 - Fanfarria del pergamino
		dw MUS_Mapa2
		dw MUS_Mapa3

		dw MUS_StageClr		; 20 - Stage clear. Ha cogido todas las	gemas
		dw MUS_StageClr2
		dw MUS_StageClr3

		dw MUS_Start		; 23 - Start game
		dw MUS_Start2
		dw MUS_Start3		; 25

		dw MUS_GameOver		; 26 - Game Over
		dw MUS_GameOver2
		dw MUS_GameOver3

		dw MUS_Muerte		; 29 - Prota muere
		dw MUS_Muerte2		; 30
		dw MUS_Muerte3

		dw SFX_Dummy		; 32 - Silencio
		dw SFX_Dummy
		dw SFX_Dummy

SFX_Dummy:	db 0FFh

SFX_Momia:      db 0D1h, 0FCh, 3, 3, 0E2h, 0, 0C0h, 10h, 0C0h, 20h, 0C0h
		db 20h, 0C0h, 40h, 80h, 40h, 80h, 0CEh, 0FDh, 0, 0C0h
		db 10h, 0C0h, 20h, 0C0h, 20h, 0C0h, 40h, 80h, 40h, 80h
		db 0CEh, 0D2h, 0C6h

		db 0FEh, 2
		dw SFX_Momia
		db 0FFh

SFX_Hit:	db 21h,	0E0h, 0A0h, 0E0h, 0C0h,	0E0h, 0E0h, 0D0h, 60h
		db 0D0h, 80h, 0D0h, 0A0h, 0D0h,	20h, 0C0h, 40h,	0C0h, 60h
		db 0C0h, 80h, 0FFh

SFX_Gema:	db 22h,	0D0h, 54h, 0, 0, 0D0h, 50h, 0, 0, 0D0h,	47h, 0D0h
		db 42h,	0, 0, 0D0h, 38h, 0D0h, 33h, 0FFh

SFX_Coger:	db 22h,	0C1h, 52h, 0E0h, 74h, 0C0h, 91h, 0F0h, 74h, 0D0h
		db 75h,	0FFh

SFX_Picar:	db 22h,	1Ch, 1Fh, 8, 16h, 0Ch, 0FFh

SFX_Lanzar:	db 21h,	0E0h, 78h, 0C0h, 70h, 0C0h, 68h, 0E0h, 63h, 0D0h
		db 5Ah,	0D0h, 53h, 0B0h, 53h, 90h, 53h,	50h, 53h, 0FFh

SFX_PuertaGir:	db 26h,	0F6h, 94h, 0F6h, 8Fh, 0F6h, 8Fh, 0F6h, 8Ah, 0E6h
		db 85h,	0E6h, 80h, 0D6h, 7Ah, 0D6h, 75h, 0C6h, 70h, 0C6h
		db 6Ah,	0B6h, 85h, 0A6h, 70h, 96h, 6Ah,	0FFh

MUS_Muerte:	db 26h,	0E1h, 80h, 0E2h, 80h, 0D2h, 0, 0D3h, 0,	0C2h, 80h
		db 0C3h, 80h, 0B3h, 0, 0B4h, 0,	0FFh

MUS_Muerte2:	db 26h,	0E0h, 80h, 0E1h, 80h, 0D1h, 0, 0D2h, 0,	0C1h, 80h
		db 0C2h, 80h, 0B2h, 0, 0B3h, 0,	0FFh

MUS_Muerte3:	db 26h,	0E1h, 0, 0E1h, 0, 0D1h,	80h, 0D2h, 80h,	0C2h, 0	; ...
		db 0C3h, 0, 0B2h, 80h, 0B3h, 80h, 0FFh

MUS_Ingame:	db 0D8h, 0FCh, 3, 3, 0E2h, 42h,	50h, 42h, 50h, 80h, 0C0h
		db 90h,	0C0h, 0B0h, 90h, 80h, 50h, 42h,	50h, 41h, 21h
		db 11h,	21h, 43h, 82h, 90h, 82h, 90h, 0B0h, 0C0h, 0E1h
		db 0, 0C0h, 30h, 0, 0E2h, 0B0h,	90h, 80h, 90h, 0B0h, 90h
		db 80h,	0C0h, 50h, 0C0h, 42h, 50h, 41h,	0B0h, 90h, 0B0h
		db 0E1h, 0, 30h, 40h, 30h, 0C0h, 0, 0C0h, 0E2h,	0B2h, 0E1h
		db 0, 0E2h, 0B1h, 0B0h,	90h, 0B0h, 0E1h, 0, 30h, 40h, 60h
		db 40h,	30h, 0,	0E2h, 0B2h, 0E1h, 0, 0E2h, 0B3h, 0FEh
		db 0FFh
		dw MUS_Ingame

MUS_Ingame2:	db 0D8h, 0FCh, 3, 3, 0E3h

byte_7E61:	db 41h,	80h, 80h, 40h, 0C0h, 81h, 0FEh,	4
		dw byte_7E61

byte_7E6B:	db 51h,	90h, 90h, 50h, 0C0h, 91h, 0FEh,	2
		dw byte_7E6B

byte_7E75:	db 41h,	80h, 80h, 40h, 0C0h, 81h, 0FEh,	2
		dw byte_7E75

byte_7E7F:	db 31h,	90h, 90h, 0E4h,	0B0h, 0C0h, 0E3h, 91h, 0FEh, 3
		dw byte_7E7F
		db 31h,	90h, 90h, 0E4h,	0B0h, 0E3h, 30h, 60h, 0B0h, 0FEh
		db 0FFh
		dw MUS_Ingame2
		db 0FEh
		db 0FFh

MUS_StageClr:	db 0E8h
MUS_StageClr2:	db 0D6h, 0FCh, 1, 1, 0E1h, 1, 11h, 41h,	51h, 41h, 11h
		db 1, 0E2h, 0A1h, 0E1h,	0, 10h,	0, 10h,	0, 10h,	0, 10h
		db 3, 0FFh

MUS_StageClr3:	db 0D6h, 0FBh, 1, 1, 0E3h, 0B1h, 0E2h, 11h, 41h, 51h, 41h
		db 11h,	1, 0E3h, 0A1h, 0E2h, 0,	10h, 0,	10h, 0,	10h, 0
		db 10h,	3, 0FFh

MUS_GameOver:	db 0E8h
MUS_GameOver2:	db 0DAh, 0FCh, 2, 2, 0E1h, 73h,	0B3h, 0A3h, 83h, 80h, 70h
		db 40h,	30h, 40h, 0C0h,	70h, 0C0h, 0D5h, 80h, 0A0h, 0DAh
		db 83h,	0FFh

MUS_GameOver3:	db 0DAh, 0FDh, 2, 2, 0E2h, 70h,	80h, 0A0h, 0B0h, 0E1h
		db 20h,	0C0h, 0E2h, 0B0h, 0C0h,	0A0h, 0C0h, 80h, 0C0h
		db 0D5h, 0A0h, 0B0h, 0DAh, 0A2h, 80h, 70h, 40h,	30h, 40h
		db 0C0h, 70h, 0C0h, 84h, 0FFh

MUS_Start:	db 0E8h
MUS_Start2:	db 0D4h, 0FCh, 1, 1, 0E0h, 21h,	0C1h, 0E1h, 91h, 0C1h
		db 0E0h, 1, 0E1h, 0A1h,	91h, 0C1h, 71h,	0A1h, 0E0h, 11h
		db 0E1h, 0A1h, 97h, 31h, 21h, 31h, 61h,	91h, 71h, 91h
		db 0A1h, 91h, 71h, 61h,	31h, 27h, 0FFh

MUS_Start3:	db 0D3h, 0FBh, 1, 1, 0E1h, 0C0h, 0D4h, 21h, 0C1h, 0E2h
		db 91h,	0C1h, 0E1h, 1, 0E2h, 0A1h, 91h,	0C1h, 71h, 0A1h
		db 0E1h, 11h, 0E2h, 0A1h, 97h, 31h, 21h, 31h, 61h, 91h
		db 71h,	91h, 0A1h, 91h,	71h, 61h, 31h, 27h, 0FFh

SFX_VidaExtra:	db 0D4h, 0FDh, 3, 3, 0E2h, 70h,	60h, 70h, 0E1h,	70h, 60h
		db 71h,	0FFh

MUS_CloseDoor:	db 0D1h, 0FCh, 1, 1, 0E3h, 1, 1, 51h, 51h, 21h,	21h, 71h
		db 71h,	0CEh, 51h, 51h,	91h, 91h, 71h, 71h, 0B1h, 0B1h
		db 91h,	91h, 0E3h, 1, 1, 0FFh

MUS_CloseDoor2:	db 0D1h, 0FCh, 1, 1, 0E2h, 1, 1, 51h, 51h, 21h,	21h, 71h
		db 71h,	0CFh, 51h, 51h,	91h, 91h, 71h, 71h, 0B1h, 0B1h
		db 91h,	91h, 0E1h, 1, 1, 0FFh

MUS_Mapa:	db 0D6h, 0FCh, 3, 3, 0E2h, 0B2h, 0B0h, 0D7h, 0B0h, 70h
		db 0D8h, 90h, 0D6h, 0B1h, 0E1h,	20h, 20h, 41h, 0, 40h
		db 7Bh,	0FFh

MUS_Mapa2:	db 0D6h
		db 0FCh, 3, 3, 0E2h, 72h, 70h, 0D7h, 70h, 20h, 0D8h, 50h
		db 0D6h, 71h, 0B0h, 0B0h, 0E1h,	1, 0E2h, 90h, 0E2h, 0
		db 2Bh,	0FFh

MUS_Mapa3:	db 0D6h, 0FCh, 3, 3, 0E2h, 22h,	20h, 0D7h, 20h,	0E3h, 0B0h
		db 0D8h, 0E2h, 20h, 0D6h, 21h, 70h, 70h, 91h, 50h, 90h
		db 0BBh, 0FFh

MUS_SalirPiram:	db 0D4h, 0FCh, 3, 3, 0E1h, 70h,	0E0h, 40h, 70h,	40h, 70h
		db 0FFh

MUS_SalirPiram2:db 0D4h, 0FCh, 3, 3, 0E1h, 40h,	0E0h, 0, 40h, 0, 40h, 0FFh

	IF	(VERSION2)
		db #ff
	ENDIF

;------------------------------------------------------------------------------
;
; Identificador del juego de Konami: OUKE NO TANI
;
;    -00: #AA (Token)
;    -01: N�mero RC7xx en formato BCD
;    -02: N�mero de bytes usados para el nombre
;    -03: Nombre en katakana (escrito al rev�s)
;
; 코나미 게임 ID: OUKE NO TANI(수령 의 계곡)
;
;    -00: #AA(토큰)
;    -01: ​​BCD 형식의 ​RC7xx 숫자
;    -02: 이름에 사용된 바이트 수
;    -03: 가타카나로 된 이름(뒤로 쓰기)
;
;     bytes([x+0x31 for x in [0x84,0x82,0x88,0x98,0x8f,0x95]]).decode('shift_jis')
;     'ｵｳｹﾉﾀﾆ'
;
;------------------------------------------------------------------------------
		db 95h,	8Fh, 98h, 88h, 82h, 84h, 6, 27h, 0AAh




; ===========================================================================

		MAP     #e000

GameStatus:	# 1
					; 0 = Konami Logo
					; 1 = Menu wait
					; 2 = Set demo
					; 3 = Musica de	inicio,	parpadea START PLAY, pone modo juego
					;		음악 시작, START PLAY 깜박임, 게임 모드 전환
					; 4 = Empezando	partida
					;		게임 시작
					; 5 = Jugando /	Mapa
					;		재생 / 지도
					; 6 = Perdiendo	una vida / Game	Over
					;		목숨을 잃다 / 게임 오버
					; 7 = Game Over
					; 8 = Stage Clear
					; 9 = Scroll pantalla
					;		스크롤 화면
					; 10 = Muestra el final	del juego
					;		게임의 끝을 보여주세요
subStatus:	# 1
controlPlayer:	# 1			; bit 6	= Prota	controlado por el jugador
							;		플레이어 제어 게이트
timer:		# 1
waitCounter:	# 1
tickInProgress:	# 1			; Si el	bit0 esta a 1 no se ejecuta la logica del juego
							;		bit0이 1이면 게임 로직이 실행되지 않습니다.

dummy_1		# 2

KeyTrigger:	# 1
KeyHold:	# 1			; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha, #10 = Boton A, #20	=Boton B
						;	1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
gameLogoCnt:	# 1

dummy_2		# 2

flagEndPergamino:# 1
					; 1 = Ha terminado de mostar el	pergamino/mapa
					;		스크롤/지도 표시를 완료했습니다.
CoordKonamiLogo:# 2			; Direccion BG Map (name table)	del logo
							;		로고의 BG Map 주소(네임표)


MusicChanData:	# 2
musicCh1:	# 12

MusicChanData2:	# 2
musicCh2:	# 12

MusicChanData3:	# 2
musicCh3:	# 12

mixerValuePSG:	# 1
flagSetCaeSnd:	# 1			; Si es	0 hay que inicializar los datos	del sonido de caida
							;	; 0이면 떨어지는 소리의 데이터 초기화가 필요하다
dummy_3		# 2

caidaSndDat:	# 1			; Este byte y los dos anteriores controlan la frecuencia del sonido de caida
							;	이 바이트와 이전 2바이트는 감쇠 사운드의 주파수를 제어합니다.
dummy:		# 1

KeyTrigger2:	# 1
KeyHold2:	# 1

dummy0:		# 1

record_0000xx:	# 2
record_xx0000:	# 1

dummy_4		# 3

score_0000xx:	# 2
score_xx0000:	# 1

dummy_5		# 4

Vidas:		# 1
flagPiramideMap:# 1
					; 0 = Mostrando	mapa, 1	= Dentro de la piramide
					;	 0 = 지도 보기, 1 = 피라미드 내부
extraLifeCounter:# 1
flagVivo:	# 1
					; 0 = Muerto, 1	= Vivo
					;	; 0 = 사망, 1 = 생존
piramideActual:	# 1
piramideDest:	# 1
puertaEntrada:	# 1
					; Indica la puerta/direccion por la que	se esta	entrando a la piramide
					; 피라미드로 들어가는 문/방향을 나타냅니다.
puertaSalida:	# 1
					; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha
					; 1 = 위쪽, 2 = 아래쪽, 4 = 왼쪽, 8 = 오른쪽
numFinishGame:	# 1
					; Numero de veces que se ha terminado el juego
					; 게임이 끝난 횟수
dummy_6		# 2

UNKNOWN:	# 1			; (!?) Se usa?
dummy_7		# 2

flagMuerte:	# 1			; No se	usa (!?)
						; 사용하지 않음(!?)
quienEscalera:	# 1			; (!?) Se usa esto? Quien esta en una escalera 0 = Prota. 1 = Momia
							; (!?) 이것은 사용됩니까? 사다리에 있는 사람 0 = 주인공. 1 = 미라

dummy_8:	# 1

offsetPlanoSpr:	# 1			; Contador que modifica	el plano en el que son pintados	los sprites, asi se consigue que parpaden en vez de desaparecer
							; 스프라이트가 그려지는 평면을 수정하여 사라지지 않고 깜박이도록 하는 카운터
PiramidesPasadas:# 2			; Cada bit indica si la	piramide correspondiente ya esta pasada/terminada
								; 각 비트는 해당 피라미드가 이미 통과/완료되었는지 여부를 나타냅니다.
keyTriggerMap:	# 1
keyHoldMap:	# 1
mapPaused:	# 1			; 1 = Pausing

dummy_9:	# 25

keyPressDemo:	# 2			; Puntero a los	controles grabados
							; 기록된 컨트롤에 대한 포인터
KeyHoldCntDemo:	# 1
escaleraData:	# 45		; 사다리 데이터

;----------------------------------------------------
; Tabla	de atributos de	los sprites en RAM
; Sprites:
; 0-3 =	Parte izquierda	de la puerta de	la piramide (usada para	tapar al prota y dar sensacion de que pasa por detras)
; 3 = Tambien usado como halo de la piramide en	el mapa
; 4-5 =	Prota
; 6-9 =	Momias
; 15 = Cuchillo	o flecha mapa
;
; RAM에 있는 스프라이트의 속성 테이블
; 스프라이트:
; 0-3 = 피라미드 문의 왼쪽 부분(주인공을 가리고 그가 뒤를 지나가고 있다는 인상을 주기 위해 사용됨)
; 3 = 지도에서 피라미드의 후광으로도 사용됨
; 4-5 = 주인공
; 6-9 = 미라
; 15 = 칼 또는 지도 화살표
;----------------------------------------------------
sprAttrib:	# 1			; Tabla	de atributos de	los sprites en RAM (Y, X, Spr, Col)
						; RAM의 스프라이트 속성 테이블(Y, X, Spr, Col)
puertaXspr:	# 15
protaAttrib:	# 3
protaColorRopa:	# 4
ProtaColorPiel:	# 1
enemyAttrib:	# 16
unk_E0D8:	# 20

; Atributos del	cuchillo al rebotar
; Ricochet의 칼 속성
knifeAttrib:	# 16
attrPiramidMap:	# 3			; Atributos del	sprite usado para resaltar una piramide	en el mapa (silueta)
							; 지도에서 피라미드를 강조 표시하는 데 사용되는 스프라이트의 속성(실루엣)

colorPiramidMap:# 1			; Color	del outline de la piramide en el mapa
							; 지도의 피라미드 윤곽선 색상
attrFlechaMap:	# 3			; Atributos de la flecha del mapa
							; 지도 화살표 속성

colorFlechaMap:	# 1			; Color	de la flecha que indica	a que piramide vamos en	el mapa
							; 지도에서 우리가 가고 있는 피라미드를 나타내는 화살표의 색상

dummy_10:	# 2Ch

statusEntrada:	# 1			; Timer	usado en el mapa/pergamino de piramides
					; como status del prota	en las escaleras de entrada/salida
							; 맵/피라미드 스크롤에 사용되는 타이머는 입구/출구 계단에서 주인공의 상태로 스크롤됩니다.
lanzamFallido:	# 1			; 1 = El cuchillo se ha	lanzado	contra un muro y directamente sale rebotando
							; 1 = 칼이 벽에 부딪혀 바로 튕겨져 나옴
flagEntraSale:	# 1			; 1 = Entrando o saliendo de la	piramide. Ejecuta una logica especial para este	caso
							; 1 = 피라미드에 들어가거나 나가는 것. 이 경우에 대해 특수 논리 실행
flagStageClear:	# 1
protaStatus:	# 1			; 0 = Normal
					; 1 = Salto
					; 2 = Cayendo
					; 3 = Escaleras
					; 4 = Lanzando un cuhillo
					; 5 = Picando
					; 6 = Pasando por un apuerta giratoria

					; 0 = 정상
					; 1 = 점프
					; 2 = 떨어지는
					; 3 = 계단
					; 4 = 칼을 던지다
					; 5 = 찌른다
					; 6 = 회전문 통과하기

protaControl:	# 1			; 1 = Arriba, 2	= Abajo, 4 = Izquierda,	8 = Derecha, #10 = Boton A, #20	=Boton B
							; 1 = 위, 2 = 아래, 4 = 왼쪽, 8 = 오른쪽, #10 = 버튼 A, #20 = 버튼 B
sentidoProta:	# 1			; 1 = Izquierda, 2 = Derecha
							; 1 = 왼쪽, 2 = 오른쪽
ProtaY:		# 1
ProtaXdecimal:	# 1			; 'Decimales' usados en el calculo de la X. Asi se consiguen velocidades menores a 1 pixel
							; X 계산에 사용되는 '소수'. 따라서 1픽셀 미만의 속도가 달성됩니다.
ProtaX:		# 1
ProtaRoom:	# 1			; Parte	alta de	la coordenada X. Indica	la habitacion de la piramide
						; X 좌표의 상단 피라미드의 방을 나타냅니다.
protaSpeed:	# 2			; El byte bajo indica la parte "decimal" y el alto la entera
						; 하위 바이트는 "소수" 부분을 나타내고 상위 바이트는 정수를 나타냅니다.
speedRoom:	# 1			; Usando para sumar/restar a la	habitacion cuando se pasa de una a otra
						; 한 방에서 다른 방으로 이동할 때 방에 더하거나 빼기 위해 사용
protaMovCnt:	# 1			; Contador usado cada vez que se mueve el prota. (!?) No se usa	su valor
							; 주인공이 움직일 때마다 사용하는 카운터. (!?) 값이 사용되지 않습니다.
protaFrame:	# 1

; Los siguientes dos bytes se usan para	guardar	un puntero a una tabla con los valores del salto +#0C y	+#0D
; 다음 2바이트는 점프 값이 +#0C 및 +#0D인 테이블에 대한 포인터를 저장하는 데 사용됩니다.
timerPergam2:	# 1			; Se usa para hacer una	pausa tras terminar de sonar la	musica del pergamino al	llegar al GOAL
							; GOAL에 도달했을 때 스크롤 음악 재생이 끝난 후 일시 중지하는 데 사용됩니다.
dummy_11:	# 1

flagSalto:	# 1			; 0 = Saltando,	1 = En el suelo
						; 0 = 점프, 1 = 지상에서
sentidoEscalera:# 1			; 0 = \, 1 = /
					; Tambien usado	para saber si el salto fue en vertical (guarda el estado de las	teclas en el momento del salto.
					; 또한 점프가 수직인지 확인하는 데 사용됩니다(점프 시 키의 상태를 저장합니다.
objetoCogido:	# 1			; #10 =	Cuchillo, #20 =	Pico
							; #10 = 칼, #20 = 곡괭이
accionWaitCnt:	# 1			; Contador usado para controlar	la animacion y duracion	de la accion (lanzar cuchillo, cavar, pasar puerta giratoria)
							; 동작의 애니메이션 및 지속 시간을 제어하는 ​​데 사용되는 카운터(칼 던지기, 파기, 회전문 통과)
timerEmpuja:	# 1			; Timer	usado para saber el tiempo que se empuja una puerta giratoria
							; 회전문을 누르는 시간을 알던 타이머
flagScrolling:	# 1
agujeroCnt:	# 1			; Al comenzar a	pica vale #15
						; 구멍숫자(?) Pica를 시작할 때 #15의 가치가 있습니다.

; Datos	del agujero que	se esta	picando
; 드릴되는 구멍의 세부 정보
agujeroDat:	# 4			; Y, X,	habitacion
						; Y, X, 방

modoSentEsc:	# 1			; Si es	0 guarda en "sentidoEscalera" el tipo de escalera que se coge el prota. 0 = \, 1 = /
							; 0이면 주인공이 취하는 사다리의 종류를 "sentidoEscalera"에 저장합니다. 0 = \, 1 = /
momiasPiramid:	# 3*6			; Datos	de las momias que hay en la piramide actual: y,	x (%xxxxx--p), tipo
								; 현재 피라미드에 있는 미라 데이터: y, x(%xxxxx--p), 유형

dummy_12:	# 2
pMomiaProceso:	# 2			; Puntero a los	datos de la momia en proceso
							; 처리 중인 미라 데이터에 대한 포인터
numMomias:	# 1
momiaEnProceso:	# 1
ordenSubir:	# 1
distSubida:	# 1
ordenBajar:	# 1
distBajada:	# 1
momiaDat:	# 16h*4			; 0 = Andando
					; 1 = Salto
					; 2 = Cayendo
					; 3 = Escaleras
					; 4 = Limbo
					; 5 = Aparece
					; 6 = Suicida
					; 7 = pensando
					;
					; +#00 = Status
					; +#01 = Control
					; +#02 = Sentido
					; +#03 = Y
					; +#04 = X decimal
					; +#05 = X
					; +#06 = Room
					; +#07 = Speed X decimal
					; +#08 = Speed X
					; +#09 = Speed Room
					; +#0b = Frame
					; +#11 = Timer
					; +#14 = Tipo momia

					; 0 = 걷기
					; 1 = 점프
					; 2 = 떨어지는
					; 3 = 계단
					; 4 = 림보
					; 5 = 나타남
					; 6 = 자살
					; 7 = 생각
					;
					; +#00 = 상태
					; +#01 = 모니터
					; +#02 = 방향
					; +#03 = 그리고
					; +#04 = X 소수부
					; +#05 = X
					; +#06 = 방
					; +#07 = 속도 X 소수부
					; +#08 = 속도 X
					; +#09 = 스피드룸
					; +#0b = 프레임
					; +#11 = 타이머
					; +#14 = 미라 유형

puertaCerrada:	# 1			; Vale 1 al cerrarse la	salida
							; 문 닫힘: 출력이 닫힐 때 1의 가치가 있습니다.

dummy_13:	# 1

numPuertas:	# 1
pyramidDoors:	# 18h			; Y (FF	= Desactivado)
					; X decimales
					; X
					; Habitacion
					; Status (Nibble alto =	Status,	Nibble bajo = contador)
					; Piramide destino
					; Direccion por	la que se entra	/ Flecha del mapa

					; Y (FF = 꺼짐)
					; X 소수부
					; X
					; 방
					; 상태(높은 니블 = 상태, 낮은 니블 = 카운터)
					; 운명의 피라미드
					; 진입 방향 / 지도 화살표
dummy_14:	# 21

gemasCogidas:	# 1
gemasTotales:	# 1
ElemEnProceso:	# 1			; Usado	para saber la gema o puerta que	se esta	procesando
							; 처리중인 보석이나 문을 아는 데 사용됩니다.
datosGemas:	# 6Ch			; 0 = Color/activa. Nibble alto	indica el color. El bajo si esta activa	(1) o no (0)
					; 1 = Status
					; 2 = Y
					; 3 = decimales	X
					; 4 = X
					; 5 = habitacion
					; 6-8 =	0, 0, 0

					; 0 = 색상/활성. 높은 니블은 색상을 나타냅니다. 저음이 활성화된 경우(1) 그렇지 않은 경우(0)
					; 1 = 상태
					; 2 = Y
					; 3 = X 소수부
					; 4 = X
					; 5 = 방
					; 6-8 = 0, 0, 0


IDcuchilloCoge:	# 1			; Cuchillo que coge el prota
							; 주인공을 잡는 칼
knifeEnProceso:	# 1
numKnifes:	# 1
;
; Datos	de los cuchillos
; Numero maximo	de cuchillos 6
; Tama�o de la estructura 17 bytes
;
; 칼 데이터
; 칼의 최대 수 6
; 구조 크기 17바이트 (6*17=102=66h)
;
knifesData:	# 66h			; 0 = Status (1	= suelo, 2 = Cogido, 4 = Lanzamiento?, 5= lanzado, 7 =Rebotando)
					; 1 = Sentido (1 = izquierda, 2	= Derecha)
					; 2 = Y
					; 3 = X	decimales
					; 4 = X
					; 5 = Habitacion
					; 6 = Velocidad	decimales
					; 7 = Velocidad	cuchillo
					; 8 = Velocidad	cambio habitacion
					; 9 = Contador movimiento
					; A = Tile backup 1 (fondo)
					; B = Tile backup 2 (guarda dos	tiles al lanzarlo)

					; 0 = 상태(1 = 땅, 2 = 잡힘, 4 = 시작?, 5= 던짐, 7 = 튕김)
					; 1 = 방향(1 = 왼쪽, 2 = 오른쪽)
					; 2 = Y
					; 3 = X 소수
					; 4 = X
					; 5 = 방
					; 6 = 소수 속도
					; 7 = 나이프 속도
					; 8 = 방 변경 속도
					; 9 = 이동 카운터
					; A = 타일 백업 1(백그라운드)
					; B = 타일 백업 2(시전 시 타일 2개 저장)
idxPicoCogido:	# 1			; Indice del pico cogido por el	prota
							; 주인공이 잡은 곡괭이의 인덱스
numPicos:	# 1

; 5 bytes por entrada
; 입력당 5바이트
picosData:	# 50h			; 0 = Status
					; 1 = Y
					; 2 = X	decimal
					; 3 = X
					; 4 = Habitacion

					; 0 = 상태
					; 1 = Y
					; 2 = X 소수
					; 3 = X
					; 4 = 방
GiratEnProceso:	# 1
numDoorGira:	# 1

; 7 bytes por puerta
; 게이트당 7바이트
doorGiraData:	# 0DFh			; 0 = Status (bit 0 = Girando, bits 2-1	= altura + 2)
					; 1 = Y
					; 2 = X	decimal
					; 3 = X
					; 4 = Habitacion
					; 5 = Sentido giro
					; 6 = Contador giro

					; 0 = 상태(비트 0 = 회전, 비트 2-1 = 높이 + 2)
					; 1 = Y
					; 2 = X 소수
					; 3 = X
					; 4 = 방
					; 5 = 회전 방향
					; 6 = 카운터 회전
muroTrampProces:# 1
numMuroTrampa:	# 1 			; Numero de muros trampa que hay en la piramide
								; 피라미드의 트랩 벽 수
muroTrampaDat:	# 5*4			; Y, decimales X, X, habitacion
								; Y, 소수 X, X, 방

stackArea:	# 2edh; 301h
stackTop:	# 0
MapaRAMRoot:	# 60h			; La primera fila del mapa no se usa (ocupada por el marcador).	Tambien	usado como inicio de la	pila
								; 지도의 첫 번째 행은 사용되지 않습니다(마커가 점유). 스택의 시작으로 사용됨
MapaRAM:	# 8A0h			; Mapa de las tres posibles habitaciones de la piramide. Cada fila ocupa #60 bytes (#20 * 3)
							; 피라미드의 가능한 세 개의 방의 지도. 각 행은 #60바이트를 차지합니다(#20 * 3).

