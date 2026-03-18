.386

.model	flat, stdcall
option casemap:none

; inclusione file header
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\glmf32.inc
include c:\masm32\include\glu32.inc
include c:\masm32\include\opengl32.inc

; inclusione librerie
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\glmf32.lib
includelib c:\masm32\lib\glu32.lib
includelib c:\masm32\lib\opengl32.lib

; prototipi di funzione per invoke
WinMain		proto :DWORD, :DWORD, :DWORD, :DWORD
CreateGLWindow 	proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WndProc 	proto :HWND, :UINT, :WPARAM, :LPARAM
memset0		proto :DWORD, :DWORD
KillGLWindow 	proto
ReSizeGLScene 	proto :DWORD, :DWORD
InitGL		proto
DrawGLScene 	proto

.data?
hInst	DD ?			; variabile per la memorizzazione dell'istanza del programma
hRC	DWORD ?
hDC	HDC ?
hWnd	HWND ?
keys	DB 256 DUP (?)		; array della tastiera per comodità di indirizzamento usiamo i byte anziché i bit

.data
fullscreen	DB 1	;TRUE
active		DB 1	;TRUE

dmScreenSettings	DEVMODE<>

; stringhe e messaggi d'errore
msg_Fullscreen		db "Ti piacerebbe eseguire in modalita' a schermo intero?", 0
capt_Fullscreen 	db "Inizia a schermo intero?", 0
Titolo			db "NeHe's OpenGL Framework",0
szClassName		db "OpenGL",0
szCGL_Register_Error 	db "Fallita la registrazione della classe della finestra.",0
szErrorCaption		db "ERRORE",0
szNotFullSupp		db "La modalità a schermo intero richiesta non è supportata dalla tua scheda video. Utilizzare invece la modalità a finestra?",0
szNotFullCapt		db "NeHe GL",0
szInClose		db "Il programma verrà ora chiuso.",0
szErrWinCreate  	db "Errore nella creazione della finestra",0
szErrContextGL  	db "Impossibile creare un contesto di dispositivo GL.",0
szErrorPixelFromat 	db "Impossibile trovare un PixelFormat adatto.",0
szErrorSetPixelFormat 	db "Impossibile impostare PixelFormat.",0
szErrorwglCreateContext db "Impossibile creare un contesto di rendering GL.",0
szErrorwglMakeCurrent 	db "Impossibile attivare il contesto di rendering GL.",0
szErrorInitGL		db "Inizializzazione Fallita.",0
szNoFullBoard		db "La modalità a schermo intero richiesta non è supportata dalla",0dh, 0ah, "tua scheda video. Utilizzare invece la modalità a finestra?",0
szRilascioDCRC		db "Rilascio di DC e RC non riuscito.", 0
szCaptionShoutD		db "SPEGNIMENTO CAUSA ERRORE", 0
szRilasciohDC		db "Rilascio contesto dispositivo non riuscito.", 0
szRilasciohWnd		db "Impossibile rilasciare hWnd.", 0
szRilascioClassW 	db "Impossibile annullare la registrazione della classe.", 0
szRilasciohDCehRC 	db "Rilascio di DC e RC non riuscito.",0
szReleaseDC		db "Rilascio contesto dispositivo non riuscito.",0
szDestroyWindow 	db "Impossibile rilasciare hWnd.",0
szUnregisterClass 	db "Impossibile annullare la registrazione della classe.",0

.code

;
; Punto d'ingresso del programm
;
; Qui si creano le condizioni iniziali per l'esecuzione del corpo principale del programma WinMain
start:

	invoke	GetModuleHandle, 0				; ottiene handle del programma
	mov	hInst, eax					; lo memorizza
	invoke	GetCommandLine					; ottiene la riga di comando, anche se non serve in questo programma

	invoke	WinMain, hInst, NULL, eax, SW_SHOWDEFAULT	; chiama WinMain come per il C/C++

	invoke	ExitProcess, 0					; esce a Windows

;
; Corpo principale del programma
;
; Uso il sistema c/c++ per chiarirmi meglio i blocchi del programma
;
WinMain proc hInstance:HINSTANCE, hPrevInstance:HINSTANCE, cmdLine:LPSTR, cmdShow:UINT
local	msg:MSG
local	done:BOOL


	; impostiamo a FALSE in modo che possa ciclare all'infinito
	mov	done, FALSE
	
	; chiediamo all'utente se vuole l'applicazione in finestra o a schermo intero
	invoke	MessageBox, NULL, offset msg_Fullscreen, offset capt_Fullscreen, MB_YESNO or  MB_ICONQUESTION
	cmp	eax, IDNO
	jne	Si_Fullscreen
	
	; scelto di eseguire in finestra
	mov	fullscreen, FALSE

	; per default il programma viene eseguito a schermo intero
Si_Fullscreen:
	xor	eax, eax
	; l'azzeramento di eax con il metodo xor è più veloce del mov al,0 , serve per inserire un valore considerato Byte in una DWord
	mov	al, fullscreen

	; chiamiamo la funzione di generazione della finestra e inizializzazione OpenGL
	; ATTENZIONE qui potete provare se il vostro monitor supporta la modalità schermo intero a 16 bit
	; decommentando il primo CreateGLWindow e commentando il secondo in modalità a 32 bit
	;invoke	CreateGLWindow, addr Titolo, 640, 480, 16, eax		; la lezione originale prevedeva 16 bit di colore
	invoke	CreateGLWindow, addr Titolo, 640, 480, 32, eax		; il mio monitor a schermo intero restituisce errore con 16 bpp
	
	; lavoro compiuto con successo?
	cmp	eax, FALSE
	jne	CreateGLWindow_OK
	
	; no, i messggi di errore sono già stati mostrati, per cui usciamo e basta
	xor	eax, eax
	ret
	
CreateGLWindow_OK:

	; ok, tutto eseguito con successo, possiamo creare il ciclo principale della finestra
	.WHILE done == FALSE
		;preleviamo il messaggio dalla coda
	   	invoke	PeekMessage, ADDR msg, NULL, 0, 0, PM_REMOVE

		;  ci sono messaggi?
	   	cmp	eax, 0
	   	je	No_Message

		; si ci sono messaggi
		; ed è un WM_QUIT?
		cmp 	msg.message, WM_QUIT
		jne	While_not_quit_now

		;si, per cui usciamo
		mov	done, TRUE
		jmp	Next_loop
While_not_quit_now:

		; il messaggio non è WM_QUIT

		; ok, procedi con la funzionalità normale		
		invoke	TranslateMessage, ADDR msg
		invoke	DispatchMessage, ADDR msg
		
		; messaggio elaborato, er cui nuovo ciclo
		jmp	Next_loop

No_Message:

		; senza i messaggi di windows possiamo disegnare la scena
	
		; controlliamo che il programma sia attivo così disegnamo la scena
		cmp	active, FALSE
		je	No_Drawing
	
		;ok il progrmma è attivo

		; prima di disegnare controllamo se è stato premuto il tasto ESC
		mov	eax, VK_ESCAPE
		; controlliamo che la tabella tasti premuti sia segnato il tasto ESC
		cmp	byte ptr [keys+ax], TRUE
		jne	No_ESC_key

		; ESC è stato premuto, quindi usciamo
		mov	done, TRUE
		; nel programma scritto in C era prevista l'uscita No_Drawing
		; con successivo controlli di ulteriori tasti premuti
		; mi sembra inutile visto che usciamo quindi andiamo subito
		; al controllo del WHILE per uscire
		jmp	Next_loop
No_ESC_key:

		; niente tasto ESC quini disegnamo la scena
		invoke	DrawGLScene
		invoke	SwapBuffers, hDC	
No_Drawing:
		; il programma non è attivo o in background, quindi non disegnamo

		; intanto controlliamo altri tasti premuti interessanti

		mov	eax, VK_F1
		; premuto il tasto F1?
		cmp	byte ptr [keys+ax], TRUE
		jne	No_F1_key

		; si F1 è stato premuto, e ora lo mettiamo a FALSE per evitare causi problemi
		mov	byte ptr [keys+ax], FALSE

		; distruggiamo la finestra per fare la commutazione Finestra/schermo intero e viceversa		
		invoke	KillGLWindow

		; prendiamo il valore attuale di fullscreen
		xor	eax, eax
		mov	al, fullscreen

		; e impostiamo la versione contraria all'attuale
		not	al
		and	al,1

		; memorizza il risultato
		mov	fullscreen, al

		; rigenera la finestra con la modifica
		invoke	CreateGLWindow, addr Titolo, 640, 480, 16, eax

		; errore nella creazione della finestra?
		cmp	eax, 0
		jne	No_F1_key

		; si, esce
		ret	

		; no, continua con il prossimo ciclo
No_F1_key:
		; non è stato premuto F1, continuiamo

Next_loop:
		;controllato o modificato tutte le cose che ci interessavamo. Procediamo con un nuovo ciclo
	.ENDW

	;Usciti dal ciclo chiudiamo la finestra e usciamo dal programma
	invoke	KillGLWindow

	; restituiamo l'ultimo valore di ritorno del programma
	mov	eax, msg.wParam	
	ret

WinMain endp

;
; Funzione di creazione della finestra
;
CreateGLWindow proc titolo:DWORD, larg:DWORD, alte:DWORD, bits:DWORD, fulls:DWORD
local	PixelFormat:DWORD
local	wc:WNDCLASS
local	dwExStyle:DWORD
local	dwStyle:DWORD
local	WindowRect:RECT
local	pfd:PIXELFORMATDESCRIPTOR

	; genera la dimensione della finestra
	mov	WindowRect.left, 0		;valore lato sinistro
	mov	eax, larg
	mov	WindowRect.right, eax		; valore destro della finestra
	mov	WindowRect.top, 0		; valore cima della finestra
	mov	eax, alte
	mov	WindowRect.bottom, eax		; valore fondo della fienstra
	mov	eax, fulls		
	mov	fullscreen, al			; memorizza flag fullscreen passato alla funzione
	
	; riempe la struttura Classe della Finestra
	mov	wc.style, CS_HREDRAW or CS_VREDRAW or CS_OWNDC
	mov	wc.lpfnWndProc, WndProc
	mov	wc.cbClsExtra, 0
	mov	wc.cbWndExtra, 0
	push	hInst
	pop	wc.hInstance
	invoke	LoadIcon, NULL, IDI_WINLOGO
	mov	wc.hIcon, eax
	invoke	LoadCursor, NULL, IDC_ARROW
	mov	wc.hCursor, eax
	mov	wc.hbrBackground, NULL
	mov	wc.lpszMenuName, NULL
	mov	wc.lpszClassName, offset szClassName

	; registra la classe della fienstra
	invoke RegisterClass, ADDR wc
	; sopraggiunti errori
	cmp	eax, 0
	jne	RegisterClass_OK
	
	; si, mostra messaggio
	invoke	MessageBox, NULL, offset szCGL_Register_Error, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	; imposta valore FALSE per la creazione della fiestra come sopraggiunto errore
	mov	eax, FALSE
	ret

RegisterClass_OK:
	; registrazione effettuata con successo

	; procediamo con modalità finestra intera?
	cmp	fullscreen, 01
	jne	No_Full_Screen

	; si, procediamo con la finestra intera
	invoke	memset0, ADDR dmScreenSettings, sizeof DEVMODE	;dmScreenSettings			; pulisce la struttura

	mov	dmScreenSettings.dmSize, sizeof DEVMODE	;dmScreenSettings			; memorizza dimensione struttura
	mov	eax, larg
	mov	dmScreenSettings.dmPelsWidth, eax					; larghezza schermo selezionato
	mov	eax, alte
	mov	dmScreenSettings.dmPelsHeight, eax					; altezza schermo selezionato
	mov	eax, bits
	mov	dmScreenSettings.dmBitsPerPel, eax					; bit per pixel selezionato
	mov	dmScreenSettings.dmFields, DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT ;eax

	invoke	ChangeDisplaySettings, ADDR dmScreenSettings, CDS_FULLSCREEN

	; Tutto ok?
	cmp	eax, DISP_CHANGE_SUCCESSFUL
	je	Fix_Style				;siamo a finestra intera e sistemiamo lo stile della finestra

	; no, chiedi di cambiare opzione
	invoke	MessageBox, NULL, offset szNoFullBoard, offset szNotFullCapt, MB_YESNO or MB_ICONEXCLAMATION
	cmp	eax, IDYES
	jne	ChangeDisplay_Error
	
	; ok, opzione a finestra accettata
	mov	fullscreen, FALSE
	jmp	Fix_Style

	; opzione finestra scartata, segnaliamo errore e torniamo al chiamante
ChangeDisplay_Error:
	invoke	MessageBox, NULL, offset szInClose, offset szErrorCaption, MB_OK or MB_ICONSTOP
	mov	eax, FALSE
	ret

Fix_Style:
	; ok, sistemiamo lo stile della finestra
	mov	dwExStyle, WS_EX_APPWINDOW				; stile della finestra esteso
	mov	dwStyle, WS_POPUP					; stile della finestra
	invoke	ShowCursor, FALSE					; nasconde il cursore

	; fin qui nessun errore, saltiamo alla sistemazione della dimensione della finestra
	jmp	AdjustWindow_Rect

	; no, procediamo in modalità finestra
No_Full_Screen:

	mov	dwExStyle, WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
	mov	dwStyle, WS_OVERLAPPEDWINDOW

AdjustWindow_Rect:

	invoke	AdjustWindowRectEx, ADDR WindowRect, dwStyle, FALSE, dwExStyle

	; prende i valori di larghezza in eax e altezza in edx
	mov	eax, WindowRect.right
	sub	eax, WindowRect.left
	mov	edx, WindowRect.bottom
	sub	edx, WindowRect.top

	; salviamo ebx per sicurezza
	push	ebx

	; carichiamo lo stile della finestra
	mov	ebx, dwStyle
	or	ebx, WS_CLIPSIBLINGS 
	or	ebx, WS_CLIPCHILDREN

	; chiediamo a windows di creare la finestra
	invoke	CreateWindowEx, dwExStyle, offset szClassName, offset Titolo, ebx, 0, 0, eax, edx, NULL, NULL, hInst, NULL
	
	; ripristianiamo ebx
	pop	ebx

	; errori nella creazione della finestra?
	cmp	eax, 0
	jne	Window_CreateSuccess
	
	; si, segnaliamo errore

	invoke	KillGLWindow			; chiudiamo la finestra
	invoke	MessageBox, NULL, offset szErrWinCreate, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; nessun errore, continuiamo
Window_CreateSuccess:
	mov 	hWnd,eax			; salviamo l'handle

	mov	eax, sizeof PIXELFORMATDESCRIPTOR
	; pulisce la zona di memoria di pfd per poi inserire i soli valori interessanti
	invoke	memset0, ADDR pfd, eax

	mov [pfd.nSize],ax
	mov [pfd.nVersion],1
	mov [pfd.dwFlags],PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
	mov [pfd.iPixelType],PFD_TYPE_RGBA
	mov eax,bits
	mov [pfd.cColorBits],al
	mov [pfd.cDepthBits],16
	mov [pfd.iLayerType],PFD_MAIN_PLANE
	
	; creiamo in DC a ciu associare PIXELFORMATDESCRIPTOR
	invoke	GetDC, hWnd

	; errore durante la creazione del DC?
	cmp	eax, 0
	jne	GetDC_OK
	
	; si, chiudiamo e segnaliamo l'errore
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrContextGL, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; no, memroiazziamo il DC per le prossime operazioni
GetDC_OK:
	mov	hDC, eax

	; impostiamo il formato pixel
	invoke	ChoosePixelFormat, hDC, ADDR pfd

	; errore durante la scelta del formato pixel?
	cmp	eax, 0
	jne	ChoosePixelFormat_OK

	; si, chiudiamo la finestra e segnaliamo l'errore
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrorPixelFromat, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; no, proviamo a impostate il pixel format scelto
ChoosePixelFormat_OK:

	mov PixelFormat,eax			; salviamo il Pixel Format

	; probabile bug con il debugger (OllyDebug), usare il registro edx per usare PixelFormat 
	; nella funzione SetPixelFormat in caso diretto (con eax) non funziona 
	mov	edx, eax
	invoke	SetPixelFormat, hDC, edx, ADDR pfd

	; errore nell'impostazione del formato pixel?
	cmp	eax, 0
	jne	SetPixelFormat_OK

	; si, chiudiamo la finestra e segnaliamo l'errore 
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrorSetPixelFormat, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	;no, andato tutto bene
SetPixelFormat_OK:

	; creiamo il rendering context
	invoke	wglCreateContext, hDC
	mov 	hRC, eax				; ATTENZIONE mi ero scordati di salvare il valore

	; errore nel richiamare il rendering context?
	cmp	eax, 0
	jne	WglCreateContext_OK

	; si, chiudiamo la finestra e segnaliamo l'errore 
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrorwglCreateContext, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; no, context creato
WglCreateContext_OK:

	; proviamo ad attivarlo
	invoke	wglMakeCurrent, hDC, hRC

	; errore durante l'attivazione del rendering context?
	cmp	eax, 0
	jne	WglMakeCurrent_OK

	; si, chiudi finestra e segnaliamo l'errore
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrorwglMakeCurrent, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; no, rendering context attivato
WglMakeCurrent_OK:

	; mostriamo la finestra, e la attiva
	invoke	ShowWindow, hWnd, SW_SHOW
	invoke	SetForegroundWindow, hWnd	; aumenta la priorità della finestra leggermente
	invoke	SetFocus, hWnd

	; ridimensioniamo la finestra
	invoke	ReSizeGLScene, larg, alte

	; inizializza OpenGL
	invoke	InitGL

	; errore nell'inizializzazione?
	cmp	eax, 0
	jne	InitGL_OK

	; si, chiudiamo la finestra e usciamo
	invoke	KillGLWindow
	invoke	MessageBox, NULL, offset szErrorInitGL, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	mov	eax, FALSE
	ret

	; no, inizializzazione completata
InitGL_OK:
	; andato tutto bene e restituiamo TRUE per conferma al chiamante
	mov	eax, TRUE
	ret

CreateGLWindow endp

;
; Procedura gestione messaggi
; Qui gestiamo i messaggi che interessano al programma, gli altri li giriamo a windows
;
WndProc proc  hwnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	.IF uMsg == WM_ACTIVATE
		; controlla che l'applicazione minimizzata
		mov	eax, wParam
		shr	eax, 16
		and	eax, 0000ffffh
		; è attiva (non minimizzata)?
		cmp	eax, 0
		je	Active_Yes

		; no, salviamo lo stato attivazione
		mov	active, FALSE
		jmp	WM_ACTIVATE_Exit

Active_Yes:
		; si, salviamo lo stato attivazione
		mov	active, TRUE

WM_ACTIVATE_Exit:
		; torniamo al ciclo messaggi
		xor	eax, eax
		ret

	.ELSEIF uMsg == WM_SYSCOMMAND
		; lo screeen saver prova a partire?
		.IF wParam == SC_SCREENSAVE
			; per ora nessuna operazione
			xor	eax, eax
			ret
			
		; il monitor prova ad entrare in powersave?
		.ELSEIF wParam == SC_MONITORPOWER
			; per ora nessuna operazione
			xor	eax, eax
			ret
		.ENDIF		

	; ricevuto messaggio di chiusura?		
	.ELSEIF uMsg == WM_CLOSE
		; invia messaggio di chisura applicazione
		invoke	PostQuitMessage, 0
		xor	eax, eax
		ret

	; premuto un tasto?
	.ELSEIF uMsg == WM_KEYDOWN
		; prende il valore del tasto come indice nell'array
		mov	eax, wParam
		; e lo mette a true
		mov	byte ptr [keys+ax], TRUE

		; ed esce
		xor	eax, eax
		ret

	; rilasciato un tasto?
	.ELSEIF uMsg == WM_KEYUP
		; prende il valore del tasto come indice nell'array
		mov	eax, wParam
		; e lo mette a false
		mov	byte ptr [keys+ax], FALSE

		; ed esce
		xor	eax, eax
		ret	
	
	; richiesta di ridimensionamento della finestra?
	.ELSEIF uMsg == WM_SIZE
		; in lParam LOWORD = larghezza, HIWORD = altezza
		mov	eax, lParam
		mov	edx, eax
		shr	eax, 16
		and	edx, 0000ffffh
		; ridimensiona la finestra
		invoke	ReSizeGLScene,  edx, eax
		xor	eax, eax
		ret
	.ENDIF

	; messaggi non elaborati da noi ci pensa windows
	invoke	DefWindowProc, hwnd, uMsg, wParam, lParam
	ret
WndProc endp

;
; Funzione di riempimento della memoria con valore 0
;
memset0 proc Dest:DWORD, Dim:DWORD
	mov	edi, Dest
	mov	ecx, Dim

	mov	al, 0
	rep	stosb

	xor	eax, eax
	ret
memset0	endp

;
; Funzione di chiusura della finestra OpenGL
; 	distrugge la finestra a modino
;
KillGLWindow proc
	cmp	fullscreen, TRUE			; modalità schermo intero?
	jne	KGW_NOT_fullscreen			; no, salta oltre
	
	invoke	ChangeDisplaySettings, NULL, 0		; si, torna alla modalità Desktop
	invoke	ShowCursor, TRUE			; mostra il puntatore del mouse

KGW_NOT_fullscreen:
	; sistemato la modalità video

	cmp	hRC, 0					; Rendering Context presente?
	je	KGW_NOT_hRC				; no, salta oltre

	invoke	wglMakeCurrent,NULL, NULL		; si, Siamo in grado di rilasciare i contesti DC e RC?
	cmp	eax, FALSE				; errore nel rilascio?
	jne	KGW_NOT_Need_wglMakeCurrent_Error	; no, continua senza errori

	invoke	MessageBox, NULL, offset szRilasciohDCehRC, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION

KGW_NOT_Need_wglMakeCurrent_Error:
	mov	hRC, NULL				; imposta RC a NULL

KGW_NOT_hRC:
	; sistemato hRC

	cmp	hDC, 0					; abbiamo salvato la hDC? 
	je	KGW_NOT_hDC				; no, quindi continua con la chiusura

	invoke	ReleaseDC, hWnd, hDC			; si, Siamo in grado di rilasciare la DC?
	cmp	eax, 0					; errore nel rilascio?
	jne	KGW_NOT_hDC				; no, continua
	
	; si trovato errore e lo segnala
	invoke	MessageBox, NULL, offset szReleaseDC, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
	mov	hDC, NULL
	
KGW_NOT_hDC:
	; sistemato hDC
 
	cmp	hWnd, 0					; c'è l'handle della finestra?
	je	KGW_NOT_hWnd				; no, continua con la chiusura

	invoke	DestroyWindow, hWnd			; si, chiude la finestra
	cmp	eax, 0					; errore?
	jne	KGW_NOT_hWnd				; no, continua

	; si trovato errore e lo segnala
	invoke	MessageBox, NULL, offset szDestroyWindow, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
	mov	hWnd, NULL
	
KGW_NOT_hWnd:
	; sistemato hWnd

	invoke	UnregisterClass, ADDR szClassName, hInst	; Possiamo annullare la registrazione della lezione
	cmp	eax, 0					; errore?
	jne	KGW_Unregister_OK			; nessun errore continua

	; si trovato errore e lo segnala
	invoke	MessageBox, NULL, offset szUnregisterClass, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
	mov	hInst, NULL

KGW_Unregister_OK:
	ret
KillGLWindow endp

;
; Funzione di ridimensionamento della finestra tramite le librerie di OpenGL
;
ReSizeGLScene proc larg:DWORD, alte:DWORD
Local	fovy:REAL8
Local	aspect:REAL8
Local	zNear:REAL8
Local	zFar:REAL8

	; l'altezza è 0?
	cmp	alte, 0
	jne	No_Fix_0_DIVIDE

	; si, mettiamo a 1 per evitare l'errore divisione per 0
	mov	alte, 1

	; no, possiamo calcolare con precisione l'aspect ratio della finestra	
No_Fix_0_DIVIDE:

	invoke	glViewport, 0, 0, larg, alte		; resetta il viewport corrente

	invoke	glMatrixMode, GL_PROJECTION		; seleziona la matrice di proiezione
	invoke	glLoadIdentity				; resetta la matrice di proiezione

	;calcola aspect ratio della finestra
	
	; prepara il primo parametro
	mov 	eax, 45					; convertiamo 45 in 45.0f
	push 	eax					; salva sullo stack
	fild 	dword ptr [esp]				; prende il numero sul x87 dallo stack senza estrazione
	fstp	fovy					; lo salva sul parametro sullo stack
	pop	eax					; estrae il numero salvato precedentemente

	; prepara il secondo parametro	
	fld	alte					; carica l'altezza nel registro ST(0)
							; con la prossima istruzione passerà a ST(1)
	fld	larg					; carica la larghezza nel registro ST(0)
	fdiv	ST, ST(1)				; larghezza [ST(0)] / altezza [ST(1)]
	fstp	aspect					; memorizza il risultato estraendolo dal 
							; registro nella variabile sullo stack
	
	; prepara il terzo parametro
	mov 	eax, 10					; mettiamo in eax e poi sullo stack il valore 10 (divisore)
	push 	eax
	fild	dword ptr [esp]				; lo mettiamo nel registro ST(0) che diventerà ST(1) al prossimo caricamento
	pop	eax					; rimuoviamo il valore dallo stack
	mov	eax, 1					; carichiamo il valore del dividendo 
	push	eax					; sullo stack
	fild	dword ptr [esp]				; e lo carichiamo sul registro ST(0)
	fdiv	ST, ST(1)				; 1 / 10 = 0.1f che è il parametro che vogliamo usare nella funzione OpenGL
	fstp	zNear					; e lo memorizza nella variabile sullo stack a 64 bit
	pop	eax

	; prepariamo il quarto edultimo parametro
	mov 	eax,100					; meno lavoro perché il secondo parametro è 100.0f
	push 	eax					; come per i precedenti passiamo dallo stack
	fild 	dword ptr [esp]				; caricato nel registro ST(0) del x87 questo diventa in automatico 100.0f
	fstp	zFar					; che salviamo nella variabile temporanea sullo stack
	pop	eax					; accertiamoci di eliminare il valore dallo stack
	
	
	; ho deciso di utilizzare l'assembly a 32 bit, per i 64 bit sono ancora il fase iniziale di studio
	mov	eax, DWORD ptr [zFar]			; per ogni valore salviamo sullo stack prima il valore 32 bit basso 
	push	eax					; poi quello alto
	mov	eax, DWORD ptr [zFar+4]			
	push	eax
	mov	eax, DWORD ptr [zNear]
	push	eax
	mov	eax, DWORD ptr [zNear+4]
	push	eax
	mov	eax, DWORD ptr [aspect]
	push	eax
	mov	eax, DWORD ptr [aspect+4]
	push	eax
	mov	eax, DWORD ptr [fovy]
	push	eax
	mov	eax, DWORD ptr [fovy+4]
	push	eax
	call	gluPerspective				; chiamiamo la funzione OpenGL

	; ora selezioniamo la matrice GL_MODELVIEW e con glLoadIdentity la salviamo all'interno di OpenGL
	invoke	glMatrixMode, GL_MODELVIEW
	invoke	glLoadIdentity
	
	ret

ReSizeGLScene endp

;
; Funzione di inizializzazione OpenGL
;
InitGL 	proc
local	Zero:REAL4
local	Uno:REAL4

	invoke	glShadeModel, GL_SMOOTH			; abilita lo smooth shading

	; glClearColor(0.0f, 0.0f, 0.0f, 0.0f) 
    	; 4 parametri da 32-bit (float). Lo zero è uguale sia in int che in float.
    	invoke	glClearColor, 0, 0, 0, 0

    	; glClearDepth(1.0) 
    	; ATTENZIONE: vuole un DOUBLE (64-bit). 
    	; Il valore esadecimale per 1.0 (64-bit) è 3FF0000000000000h
	; meglio usare la call
    	push 3FF00000h ; Parte alta
    	push 0         ; Parte bassa
    	call glClearDepth
	
	invoke	glEnable, GL_DEPTH_TEST			; abilita il test di profondità
	invoke	glDepthFunc, GL_LEQUAL			; fa il tipo di test di profondità
	invoke	glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST	; calcola la prospettiva davvero carina
	
	mov	eax, TRUE				; restituisce tutto ok
	ret
InitGL 	endp

;
; Funzione di disegno della finestra
;
DrawGLScene	proc
	invoke	glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT	; pulisce lo schermo e depth buffer
	invoke	glLoadIdentity						; resetta la matrice Modelview corrente
	
	mov	eax, TRUE						; restituisce tutto ok
	ret
DrawGLScene	endp

end start