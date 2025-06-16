; Initialize game state
InitGame:
    push rbp
    mov rbp, rsp
    
    ; Initialize player position (center bottom)
    mov eax, SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
    mov [playerX], eax
    mov eax, SCREEN_HEIGHT - PLAYER_HEIGHT - 50
    mov [playerY], eax
    
    ; Clear velocities
    xor eax, eax
    mov [playerVelX], eax
    mov [playerVelY], eax
    
    ; Clear input state
    mov [keyLeft], al
    mov [keyRight], al
    mov [keyUp], al
    mov [keyDown], al
    mov [keySpace], al
    
    ; Clear bullets
    lea rdi, [bullets]
    xor rax, rax
    mov rcx, MAX_BULLETS * 3  ; 3 dwords per bullet
    rep stosd
    
    ; Initialize starfield
    call InitStarfield
    
    pop rbp
    ret

; Initialize starfield
InitStarfield:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [stars]
    mov r12, 200         ; Number of stars
    
.star_loop:
    ; Random X position (simple pseudo-random)
    rdtsc
    xor edx, edx
    mov ecx, SCREEN_WIDTH
    div ecx
    mov [rbx], edx      ; x position
    
    ; Random Y position
    rdtsc
    xor edx, edx
    mov ecx, SCREEN_HEIGHT
    div ecx
    mov [rbx+4], edx    ; y position
    
    ; Random speed (1-3)
    rdtsc
    and eax, 3
    inc eax
    mov [rbx+8], eax    ; speed
    
    add rbx, 12         ; Next star
    dec r12
    jnz .star_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Update game logic
UpdateGame:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Update player movement
    call UpdatePlayer
    
    ; Update bullets
    call UpdateBullets
    
    ; Update starfield
    call UpdateStarfield
    
    ; Handle shooting
    cmp byte [keySpace], 1
    jne .no_shoot
    cmp dword [bulletCooldown], 0
    jg .no_shoot
    call FireBullet
    mov dword [bulletCooldown], 5   ; Cooldown frames (faster shooting)
.no_shoot:
    
    ; Decrease bullet cooldown
    cmp dword [bulletCooldown], 0
    jle .done
    dec dword [bulletCooldown]
    
.done:
    add rsp, 32
    pop rbp
    ret

; Update player position based on input
UpdatePlayer:
    push rbp
    mov rbp, rsp
    
    ; Horizontal movement
    xor eax, eax
    cmp byte [keyLeft], 1
    jne .check_right
    sub eax, PLAYER_SPEED
.check_right:
    cmp byte [keyRight], 1
    jne .apply_x
    add eax, PLAYER_SPEED
.apply_x:
    add eax, [playerX]
    
    ; Clamp X position
    cmp eax, 0
    jge .check_max_x
    xor eax, eax
.check_max_x:
    mov edx, SCREEN_WIDTH - PLAYER_WIDTH
    cmp eax, edx
    jle .set_x
    mov eax, edx
.set_x:
    mov [playerX], eax
    
    ; Vertical movement
    xor eax, eax
    cmp byte [keyUp], 1
    jne .check_down
    sub eax, PLAYER_SPEED
.check_down:
    cmp byte [keyDown], 1
    jne .apply_y
    add eax, PLAYER_SPEED
.apply_y:
    add eax, [playerY]
    
    ; Clamp Y position
    cmp eax, 0
    jge .check_max_y
    xor eax, eax
.check_max_y:
    mov edx, SCREEN_HEIGHT - PLAYER_HEIGHT
    cmp eax, edx
    jle .set_y
    mov eax, edx
.set_y:
    mov [playerY], eax
    
    pop rbp
    ret

; Fire a bullet from player position
FireBullet:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Find an inactive bullet slot
    lea rbx, [bullets]
    mov ecx, MAX_BULLETS
.find_slot:
    cmp dword [rbx+8], 0    ; Check active flag
    je .found_slot
    add rbx, 12
    loop .find_slot
    jmp .done               ; No free slots
    
.found_slot:
    ; Set bullet position (center of player)
    mov eax, [playerX]
    add eax, PLAYER_WIDTH / 2 - BULLET_WIDTH / 2
    mov [rbx], eax          ; x
    
    mov eax, [playerY]
    sub eax, BULLET_HEIGHT
    mov [rbx+4], eax        ; y
    
    mov dword [rbx+8], 1    ; active
    
.done:
    pop rbx
    pop rbp
    ret

; Update all bullets
UpdateBullets:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [bullets]
    mov r12, MAX_BULLETS
    
.bullet_loop:
    cmp dword [rbx+8], 0    ; Check if active
    je .next_bullet
    
    ; Move bullet up
    mov eax, [rbx+4]        ; y position
    sub eax, BULLET_SPEED
    mov [rbx+4], eax
    
    ; Check if off screen
    cmp eax, 0
    jge .next_bullet
    mov dword [rbx+8], 0    ; Deactivate
    
.next_bullet:
    add rbx, 12
    dec r12
    jnz .bullet_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Update starfield
UpdateStarfield:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [stars]
    mov r12, 200
    
.star_loop:
    ; Move star down by its speed
    mov eax, [rbx+4]        ; y position
    add eax, [rbx+8]        ; speed
    
    ; Wrap around if off screen
    cmp eax, SCREEN_HEIGHT
    jl .store_y
    xor eax, eax            ; Reset to top
    
    ; New random X when wrapping
    push rax
    rdtsc
    xor edx, edx
    mov ecx, SCREEN_WIDTH
    div ecx
    mov [rbx], edx          ; New x position
    pop rax
    
.store_y:
    mov [rbx+4], eax
    
    add rbx, 12
    dec r12
    jnz .star_loop
    
    pop r12
    pop rbx
    pop rbp
    ret    
	
	errorClassFailed db 'RegisterClassEx failed', 0
    errorCreateFailed db 'CreateWindowEx failed', 0
    errorSetupFailed db 'DIB setup failed', 0; Space Shooter - Windows x64 Assembly
; Build commands:
; nasm -f win64 space_shooter.asm -o space_shooter.obj
; golink /entry:Start kernel32.dll user32.dll gdi32.dll space_shooter.obj
;
; For debugging with console:
; golink /entry:Start /console kernel32.dll user32.dll gdi32.dll space_shooter.obj

bits 64
default rel

; Enable rdtsc instruction
%define RDTSC_ENABLED

section .data
    className db 'SpaceShooterClass', 0
    windowName db 'Space Shooter', 0
    errorTitle db 'Error', 0
    errorMsg db 'Failed to create window!', 0
    errorDIB db 'Failed to create DIB section!', 0
    errorClass db 'Failed to register window class!', 0
    debugMsg db 'Debug: %s', 13, 10, 0
    debugInt db 'Debug: %d', 13, 10, 0
    debugHex db 'Debug: 0x%llX', 13, 10, 0
    errorCodeFmt db 'Error code: %d', 0
    initMsg db 'Initializing...', 0
    windowCreatedMsg db 'Window created successfully', 0
    dibCreatedMsg db 'DIB created successfully', 0
    registeringMsg db 'Registering window class...', 0
    registeredMsg db 'Window class registered', 0
    creatingWindowMsg db 'Creating window...', 0
    setupDIBMsg db 'Setting up framebuffer...', 0
    messageLoopMsg db 'Entering message loop...', 0
    
    ; Screen dimensions
    SCREEN_WIDTH equ 1920
    SCREEN_HEIGHT equ 1080
    BYTES_PER_PIXEL equ 4
    
    ; Game constants
    PLAYER_WIDTH equ 64
    PLAYER_HEIGHT equ 48
    PLAYER_SPEED equ 8
    BULLET_WIDTH equ 6
    BULLET_HEIGHT equ 16
    BULLET_SPEED equ 15
    MAX_BULLETS equ 20
    
    ; Colors (BGRA format)
    COLOR_BLACK equ 0x00000000
    COLOR_WHITE equ 0x00FFFFFF
    COLOR_RED equ 0x000000FF
    COLOR_GREEN equ 0x0000FF00
    COLOR_BLUE equ 0x00FF0000
    COLOR_YELLOW equ 0x0000FFFF
    COLOR_CYAN equ 0x00FFFF00
    
    ; Window styles
    WS_OVERLAPPEDWINDOW equ 0x00CF0000
    WS_POPUP equ 0x80000000
    WS_VISIBLE equ 0x10000000
    WS_EX_TOPMOST equ 0x00000008
    SW_SHOW equ 5
    
    ; Messages
    WM_DESTROY equ 0x0002
    WM_CLOSE equ 0x0010
    WM_PAINT equ 0x000F
    WM_KEYDOWN equ 0x0100
    WM_KEYUP equ 0x0101
    WM_TIMER equ 0x0113
    
    ; Virtual key codes
    VK_ESCAPE equ 0x1B
    VK_SPACE equ 0x20
    VK_LEFT equ 0x25
    VK_UP equ 0x26
    VK_RIGHT equ 0x27
    VK_DOWN equ 0x28
    
    ; Timer ID
    GAME_TIMER_ID equ 1
    FRAME_TIME equ 16    ; ~60 FPS (1000ms / 60)
    
section .bss
    hInstance resq 1
    hWindow resq 1
    hdc resq 1
    hdcMem resq 1
    hBitmap resq 1
    pBits resq 1          ; Pointer to our pixel buffer
    hConsole resq 1       ; Console handle for debugging
    
    msg resb 48           ; MSG structure
    wc resb 80            ; WNDCLASSEX structure (80 bytes for x64!)
    bmi resb 44           ; BITMAPINFO structure
    ps resb 72            ; PAINTSTRUCT
    
    ; Game state
    playerX resd 1        ; Player X position
    playerY resd 1        ; Player Y position
    playerVelX resd 1     ; Player X velocity
    playerVelY resd 1     ; Player Y velocity
    
    ; Input state
    keyLeft resb 1
    keyRight resb 1
    keyUp resb 1
    keyDown resb 1
    keySpace resb 1
    
    ; Bullets array (x, y, active for each bullet)
    bullets resb MAX_BULLETS * 12  ; 4 bytes x, 4 bytes y, 4 bytes active
    bulletCooldown resd 1
    
    ; Starfield
    stars resb 200 * 12   ; 200 stars, each with x, y, speed
    
section .text
global Start

extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern ShowWindow
extern UpdateWindow
extern GetDC
extern CreateCompatibleDC
extern CreateDIBSection
extern SelectObject
extern BitBlt
extern GetMessageA
extern TranslateMessage
extern DispatchMessageA
extern PostQuitMessage
extern DefWindowProcA
extern ExitProcess
extern GetLastError
extern MessageBoxA
extern GetStdHandle
extern WriteConsoleA
extern AllocConsole
extern wsprintfA
extern BeginPaint
extern EndPaint
extern FillRect
extern GetClientRect
extern InvalidateRect
extern SetTimer
extern KillTimer
extern GetAsyncKeyState

Start:
    sub rsp, 40          ; Shadow space (32) + alignment (8)
    
    ; Allocate console for debugging
    ; Uncomment these lines to enable console debugging:
    ; call AllocConsole
    ; mov rcx, -11         ; STD_OUTPUT_HANDLE
    ; call GetStdHandle
    ; mov [hConsole], rax
    ; lea rcx, [initMsg]
    ; call PrintDebug
    
    ; Get instance handle
    xor rcx, rcx
    call GetModuleHandleA
    mov [hInstance], rax
    test rax, rax
    jz ErrorExit
    
    ; Register window class
    call RegisterWindowClass
    test rax, rax
    jz ErrorRegisterClass
    
    ; Create fullscreen window
    call CreateFullscreenWindow
    test rax, rax
    jz ErrorCreateWindow
    
    ; Setup DIB framebuffer
    call SetupFramebuffer
    test rax, rax
    jz ErrorCreateDIB
    
    ; Initialize game
    call InitGame
    
    ; Set up game timer for 60 FPS
    mov rcx, [hWindow]
    mov rdx, GAME_TIMER_ID
    mov r8, FRAME_TIME
    xor r9, r9
    call SetTimer
    
    ; Force initial paint
    mov rcx, [hWindow]
    xor rdx, rdx         ; NULL = entire window
    mov r8, 1            ; TRUE = erase background
    call InvalidateRect
    
    ; Print message loop entry
    ; lea rcx, [messageLoopMsg]
    ; call PrintDebug
    
    ; Main message loop
MessageLoop:
    lea rcx, [msg]
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    call GetMessageA
    
    test rax, rax
    jz ExitProgram
    
    lea rcx, [msg]
    call TranslateMessage
    
    lea rcx, [msg]
    call DispatchMessageA
    
    jmp MessageLoop

ErrorRegisterClass:
    lea rcx, [errorClass]
    call ShowError
    jmp ExitProgram

ErrorCreateWindow:
    lea rcx, [errorMsg]
    call ShowError
    jmp ExitProgram

ErrorCreateDIB:
    lea rcx, [errorDIB]
    call ShowError
    jmp ExitProgram

ErrorExit:
ExitProgram:
    xor rcx, rcx
    call ExitProcess

; Helper function to show error message
ShowError:
    ; RCX = error message
    sub rsp, 40
    mov rdx, rcx         ; lpText (message)
    xor rcx, rcx         ; hWnd (NULL)
    lea r8, [errorTitle] ; lpCaption
    mov r9, 0x10         ; MB_OK | MB_ICONERROR
    call MessageBoxA
    add rsp, 40
    ret

; Helper function to print debug messages
PrintDebug:
    ; RCX = string to print
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    mov rdx, rcx         ; String to print
    
    ; Get string length
    mov rdi, rcx
    xor rax, rax
    mov rcx, -1
    repne scasb
    not rcx
    dec rcx              ; Length without null
    
    ; Write to console
    mov r8, rcx          ; Length
    mov rcx, [hConsole]
    lea r9, [rsp+32]     ; Bytes written
    mov qword [rsp+32], 0
    call WriteConsoleA
    
    ; Add newline
    mov word [rsp+40], 0x0A0D  ; CR LF
    mov rcx, [hConsole]
    lea rdx, [rsp+40]
    mov r8, 2
    lea r9, [rsp+32]
    mov qword [rsp+32], 0
    call WriteConsoleA
    
    add rsp, 48
    pop rbp
    ret

; Helper function to print debug integers
PrintDebugInt:
    ; RCX = format string, RDX = integer
    push rbp
    mov rbp, rsp
    sub rsp, 64
    
    ; Format the string
    lea r8, [rsp+48]     ; Output buffer
    call wsprintfA
    
    ; Print the formatted string
    lea rcx, [rsp+48]
    call PrintDebug
    
    add rsp, 64
    pop rbp
    ret

; Window procedure
WindowProc:
    ; RCX = hWnd, RDX = uMsg, R8 = wParam, R9 = lParam
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    sub rsp, 88          ; Shadow space + locals + alignment
    
    ; Save parameters
    mov [rbp+16], rcx    ; hWnd
    mov [rbp+24], rdx    ; uMsg
    mov [rbp+32], r8     ; wParam
    mov [rbp+40], r9     ; lParam
    
    cmp rdx, WM_PAINT
    je .paint
    cmp rdx, WM_KEYDOWN
    je .keydown
    cmp rdx, WM_KEYUP
    je .keyup
    cmp rdx, WM_TIMER
    je .timer
    cmp rdx, WM_CLOSE
    je .close
    cmp rdx, WM_DESTROY
    je .destroy
    
    ; Default processing
    mov rcx, [rbp+16]
    mov rdx, [rbp+24]
    mov r8, [rbp+32]
    mov r9, [rbp+40]
    call DefWindowProcA
    jmp .done
    
.timer:
    cmp r8, GAME_TIMER_ID
    jne .default_proc
    
    ; Update game logic
    call UpdateGame
    
    ; Request redraw
    mov rcx, [rbp+16]    ; hWnd
    xor rdx, rdx         ; NULL = entire window
    xor r8, r8           ; FALSE = don't erase
    call InvalidateRect
    
    xor rax, rax
    jmp .done
    
.keydown:
    mov rax, r8          ; wParam = virtual key code
    cmp rax, VK_LEFT
    jne .kd_right
    mov byte [keyLeft], 1
    jmp .key_handled
.kd_right:
    cmp rax, VK_RIGHT
    jne .kd_up
    mov byte [keyRight], 1
    jmp .key_handled
.kd_up:
    cmp rax, VK_UP
    jne .kd_down
    mov byte [keyUp], 1
    jmp .key_handled
.kd_down:
    cmp rax, VK_DOWN
    jne .kd_space
    mov byte [keyDown], 1
    jmp .key_handled
.kd_space:
    cmp rax, VK_SPACE
    jne .kd_escape
    mov byte [keySpace], 1
    jmp .key_handled
.kd_escape:
    cmp rax, VK_ESCAPE
    jne .key_handled
    jmp .close
.key_handled:
    xor rax, rax
    jmp .done
    
.keyup:
    mov rax, r8          ; wParam = virtual key code
    cmp rax, VK_LEFT
    jne .ku_right
    mov byte [keyLeft], 0
    jmp .key_handled
.ku_right:
    cmp rax, VK_RIGHT
    jne .ku_up
    mov byte [keyRight], 0
    jmp .key_handled
.ku_up:
    cmp rax, VK_UP
    jne .ku_down
    mov byte [keyUp], 0
    jmp .key_handled
.ku_down:
    cmp rax, VK_DOWN
    jne .ku_space
    mov byte [keyDown], 0
    jmp .key_handled
.ku_space:
    cmp rax, VK_SPACE
    jne .key_handled
    mov byte [keySpace], 0
    jmp .key_handled
    
.paint:
    ; Begin paint
    mov rcx, [rbp+16]    ; hWnd
    lea rdx, [ps]
    call BeginPaint
    mov rbx, rax         ; Save HDC
    
    ; Draw our scene
    call DrawScene
    
    ; End paint
    mov rcx, [rbp+16]    ; hWnd
    lea rdx, [ps]
    call EndPaint
    
    xor rax, rax
    jmp .done
    
.close:
.destroy:
    ; Kill timer
    mov rcx, [rbp+16]
    mov rdx, GAME_TIMER_ID
    call KillTimer
    
    xor rcx, rcx
    call PostQuitMessage
    xor rax, rax
    jmp .done
    
.default_proc:
    mov rcx, [rbp+16]
    mov rdx, [rbp+24]
    mov r8, [rbp+32]
    mov r9, [rbp+40]
    call DefWindowProcA
    
.done:
    add rsp, 88
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

; Draw the game scene
DrawScene:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Clear screen to black
    call ClearScreen
    
    ; Draw starfield
    call DrawStarfield
    
    ; Draw player
    mov r8d, [playerX]
    mov r9d, [playerY]
    mov r10d, PLAYER_WIDTH
    mov r11d, PLAYER_HEIGHT
    mov eax, COLOR_CYAN
    call DrawRectangle
    
    ; Draw player cockpit (darker center)
    mov r8d, [playerX]
    add r8d, PLAYER_WIDTH / 4
    mov r9d, [playerY]
    add r9d, 8
    mov r10d, PLAYER_WIDTH / 2
    mov r11d, PLAYER_HEIGHT / 2
    mov eax, 0x00808000      ; Darker cyan
    call DrawRectangle
    
    ; Draw thruster effects when moving
    cmp byte [keyUp], 1
    je .draw_thrusters
    cmp byte [keyDown], 1
    je .draw_thrusters
    cmp byte [keyLeft], 1
    je .draw_thrusters
    cmp byte [keyRight], 1
    jne .no_thrusters
    
.draw_thrusters:
    ; Left thruster
    mov r8d, [playerX]
    add r8d, 10
    mov r9d, [playerY]
    add r9d, PLAYER_HEIGHT
    mov r10d, 8
    mov r11d, 6
    mov eax, COLOR_YELLOW
    call DrawRectangle
    
    ; Right thruster
    mov r8d, [playerX]
    add r8d, PLAYER_WIDTH - 18
    mov r9d, [playerY]
    add r9d, PLAYER_HEIGHT
    mov r10d, 8
    mov r11d, 6
    mov eax, COLOR_YELLOW
    call DrawRectangle
    
.no_thrusters:
    ; Draw bullets
    call DrawBullets
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 32
    pop rbp
    ret

; Draw starfield
DrawStarfield:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    lea rbx, [stars]
    mov r12, 200            ; Number of stars
    
.star_loop:
    ; Calculate star brightness based on speed
    mov eax, [rbx+8]        ; speed (1-3)
    imul eax, 85           ; 85, 170, or 255
    
    ; Create grayscale color (same value for R, G, B)
    mov ecx, eax
    shl ecx, 8
    or eax, ecx
    shl ecx, 8
    or eax, ecx            ; Now eax = 0x00RRGGBB
    
    ; Draw star (size based on speed/distance)
    mov r8d, [rbx]         ; x
    mov r9d, [rbx+4]       ; y
    mov r10d, [rbx+8]      ; speed (1-3)
    inc r10d               ; size = speed + 1 (2-4 pixels)
    mov r11d, r10d         ; square stars
    mov r13d, eax          ; Save color
    mov eax, r13d
    call DrawRectangle
    
    add rbx, 12
    dec r12
    jnz .star_loop
    
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw all active bullets
DrawBullets:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [bullets]
    mov r12, MAX_BULLETS
    
.bullet_loop:
    cmp dword [rbx+8], 0    ; Check if active
    je .next_bullet
    
    ; Draw bullet
    mov r8d, [rbx]          ; x
    mov r9d, [rbx+4]        ; y
    mov r10d, BULLET_WIDTH
    mov r11d, BULLET_HEIGHT
    mov eax, COLOR_YELLOW
    call DrawRectangle
    
.next_bullet:
    add rbx, 12
    dec r12
    jnz .bullet_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

RegisterWindowClass:
    push rbp
    mov rbp, rsp
    sub rsp, 48          ; Shadow space + alignment
    
    ; Print registering message
    ; lea rcx, [registeringMsg]
    ; call PrintDebug
    
    ; Zero out structure first
    lea rdi, [wc]
    xor rax, rax
    mov rcx, 10          ; 80 bytes / 8
    rep stosq
    
    ; Fill WNDCLASSEX structure
    lea rdi, [wc]
    mov dword [rdi], 80               ; cbSize (80 for x64!)
    mov dword [rdi+4], 0x0003         ; style (CS_HREDRAW | CS_VREDRAW)
    lea rax, [WindowProc]
    mov [rdi+8], rax                  ; lpfnWndProc
    mov dword [rdi+16], 0             ; cbClsExtra
    mov dword [rdi+20], 0             ; cbWndExtra
    mov rax, [hInstance]
    mov [rdi+24], rax                 ; hInstance
    mov qword [rdi+32], 0             ; hIcon
    mov qword [rdi+40], 0             ; hCursor
    mov qword [rdi+48], 0             ; hbrBackground (NULL)
    mov qword [rdi+56], 0             ; lpszMenuName
    lea rax, [className]
    mov [rdi+64], rax                 ; lpszClassName
    mov qword [rdi+72], 0             ; hIconSm
    
    lea rcx, [wc]
    call RegisterClassExA
    
    ; Check for error
    test rax, rax
    jnz .success
    
    ; Get last error for debugging
    call GetLastError
    xor rax, rax         ; Return failure
    jmp .done
    
.success:
    ; lea rcx, [registeredMsg]
    ; call PrintDebug
    mov rax, 1           ; Return success
    
.done:
    add rsp, 48
    pop rbp
    ret

CreateFullscreenWindow:
    push rbp
    mov rbp, rsp
    sub rsp, 128         ; Need space for all parameters + shadow space
    
    ; Print creating window message
    ; lea rcx, [creatingWindowMsg]
    ; call PrintDebug
    
    ; CreateWindowEx parameters (first 4 in registers, rest on stack)
    mov rcx, WS_EX_TOPMOST            ; dwExStyle
    lea rdx, [className]              ; lpClassName
    lea r8, [windowName]              ; lpWindowName
    mov r9, WS_POPUP | WS_VISIBLE     ; dwStyle (fullscreen)
    
    ; Stack parameters (after shadow space of 32 bytes)
    mov dword [rsp+32], 0             ; x
    mov dword [rsp+40], 0             ; y
    mov dword [rsp+48], SCREEN_WIDTH  ; nWidth
    mov dword [rsp+56], SCREEN_HEIGHT ; nHeight
    mov qword [rsp+64], 0             ; hWndParent
    mov qword [rsp+72], 0             ; hMenu
    mov rax, [hInstance]
    mov [rsp+80], rax                 ; hInstance
    mov qword [rsp+88], 0             ; lpParam
    
    call CreateWindowExA
    mov [hWindow], rax
    
    ; Check for error
    test rax, rax
    jz .error
    
    ; Show window
    mov rcx, rax
    mov rdx, SW_SHOW
    call ShowWindow
    
    mov rcx, [hWindow]
    call UpdateWindow
    
    ; Print success message
    ; lea rcx, [windowCreatedMsg]
    ; call PrintDebug
    
    mov rax, [hWindow]    ; Return window handle
    jmp .done
    
.error:
    call GetLastError     ; For debugging
    xor rax, rax
    
.done:
    add rsp, 128
    pop rbp
    ret

SetupFramebuffer:
    push rbp
    mov rbp, rsp
    sub rsp, 64          ; Shadow space + locals
    
    ; Print setup message
    ; lea rcx, [setupDIBMsg]
    ; call PrintDebug
    
    ; Get window DC
    mov rcx, [hWindow]
    call GetDC
    mov [hdc], rax
    test rax, rax
    jz .error
    
    ; Create memory DC
    mov rcx, rax
    call CreateCompatibleDC
    mov [hdcMem], rax
    test rax, rax
    jz .error
    
    ; Zero out BITMAPINFO structure
    lea rdi, [bmi]
    xor rax, rax
    mov rcx, 44/8 + 1
    rep stosq
    
    ; Setup BITMAPINFO
    lea rdi, [bmi]
    mov dword [rdi], 40               ; biSize
    mov dword [rdi+4], SCREEN_WIDTH   ; biWidth
    mov dword [rdi+8], -SCREEN_HEIGHT ; biHeight (negative for top-down)
    mov word [rdi+12], 1              ; biPlanes
    mov word [rdi+14], 32             ; biBitCount
    mov dword [rdi+16], 0             ; biCompression (BI_RGB)
    mov dword [rdi+20], 0             ; biSizeImage (can be 0 for BI_RGB)
    mov dword [rdi+24], 0             ; biXPelsPerMeter
    mov dword [rdi+28], 0             ; biYPelsPerMeter
    mov dword [rdi+32], 0             ; biClrUsed
    mov dword [rdi+36], 0             ; biClrImportant
    
    ; Create DIB section
    mov rcx, [hdc]
    lea rdx, [bmi]
    xor r8, r8                        ; DIB_RGB_COLORS
    lea r9, [pBits]
    mov qword [rsp+32], 0             ; hSection
    mov qword [rsp+40], 0             ; offset
    
    call CreateDIBSection
    mov [hBitmap], rax
    
    ; Check for error
    test rax, rax
    jz .error
    
    ; Verify bits pointer was set
    cmp qword [pBits], 0
    je .error
    
    ; Select bitmap into memory DC
    mov rcx, [hdcMem]
    mov rdx, [hBitmap]
    call SelectObject
    
    ; Print success message
    ; lea rcx, [dibCreatedMsg]
    ; call PrintDebug
    
    mov rax, 1           ; Success
    jmp .done
    
.error:
    call GetLastError    ; For debugging
    xor rax, rax         ; Failure
    
.done:
    add rsp, 64
    pop rbp
    ret

ClearScreen:
    push rbp
    mov rbp, rsp
    
    ; Check if pBits is valid
    mov rdi, [pBits]
    test rdi, rdi
    jz .done
    
    mov rcx, SCREEN_WIDTH * SCREEN_HEIGHT
    xor eax, eax                      ; Black color (0x00000000)
    rep stosd
    
.done:
    pop rbp
    ret

DrawRectangle:
    ; R8D = x, R9D = y, R10D = width, R11D = height, EAX = color
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Bounds checking
    test r8d, r8d                     ; x < 0?
    js .done
    test r9d, r9d                     ; y < 0?
    js .done
    cmp r8d, SCREEN_WIDTH
    jge .done
    cmp r9d, SCREEN_HEIGHT
    jge .done
    
    ; Check if pBits is valid
    mov rbx, [pBits]
    test rbx, rbx
    jz .done
    
    ; Clip width and height
    mov r13d, r8d
    add r13d, r10d                    ; x + width
    cmp r13d, SCREEN_WIDTH
    jle .width_ok
    mov r10d, SCREEN_WIDTH
    sub r10d, r8d                     ; width = SCREEN_WIDTH - x
.width_ok:
    
    mov r13d, r9d
    add r13d, r11d                    ; y + height
    cmp r13d, SCREEN_HEIGHT
    jle .height_ok
    mov r11d, SCREEN_HEIGHT
    sub r11d, r9d                     ; height = SCREEN_HEIGHT - y
.height_ok:
    
    ; Calculate starting position
    mov r12d, r9d                     ; y
    imul r12d, SCREEN_WIDTH
    add r12d, r8d                     ; + x
    shl r12, 2                        ; * 4 bytes per pixel
    add rbx, r12
    
    ; Draw rectangle
    mov ecx, r11d                     ; height
.drawRow:
    push rcx
    push rbx
    
    mov ecx, r10d                     ; width
    mov rdi, rbx
    rep stosd                         ; Store color for entire row
    
    pop rbx
    pop rcx
    
    add rbx, SCREEN_WIDTH * 4         ; Next row
    dec ecx
    jnz .drawRow
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

UpdateScreen:
    push rbp
    mov rbp, rsp
    sub rsp, 80          ; Need more space for 9 parameters
    
    ; BitBlt from memory DC to window DC
    mov rcx, [hdc]                    ; hdcDest
    xor rdx, rdx                      ; xDest
    xor r8, r8                        ; yDest
    mov r9d, SCREEN_WIDTH             ; width
    mov dword [rsp+32], SCREEN_HEIGHT ; height
    mov rax, [hdcMem]
    mov [rsp+40], rax                 ; hdcSrc
    mov qword [rsp+48], 0             ; xSrc
    mov qword [rsp+56], 0             ; ySrc
    mov dword [rsp+64], 0x00CC0020    ; SRCCOPY
    
    call BitBlt
    
    ; Check for error
    test eax, eax
    jnz .success
    
    ; BitBlt failed
    call GetLastError
    
.success:
    add rsp, 80
    pop rbp
    ret