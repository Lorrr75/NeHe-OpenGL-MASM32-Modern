.386

.model    flat, stdcall
option casemap:none

; Include header files
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\glmf32.inc
include c:\masm32\include\glu32.inc
include c:\masm32\include\opengl32.inc

; library inclusions
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\glmf32.lib
includelib c:\masm32\lib\glu32.lib
includelib c:\masm32\lib\opengl32.lib

; function prototypes for invoke
WinMain        	proto :DWORD, :DWORD, :DWORD, :DWORD
CreateGLWindow 	proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WndProc     	proto :HWND, :UINT, :WPARAM, :LPARAM
memset0        	proto :DWORD, :DWORD
KillGLWindow    proto
ReSizeGLScene   proto :DWORD, :DWORD
InitGL        	proto
DrawGLScene     proto

.data?
hInst   DD ?            ; variable for storing the program instance
hRC    	DWORD ?
hDC    	HDC ?
hWnd    HWND ?
keys    DB 256 DUP (?)		; keyboard array; for ease of addressing, we use bytes instead of bits

.data
fullscreen    DB 1    ;TRUE
active        DB 1    ;TRUE

dmScreenSettings    DEVMODE<>

; strings and error messages
msg_Fullscreen  	db "Would you like to run in full-screen mode?", 0
capt_Fullscreen 	db "Start in full-screen mode?", 0
Title        		db "NeHe's OpenGL Framework", 0
szClassName    		db "OpenGL", 0
szCGL_Register_Error 	db "Failed to register the window class.", 0
szErrorCaption        	db "ERROR",0
szNotFullSupp        	db "The requested full-screen mode is not supported by your video card. Would you like to use windowed mode instead?",0
szNotFullCapt        	db "NeHe GL",0
szInClose        	db "The program will now close.",0
szErrWinCreate      	db "Error creating window",0
szErrContextGL      	db "Unable to create a GL device context.",0
szErrorPixelFormat     	db "Unable to find a suitable PixelFormat.",0
szErrorSetPixelFormat   db "Unable to set PixelFormat.",0
szErrorwglCreateContext db "Unable to create a GL rendering context.",0
szErrorwglMakeCurrent   db "Unable to activate the GL rendering context.",0
szErrorInitGL        	db "Initialization failed.",0
szNoFullBoard        	db "The requested full-screen mode is not supported by",0dh, 0ah, "your video card. Use windowed mode instead?",0
szRilascioDCRC        	db "Failed to release DC and RC.", 0
szCaptionShoutD        	db "SHUTDOWN DUE TO ERROR", 0
szRilasciohDC        	db "Device context release failed.", 0
szRilasciohWnd        	db "Unable to release hWnd.", 0
szRilascioClassW     	db "Unable to unregister the class.", 0
szRilasciohDCehRC     	db "DC and RC release failed. ",0
szReleaseDC        	db "Device context release failed.",0
szDestroyWindow     	db "Unable to release hWnd.",0
szUnregisterClass     	db "Unable to unregister class.",0

.code

;
; Program entry point
;
; Here, the initial conditions are set for executing the main body of the WinMain program
start:

    	invoke GetModuleHandle, 0                	 ; retrieves the program handle
    	mov    hInst, eax                    		 ; stores it
    	invoke GetCommandLine                    	 ; retrieves the command line, even though it is not needed in this program

    	invoke WinMain, hInst, NULL, eax, SW_SHOWDEFAULT ; calls WinMain as in C/C++

    	invoke ExitProcess, 0                    	 ; exits to Windows

;
; Main body of the program
;
; I'm using the C/C++ syntax to better illustrate the program's structure
;
WinMain	proc hInstance:HINSTANCE, hPrevInstance:HINSTANCE, cmdLine:LPSTR, cmdShow:UINT
local   msg:MSG
local   done:BOOL


    	; Set to FALSE so it can loop indefinitely
    	mov    done, FALSE
	
	; Ask the user if they want the application in windowed or full-screen mode
    	invoke MessageBox, NULL, offset msg_Fullscreen, offset capt_Fullscreen, MB_YESNO or  MB_ICONQUESTION
    	cmp    eax, IDNO
    	jne    Si_Fullscreen
    
    	; Chose to run in windowed mode
    	mov    fullscreen, FALSE

	; By default, the program runs in full-screen mode
Si_Fullscreen:
    	xor    eax, eax
    	; Clearing eax using the XOR method is faster than `mov al, 0`
	; this is used to store a byte-sized value in a DWord
    	mov    al, fullscreen

    	; Call the function to create the window and initialize OpenGL
	; NOTE: Here you can test whether your monitor supports 16-bit full-screen mode
    	; by uncommenting the first CreateGLWindow and commenting out the second in 32-bit mode
    	;invoke CreateGLWindow, addr Title, 640, 480, 16, eax        ; the original lesson specified 16-bit color
    	invoke CreateGLWindow, addr Title, 640, 480, 32, eax        	; My full-screen monitor is displaying an error with 16 bpp
    
    	; was the operation successful?
    	cmp    eax, FALSE
    	jne    CreateGLWindow_OK

	; no, the error messages have already been displayed, so we'll just exit
    	xor    eax, eax
    	ret
    
CreateGLWindow_OK:

    	; ok, everything executed successfully, we can create the window's main loop
	.WHILE done == FALSE
        ; retrieve the message from the queue
        	invoke	PeekMessage, ADDR msg, NULL, 0, 0, PM_REMOVE

        	; are there any messages?
           	cmp    	eax, 0
           	je    	No_Message

		; yes, there are messages
        	; and is it a WM_QUIT?
        	cmp     msg.message, WM_QUIT
        	jne    	While_not_quit_now

        	;yes, so we exit
        	mov    done, TRUE
        	jmp    Next_loop
While_not_quit_now:
		; the message is not WM_QUIT

        	; OK, proceed with normal functionality        
        	invoke   TranslateMessage, ADDR msg
        	invoke   DispatchMessage, ADDR msg
        
        	; message processed, so start a new loop
        	jmp    	Next_loop

No_Message:

        	; without Windows messages, we can draw the scene
    
        	; check that the program is active so we can draw the scene
        	cmp    active, FALSE
        	je    	No_Drawing
    
        	; ok, the program is active

		; Before drawing, we check if the ESC key has been pressed
        	mov	eax, VK_ESCAPE
        	; We check if the ESC key is marked in the key press table
        	cmp    	byte ptr [keys+ax], TRUE
        	jne    	No_ESC_key

		; ESC has been pressed, so we exit
        	mov    	done, TRUE
        	; in the C program, the No_Drawing exit was provided
        	; with subsequent checks for additional pressed keys
        	; this seems unnecessary to me since we're exiting, so we go straight
        	; to the WHILE loop check to exit
        	jmp    	Next_loop
No_ESC_key:

		; No ESC key, so let's draw the scene
        	invoke 	DrawGLScene
        	invoke	SwapBuffers, hDC    
No_Drawing:
        	; The program is not active or is running in the background, so we don't draw

        	; In the meantime, let's check for other interesting key presses

		mov    	eax, VK_F1
        	; Was the F1 key pressed?
        	cmp    	byte ptr [keys+ax], TRUE
        	jne    	No_F1_key

        	; If F1 was pressed, we now set it to FALSE to avoid causing problems
        	mov    	byte ptr [keys+ax], FALSE

		; destroy the window to toggle between windowed and full-screen mode and vice versa        
        	invoke	KillGLWindow

        	; get the current value of fullscreen
       		xor    	eax, eax
        	mov    	al, fullscreen

		; and set the complement of the current value
        	not    	al
        	and    	al,1

		; store the result
        	mov    	fullscreen, al

        	; redraw the window with the change
        	invoke  CreateGLWindow, addr Title, 640, 480, 16, eax

        	; error creating the window?
        	cmp    	eax, 0
        	jne    	No_F1_key

		; yes, exit
        	ret    

        	; no, continue with the next loop
No_F1_key:
        	; F1 was not pressed, continue

Next_loop:
        	; checked or modified everything we were interested in. Proceed with a new loop
    	.ENDW

	;After exiting the loop, we close the window and exit the program
    	invoke    KillGLWindow

    	; Return the program's last return value
    	mov    eax, msg.wParam    
    	ret
WinMain endp

;
; Window creation function
;
CreateGLWindow proc title:DWORD, width:DWORD, height:DWORD, bits:DWORD, fulls:DWORD
local	PixelFormat:DWORD
local   wc:WNDCLASS
local   dwExStyle:DWORD
local   dwStyle:DWORD
local   WindowRect:RECT
local   pfd:PIXELFORMATDESCRIPTOR

	; sets the window dimensions
    	mov	WindowRect.left, 0        ; left side value
    	mov    	eax, width
    	mov    	WindowRect.right, eax        ; right side value
    	mov    	WindowRect.top, 0        ; top value
    	mov    	eax, height
	mov    	WindowRect.bottom, eax        ; bottom value of the window
    	mov    	eax, fulls        
    	mov    	fullscreen, al            ; stores the fullscreen flag passed to the function
    
    	; fills the Window Class structure
    	mov    	wc.style, CS_HREDRAW or CS_VREDRAW or CS_OWNDC
	mov    	wc.lpfnWndProc, WndProc
    	mov    	wc.cbClsExtra, 0
    	mov    	wc.cbWndExtra, 0
    	push    hInst
    	pop    	wc.hInstance
    	invoke  LoadIcon, NULL, IDI_WINLOGO
	mov    	wc.hIcon, eax
    	invoke  LoadCursor, NULL, IDC_ARROW
    	mov    	wc.hCursor, eax
    	mov    	wc.hbrBackground, NULL
    	mov    	wc.lpszMenuName, NULL
    	mov    	wc.lpszClassName, offset szClassName

	; register the window class
    	invoke 	RegisterClass, ADDR wc
    	; errors occurred
    	cmp    	eax, 0
    	jne    	RegisterClass_OK
    
    	; yes, display a message
    	invoke  MessageBox, NULL, offset szCGL_Register_Error, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
	; set the window creation value to FALSE due to the error
   	mov 	eax, FALSE
    	ret

RegisterClass_OK:
    	; registration successful

    	; proceed in full-screen mode?
    	cmp    fullscreen, 01
    	jne    No_Full_Screen

	; yes, proceed with full-screen mode
    	invoke	memset0, ADDR dmScreenSettings, sizeof DEVMODE    ;dmScreenSettings            ; clears the structure

    	mov	dmScreenSettings.dmSize, sizeof DEVMODE    ;dmScreenSettings            ; stores structure size
    	mov    	eax, width
	mov    	dmScreenSettings.dmPelsWidth, eax                    ; selected screen width
    	mov    	eax, height
    	mov    	dmScreenSettings.dmPelsHeight, eax                    ; selected screen height
    	mov    	eax, bits
    	mov    	dmScreenSettings.dmBitsPerPel, eax					; selected bits per pixel
    	mov    	dmScreenSettings.dmFields, DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT ;eax

	invoke    ChangeDisplaySettings, ADDR dmScreenSettings, CDS_FULLSCREEN

    	; Everything OK?
    	cmp    	eax, DISP_CHANGE_SUCCESSFUL
    	je    	Fix_Style                ; We're in full-screen mode, so let's adjust the window style

	; no, ask to change option
    	invoke  MessageBox, NULL, offset szNoFullBoard, offset szNotFullCapt, MB_YESNO or MB_ICONEXCLAMATION
    	cmp    	eax, IDYES
    	jne    	ChangeDisplay_Error
    
    	; ok, windowed mode accepted
    	mov    	fullscreen, FALSE
	jmp    	Fix_Style

    	; window option rejected, report error and return to caller
ChangeDisplay_Error:
    	invoke  MessageBox, NULL, offset szInClose, offset szErrorCaption, MB_OK or MB_ICONSTOP
    	mov    	eax, FALSE
    	ret

Fix_Style:
    	; OK, let's set the window style
    	mov    	dwExStyle, WS_EX_APPWINDOW                ; extended window style
    	mov    	dwStyle, WS_POPUP                    ; window style
    	invoke  ShowCursor, FALSE                    ; hides the cursor

	; no errors so far, let's move on to adjusting the window size
    	jmp    	AdjustWindow_Rect

    	; no, let's proceed in windowed mode
No_Full_Screen:

    	mov    	dwExStyle, WS_EX_APPWINDOW or WS_EX_WINDOWEDGE
    	mov    	dwStyle, WS_OVERLAPPEDWINDOW

AdjustWindow_Rect:

    	invoke  AdjustWindowRectEx, ADDR WindowRect, dwStyle, FALSE, dwExStyle

    	; stores the width value in eax and the height value in edx
    	mov    	eax, WindowRect.right
    	sub    	eax, WindowRect.left
	mov    	edx, WindowRect.bottom
    	sub    	edx, WindowRect.top

    	; save ebx for safety
    	push    ebx

    	; load the window style
    	mov    	ebx, dwStyle
    	or    	ebx, WS_CLIPSIBLINGS 
    	or    	ebx, WS_CLIPCHILDREN

	; ask Windows to create the window
    	invoke	CreateWindowEx, dwExStyle, offset szClassName, offset Title, ebx, 0, 0, eax, edx, NULL, NULL, hInst, NULL
    
    	; restore ebx
    	pop    	ebx

    	; were there any errors creating the window?
    	cmp    	eax, 0
	jne    	Window_CreateSuccess
    
    	; yes, report error

    	invoke  KillGLWindow            	; close the window
    	invoke  MessageBox, NULL, offset szErrWinCreate, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov    	eax, FALSE
	ret

    	; no error, continue
Window_CreateSuccess:
    	mov     hWnd,eax            		; save the handle

	mov    	eax, sizeof PIXELFORMATDESCRIPTOR
    	; clears the pfd memory area to insert only the relevant values
    	invoke  memset0, ADDR pfd, eax

	mov 	[pfd.nSize], ax
    	mov 	[pfd.nVersion], 1
    	mov 	[pfd.dwFlags], PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
    	mov 	[pfd.iPixelType] ,PFD_TYPE_RGBA
	mov 	eax, bits
    	mov 	[pfd.cColorBits], al
    	mov 	[pfd.cDepthBits], 16
    	mov 	[pfd.iLayerType], PFD_MAIN_PLANE
    
    	; create a DC to associate with the PIXELFORMATDESCRIPTOR
    	invoke  GetDC, hWnd

	; error during DC creation?
    	cmp     eax, 0
    	jne     GetDC_OK
    
    	; yes, close it and report the error
    	invoke  KillGLWindow
    	invoke  MessageBox, NULL, offset szErrContextGL, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov     eax, FALSE
	ret

    	; no, store the DC in memory for future operations
GetDC_OK:
    	mov     hDC, eax

	; set the pixel format
    	invoke  ChoosePixelFormat, hDC, ADDR pfd

    	; error while selecting the pixel format?
    	cmp     eax, 0
    	jne     ChoosePixelFormat_OK

    	; yes, close the window and report the error
    	invoke  KillGLWindow
	invoke  MessageBox, NULL, offset szErrorPixelFormat, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov     eax, FALSE
    	ret

    	; no, let's try to set the selected pixel format
ChoosePixelFormat_OK:

    	mov 	PixelFormat,eax            	; save the Pixel Format

	; probable bug with the debugger (OllyDebug); use the edx register to set PixelFormat 
    	; in the SetPixelFormat function; the direct method (with eax) does not work 
    	mov    	edx, eax
    	invoke  SetPixelFormat, hDC, edx, ADDR pfd

    	; error setting the pixel format?
	cmp     eax, 0
    	jne     SetPixelFormat_OK

    	; yes, close the window and report the error 
    	invoke  KillGLWindow
    	invoke  MessageBox, NULL, offset szErrorSetPixelFormat, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov    	eax, FALSE
    	ret

	;no, everything went well
SetPixelFormat_OK:

    	; let's create the rendering context
    	invoke	wglCreateContext, hDC
    	mov     hRC, eax                	; WARNING: I forgot to save the value

    	; error retrieving the rendering context?
    	cmp    	eax, 0
    	jne    	WglCreateContext_OK
	
	; yes, close the window and report the error 
    	invoke  KillGLWindow
    	invoke  MessageBox, NULL, offset szErrorwglCreateContext, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
   	mov    	eax, FALSE
    	ret

    	; no, context created
WglCreateContext_OK:

	; let's try to activate it
    	invoke	wglMakeCurrent, hDC, hRC

    	; error while activating the rendering context?
    	cmp    	eax, 0
    	jne    	WglMakeCurrent_OK

    	; yes, close the window and report the error
    	invoke  KillGLWindow
	invoke  MessageBox, NULL, offset szErrorwglMakeCurrent, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov    	eax, FALSE
    	ret

    	; no, rendering context activated
WglMakeCurrent_OK:

    	; display the window and bring it to the foreground
    	invoke  ShowWindow, hWnd, SW_SHOW
	invoke  SetForegroundWindow, hWnd    	; slightly increase the window's priority
    	invoke  SetFocus, hWnd

    	; resize the window
    	invoke  ReSizeGLScene, width, height

    	; initialize OpenGL
    	invoke  InitGL

    	; initialization error?
	cmp    	eax, 0
    	jne    	InitGL_OK

    	; yes, close the window and exit
    	invoke  KillGLWindow
    	invoke  MessageBox, NULL, offset szErrorInitGL, offset szErrorCaption, MB_OK or MB_ICONEXCLAMATION
    	mov    	eax, FALSE
	ret

    	; no, initialization complete
InitGL_OK:
    	; everything went well, so we return TRUE to the caller for confirmation
    	mov    	eax, TRUE
    	ret

CreateGLWindow endp

;
; Message handling procedure
; Here we handle the messages relevant to the program; the others are passed on to Windows
;
WndProc proc  hwnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	.IF uMsg == WM_ACTIVATE
        	; check if the minimized application
        	mov	eax, wParam
        	shr    	eax, 16
        	and    	eax, 0000ffffh
        	; is active (not minimized)?
        	cmp    	eax, 0
        	je    	Active_Yes

		; no, save the activation state
        	mov    	active, FALSE
        	jmp    	WM_ACTIVATE_Exit

Active_Yes:
        	; yes, save the activation state
        	mov    	active, TRUE

WM_ACTIVATE_Exit:
        	; return to the message loop
        	xor    	eax, eax
        	ret

	.ELSEIF uMsg == WM_SYSCOMMAND
        	; Is the screen saver trying to start?
        	.IF wParam == SC_SCREENSAVE
            		; No action for now
            		xor	eax, eax
            		ret
            
        	; Is the monitor trying to enter power-saving mode?
		.ELSEIF wParam == SC_MONITORPOWER
            		; no action for now
            		xor    	eax, eax
            		ret
        	.ENDIF		

	; Did I receive a close message?        
    	.ELSEIF uMsg == WM_CLOSE
        	; Send application close message
        	invoke	PostQuitMessage, 0
        	xor    	eax, eax
        	ret

	; Was a key pressed?
	.ELSEIF uMsg == WM_KEYDOWN
        	; takes the key value as an index into the array
        	mov	eax, wParam
        	; and sets it to true
        	mov    	byte ptr [keys+ax], TRUE

        	; and exits
        	xor    	eax, eax
        	ret

    	; key released?
	.ELSEIF uMsg == WM_KEYUP
        	; takes the key value as an index into the array
        	mov    	eax, wParam
        	; and sets it to false
        	mov    	byte ptr [keys+ax], FALSE

        	; and exits
        	xor    	eax, eax
        	ret	

	; Window resize request?
    	.ELSEIF uMsg == WM_SIZE
        	; In lParam: LOWORD = width, HIWORD = height
        	mov    	eax, lParam
        	mov    	edx, eax
        	shr    	eax, 16
		and    	edx, 0000ffffh
        	; resize the window
        	invoke  ReSizeGLScene,  edx, eax
        	xor    	eax, eax
        	ret
    	.ENDIF

    	; Windows handles messages not processed by us
    	invoke	DefWindowProc, hwnd, uMsg, wParam, lParam
	ret
WndProc endp

;
; Function to fill memory with the value 0
;
memset0 proc Dest:DWORD, Dim:DWORD
    	mov   	edi, Dest
    	mov    	ecx, Dim

    	mov    	al, 0
    	rep    	stosb

    	xor    	eax, eax
    	ret	
memset0    endp


;
; Function to close the OpenGL window
;     properly destroys the window
;
KillGLWindow proc
    	cmp    	fullscreen, TRUE            	; full-screen mode?
    	jne    	KGW_NOT_fullscreen            	; no, skip ahead
	
	invoke  ChangeDisplaySettings, NULL, 0  ; yes, return to desktop mode
    	invoke  ShowCursor, TRUE            	; show the mouse pointer

KGW_NOT_fullscreen:
    	; cleared video mode

    	cmp    	hRC, 0                    	; Rendering Context present?
	je    	KGW_NOT_hRC                	; no, skip ahead

    	invoke  wglMakeCurrent,NULL, NULL       ; yes, can we release the DC and RC contexts?
    	cmp    	eax, FALSE                	; error releasing?
    	jne    	KGW_NOT_Need_wglMakeCurrent_Error    ; no, continue without errors

	invoke  MessageBox, NULL, offset szRilasciohDCehRC, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION

KGW_NOT_Need_wglMakeCurrent_Error:
    	mov    	hRC, NULL                	; set RC to NULL

KGW_NOT_hRC:
    	; cleared hRC

	cmp    	hDC, 0                    	; Did we save the hDC? 
    	je    	KGW_NOT_hDC                	; No, so continue with closing

    	invoke  ReleaseDC, hWnd, hDC            ; Yes, can we release the DC?
    	cmp    	eax, 0                    	; Error releasing?
	jne    	KGW_NOT_hDC                	; no, continue
    
    	; an error was found and is being reported
    	invoke  MessageBox, NULL, offset szReleaseDC, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
    	mov    	hDC, NULL
    
KGW_NOT_hDC:
    	; cleared hDC
 
	cmp    	hWnd, 0                    	; is the window handle present?
    	je    	KGW_NOT_hWnd                	; no, continue with closing

    	invoke  DestroyWindow, hWnd            	; yes, close the window
    	cmp    	eax, 0                    	; error?
	jne    	KGW_NOT_hWnd                	; no, continue

    	; an error was found and is reported
    	invoke  MessageBox, NULL, offset szDestroyWindow, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
    	mov    	hWnd, NULL
	
KGW_NOT_hWnd:
    	; cleared hWnd

    	invoke  UnregisterClass, ADDR szClassName, hInst    ; We can unregister the class
    	cmp    	eax, 0                    	; error?
	jne    	KGW_Unregister_OK            	; no error, continue

    	; an error was found and is reported
    	invoke  MessageBox, NULL, offset szUnregisterClass, offset szCaptionShoutD, MB_OK or MB_ICONINFORMATION
    	mov    	hInst, NULL

KGW_Unregister_OK:
    	ret
KillGLWindow endp

;
; Window resizing function using OpenGL libraries
;
ReSizeGLScene proc larg:DWORD, alte:DWORD
Local	fovy:REAL8
Local   aspect:REAL8
Local   zNear:REAL8
Local   zFar:REAL8

    	; Is the height 0?
    	cmp    	alte, 0
	jne    	No_Fix_0_DIVIDE

    	; yes, set to 1 to avoid a division-by-zero error
    	mov    	height, 1

    	; no, we can accurately calculate the window's aspect ratio    
No_Fix_0_DIVIDE:

    	invoke  glViewport, 0, 0, width, height	; resets the current viewport

	invoke  glMatrixMode, GL_PROJECTION     ; selects the projection matrix
    	invoke  glLoadIdentity                	; resets the projection matrix

    	; calculates the window's aspect ratio
    
    	; prepares the first parameter
    	mov   	eax, 45                    	; convert 45 to 45.0f
	push    eax                    		; save to the stack
    	fild    dword ptr [esp]                	; fetch the number from the x87 register onto the stack without extraction
    	fstp    fovy                    	; save it to the parameter on the stack
    	pop    	eax                    		; retrieve the previously saved number

	; prepare the second parameter    
    	fld    	height                    	; load the height into register ST(0)
                            			; the next instruction will move it to ST(1)
    	fld    	width                    	; load the width into register ST(0)
    	fdiv    ST, ST(1)			; width [ST(0)] / height [ST(1)]
    	fstp    aspect                    	; stores the result by extracting it from 
                            			; the register into the variable on the stack
    
    	; prepare the third parameter
    	mov    	eax, 10                    	; put the value 10 into eax and then onto the stack (divisor)
    	push    eax
    	fild    dword ptr [esp]                	; we put it into register ST(0), which will become ST(1) on the next load
    	pop    	eax                    		; we remove the value from the stack
    	mov    	eax, 1				; load the value of the dividend 
    	push    eax                    		; onto the stack
    	fild    dword ptr [esp]                	; and load it into register ST(0)
    	fdiv    ST, ST(1)                	; 1 / 10 = 0.1f, which is the parameter we want to use in the OpenGL function
	fstp    zNear                    	; and store it in the 64-bit stack variable
    	pop    	eax

    	; prepare the fourth and final parameter
    	mov     eax,100                    	; less work because the second parameter is 100.0f
    	push    eax                    		; as with the previous ones, we pass it from the stack
	fild    dword ptr [esp]                	; loaded into the x87 ST(0) register, this automatically becomes 100.0f
    	fstp    zFar                    	; which we save in the temporary variable on the stack
    	pop    	eax                    		; let’s make sure to remove the value from the stack

	; I decided to use 32-bit assembly, I'm still in the early stages of learning 64-bit assembly
    	mov    eax, DWORD ptr [zFar]            ; for each value, we first save the lower 32-bit value to the stack 
    	push    eax                    		; then the upper 32-bit value
	mov    eax, DWORD ptr [zFar+4]            
    	push    eax
    	mov    eax, DWORD ptr [zNear]
    	push    eax
    	mov    eax, DWORD ptr [zNear+4]
	push    eax
    	mov    eax, DWORD ptr [aspect]
    	push    eax
    	mov    eax, DWORD ptr [aspect+4]
    	push    eax
    	mov    eax, DWORD ptr [fovy]
    	push    eax
    	mov    eax, DWORD ptr [fovy+4]
	push    eax
    	call    gluPerspective                	; call the OpenGL function

    	; now select the GL_MODELVIEW matrix and use glLoadIdentity to load it into OpenGL
    	invoke    glMatrixMode, GL_MODELVIEW
    	invoke    glLoadIdentity
    
    	ret
ReSizeGLScene endp

;
; OpenGL initialization function
;
InitGL	proc
local   Zero:REAL4
local   One:REAL4

    	invoke 	glShadeModel, GL_SMOOTH     	; enables smooth shading

    	; glClearColor(0.0f, 0.0f, 0.0f, 0.0f) 
    	; 4 32-bit (float) parameters. Zero is the same in both int and float.
        invoke  glClearColor, 0, 0, 0, 0

        ; glClearDepth(1.0) 
        ; WARNING: requires a DOUBLE (64-bit). 
    	; The hexadecimal value for 1.0 (64-bit) is 3FF0000000000000h
    	; better to use the call
        push 	3FF00000h ; High byte
        push 	0         ; Low byte
        call 	glClearDepth

	invoke    glEnable, GL_DEPTH_TEST       ; enables depth testing
    	invoke    glDepthFunc, GL_LEQUAL        ; sets the depth test type
    	invoke    glHint, GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST    ; calculates the perspective correction
	
	mov    eax, TRUE                	; returns OK
    	ret
InitGL	endp

;
; Window drawing function
;
DrawGLScene    	proc
	invoke	glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT    ; clears the screen and depth buffer
   	invoke  glLoadIdentity                 	; resets the current ModelView matrix
    
    	mov    	eax, TRUE                       ; returns OK
    	ret
DrawGLScene    	endp

end start