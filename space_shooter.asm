; Space Shooter - Windows x64 Assembly
; Build commands:
; nasm -f win64 space_shooter.asm -o space_shooter.obj
; golink /entry:Start kernel32.dll user32.dll gdi32.dll space_shooter.obj
;
; For debugging with console:
; golink /entry:Start /console kernel32.dll user32.dll gdi32.dll space_shooter.obj
;
; Note: Custom cursor implementation hides system cursor and draws custom graphics

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
    titleText             db 'SPACE SHOOTER', 0
    creditText            db 'vladamisici@github', 0
    enterNameText         db 'Enter Name:', 0
    difficultyText        db 'Select Difficulty:', 0
    easyText              db 'Easy', 0
    normalText            db 'Normal', 0
    hardText              db 'Hard', 0
    insaneText            db 'Insane!', 0
    newGameText           db 'New Game', 0
    loadGameText          db 'Load Game', 0
    scoreText             db 'Score: ', 0
    gameOverText          db 'GAME OVER', 0
    finalScoreText        db 'Final Score: ', 0
    pressEscText          db 'Press ESC to return to menu', 0
    dashInstructionText   db 'Hold SHIFT to Dash!', 0
    backText              db 'BACK', 0
    levelNumbersText      db 'Level Numbers', 0
    galaxyCompleteText    db 'Galaxy Complete!', 0
    allClearText          db 'All Galaxies Cleared!', 0
    levelText             db 'Level ', 0
    galaxyText            db 'Galaxy ', 0
    saveFileName          db 'spaceshooter.sav', 0
    dashText              db 'DASH', 0
    backArrowText         db '< ', 0
    dashSeparator         db '-', 0
    slashSeparator        db '/', 0
    
    ; Screen dimensions
    SCREEN_WIDTH equ 1920
    SCREEN_HEIGHT equ 1080
    BYTES_PER_PIXEL equ 4
    
    ; Game constants
    PLAYER_WIDTH equ 64
    PLAYER_HEIGHT equ 48
    PLAYER_SPEED equ 8
    MAX_NAME_LENGTH equ 16
    STATE_MENU         equ 0
    STATE_PLAYING      equ 1
    STATE_PAUSED       equ 2
    STATE_GAME_OVER    equ 3
    STATE_LEVEL_SELECT equ 4
    STATE_VICTORY      equ 5
    BULLET_WIDTH equ 6
    BULLET_HEIGHT equ 16
    BULLET_SPEED equ 15
    MAX_BULLETS equ 20
    
    ; Enemy constants
    ALIEN_WIDTH equ 40
    ALIEN_HEIGHT equ 32
    ALIEN_SPEED equ 3
    MAX_ALIENS equ 10
    ALIEN_SPAWN_DELAY equ 60    ; Frames between spawns
    
    ; Asteroid constants
    ASTEROID_SIZE equ 48
    ASTEROID_SPEED equ 5
    MAX_ASTEROIDS equ 8
    ASTEROID_SPAWN_DELAY equ 90  ; Frames between spawns
    
    ; Level system constants
    MAX_GALAXIES equ 5
    LEVELS_PER_GALAXY equ 10
    MAX_TOTAL_LEVELS equ MAX_GALAXIES * LEVELS_PER_GALAXY
    
    ; Node types for level map
    NODE_NORMAL equ 0
    NODE_SPECIAL equ 1
    NODE_BOSS equ 2
    NODE_CORNER equ 3
    
    ; Node visual properties
    NODE_SIZE equ 32
    NODE_SPACING_X equ 120
    NODE_SPACING_Y equ 100
    
    ; Colors (BGRA format)
    COLOR_BLACK equ 0x00000000
    COLOR_WHITE equ 0x00FFFFFF
    COLOR_RED equ 0x000000FF
    COLOR_GREEN equ 0x0000FF00
    COLOR_BLUE equ 0x00FF0000
    COLOR_YELLOW equ 0x0000FFFF
    COLOR_CYAN equ 0x00FFFF00
    COLOR_PURPLE equ 0x00FF00FF
    COLOR_ORANGE equ 0x000080FF
    
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
    WM_LBUTTONDOWN equ 0x0201
    WM_MOUSEMOVE equ 0x0200
    WM_CHAR equ 0x0102
    WM_SETCURSOR equ 0x0020
    
    ; Virtual key codes
    VK_ESCAPE equ 0x1B
    VK_SPACE equ 0x20
    VK_LEFT equ 0x25
    VK_UP equ 0x26
    VK_RIGHT equ 0x27
    VK_DOWN equ 0x28
    VK_SHIFT equ 0x10
    VK_RETURN equ 0x0D
    
    ; File access constants
    GENERIC_READ equ 0x80000000
    GENERIC_WRITE equ 0x40000000
    CREATE_ALWAYS equ 2
    OPEN_EXISTING equ 3
    FILE_ATTRIBUTE_NORMAL equ 0x80
    INVALID_HANDLE_VALUE equ -1
    
    ; Cursor constants
    IDC_ARROW equ 32512
    HTCLIENT equ 1
    
    ; Timer ID
    GAME_TIMER_ID equ 1
    FRAME_TIME equ 16    ; ~60 FPS (1000ms / 60)
    
    ; 8-bit font data (5x7 pixels per character, starting from ASCII 32 ' ')
    ; Each byte represents one row of the character
    font8bit:
        ; Space
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ; !
        db 0x20, 0x20, 0x20, 0x20, 0x00, 0x20, 0x00
        ; "
        db 0x50, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00
        ; #
        db 0x50, 0xF8, 0x50, 0x50, 0xF8, 0x50, 0x00
        ; $
        db 0x20, 0x78, 0xA0, 0x70, 0x28, 0xF0, 0x20
        ; %
        db 0xC0, 0xC8, 0x10, 0x20, 0x40, 0x98, 0x18
        ; &
        db 0x40, 0xA0, 0x40, 0xA8, 0x90, 0x68, 0x00
        ; '
        db 0x20, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00
        ; (
        db 0x10, 0x20, 0x40, 0x40, 0x40, 0x20, 0x10
        ; )
        db 0x40, 0x20, 0x10, 0x10, 0x10, 0x20, 0x40
        ; *
        db 0x00, 0x50, 0x20, 0xF8, 0x20, 0x50, 0x00
        ; +
        db 0x00, 0x20, 0x20, 0xF8, 0x20, 0x20, 0x00
        ; ,
        db 0x00, 0x00, 0x00, 0x00, 0x30, 0x10, 0x20
        ; -
        db 0x00, 0x00, 0x00, 0xF8, 0x00, 0x00, 0x00
        ; .
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00
        ; /
        db 0x00, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00
        ; 0
        db 0x70, 0x88, 0x98, 0xA8, 0xC8, 0x88, 0x70
        ; 1
        db 0x20, 0x60, 0x20, 0x20, 0x20, 0x20, 0x70
        ; 2
        db 0x70, 0x88, 0x08, 0x30, 0x40, 0x80, 0xF8
        ; 3
        db 0x70, 0x88, 0x08, 0x30, 0x08, 0x88, 0x70
        ; 4
        db 0x10, 0x30, 0x50, 0x90, 0xF8, 0x10, 0x10
        ; 5
        db 0xF8, 0x80, 0xF0, 0x08, 0x08, 0x88, 0x70
        ; 6
        db 0x38, 0x40, 0x80, 0xF0, 0x88, 0x88, 0x70
        ; 7
        db 0xF8, 0x08, 0x10, 0x20, 0x40, 0x40, 0x40
        ; 8
        db 0x70, 0x88, 0x88, 0x70, 0x88, 0x88, 0x70
        ; 9
        db 0x70, 0x88, 0x88, 0x78, 0x08, 0x10, 0xE0
        ; :
        db 0x00, 0x20, 0x00, 0x00, 0x20, 0x00, 0x00
        ; ;
        db 0x00, 0x20, 0x00, 0x00, 0x20, 0x10, 0x20
        ; <
        db 0x08, 0x10, 0x20, 0x40, 0x20, 0x10, 0x08
        ; =
        db 0x00, 0x00, 0xF8, 0x00, 0xF8, 0x00, 0x00
        ; >
        db 0x40, 0x20, 0x10, 0x08, 0x10, 0x20, 0x40
        ; ?
        db 0x70, 0x88, 0x08, 0x10, 0x20, 0x00, 0x20
        ; @
        db 0x70, 0x88, 0xB8, 0xA8, 0xB8, 0x80, 0x78
        ; A
        db 0x70, 0x88, 0x88, 0xF8, 0x88, 0x88, 0x88
        ; B
        db 0xF0, 0x88, 0x88, 0xF0, 0x88, 0x88, 0xF0
        ; C
        db 0x70, 0x88, 0x80, 0x80, 0x80, 0x88, 0x70
        ; D
        db 0xE0, 0x90, 0x88, 0x88, 0x88, 0x90, 0xE0
        ; E
        db 0xF8, 0x80, 0x80, 0xF0, 0x80, 0x80, 0xF8
        ; F
        db 0xF8, 0x80, 0x80, 0xF0, 0x80, 0x80, 0x80
        ; G
        db 0x70, 0x88, 0x80, 0xB8, 0x88, 0x88, 0x78
        ; H
        db 0x88, 0x88, 0x88, 0xF8, 0x88, 0x88, 0x88
        ; I
        db 0x70, 0x20, 0x20, 0x20, 0x20, 0x20, 0x70
        ; J
        db 0x38, 0x10, 0x10, 0x10, 0x10, 0x90, 0x60
        ; K
        db 0x88, 0x90, 0xA0, 0xC0, 0xA0, 0x90, 0x88
        ; L
        db 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xF8
        ; M
        db 0x88, 0xD8, 0xA8, 0xA8, 0x88, 0x88, 0x88
        ; N
        db 0x88, 0xC8, 0xA8, 0x98, 0x88, 0x88, 0x88
        ; O
        db 0x70, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70
        ; P
        db 0xF0, 0x88, 0x88, 0xF0, 0x80, 0x80, 0x80
        ; Q
        db 0x70, 0x88, 0x88, 0x88, 0xA8, 0x90, 0x68
        ; R
        db 0xF0, 0x88, 0x88, 0xF0, 0xA0, 0x90, 0x88
        ; S
        db 0x70, 0x88, 0x80, 0x70, 0x08, 0x88, 0x70
        ; T
        db 0xF8, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
        ; U
        db 0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70
        ; V
        db 0x88, 0x88, 0x88, 0x88, 0x50, 0x50, 0x20
        ; W
        db 0x88, 0x88, 0x88, 0xA8, 0xA8, 0xD8, 0x88
        ; X
        db 0x88, 0x88, 0x50, 0x20, 0x50, 0x88, 0x88
        ; Y
        db 0x88, 0x88, 0x50, 0x20, 0x20, 0x20, 0x20
        ; Z
        db 0xF8, 0x08, 0x10, 0x20, 0x40, 0x80, 0xF8
    
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
    keyShift resb 1
    
    ; Dash ability
    dashAmount resd 1       ; Current dash amount (0-180 frames = 3 seconds)
    dashCooldown resd 1     ; Cooldown timer (600 frames = 10 seconds)
    isDashing resb 1        ; Currently dashing flag
    DASH_MAX equ 180        ; 3 seconds at 60 FPS
    DASH_COOLDOWN_MAX equ 600  ; 10 seconds at 60 FPS
    DASH_RECHARGE_RATE equ 3   ; Recharge rate when not on cooldown
    
    ; Bullets array (x, y, active for each bullet)
    bullets resb MAX_BULLETS * 12  ; 4 bytes x, 4 bytes y, 4 bytes active
    bulletCooldown resd 1
    
    ; Starfield
    stars resb 200 * 12   ; 200 stars, each with x, y, speed
    
    ; Ship trail effect
    TRAIL_LENGTH equ 8
    trailX resb TRAIL_LENGTH * 4
    trailY resb TRAIL_LENGTH * 4
    trailIndex resd 1
    
    ; Screen flash effect
    screenFlash resd 1
    gameState             resd 1
    selectedMenuItem      resd 1
    selectedDifficulty    resd 1
    nameLength            resd 1
    playerName            resb MAX_NAME_LENGTH+1
    cursorBlink           resd 1
    animTimer             resd 1
    titleAnimFrame        resd 1
    mouseX                resd 1
    mouseY                resd 1
    
    ; Game score and state
    playerScore           resd 1
    playerLives           resd 1
    alienSpawnTimer       resd 1
    asteroidSpawnTimer    resd 1
    
    ; Level system
    currentGalaxy         resd 1
    currentLevel          resd 1
    levelsCompleted       resb MAX_TOTAL_LEVELS  ; Bit array of completed levels
    hasSaveGame           resb 1
    selectedNode          resd 1
    levelScore            resd 1    ; Score for current level
    totalScore            resd 1    ; Total score across all levels
    enemiesKilled         resd 1    ; Enemies killed in current level
    enemiesRequired       resd 1    ; Enemies required to complete level
    levelTimer            resd 1    ; Timer for level completion
    
    ; Aliens array (x, y, active, type for each alien)
    aliens resb MAX_ALIENS * 16  ; 4 bytes each field
    
    ; Asteroids array (x, y, active, rotation for each asteroid)
    asteroids resb MAX_ASTEROIDS * 16  ; 4 bytes each field
    
    ; Temporary variables
    tempFileHandle resq 1
    bytesWritten resd 1
    bytesRead resd 1
    
    ; Cursor state
    showCustomCursor resb 1
    cursorVisible resb 1
    
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
extern CreateFileA
extern WriteFile
extern ReadFile
extern CloseHandle
extern GetFileSize
extern ShowCursor
extern SetCursor
extern LoadCursorA

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
    
    ; Start in menu mode
    mov dword [gameState], STATE_MENU
    call InitGame
    
    ; Check for existing save file
    call CheckSaveFile
    
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
    ; Show cursor before exiting
    mov rcx, 1           ; TRUE - show cursor
    call ShowCursor
    
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

; Draw animated title with effects
DrawAnimatedTitle:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    
    ; Calculate animated color
    mov eax, [animTimer]
    and eax, 63
    cmp eax, 32
    jl .bright_phase
    
    ; Dim phase
    mov r14d, COLOR_CYAN
    jmp .start_draw
    
.bright_phase:
    ; Bright phase - calculate pulsing effect
    mov r14d, eax
    shl r14d, 3          ; Multiply by 8
    mov eax, 0xFF
    sub eax, r14d        ; Inverse for pulsing
    mov r14d, eax
    shl r14d, 8         ; Green channel
    or r14d, 0x00FF0000  ; Add blue
    or r14d, eax         ; Add some red
    
.start_draw:
    ; Draw glow background
    mov r8d, SCREEN_WIDTH / 2 - 350
    mov r9d, 70
    mov r10d, 700
    mov r11d, 90
    mov eax, 0x00101010
    call DrawRectangleWithGlow
    
    ; Draw main title text using DrawStringCentered for simplicity
    mov r9d, 100
    lea rdx, [titleText]
    mov r11d, r14d       ; Animated color
    mov ecx, 8           ; Large scale
    call DrawStringCentered
    
    ; Draw a simple shadow effect
    mov r9d, 104         ; Slightly offset
    lea rdx, [titleText]
    mov r11d, 0x00202020 ; Dark shadow
    mov ecx, 8
    call DrawStringCentered
    
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
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
    cmp rdx, WM_LBUTTONDOWN
    je .lbuttondown
    cmp rdx, WM_MOUSEMOVE
    je .mousemove
    cmp rdx, WM_CHAR
    je .char
    cmp rdx, WM_SETCURSOR
    je .setcursor 
    
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
    
    ; Update animation timers regardless of game state
    inc dword [animTimer]
    
    ; Update cursor blink
    mov eax, [animTimer]
    and eax, 0x1F        ; Every 32 frames
    jnz .no_cursor_toggle
    xor dword [cursorBlink], 1
.no_cursor_toggle:
    
    ; Update title animation
    mov eax, [animTimer]
    and eax, 0x0F        ; Every 16 frames
    jnz .no_title_update
    inc dword [titleAnimFrame]
.no_title_update:
    
    ; Update cursor visibility based on state
    cmp dword [gameState], STATE_PLAYING
    je .hide_system_cursor
    cmp dword [gameState], STATE_LEVEL_SELECT
    je .hide_system_cursor
    cmp dword [gameState], STATE_VICTORY
    je .hide_system_cursor
    cmp dword [gameState], STATE_GAME_OVER
    je .hide_system_cursor
    
    ; Show system cursor in menus
    cmp byte [cursorVisible], 1
    je .cursor_done
    mov rcx, 1           ; TRUE - show cursor
    call ShowCursor
    mov byte [cursorVisible], 1
    jmp .cursor_done
    
.hide_system_cursor:
    ; Hide system cursor in game
    cmp byte [cursorVisible], 0
    je .cursor_done
    xor rcx, rcx         ; FALSE - hide cursor
    call ShowCursor
    mov byte [cursorVisible], 0
    
.cursor_done:
    ; Update based on game state
    cmp dword [gameState], STATE_PLAYING
    jne .timer_done
    
    call UpdateGame
    
.timer_done:
    ; Request redraw
    mov rcx, [rbp+16]    ; hWnd
    xor rdx, rdx         ; NULL = entire window
    xor r8, r8           ; FALSE = don't erase
    call InvalidateRect
    
    xor rax, rax
    jmp .done
    
.char:
    ; Handle character input in menu
    cmp dword [gameState], STATE_MENU
    jne .done
    
    mov rax, r8          ; wParam = character
    
    ; Check if entering name
    cmp dword [selectedMenuItem], 0
    jne .done
    
    ; Validate character (alphanumeric only)
    cmp al, '0'
    jl .check_letter
    cmp al, '9'
    jle .valid_char
    
.check_letter:
    cmp al, 'A'
    jl .check_lower
    cmp al, 'Z'
    jle .valid_char
    
.check_lower:
    cmp al, 'a'
    jl .done
    cmp al, 'z'
    jg .done
    
    ; Convert to uppercase
    sub al, 32
    
.valid_char:
    ; Add to name if not full
    mov ecx, [nameLength]
    cmp ecx, MAX_NAME_LENGTH
    jge .done
    
    lea rdi, [playerName]
    add rdi, rcx
    mov [rdi], al
    inc dword [nameLength]
    
    xor rax, rax
    jmp .done
    
.keydown:
    mov rax, r8          ; wParam = virtual key code
    
    cmp rax, VK_ESCAPE
    jne .check_game_keys
    
    ; Escape pressed - handle based on state
    cmp dword [gameState], STATE_PLAYING
    je .pause_game
    cmp dword [gameState], STATE_GAME_OVER
    je .back_to_menu
    cmp dword [gameState], STATE_LEVEL_SELECT
    je .back_to_menu
    cmp dword [gameState], STATE_VICTORY
    je .back_to_menu
    jmp .key_handled
    
.pause_game:
    ; Could implement pause here
    jmp .close
    
.back_to_menu:
    mov dword [gameState], STATE_MENU
    jmp .key_handled
    
.check_game_keys:
    ; Handle Enter key for menus
    cmp rax, VK_RETURN
    jne .check_playing_keys
    
    cmp dword [gameState], STATE_MENU
    je .menu_enter
    cmp dword [gameState], STATE_LEVEL_SELECT
    je .level_select_enter
    jmp .key_handled
    
.menu_enter:
    ; Handle menu selection with Enter
    cmp dword [selectedMenuItem], 2  ; New Game
    je .start_new_game
    cmp dword [selectedMenuItem], 3  ; Load Game
    je .load_game_pressed
    jmp .key_handled
    
.start_new_game:
    cmp dword [nameLength], 0
    jle .key_handled
    mov dword [currentGalaxy], 0
    mov dword [currentLevel], 0
    mov dword [totalScore], 0
    ; Clear completed levels
    lea rdi, [levelsCompleted]
    xor rax, rax
    mov rcx, MAX_TOTAL_LEVELS
    rep stosb
    mov dword [gameState], STATE_LEVEL_SELECT
    jmp .key_handled
    
.load_game_pressed:
    cmp byte [hasSaveGame], 0
    je .key_handled
    call LoadGame
    mov dword [gameState], STATE_LEVEL_SELECT
    jmp .key_handled
    
.level_select_enter:
    ; Start selected level
    call StartLevel
    jmp .key_handled
    
.check_playing_keys:
    cmp dword [gameState], STATE_PLAYING
    jne .check_level_select_keys
    
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
    jne .kd_shift
    mov byte [keySpace], 1
    jmp .key_handled
.kd_shift:
    cmp rax, VK_SHIFT
    jne .key_handled
    mov byte [keyShift], 1
    jmp .key_handled
    
.check_level_select_keys:
    cmp dword [gameState], STATE_LEVEL_SELECT
    jne .key_handled
    
    ; Navigate level selection
    cmp rax, VK_LEFT
    jne .ls_right
    call MoveLevelSelectLeft
    jmp .key_handled
.ls_right:
    cmp rax, VK_RIGHT
    jne .ls_up
    call MoveLevelSelectRight
    jmp .key_handled
.ls_up:
    cmp rax, VK_UP
    jne .ls_down
    call MoveLevelSelectUp
    jmp .key_handled
.ls_down:
    cmp rax, VK_DOWN
    jne .key_handled
    call MoveLevelSelectDown
    
.key_handled:
    xor rax, rax
    jmp .done
    
.keyup:
    mov rax, r8          ; wParam = virtual key code
    cmp dword [gameState], STATE_PLAYING
    jne .done
    
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
    jne .ku_shift
    mov byte [keySpace], 0
    jmp .key_handled
.ku_shift:
    cmp rax, VK_SHIFT
    jne .key_handled
    mov byte [keyShift], 0
    jmp .key_handled
    
.lbuttondown:
    ; Handle mouse clicks in menu and level select
    cmp dword [gameState], STATE_MENU
    je .menu_click
    cmp dword [gameState], STATE_LEVEL_SELECT
    je .level_select_click
    jmp .done
    
.menu_click:
    mov eax, [mouseX]
    mov edx, [mouseY]
    
    ; Check name entry box (x: center-200 to center+200, y: 400-450)
    mov ecx, SCREEN_WIDTH / 2 - 200
    cmp eax, ecx
    jl .check_difficulty
    add ecx, 400
    cmp eax, ecx
    jg .check_difficulty
    cmp edx, 400
    jl .check_difficulty
    cmp edx, 450
    jg .check_difficulty
    
    mov dword [selectedMenuItem], 0
    jmp .done
    
.check_difficulty:
    ; Check difficulty buttons (y: 550-600)
    cmp edx, 550
    jl .check_start
    cmp edx, 600
    jg .check_start
    
    ; Check which difficulty button
    mov ecx, SCREEN_WIDTH / 2 - 320
    mov r8d, 0           ; Difficulty counter
    
.diff_check_loop:
    mov r9d, ecx
    add r9d, 150         ; Button width
    cmp eax, ecx
    jl .next_diff
    cmp eax, r9d
    jg .next_diff
    
    ; Found clicked difficulty
    mov [selectedDifficulty], r8d
    mov dword [selectedMenuItem], 1
    jmp .done
    
.next_diff:
    add ecx, 160         ; Next button
    inc r8d
    cmp r8d, 4
    jl .diff_check_loop
    
.check_start:
    ; Check New Game button (x: center-150 to center+150, y: 700-780)
    mov ecx, SCREEN_WIDTH / 2 - 150
    cmp eax, ecx
    jl .check_load
    add ecx, 300
    cmp eax, ecx
    jg .check_load
    cmp edx, 700
    jl .check_load
    cmp edx, 780
    jg .check_load
    
    ; Check if name is entered
    cmp dword [nameLength], 0
    jle .done
    
    ; Start new game
    mov dword [selectedMenuItem], 2
    mov dword [currentGalaxy], 0
    mov dword [currentLevel], 0
    mov dword [totalScore], 0
    ; Clear completed levels
    lea rdi, [levelsCompleted]
    xor rax, rax
    mov rcx, MAX_TOTAL_LEVELS
    rep stosb
    mov dword [gameState], STATE_LEVEL_SELECT
    jmp .done
    
.check_load:
    ; Check Load Game button (x: center-150 to center+150, y: 800-880)
    mov ecx, SCREEN_WIDTH / 2 - 150
    cmp eax, ecx
    jl .done
    add ecx, 300
    cmp eax, ecx
    jg .done
    cmp edx, 800
    jl .done
    cmp edx, 880
    jg .done
    
    ; Check if save game exists
    cmp byte [hasSaveGame], 0
    je .done
    
    ; Load game
    mov dword [selectedMenuItem], 3
    call LoadGame
    mov dword [gameState], STATE_LEVEL_SELECT
    jmp .done
    
.level_select_click:
    ; Check if clicking BACK button
    mov eax, [mouseX]
    mov edx, [mouseY]
    
    cmp eax, 50
    jl .check_nodes
    cmp eax, 250
    jg .check_nodes
    mov ecx, SCREEN_HEIGHT - 150
    cmp edx, ecx
    jl .check_nodes
    add ecx, 60
    cmp edx, ecx
    jg .check_nodes
    
    ; Back button clicked
    mov dword [gameState], STATE_MENU
    jmp .done
    
.check_nodes:
    ; Could implement clicking on level nodes here
    ; For now, use keyboard navigation
    
    jmp .done
    
.mousemove:
    ; Store mouse position for all states
    mov rax, [rbp+40]    ; lParam
    movzx edx, ax        ; LOWORD(lParam) = x
    mov [mouseX], edx
    shr rax, 16
    movzx edx, ax        ; HIWORD(lParam) = y
    mov [mouseY], edx
    
    ; Set custom cursor flag based on state
    cmp dword [gameState], STATE_PLAYING
    je .enable_custom
    cmp dword [gameState], STATE_LEVEL_SELECT  
    je .enable_custom
    cmp dword [gameState], STATE_VICTORY
    je .enable_custom
    cmp dword [gameState], STATE_GAME_OVER
    je .enable_custom
    
    mov byte [showCustomCursor], 0
    jmp .done
    
.enable_custom:
    mov byte [showCustomCursor], 1
    jmp .done
    
.paint:
    mov   rcx, [rbp+16]
    lea   rdx, [ps]
    call  BeginPaint
    mov   rbx, rax

    mov   ecx, [gameState]
    cmp   ecx, STATE_MENU
    je    .menu_branch
    cmp   ecx, STATE_PLAYING
    je    .play_branch
    cmp   ecx, STATE_GAME_OVER
    je    .gameover_branch
    cmp   ecx, STATE_LEVEL_SELECT
    je    .level_select_branch
    cmp   ecx, STATE_VICTORY
    je    .victory_branch

    jmp   .end_paint

.menu_branch:
    call  DrawMenuScene
    jmp   .end_paint

.play_branch:
    call  DrawScene
    jmp   .end_paint
    
.gameover_branch:
    call  DrawGameOverScene
    jmp   .end_paint
    
.level_select_branch:
    call  DrawLevelSelectScene
    jmp   .end_paint
    
.victory_branch:
    call  DrawVictoryScene
    jmp   .end_paint

.end_paint:
    mov   rcx, [rbp+16]
    lea   rdx, [ps]
    call  EndPaint
    xor   rax, rax
    jmp   .done      ; back to the common cleanup


    
.close:
.destroy:
    ; Kill timer
    mov rcx, [rbp+16]
    mov rdx, GAME_TIMER_ID
    call KillTimer
    
    ; Show cursor before exiting
    mov rcx, 1           ; TRUE - show cursor
    call ShowCursor
    
    xor rcx, rcx
    call PostQuitMessage
    xor rax, rax
    jmp .done
    
.setcursor:
    ; Prevent Windows from setting cursor in client area
    mov rax, r9          ; lParam (hit test result)
    and rax, 0xFFFF      ; LOWORD
    cmp rax, HTCLIENT    ; Client area
    jne .default_proc
    
    ; In client area - handle based on cursor visibility
    cmp byte [cursorVisible], 0
    jne .default_proc
    
    ; Set NULL cursor
    xor rcx, rcx
    call SetCursor
    
    ; Return TRUE to indicate we handled it
    mov rax, 1
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
    push r12
    sub rsp, 56
    
    ; Clear screen with gradient
    call ClearScreen
    
    ; Draw starfield
    call DrawStarfield
    
    ; Draw asteroids (behind everything)
    call DrawAsteroids
    
    ; Draw player motion trail
    call DrawPlayerTrail
    
    ; Draw aliens
    call DrawAliens
    
    ; Draw player spaceship with improved design
    call DrawSpaceship
    
    ; Apply screen flash if active (before bullets so they're on top)
    call ApplyScreenFlash
    
    ; Draw bullets
    call DrawBullets
    
    ; Draw HUD (on top of everything)
    call DrawHUD
    
    ; Draw custom cursor on top
    call DrawCustomCursor
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 56
    pop r12
    pop rbp
    ret

; Apply screen flash effect (additive blending)
ApplyScreenFlash:
    push rbp
    mov rbp, rsp
    
    cmp dword [screenFlash], 0
    jle .done
    
    ; Simple white overlay approach
    mov eax, [screenFlash]
    shl eax, 4              ; Multiply by 16 for intensity
    cmp eax, 0x20
    jbe .intensity_ok
    mov eax, 0x20           ; Cap intensity
.intensity_ok:
    ; Create faint white color
    mov ecx, eax
    shl ecx, 8
    or eax, ecx
    shl ecx, 8
    or eax, ecx             ; 0x00XXXXXX
    
    ; Draw flash overlay around player
    mov r8d, [playerX]
    sub r8d, 50
    cmp r8d, 0
    jge .x_ok
    xor r8d, r8d
.x_ok:
    
    mov r9d, [playerY]
    sub r9d, 50
    cmp r9d, 0
    jge .y_ok
    xor r9d, r9d
.y_ok:
    
    mov r10d, PLAYER_WIDTH + 100
    mov r11d, PLAYER_HEIGHT + 100
    call DrawRectangle
    
.done:
    pop rbp
    ret

; Draw a character at position
; R8D = x, R9D = y, R10D = character, R11D = color, [RSP+40] = scale
DrawChar:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 40          ; Shadow space + alignment
    
    ; Save parameters
    mov r14d, r8d        ; x
    mov r15d, r9d        ; y
    mov r12d, r10d       ; character
    mov r13d, r11d       ; color
    
    ; Get scale from stack - it should be at [rbp+48] after all our pushes
    mov ebx, 3           ; Default scale if not provided
    cmp qword [rbp+48], 0
    je .use_default_scale
    mov ebx, [rbp+48]    ; scale (5th parameter on stack)
.use_default_scale:
    
    ; Validate character
    cmp r12d, 32
    jl .done
    cmp r12d, 90
    jg .check_lowercase
    jmp .valid_char
    
.check_lowercase:
    ; Convert lowercase to uppercase
    cmp r12d, 'a'
    jl .done
    cmp r12d, 'z'
    jg .done
    sub r12d, 32         ; Convert to uppercase
    
.valid_char:
    ; Get font data pointer
    sub r12d, 32         ; Offset from space
    imul r12d, 7         ; 7 bytes per character
    lea rsi, [font8bit]
    add rsi, r12
    
    ; Draw character
    xor ecx, ecx         ; Row counter
    
.row_loop:
    movzx edx, byte [rsi + rcx]  ; Get row data
    test edx, edx
    jz .next_row
    
    ; Draw pixels in row
    xor edi, edi         ; Column counter
    push rsi             ; Save font pointer
    mov esi, 0x80        ; Bit mask
    
.col_loop:
    test edx, esi
    jz .skip_pixel
    
    ; Draw scaled pixel
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Calculate position
    mov r8d, r14d        ; x
    mov eax, edi
    imul eax, ebx        ; col * scale
    add r8d, eax
    
    mov r9d, r15d        ; y
    mov eax, ecx
    imul eax, ebx        ; row * scale
    add r9d, eax
    
    mov r10d, ebx        ; width = scale
    mov r11d, ebx        ; height = scale
    mov eax, r13d        ; color
    call DrawRectangle
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    
.skip_pixel:
    shr esi, 1           ; Next bit
    inc edi
    cmp edi, 8
    jl .col_loop
    
    pop rsi              ; Restore font pointer
    
.next_row:
    inc ecx
    cmp ecx, 7
    jl .row_loop
    
.done:
    add rsp, 40
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw improved spaceship design
DrawSpaceship:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    
    mov r14d, [playerX]
    mov r15d, [playerY]
    
    ; Add dash effect (glow/shield) if dashing
    cmp byte [isDashing], 1
    jne .draw_ship
    
    ; Draw dash shield effect
    mov r8d, r14d
    sub r8d, 10
    mov r9d, r15d
    sub r9d, 10
    mov r10d, PLAYER_WIDTH + 20
    mov r11d, PLAYER_HEIGHT + 20
    mov eax, 0x40FFFF00      ; Transparent cyan shield
    call DrawRectangleWithGlow
    
    ; Draw energy particles around ship
    mov eax, [animTimer]
    and eax, 7
    cmp eax, 4
    jg .draw_ship
    
    ; Draw some energy particles
    mov r8d, r14d
    sub r8d, 5
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 2
    mov r10d, 4
    mov r11d, 4
    mov eax, COLOR_WHITE
    call DrawRectangle
    
    add r8d, PLAYER_WIDTH + 6
    call DrawRectangle
    
.draw_ship:
    ; Main body - sleek fighter shape
    ; Draw main fuselage (narrower at top)
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 4
    mov r9d, r15d
    mov r10d, PLAYER_WIDTH / 2
    mov r11d, PLAYER_HEIGHT / 3
    
    ; Choose color based on dash state
    cmp byte [isDashing], 1
    jne .normal_color
    mov eax, COLOR_WHITE     ; Bright white when dashing
    jmp .draw_fuselage
.normal_color:
    mov eax, 0x00E0E000      ; Bright cyan
.draw_fuselage:
    call DrawRectangle
    
    ; Middle section (wider)
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 6
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 3
    mov r10d, PLAYER_WIDTH * 2 / 3
    mov r11d, PLAYER_HEIGHT / 3
    cmp byte [isDashing], 1
    jne .normal_mid
    mov eax, 0x00F0F000      ; Bright when dashing
    jmp .draw_mid
.normal_mid:
    mov eax, COLOR_CYAN
.draw_mid:
    call DrawRectangle
    
    ; Bottom section (widest)
    mov r8d, r14d
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT * 2 / 3
    mov r10d, PLAYER_WIDTH
    mov r11d, PLAYER_HEIGHT / 3
    cmp byte [isDashing], 1
    jne .normal_bottom
    mov eax, 0x00E0E000      ; Bright when dashing
    jmp .draw_bottom
.normal_bottom:
    mov eax, 0x00C0C000      ; Slightly darker cyan
.draw_bottom:
    call DrawRectangle
    
    ; Wing details - angled wings
    ; Left wing
    mov r8d, r14d
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 2
    mov r10d, PLAYER_WIDTH / 4
    mov r11d, PLAYER_HEIGHT / 2
    mov eax, 0x00A0A000      ; Darker cyan for wings
    call DrawRectangle
    
    ; Right wing
    mov r8d, r14d
    add r8d, PLAYER_WIDTH * 3 / 4
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 2
    mov r10d, PLAYER_WIDTH / 4
    mov r11d, PLAYER_HEIGHT / 2
    mov eax, 0x00A0A000      ; Darker cyan for wings
    call DrawRectangle
    
    ; Cockpit window
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 2 - 8
    mov r9d, r15d
    add r9d, 4
    mov r10d, 16
    mov r11d, 12
    mov eax, 0x00FF8000      ; Blue-tinted glass
    call DrawRectangleWithGlow
    
    ; Engine nacelles
    ; Left engine
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 5
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT - 10
    mov r10d, 8
    mov r11d, 10
    mov eax, 0x00606060      ; Dark gray
    call DrawRectangle
    
    ; Right engine
    mov r8d, r14d
    add r8d, PLAYER_WIDTH - PLAYER_WIDTH / 5 - 8
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT - 10
    mov r10d, 8
    mov r11d, 10
    mov eax, 0x00606060      ; Dark gray
    call DrawRectangle
    
    ; Weapon hardpoints (small details)
    ; Left weapon
    mov r8d, r14d
    add r8d, 4
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 2 + 4
    mov r10d, 4
    mov r11d, 8
    mov eax, COLOR_RED
    call DrawRectangle
    
    ; Right weapon
    mov r8d, r14d
    add r8d, PLAYER_WIDTH - 8
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT / 2 + 4
    mov r10d, 4
    mov r11d, 8
    mov eax, COLOR_RED
    call DrawRectangle
    
    ; Nose cone highlight
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 2 - 4
    mov r9d, r15d
    mov r10d, 8
    mov r11d, 4
    mov eax, COLOR_WHITE
    call DrawRectangle
    
    ; Add engine glow effects when moving or dashing
    cmp byte [isDashing], 1
    je .draw_dash_thrust
    cmp byte [keyUp], 1
    je .draw_engine_thrust
    cmp byte [keyDown], 1
    je .draw_engine_thrust
    cmp byte [keyLeft], 1
    je .draw_engine_thrust
    cmp byte [keyRight], 1
    jne .no_thrust
    
.draw_engine_thrust:
    ; Left engine thrust
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 5
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 8
    mov r11d, 12
    mov eax, COLOR_YELLOW
    call DrawRectangleWithGlow
    
    ; Right engine thrust
    mov r8d, r14d
    add r8d, PLAYER_WIDTH - PLAYER_WIDTH / 5 - 8
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 8
    mov r11d, 12
    mov eax, COLOR_YELLOW
    call DrawRectangleWithGlow
    
    ; Extra boost effect when moving up
    cmp byte [keyUp], 1
    jne .draw_small_thrust
    
    ; Center engine (big boost)
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 2 - 10
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 20
    mov r11d, 16
    mov eax, 0x0080FFFF     ; Bright orange-yellow
    call DrawRectangleWithGlow
    jmp .no_thrust
    
.draw_small_thrust:
    ; Small center thrust for other movements
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 2 - 6
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 12
    mov r11d, 8
    mov eax, COLOR_ORANGE
    call DrawRectangle
    jmp .no_thrust
    
.draw_dash_thrust:
    ; Massive thrust effect when dashing
    ; Left engine mega thrust
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 5 - 4
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 16
    mov r11d, 24
    mov eax, 0x00FFFFFF     ; White hot
    call DrawRectangleWithGlow
    
    ; Right engine mega thrust
    mov r8d, r14d
    add r8d, PLAYER_WIDTH - PLAYER_WIDTH / 5 - 12
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 16
    mov r11d, 24
    mov eax, 0x00FFFFFF     ; White hot
    call DrawRectangleWithGlow
    
    ; Center mega thrust
    mov r8d, r14d
    add r8d, PLAYER_WIDTH / 2 - 12
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT
    mov r10d, 24
    mov r11d, 30
    mov eax, 0x0080FFFF     ; Bright orange-yellow
    call DrawRectangleWithGlow
    
.no_thrust:
    ; Add blinking lights on wingtips
    mov eax, [animTimer]
    and eax, 31
    cmp eax, 16
    jg .no_lights
    
    ; Left wingtip light
    mov r8d, r14d
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT * 2 / 3
    mov r10d, 3
    mov r11d, 3
    mov eax, COLOR_RED
    call DrawRectangle
    
    ; Right wingtip light
    mov r8d, r14d
    add r8d, PLAYER_WIDTH - 3
    mov r9d, r15d
    add r9d, PLAYER_HEIGHT * 2 / 3
    mov r10d, 3
    mov r11d, 3
    mov eax, COLOR_GREEN
    call DrawRectangle
    
.no_lights:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw string
; R8D = x, R9D = y, RDX = string ptr, R11D = color, [RSP+40] = scale
DrawString:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48          ; Shadow space + alignment
    
    mov r14d, r8d        ; x
    mov r15d, r9d        ; y
    mov r12, rdx         ; string
    mov r13d, r11d       ; color
    
    ; Get scale from stack
    mov ebx, 3           ; Default scale
    cmp qword [rbp+48], 0
    je .use_default
    mov ebx, [rbp+48]    ; scale (5th parameter on stack)
.use_default:
    
.char_loop:
    movzx r10d, byte [r12]
    test r10d, r10d
    jz .done
    
    ; Draw character
    mov r8d, r14d
    mov r9d, r15d
    mov r11d, r13d
    mov [rsp+32], ebx    ; Pass scale on stack
    call DrawChar
    
    ; Advance x position
    mov eax, 6           ; Character width + spacing
    imul eax, ebx        ; Scale
    add r14d, eax
    
    inc r12
    jmp .char_loop
    
.done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw string centered
; R9D = y, RDX = string ptr, R11D = color, ECX = scale
DrawStringCentered:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 64          ; Shadow space + locals + alignment
    
    mov r12d, r9d        ; Save y
    mov ebx, ecx         ; Save scale
    test ebx, ebx
    jnz .scale_ok
    mov ebx, 3           ; Default scale
.scale_ok:
    
    ; Calculate string length
    mov rdi, rdx
    push rdx             ; Save string pointer
    xor rcx, rcx
.len_loop:
    cmp byte [rdi + rcx], 0
    je .len_done
    inc rcx
    jmp .len_loop
.len_done:
    
    ; Calculate x position for centering
    mov eax, ecx
    imul eax, 6          ; Character width + spacing
    imul eax, ebx        ; Scale
    mov ecx, SCREEN_WIDTH
    sub ecx, eax
    shr ecx, 1           ; Divide by 2
    
    ; Draw string
    pop rdx              ; Restore string pointer
    mov r8d, ecx         ; Centered x
    mov r9d, r12d        ; y
    mov [rsp+32], ebx    ; Pass scale on stack
    call DrawString
    
    add rsp, 64
    pop r12
    pop rbx
    pop rbp
    ret

; Draw menu scene
DrawMenuScene:
    push rbp
    mov rbp, rsp
    push r12
    sub rsp, 56          ; Shadow space + alignment
    
    ; Clear screen with animated gradient
    call DrawMenuBackground
    
    ; Draw title with effects FIRST (before any boxes)
    call DrawAnimatedTitle
    
    ; Draw credit text
    mov r9d, 220
    lea rdx, [creditText]
    mov r11d, COLOR_YELLOW
    mov ecx, 2           ; Small scale
    call DrawStringCentered
    
    ; Draw name entry
    mov r8d, SCREEN_WIDTH / 2 - 200
    mov r9d, 350
    lea rdx, [enterNameText]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 3  ; scale
    call DrawString
    
    ; Draw name entry box
    mov r8d, SCREEN_WIDTH / 2 - 200
    mov r9d, 400
    mov r10d, 400
    mov r11d, 50
    cmp dword [selectedMenuItem], 0
    jne .name_not_selected
    mov eax, COLOR_CYAN
    jmp .draw_name_box
.name_not_selected:
    mov eax, 0x00404040
.draw_name_box:
    call DrawRectangle
    
    ; Draw entered name
    mov r8d, SCREEN_WIDTH / 2 - 190
    mov r9d, 415
    lea rdx, [playerName]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 3  ; scale
    call DrawString
    
    ; Draw cursor if selected
    cmp dword [selectedMenuItem], 0
    jne .no_cursor
    cmp dword [cursorBlink], 0
    je .no_cursor
    
    ; Calculate cursor position
    mov eax, [nameLength]
    imul eax, 18         ; Character width * scale
    add eax, SCREEN_WIDTH / 2 - 190
    mov r8d, eax
    mov r9d, 415
    mov r10d, 3
    mov r11d, 25
    mov eax, COLOR_WHITE
    call DrawRectangle
    
.no_cursor:
    ; Draw difficulty selection
    mov r8d, SCREEN_WIDTH / 2 - 200
    mov r9d, 500
    lea rdx, [difficultyText]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 3  ; scale
    call DrawString
    
    ; Draw difficulty buttons
    mov r12d, 0          ; Difficulty counter
    
.diff_loop:
    ; Calculate button position
    mov r8d, SCREEN_WIDTH / 2 - 320
    mov eax, r12d
    imul eax, 160
    add r8d, eax
    mov r9d, 550
    
    ; Check if selected
    cmp dword [selectedMenuItem], 1
    jne .diff_not_active
    cmp r12d, [selectedDifficulty]
    jne .diff_not_selected
    mov r10d, 150
    mov r11d, 50
    mov eax, COLOR_CYAN
    call DrawRectangleWithGlow
    jmp .draw_diff_text
    
.diff_not_selected:
    mov r10d, 150
    mov r11d, 50
    mov eax, 0x00606060
    call DrawRectangle
    jmp .draw_diff_text
    
.diff_not_active:
    mov r10d, 150
    mov r11d, 50
    cmp r12d, [selectedDifficulty]
    jne .diff_inactive
    mov eax, 0x00808080
    jmp .draw_diff_rect
.diff_inactive:
    mov eax, 0x00404040
.draw_diff_rect:
    call DrawRectangle
    
.draw_diff_text:
    ; Draw difficulty text
    add r8d, 75          ; Center in button
    add r9d, 15
    
    ; Get difficulty text
    cmp r12d, 0
    je .easy
    cmp r12d, 1
    je .normal
    cmp r12d, 2
    je .hard
    lea rdx, [insaneText]
    jmp .draw_diff_name
.easy:
    lea rdx, [easyText]
    jmp .draw_diff_name
.normal:
    lea rdx, [normalText]
    jmp .draw_diff_name
.hard:
    lea rdx, [hardText]
    
.draw_diff_name:
    mov r11d, COLOR_WHITE
    
    ; Center text in button
    push r8
    push r9
    push rdx
    
    ; Calculate text width
    mov rdi, rdx
    xor rcx, rcx
.diff_len_loop:
    cmp byte [rdi + rcx], 0
    je .diff_len_done
    inc rcx
    jmp .diff_len_loop
.diff_len_done:
    imul ecx, 18         ; char width * scale
    shr ecx, 1
    
    pop rdx
    pop r9
    pop r8
    sub r8d, ecx
    
    mov dword [rsp+32], 3  ; scale
    call DrawString
    
    inc r12d
    cmp r12d, 4
    jl .diff_loop
    
    ; Draw New Game button
    mov r8d, SCREEN_WIDTH / 2 - 150
    mov r9d, 700
    mov r10d, 300
    mov r11d, 80
    
    cmp dword [selectedMenuItem], 2
    jne .new_not_selected
    ; Check if name is entered
    cmp dword [nameLength], 0
    jle .new_disabled
    mov eax, COLOR_GREEN
    call DrawRectangleWithGlow
    jmp .draw_new_text
    
.new_not_selected:
    cmp dword [nameLength], 0
    jle .new_disabled
    mov eax, 0x00008000
    jmp .draw_new_rect
    
.new_disabled:
    mov eax, 0x00202020
    
.draw_new_rect:
    call DrawRectangle
    
.draw_new_text:
    mov r9d, 725
    lea rdx, [newGameText]
    cmp dword [nameLength], 0
    jg .new_enabled
    mov r11d, 0x00404040
    jmp .draw_new_label
.new_enabled:
    mov r11d, COLOR_WHITE
.draw_new_label:
    mov ecx, 4
    call DrawStringCentered
    
    ; Draw Load Game button
    mov r8d, SCREEN_WIDTH / 2 - 150
    mov r9d, 800
    mov r10d, 300
    mov r11d, 80
    
    ; Check for save file at startup
    call CheckSaveFile
    
    cmp dword [selectedMenuItem], 3
    jne .load_not_selected
    cmp byte [hasSaveGame], 0
    je .load_disabled
    mov eax, COLOR_CYAN
    call DrawRectangleWithGlow
    jmp .draw_load_text
    
.load_not_selected:
    cmp byte [hasSaveGame], 0
    je .load_disabled
    mov eax, 0x00008080
    jmp .draw_load_rect
    
.load_disabled:
    mov eax, 0x00202020
    
.draw_load_rect:
    call DrawRectangle
    
.draw_load_text:
    mov r9d, 825
    lea rdx, [loadGameText]
    cmp byte [hasSaveGame], 0
    jne .load_enabled
    mov r11d, 0x00404040
    jmp .draw_load_label
.load_enabled:
    mov r11d, COLOR_WHITE
.draw_load_label:
    mov ecx, 4
    call DrawStringCentered
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 56
    pop r12
    pop rbp
    ret

; Draw menu background with animated stars
DrawMenuBackground:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    ; Create gradient background
    mov rbx, [pBits]
    test rbx, rbx
    jz .done
    
    xor r12, r12         ; y counter
    
.gradient_loop:
    ; Calculate gradient color with animation
    mov eax, r12d
    shr eax, 5           ; Divide by 32
    
    ; Add animation
    mov ecx, [animTimer]
    shr ecx, 2
    and ecx, 15
    add eax, ecx
    
    cmp eax, 31
    jbe .color_ok
    mov eax, 31
.color_ok:
    ; Create color: purple to blue gradient
    mov ecx, eax
    shl ecx, 16          ; Blue
    mov edx, eax
    shr edx, 1
    shl edx, 8           ; Green (less)
    or ecx, edx
    mov edx, eax
    shl edx, 1           ; Red (purple tint)
    or ecx, edx
    mov eax, ecx
    
    ; Fill one row
    mov rdi, rbx
    mov ecx, SCREEN_WIDTH
    rep stosd
    
    ; Next row
    add rbx, SCREEN_WIDTH * 4
    inc r12
    cmp r12, SCREEN_HEIGHT
    jl .gradient_loop
    
.done:
    ; Draw animated stars
    call DrawStarfield
    
    pop r12
    pop rbx
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
    
    ; Brightest stars get glow effect
    cmp r10d, 3
    jne .normal_star
    
    ; Draw bright star with glow
    inc r10d               ; size = speed + 1
    mov r11d, r10d
    mov r13d, eax          ; Save color
    mov eax, r13d
    call DrawRectangleWithGlow
    jmp .next_star
    
.normal_star:
    inc r10d               ; size = speed + 1 (2-4 pixels)
    mov r11d, r10d         ; square stars
    mov r13d, eax          ; Save color
    mov eax, r13d
    call DrawRectangle
    
.next_star:
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
    
    ; Draw bullet as a plasma bolt
    mov r8d, [rbx]          ; x
    mov r9d, [rbx+4]        ; y
    
    ; Main bullet body (bright core)
    mov r10d, BULLET_WIDTH
    mov r11d, BULLET_HEIGHT
    mov eax, 0x00FFFFFF     ; White hot core
    call DrawRectangle
    
    ; Outer glow
    sub r8d, 2
    sub r9d, 2
    add r10d, 4
    add r11d, 4
    mov eax, COLOR_YELLOW
    call DrawRectangleWithGlow
    
    ; Trail effect
    mov r8d, [rbx]          ; x
    mov r9d, [rbx+4]        ; y
    add r9d, BULLET_HEIGHT
    mov r10d, BULLET_WIDTH
    mov r11d, 6
    mov eax, 0x00808000     ; Faded yellow trail
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
    ; Load arrow cursor for menu, we'll hide it in game
    xor rcx, rcx                      ; NULL instance
    mov rdx, IDC_ARROW
    call LoadCursorA
    mov [rdi+40], rax                 ; hCursor
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
    
    ; Initialize cursor state
    mov byte [cursorVisible], 1   ; Start with system cursor visible
    
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
    push rbx
    push r12
    
    ; Check if pBits is valid
    mov rbx, [pBits]
    test rbx, rbx
    jz .done
    
    ; Create gradient background (darker at top, slightly lighter at bottom)
    xor r12, r12              ; y counter
    
.gradient_loop:
    ; Calculate gradient color (very subtle blue gradient)
    mov eax, r12d
    shr eax, 6                ; Divide by 64 for gradual change
    cmp eax, 15
    jbe .color_ok
    mov eax, 15              ; Cap at 15
.color_ok:
    ; Create color: 0x00BBGGRR (adding blue component)
    shl eax, 16              ; Blue channel
    
    ; Fill one row
    mov rdi, rbx
    mov ecx, SCREEN_WIDTH
    rep stosd
    
    ; Next row
    add rbx, SCREEN_WIDTH * 4
    inc r12
    cmp r12, SCREEN_HEIGHT
    jl .gradient_loop
    
.done:
    pop r12
    pop rbx
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

; Draw player motion trail
DrawPlayerTrail:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Only draw trail if moving
    cmp byte [keyLeft], 1
    je .draw_trail
    cmp byte [keyRight], 1
    je .draw_trail
    cmp byte [keyUp], 1
    je .draw_trail
    cmp byte [keyDown], 1
    je .draw_trail
    jmp .done
    
.draw_trail:
    mov r12, TRAIL_LENGTH
    mov ebx, [trailIndex]
    
.trail_loop:
    dec ebx
    and ebx, TRAIL_LENGTH - 1
    
    ; Get trail position
    lea rdi, [trailX]
    mov r8d, [rdi + rbx*4]
    lea rdi, [trailY]
    mov r9d, [rdi + rbx*4]
    
    ; Skip if position is 0 (uninitialized)
    test r8d, r8d
    jz .next_trail
    
    ; Calculate fade (older = fainter)
    mov eax, r12d
    imul eax, 0x10          ; Fade factor
    cmp eax, 0x80
    jbe .fade_ok
    mov eax, 0x80
.fade_ok:
    ; Check if dashing for different trail color
    cmp byte [isDashing], 1
    je .dash_trail
    
    ; Normal trail - blue-white color for engine trail
    mov ecx, eax
    shl ecx, 16             ; Blue channel
    mov edx, eax
    shr edx, 1
    or ecx, edx             ; Some red
    shl edx, 8
    or ecx, edx             ; Some green
    mov eax, ecx            ; Blue-white fade
    jmp .draw_trail_parts
    
.dash_trail:
    ; Dash trail - bright cyan-white
    mov ecx, eax
    shl ecx, 16             ; Blue channel
    or ecx, eax             ; Red channel
    shl eax, 8
    or ecx, eax             ; Green channel (full white)
    mov eax, ecx
    
.draw_trail_parts:
    ; Draw engine trail from both engines
    ; Left engine trail
    add r8d, PLAYER_WIDTH / 5
    add r9d, PLAYER_HEIGHT - 5
    mov r10d, 8
    mov r11d, 10
    call DrawRectangle
    
    ; Right engine trail
    add r8d, PLAYER_WIDTH - PLAYER_WIDTH / 5 * 2 - 8
    mov r10d, 8
    mov r11d, 10
    call DrawRectangle
    
    ; Add center trail if dashing
    cmp byte [isDashing], 1
    jne .next_trail
    
    sub r8d, PLAYER_WIDTH / 2 - PLAYER_WIDTH / 5 + 4
    add r8d, PLAYER_WIDTH / 2 - 10
    mov r10d, 20
    mov r11d, 12
    call DrawRectangle
    
.next_trail:
    dec r12
    jnz .trail_loop
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw rectangle with glow effect
DrawRectangleWithGlow:
    ; R8D = x, R9D = y, R10D = width, R11D = height, EAX = color
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Save original parameters
    mov r14d, eax        ; Save color
    mov r15d, r8d        ; Save x
    mov r12d, r9d        ; Save y
    mov r13d, r10d       ; Save width
    mov ebx, r11d        ; Save height
    
    ; Draw glow layers (outer to inner)
    ; Layer 1: Very faint, large
    mov eax, r14d
    shr eax, 3           ; Divide color by 8 for very faint glow
    and eax, 0x001F1F1F  ; Mask to prevent overflow
    
    mov r8d, r15d
    sub r8d, 6           ; Expand by 6 pixels
    mov r9d, r12d
    sub r9d, 6
    mov r10d, r13d
    add r10d, 12
    mov r11d, ebx
    add r11d, 12
    call DrawRectangle
    
    ; Layer 2: Faint, medium
    mov eax, r14d
    shr eax, 2           ; Divide color by 4
    and eax, 0x003F3F3F
    
    mov r8d, r15d
    sub r8d, 4           ; Expand by 4 pixels
    mov r9d, r12d
    sub r9d, 4
    mov r10d, r13d
    add r10d, 8
    mov r11d, ebx
    add r11d, 8
    call DrawRectangle
    
    ; Layer 3: Medium glow
    mov eax, r14d
    shr eax, 1           ; Divide color by 2
    and eax, 0x007F7F7F
    
    mov r8d, r15d
    sub r8d, 2           ; Expand by 2 pixels
    mov r9d, r12d
    sub r9d, 2
    mov r10d, r13d
    add r10d, 4
    mov r11d, ebx
    add r11d, 4
    call DrawRectangle
    
    ; Draw the actual rectangle (bright core)
    mov eax, r14d
    mov r8d, r15d
    mov r9d, r12d
    mov r10d, r13d
    mov r11d, ebx
    call DrawRectangle
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Initialize game state
InitGame:
    push rbp
    mov rbp, rsp
    
    ; Initialize player position (center bottom)
    mov eax, SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
    mov [playerX], eax
    mov eax, SCREEN_HEIGHT - PLAYER_HEIGHT - 50
    mov [playerY], eax
    
    ; Init menu variables (only if coming from menu)
    cmp dword [gameState], STATE_PLAYING
    jne .init_menu_vars
    jmp .skip_menu_vars
    
.init_menu_vars:
    mov dword [selectedMenuItem], 0
    mov dword [selectedDifficulty], 1  ; Default to Normal
    mov dword [cursorBlink], 0
    mov dword [animTimer], 0
    mov dword [titleAnimFrame], 0
    mov dword [mouseX], SCREEN_WIDTH / 2
    mov dword [mouseY], SCREEN_HEIGHT / 2
    ; Don't reset nameLength - it's already set from menu
    
    ; Initialize cursor state and position
    mov byte [showCustomCursor], 0
    mov byte [cursorVisible], 1      ; Start with system cursor visible
    mov dword [mouseX], SCREEN_WIDTH / 2
    mov dword [mouseY], SCREEN_HEIGHT / 2
    
.skip_menu_vars:
    ; Initialize game variables
    mov dword [playerScore], 0
    mov dword [playerLives], 3
    mov dword [alienSpawnTimer], 0
    mov dword [asteroidSpawnTimer], 0
    mov dword [enemiesKilled], 0
    
    ; Set level parameters only if playing
    cmp dword [gameState], STATE_PLAYING
    jne .skip_level_params
    call SetLevelParameters
.skip_level_params:
    
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
    mov [keyShift], al
    
    ; Initialize dash
    mov dword [dashAmount], DASH_MAX
    mov dword [dashCooldown], 0
    mov byte [isDashing], 0
    
    ; Clear bullets
    lea rdi, [bullets]
    xor rax, rax
    mov rcx, MAX_BULLETS * 3  ; 3 dwords per bullet
    rep stosd
    mov dword [bulletCooldown], 0
    
    ; Clear aliens
    lea rdi, [aliens]
    xor rax, rax
    mov rcx, MAX_ALIENS * 4   ; 4 dwords per alien
    rep stosd
    
    ; Clear asteroids
    lea rdi, [asteroids]
    xor rax, rax
    mov rcx, MAX_ASTEROIDS * 4  ; 4 dwords per asteroid
    rep stosd
    
    ; Clear trail
    lea rdi, [trailX]
    mov rcx, TRAIL_LENGTH
    rep stosd
    lea rdi, [trailY]
    mov rcx, TRAIL_LENGTH
    rep stosd
    mov dword [trailIndex], 0
    mov dword [screenFlash], 0
    
    ; Don't clear player name - it's already set from menu
    
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
    
    ; Only update if playing
    cmp dword [gameState], STATE_PLAYING
    jne .done
    
    ; Update dash state
    call UpdateDash
    
    ; Update player movement
    call UpdatePlayer
    
    ; Update bullets
    call UpdateBullets
    
    ; Update aliens
    call UpdateAliens
    
    ; Update asteroids
    call UpdateAsteroids
    
    ; Update starfield
    call UpdateStarfield
    
    ; Check collisions
    call CheckCollisions
    
    ; Spawn new enemies
    call SpawnEnemies
    
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
    jle .check_flash
    dec dword [bulletCooldown]
    
.check_flash:
    ; Decrease screen flash
    cmp dword [screenFlash], 0
    jle .check_level_complete
    dec dword [screenFlash]
    
.check_level_complete:
    ; Check if level is complete
    mov eax, [enemiesKilled]
    cmp eax, [enemiesRequired]
    jl .done
    
    ; Level complete!
    call CompleteLevel
    
.done:
    add rsp, 32
    pop rbp
    ret

; Complete current level
CompleteLevel:
    push rbp
    mov rbp, rsp
    
    ; Mark level as completed
    mov eax, [currentGalaxy]
    imul eax, LEVELS_PER_GALAXY
    add eax, [currentLevel]
    call MarkLevelCompleted
    
    ; Add level score to total
    mov eax, [playerScore]
    add [totalScore], eax
    
    ; Save progress
    call SaveGame
    
    ; Check if this was the last level in galaxy
    mov eax, [currentLevel]
    cmp eax, LEVELS_PER_GALAXY - 1
    jl .next_level
    
    ; Galaxy complete - check if more galaxies
    mov eax, [currentGalaxy]
    cmp eax, MAX_GALAXIES - 1
    jge .game_complete
    
    ; Move to next galaxy
    inc dword [currentGalaxy]
    mov dword [currentLevel], 0
    mov dword [selectedNode], 0
    jmp .show_victory
    
.next_level:
    ; Move to next level in current galaxy
    inc dword [currentLevel]
    inc dword [selectedNode]
    
.show_victory:
    mov dword [gameState], STATE_VICTORY
    jmp .done
    
.game_complete:
    ; All galaxies complete
    mov dword [gameState], STATE_VICTORY
    
.done:
    pop rbp
    ret

; Update dash state
UpdateDash:
    push rbp
    mov rbp, rsp
    
    ; Check if on cooldown
    cmp dword [dashCooldown], 0
    jle .check_dash
    
    ; Decrease cooldown
    dec dword [dashCooldown]
    
    ; If cooldown just finished, reset dash
    cmp dword [dashCooldown], 0
    jne .done
    mov dword [dashAmount], DASH_MAX
    jmp .done
    
.check_dash:
    ; Check if shift is pressed and we have dash
    cmp byte [keyShift], 1
    jne .recharge
    cmp dword [dashAmount], 0
    jle .start_cooldown
    
    ; Activate dash
    mov byte [isDashing], 1
    dec dword [dashAmount]
    
    ; Check if dash just depleted
    cmp dword [dashAmount], 0
    jg .done
    
.start_cooldown:
    ; Start cooldown
    mov dword [dashCooldown], DASH_COOLDOWN_MAX
    mov byte [isDashing], 0
    jmp .done
    
.recharge:
    ; Not dashing, recharge if not full
    mov byte [isDashing], 0
    cmp dword [dashAmount], DASH_MAX
    jge .done
    
    ; Recharge dash
    add dword [dashAmount], DASH_RECHARGE_RATE
    cmp dword [dashAmount], DASH_MAX
    jle .done
    mov dword [dashAmount], DASH_MAX
    
.done:
    pop rbp
    ret

; Update player position based on input
UpdatePlayer:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Store old position in trail
    mov ebx, [trailIndex]
    and ebx, TRAIL_LENGTH - 1    ; Wrap around
    lea rdi, [trailX]
    mov eax, [playerX]
    mov [rdi + rbx*4], eax
    lea rdi, [trailY]
    mov eax, [playerY]
    mov [rdi + rbx*4], eax
    inc dword [trailIndex]
    
    ; Calculate speed multiplier
    mov ecx, PLAYER_SPEED
    cmp byte [isDashing], 1
    jne .normal_speed
    shl ecx, 1               ; Double speed when dashing
    
.normal_speed:
    ; Horizontal movement
    xor eax, eax
    cmp byte [keyLeft], 1
    jne .check_right
    sub eax, ecx
.check_right:
    cmp byte [keyRight], 1
    jne .apply_x
    add eax, ecx
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
    sub eax, ecx
.check_down:
    cmp byte [keyDown], 1
    jne .apply_y
    add eax, ecx
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
    
    pop rbx
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
    ; Set bullet position (from nose of ship)
    mov eax, [playerX]
    add eax, PLAYER_WIDTH / 2 - BULLET_WIDTH / 2
    mov [rbx], eax          ; x
    
    mov eax, [playerY]
    sub eax, BULLET_HEIGHT / 2
    mov [rbx+4], eax        ; y
    
    mov dword [rbx+8], 1    ; active
    
    ; Trigger screen flash
    mov dword [screenFlash], 3
    
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

; Draw HUD (score and player name)
DrawHUD:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    
    ; Draw player name
    mov r8d, 20              ; x position
    mov r9d, 20              ; y position
    lea rdx, [playerName]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 3    ; scale
    call DrawString
    
    ; Draw "Score: " text
    mov r8d, 20
    mov r9d, 50
    lea rdx, [scoreText]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 3    ; scale
    call DrawString
    
    ; Convert score to string
    mov eax, [playerScore]
    lea rdi, [rsp+64]        ; Local buffer for score string
    call IntToString
    
    ; Draw score number
    mov r8d, 140             ; After "Score: "
    mov r9d, 50
    lea rdx, [rsp+64]        ; Score string
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 3    ; scale
    call DrawString
    
    ; Draw level info
    mov r8d, 20
    mov r9d, 80
    lea rdx, [levelText]
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 2    ; scale
    call DrawString
    
    ; Draw galaxy-level number
    mov eax, [currentGalaxy]
    inc eax
    lea rdi, [rsp+64]
    call IntToString
    mov r8d, 80
    mov r9d, 80
    lea rdx, [rsp+64]
    mov r11d, COLOR_CYAN
    mov dword [rsp+32], 2
    call DrawString
    
    ; Draw galaxy-level separator
    mov r8d, 95
    mov r9d, 80
    lea rdx, [dashSeparator]  ; Need to add this string
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 2
    call DrawString
    
    mov eax, [currentLevel]
    inc eax
    lea rdi, [rsp+64]
    call IntToString
    mov r8d, 110
    mov r9d, 80
    lea rdx, [rsp+64]
    mov r11d, COLOR_CYAN
    mov dword [rsp+32], 2
    call DrawString
    
    ; Draw enemies killed / required
    mov r8d, 20
    mov r9d, 100
    mov eax, [enemiesKilled]
    lea rdi, [rsp+64]
    call IntToString
    lea rdx, [rsp+64]
    mov r11d, COLOR_GREEN
    mov dword [rsp+32], 2
    call DrawString
    
    mov r8d, 50
    mov r9d, 100
    lea rdx, [slashSeparator]  ; Need to add this string
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 2
    call DrawString
    
    mov r8d, 65
    mov r9d, 100
    mov eax, [enemiesRequired]
    lea rdi, [rsp+64]
    call IntToString
    lea rdx, [rsp+64]
    mov r11d, COLOR_RED
    mov dword [rsp+32], 2
    call DrawString
    
    ; Draw dash bar
    call DrawDashBar
    
    add rsp, 96
    pop rbp
    ret

; Draw custom cursor (crosshair style)
DrawCustomCursor:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Only draw if custom cursor is enabled
    cmp byte [showCustomCursor], 0
    je .done
    
    ; Get mouse position
    mov r8d, [mouseX]
    mov r9d, [mouseY]
    
    ; Check bounds to prevent drawing off-screen
    cmp r8d, 30
    jl .done
    cmp r9d, 30
    jl .done
    mov eax, SCREEN_WIDTH - 30
    cmp r8d, eax
    jg .done
    mov eax, SCREEN_HEIGHT - 30
    cmp r9d, eax
    jg .done
    
    ; Animated color based on timer
    mov eax, [animTimer]
    and eax, 31
    cmp eax, 16
    jl .bright_cursor
    mov ebx, COLOR_CYAN
    jmp .draw_cursor
.bright_cursor:
    mov ebx, COLOR_GREEN
    
.draw_cursor:
    ; Draw crosshair cursor
    ; Horizontal line
    push r8
    push r9
    sub r8d, 15          ; Left of cursor
    mov r10d, 30         ; Width
    mov r11d, 2          ; Height
    mov eax, ebx
    call DrawRectangle
    pop r9
    pop r8
    
    ; Vertical line
    push r8
    push r9
    sub r9d, 15          ; Top of cursor
    mov r10d, 2          ; Width
    mov r11d, 30         ; Height
    mov eax, ebx
    call DrawRectangle
    pop r9
    pop r8
    
    ; Center dot with glow
    sub r8d, 4
    sub r9d, 4
    mov r10d, 8
    mov r11d, 8
    mov eax, COLOR_WHITE
    call DrawRectangleWithGlow
    
    ; Draw targeting corners with animation
    mov r8d, [mouseX]
    mov r9d, [mouseY]
    
    ; Calculate corner animation offset
    mov eax, [animTimer]
    and eax, 63
    shr eax, 2           ; 0-15 range
    cmp eax, 8
    jl .expand
    sub eax, 16
    neg eax
.expand:
    mov ebx, eax         ; Save animation offset
    
    ; Top-left corner
    mov eax, 25
    sub eax, ebx         ; Animate corner distance
    push rax
    mov ecx, r8d
    sub ecx, eax         ; x position
    push rcx
    mov ecx, r9d
    sub ecx, eax         ; y position
    push rcx
    
    pop r9               ; y
    pop r8               ; x
    mov r10d, 10
    mov r11d, 2
    mov eax, COLOR_YELLOW
    call DrawRectangle
    mov r10d, 2
    mov r11d, 10
    call DrawRectangle
    pop rax              ; Restore offset
    
    ; Top-right corner
    mov r8d, [mouseX]
    mov r9d, [mouseY]
    mov ecx, 25
    sub ecx, ebx
    add r8d, ecx
    sub r8d, 10
    sub r9d, ecx
    mov r10d, 10
    mov r11d, 2
    call DrawRectangle
    add r8d, 8
    mov r10d, 2
    mov r11d, 10
    call DrawRectangle
    
    ; Bottom-left corner
    mov r8d, [mouseX]
    mov r9d, [mouseY]
    mov ecx, 25
    sub ecx, ebx
    sub r8d, ecx
    add r9d, ecx
    sub r9d, 2
    mov r10d, 10
    mov r11d, 2
    call DrawRectangle
    mov r10d, 2
    sub r9d, 8
    mov r11d, 10
    call DrawRectangle
    
    ; Bottom-right corner
    mov r8d, [mouseX]
    mov r9d, [mouseY]
    mov ecx, 25
    sub ecx, ebx
    add r8d, ecx
    sub r8d, 10
    add r9d, ecx
    sub r9d, 2
    mov r10d, 10
    mov r11d, 2
    call DrawRectangle
    add r8d, 8
    sub r9d, 8
    mov r10d, 2
    mov r11d, 10
    call DrawRectangle
    
.done:
    pop rbx
    pop rbp
    ret

; Draw dash bar on bottom left
DrawDashBar:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 48              ; Add proper shadow space
    
    ; Bar position and size
    mov r8d, 20              ; x position
    mov r9d, SCREEN_HEIGHT - 80  ; y position (bottom left)
    mov r10d, 200            ; max bar width
    mov r11d, 20             ; bar height
    
    ; Draw background (dark gray)
    mov eax, 0x00202020
    call DrawRectangle
    
    ; Draw border
    sub r8d, 2
    sub r9d, 2
    add r10d, 4
    add r11d, 4
    mov eax, 0x00606060
    call DrawRectangle
    
    ; Calculate filled width
    mov eax, [dashAmount]
    imul eax, 200            ; max width
    xor edx, edx
    mov ecx, DASH_MAX
    div ecx                  ; dashAmount * 200 / DASH_MAX
    mov ebx, eax             ; Save filled width
    
    ; Draw filled portion
    test ebx, ebx
    jz .no_fill
    
    mov r8d, 20
    mov r9d, SCREEN_HEIGHT - 80
    mov r10d, ebx            ; filled width
    mov r11d, 20
    
    ; Choose color based on state
    cmp dword [dashCooldown], 0
    jg .cooldown_color
    cmp byte [isDashing], 1
    je .dashing_color
    
    ; Normal color (cyan)
    mov eax, COLOR_CYAN
    jmp .draw_fill
    
.cooldown_color:
    ; Cooldown color (red)
    mov eax, COLOR_RED
    jmp .draw_fill
    
.dashing_color:
    ; Dashing color (bright yellow)
    mov eax, COLOR_YELLOW
    
.draw_fill:
    call DrawRectangle
    
.no_fill:
    ; Draw "DASH" text using DrawString instead of individual chars
    mov r8d, 25
    mov r9d, SCREEN_HEIGHT - 105
    lea rdx, [dashText]      ; Need to add this string
    mov r11d, COLOR_WHITE
    mov dword [rsp+32], 2    ; scale
    call DrawString
    
    ; Draw instruction text if dash is available
    cmp dword [dashCooldown], 0
    jg .skip_instruction
    
    mov r8d, 80
    mov r9d, SCREEN_HEIGHT - 75
    lea rdx, [dashInstructionText]
    mov r11d, 0x00808080     ; Gray text
    mov dword [rsp+32], 2    ; scale
    call DrawString
    
.skip_instruction:
    add rsp, 48
    pop rbx
    pop rbp
    ret

; Convert integer to string
IntToString:
    ; EAX = number, RDI = buffer
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    
    mov ebx, 10              ; Divisor
    lea rsi, [rdi+10]        ; End of buffer
    mov byte [rsi], 0        ; Null terminator
    dec rsi
    
    test eax, eax
    jnz .convert_loop
    mov byte [rsi], '0'      ; Handle zero
    jmp .reverse
    
.convert_loop:
    xor edx, edx
    div ebx                  ; Divide by 10
    add dl, '0'              ; Convert to ASCII
    mov [rsi], dl
    dec rsi
    test eax, eax
    jnz .convert_loop
    
.reverse:
    inc rsi
    ; Copy to start of buffer
    mov rax, rsi
.copy_loop:
    mov bl, [rax]
    test bl, bl
    jz .done
    mov [rdi], bl
    inc rdi
    inc rax
    jmp .copy_loop
.done:
    mov byte [rdi], 0
    
    pop rsi
    pop rbx
    pop rbp
    ret

; Spawn new enemies
SpawnEnemies:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Spawn aliens
    dec dword [alienSpawnTimer]
    cmp dword [alienSpawnTimer], 0
    jg .check_asteroids
    
    ; Reset timer based on difficulty
    mov eax, [selectedDifficulty]
    imul eax, 10             ; 0, 10, 20, 30
    mov ecx, ALIEN_SPAWN_DELAY
    sub ecx, eax             ; Harder = faster spawning
    cmp ecx, 20              ; Minimum spawn delay
    jge .timer_ok
    mov ecx, 20
.timer_ok:
    mov [alienSpawnTimer], ecx
    
    ; Find free alien slot
    lea rbx, [aliens]
    mov ecx, MAX_ALIENS
.find_alien_slot:
    cmp dword [rbx+8], 0     ; Check active flag
    je .spawn_alien
    add rbx, 16
    loop .find_alien_slot
    jmp .check_asteroids
    
.spawn_alien:
    ; Random X position
    rdtsc
    xor edx, edx
    mov ecx, SCREEN_WIDTH - ALIEN_WIDTH
    div ecx
    mov [rbx], edx           ; x position
    
    mov dword [rbx+4], -ALIEN_HEIGHT  ; y position (above screen)
    mov dword [rbx+8], 1     ; active
    mov dword [rbx+12], 0    ; type (basic for now)
    
.check_asteroids:
    ; Spawn asteroids
    dec dword [asteroidSpawnTimer]
    cmp dword [asteroidSpawnTimer], 0
    jg .done
    
    ; Reset timer
    mov dword [asteroidSpawnTimer], ASTEROID_SPAWN_DELAY
    
    ; Find free asteroid slot
    lea rbx, [asteroids]
    mov ecx, MAX_ASTEROIDS
.find_asteroid_slot:
    cmp dword [rbx+8], 0     ; Check active flag
    je .spawn_asteroid
    add rbx, 16
    loop .find_asteroid_slot
    jmp .done
    
.spawn_asteroid:
    ; Random X position
    rdtsc
    xor edx, edx
    mov ecx, SCREEN_WIDTH - ASTEROID_SIZE
    div ecx
    mov [rbx], edx           ; x position
    
    mov dword [rbx+4], -ASTEROID_SIZE  ; y position
    mov dword [rbx+8], 1     ; active
    rdtsc
    mov [rbx+12], eax        ; random rotation
    
.done:
    pop rbx
    pop rbp
    ret

; Update aliens
UpdateAliens:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [aliens]
    mov r12, MAX_ALIENS
    
.alien_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_alien
    
    ; Move alien down
    mov eax, [rbx+4]         ; y position
    add eax, ALIEN_SPEED
    mov [rbx+4], eax
    
    ; Check if off screen
    cmp eax, SCREEN_HEIGHT
    jl .next_alien
    mov dword [rbx+8], 0     ; Deactivate
    
.next_alien:
    add rbx, 16
    dec r12
    jnz .alien_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Update asteroids
UpdateAsteroids:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [asteroids]
    mov r12, MAX_ASTEROIDS
    
.asteroid_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_asteroid
    
    ; Move asteroid down
    mov eax, [rbx+4]         ; y position
    add eax, ASTEROID_SPEED
    mov [rbx+4], eax
    
    ; Rotate
    add dword [rbx+12], 3
    
    ; Check if off screen
    cmp eax, SCREEN_HEIGHT
    jl .next_asteroid
    mov dword [rbx+8], 0     ; Deactivate
    
.next_asteroid:
    add rbx, 16
    dec r12
    jnz .asteroid_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Check all collisions
CheckCollisions:
    push rbp
    mov rbp, rsp
    
    ; Check bullet-alien collisions
    call CheckBulletAlienCollisions
    
    ; Check player-asteroid collisions
    call CheckPlayerAsteroidCollisions
    
    ; Check player-alien collisions
    call CheckPlayerAlienCollisions
    
    pop rbp
    ret

; Check bullet-alien collisions
CheckBulletAlienCollisions:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    lea rbx, [bullets]
    mov r12, MAX_BULLETS
    
.bullet_loop:
    cmp dword [rbx+8], 0     ; Check if bullet active
    je .next_bullet
    
    ; Check against all aliens
    lea r13, [aliens]
    mov r14, MAX_ALIENS
    
.alien_loop:
    cmp dword [r13+8], 0     ; Check if alien active
    je .next_alien
    
    ; Check X overlap
    mov eax, [rbx]           ; Bullet left edge
    mov ecx, [r13]           ; Alien left edge
    add ecx, ALIEN_WIDTH     ; Alien right edge
    cmp eax, ecx             ; Bullet left >= alien right?
    jge .next_alien          ; No collision
    
    mov eax, [rbx]
    add eax, BULLET_WIDTH    ; Bullet right edge
    mov ecx, [r13]           ; Alien left edge
    cmp eax, ecx             ; Bullet right <= alien left?
    jle .next_alien          ; No collision
    
    ; Check Y overlap
    mov eax, [rbx+4]         ; Bullet top edge
    mov ecx, [r13+4]         ; Alien top edge
    add ecx, ALIEN_HEIGHT    ; Alien bottom edge
    cmp eax, ecx             ; Bullet top >= alien bottom?
    jge .next_alien          ; No collision
    
    mov eax, [rbx+4]
    add eax, BULLET_HEIGHT   ; Bullet bottom edge
    mov ecx, [r13+4]         ; Alien top edge
    cmp eax, ecx             ; Bullet bottom <= alien top?
    jle .next_alien          ; No collision
    
    ; Collision detected!
    mov dword [rbx+8], 0     ; Deactivate bullet
    mov dword [r13+8], 0     ; Deactivate alien
    add dword [playerScore], 10  ; Add score
    inc dword [enemiesKilled]     ; Increment kill counter
    mov dword [screenFlash], 5   ; Flash effect
    
.next_alien:
    add r13, 16
    dec r14
    jnz .alien_loop
    
.next_bullet:
    add rbx, 12
    dec r12
    jnz .bullet_loop
    
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Check player-asteroid collisions
CheckPlayerAsteroidCollisions:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [asteroids]
    mov r12, MAX_ASTEROIDS
    
.asteroid_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_asteroid
    
    ; Add margin to make hitbox smaller (more forgiving)
    mov eax, [playerX]       
    add eax, 8               ; Player left edge with margin
    mov ecx, [rbx]           
    add ecx, ASTEROID_SIZE   
    sub ecx, 8               ; Asteroid right edge with margin
    cmp eax, ecx             
    jge .next_asteroid       
    
    mov eax, [playerX]
    add eax, PLAYER_WIDTH    
    sub eax, 8               ; Player right edge with margin
    mov ecx, [rbx]           
    add ecx, 8               ; Asteroid left edge with margin
    cmp eax, ecx             
    jle .next_asteroid       
    
    ; Check Y overlap with margin
    mov eax, [playerY]       
    add eax, 8               ; Player top edge with margin
    mov ecx, [rbx+4]         
    add ecx, ASTEROID_SIZE   
    sub ecx, 8               ; Asteroid bottom edge with margin
    cmp eax, ecx             
    jge .next_asteroid       
    
    mov eax, [playerY]
    add eax, PLAYER_HEIGHT   
    sub eax, 8               ; Player bottom edge with margin
    mov ecx, [rbx+4]         
    add ecx, 8               ; Asteroid top edge with margin
    cmp eax, ecx             
    jle .next_asteroid       
    
    ; Collision detected!
    cmp byte [isDashing], 1
    je .destroy_asteroid
    
    ; Not dashing - game over
    mov dword [gameState], STATE_GAME_OVER
    jmp .next_asteroid
    
.destroy_asteroid:
    ; Dashing - destroy asteroid and add score
    mov dword [rbx+8], 0     ; Deactivate asteroid
    add dword [playerScore], 25  ; Points for asteroid
    inc dword [enemiesKilled]     ; Count toward level completion
    mov dword [screenFlash], 8   ; Bigger flash
    
.next_asteroid:
    add rbx, 16
    dec r12
    jnz .asteroid_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Check player-alien collisions
CheckPlayerAlienCollisions:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [aliens]
    mov r12, MAX_ALIENS
    
.alien_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_alien
    
    ; Add margin to make hitbox smaller (more forgiving)
    mov eax, [playerX]       
    add eax, 6               ; Player left edge with margin
    mov ecx, [rbx]           
    add ecx, ALIEN_WIDTH     
    sub ecx, 6               ; Alien right edge with margin
    cmp eax, ecx             
    jge .next_alien          
    
    mov eax, [playerX]
    add eax, PLAYER_WIDTH    
    sub eax, 6               ; Player right edge with margin
    mov ecx, [rbx]           
    add ecx, 6               ; Alien left edge with margin
    cmp eax, ecx             
    jle .next_alien          
    
    ; Check Y overlap with margin
    mov eax, [playerY]       
    add eax, 6               ; Player top edge with margin
    mov ecx, [rbx+4]         
    add ecx, ALIEN_HEIGHT    
    sub ecx, 6               ; Alien bottom edge with margin
    cmp eax, ecx             
    jge .next_alien          
    
    mov eax, [playerY]
    add eax, PLAYER_HEIGHT   
    sub eax, 6               ; Player bottom edge with margin
    mov ecx, [rbx+4]         
    add ecx, 6               ; Alien top edge with margin
    cmp eax, ecx             
    jle .next_alien          
    
    ; Collision detected!
    cmp byte [isDashing], 1
    je .destroy_alien
    
    ; Not dashing - game over
    mov dword [gameState], STATE_GAME_OVER
    jmp .next_alien
    
.destroy_alien:
    ; Dashing - destroy alien and add score
    mov dword [rbx+8], 0     ; Deactivate alien
    add dword [playerScore], 50  ; Points for alien
    inc dword [enemiesKilled]     ; Count toward level completion
    mov dword [screenFlash], 10  ; Big flash
    
.next_alien:
    add rbx, 16
    dec r12
    jnz .alien_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Draw aliens
DrawAliens:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    lea rbx, [aliens]
    mov r12, MAX_ALIENS
    
.alien_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_alien
    
    ; Draw alien body
    mov r8d, [rbx]           ; x
    mov r9d, [rbx+4]         ; y
    
    ; Main body (green)
    add r8d, 10
    add r9d, 8
    mov r10d, 20
    mov r11d, 16
    mov eax, COLOR_GREEN
    call DrawRectangle
    
    ; Wings
    sub r8d, 10
    add r9d, 4
    mov r10d, 40
    mov r11d, 8
    mov eax, 0x00008000      ; Dark green
    call DrawRectangle
    
    ; Eyes (red)
    add r8d, 8
    sub r9d, 8
    mov r10d, 4
    mov r11d, 4
    mov eax, COLOR_RED
    call DrawRectangle
    
    add r8d, 16
    mov r10d, 4
    mov r11d, 4
    call DrawRectangle
    
.next_alien:
    add rbx, 16
    dec r12
    jnz .alien_loop
    
    pop r12
    pop rbx
    pop rbp
    ret

; Draw asteroids
DrawAsteroids:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    lea rbx, [asteroids]
    mov r12, MAX_ASTEROIDS
    
.asteroid_loop:
    cmp dword [rbx+8], 0     ; Check if active
    je .next_asteroid
    
    mov r13d, [rbx+12]       ; rotation
    
    ; Draw rotating asteroid (octagon shape)
    mov r8d, [rbx]           ; x
    mov r9d, [rbx+4]         ; y
    
    ; Center square
    add r8d, 12
    add r9d, 12
    mov r10d, 24
    mov r11d, 24
    mov eax, 0x00606060      ; Gray
    call DrawRectangle
    
    ; Top/bottom pieces
    sub r8d, 6
    sub r9d, 6
    mov r10d, 36
    mov r11d, 6
    mov eax, 0x00404040
    call DrawRectangle
    
    add r9d, 30
    call DrawRectangle
    
    ; Side pieces
    sub r9d, 24
    mov r10d, 6
    mov r11d, 24
    call DrawRectangle
    
    add r8d, 30
    call DrawRectangle
    
    ; Add some detail
    sub r8d, 18
    add r9d, 8
    mov r10d, 8
    mov r11d, 8
    mov eax, 0x00808080
    call DrawRectangle
    
.next_asteroid:
    add rbx, 16
    dec r12
    jnz .asteroid_loop
    
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw game over scene
DrawGameOverScene:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    
    ; Clear screen
    call ClearScreen
    
    ; Draw some stars
    call DrawStarfield
    
    ; Draw "GAME OVER" text
    mov r9d, 300
    lea rdx, [gameOverText]
    mov r11d, COLOR_RED
    mov ecx, 8               ; Large scale
    call DrawStringCentered
    
    ; Draw final score
    mov r9d, 400
    lea rdx, [finalScoreText]
    mov r11d, COLOR_WHITE
    mov ecx, 4
    call DrawStringCentered
    
    ; Convert score to string
    mov eax, [playerScore]
    lea rdi, [rsp+64]
    call IntToString
    
    ; Draw score number
    mov r9d, 450
    lea rdx, [rsp+64]
    mov r11d, COLOR_YELLOW
    mov ecx, 6               ; Large scale for score
    call DrawStringCentered
    
    ; Draw instruction
    mov r9d, 600
    lea rdx, [pressEscText]
    mov r11d, COLOR_CYAN
    mov ecx, 3
    call DrawStringCentered
    
    ; Draw custom cursor on top
    call DrawCustomCursor
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 96
    pop rbp
    ret

; Draw level select scene with constellation-style map
DrawLevelSelectScene:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    
    ; Clear screen
    call ClearScreen
    
    ; Draw galaxy/level info at top
    mov r8d, SCREEN_WIDTH / 2 - 200
    mov r9d, 50
    lea rdx, [galaxyText]
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 4
    call DrawString
    
    ; Draw galaxy number
    mov eax, [currentGalaxy]
    inc eax
    lea rdi, [rsp+64]
    call IntToString
    mov r8d, SCREEN_WIDTH / 2 - 50
    mov r9d, 50
    lea rdx, [rsp+64]
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 4
    call DrawString
    
    ; Draw constellation map
    call DrawLevelConstellation
    
    ; Draw BACK button
    mov r8d, 50
    mov r9d, SCREEN_HEIGHT - 150
    mov r10d, 200
    mov r11d, 60
    mov eax, 0x00606060
    call DrawRectangle
    
    ; Draw "< BACK" text
    mov r8d, 70
    mov r9d, SCREEN_HEIGHT - 130
    lea rdx, [backArrowText]
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 4      ; scale
    call DrawString
    
    mov r8d, 100
    mov r9d, SCREEN_HEIGHT - 130
    lea rdx, [backText]
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 3
    call DrawString
    
    ; Draw level indicators at bottom
    call DrawLevelIndicators
    
    ; Draw custom cursor on top
    call DrawCustomCursor
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw the constellation-style level map
DrawLevelConstellation:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    
    ; Calculate center position
    mov r14d, SCREEN_WIDTH / 2
    mov r15d, SCREEN_HEIGHT / 2
    
    ; Draw connecting lines first
    call DrawConstellationLines
    
    ; Draw nodes (levels)
    xor r12d, r12d           ; Level counter
    
.node_loop:
    cmp r12d, LEVELS_PER_GALAXY
    jge .done
    
    ; Calculate node position in web pattern
    mov eax, r12d
    call GetNodePosition     ; Returns x in r8d, y in r9d
    
    ; Determine node type and color
    mov r13d, COLOR_ORANGE   ; Default orange for normal levels
    mov ebx, NODE_NORMAL
    
    ; Special nodes
    cmp r12d, 0
    je .corner_node
    cmp r12d, 4
    je .special_node
    cmp r12d, 7
    je .special_node
    cmp r12d, 9
    je .boss_node
    jmp .draw_node
    
.corner_node:
    mov r13d, COLOR_GREEN
    mov ebx, NODE_CORNER
    jmp .draw_node
    
.special_node:
    mov r13d, COLOR_ORANGE
    mov ebx, NODE_SPECIAL
    jmp .draw_node
    
.boss_node:
    mov r13d, COLOR_RED
    mov ebx, NODE_BOSS
    
.draw_node:
    ; Check if level is completed
    mov eax, [currentGalaxy]
    imul eax, LEVELS_PER_GALAXY
    add eax, r12d
    call IsLevelCompleted
    test al, al
    jz .draw_incomplete
    
    ; Draw completed node (filled)
    mov eax, r13d
    call DrawFilledNode
    jmp .check_selected
    
.draw_incomplete:
    ; Draw incomplete node (outline)
    mov eax, r13d
    call DrawOutlineNode
    
.check_selected:
    ; Draw selection indicator if this is selected node
    cmp r12d, [selectedNode]
    jne .next_node
    
    ; Draw selection glow
    sub r8d, 5
    sub r9d, 5
    add r10d, 10
    add r11d, 10
    mov eax, COLOR_WHITE
    call DrawRectangleWithGlow
    
.next_node:
    inc r12d
    jmp .node_loop
    
.done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Get node position in constellation pattern
; Input: EAX = node index
; Output: R8D = x, R9D = y
GetNodePosition:
    push rbp
    mov rbp, rsp
    
    ; Create a web-like pattern similar to the screenshot
    cmp eax, 0
    je .pos0
    cmp eax, 1
    je .pos1
    cmp eax, 2
    je .pos2
    cmp eax, 3
    je .pos3
    cmp eax, 4
    je .pos4
    cmp eax, 5
    je .pos5
    cmp eax, 6
    je .pos6
    cmp eax, 7
    je .pos7
    cmp eax, 8
    je .pos8
    cmp eax, 9
    je .pos9
    
.pos0:  ; Top-left corner
    mov r8d, SCREEN_WIDTH / 2 - 300
    mov r9d, SCREEN_HEIGHT / 2 - 200
    jmp .done
    
.pos1:  ; Top-center
    mov r8d, SCREEN_WIDTH / 2
    mov r9d, SCREEN_HEIGHT / 2 - 250
    jmp .done
    
.pos2:  ; Top-right corner
    mov r8d, SCREEN_WIDTH / 2 + 300
    mov r9d, SCREEN_HEIGHT / 2 - 200
    jmp .done
    
.pos3:  ; Middle-left
    mov r8d, SCREEN_WIDTH / 2 - 200
    mov r9d, SCREEN_HEIGHT / 2 - 50
    jmp .done
    
.pos4:  ; Center
    mov r8d, SCREEN_WIDTH / 2
    mov r9d, SCREEN_HEIGHT / 2
    jmp .done
    
.pos5:  ; Middle-right
    mov r8d, SCREEN_WIDTH / 2 + 200
    mov r9d, SCREEN_HEIGHT / 2 - 50
    jmp .done
    
.pos6:  ; Bottom-left
    mov r8d, SCREEN_WIDTH / 2 - 250
    mov r9d, SCREEN_HEIGHT / 2 + 150
    jmp .done
    
.pos7:  ; Bottom-center-left
    mov r8d, SCREEN_WIDTH / 2 - 100
    mov r9d, SCREEN_HEIGHT / 2 + 100
    jmp .done
    
.pos8:  ; Bottom-center-right
    mov r8d, SCREEN_WIDTH / 2 + 100
    mov r9d, SCREEN_HEIGHT / 2 + 100
    jmp .done
    
.pos9:  ; Bottom (boss)
    mov r8d, SCREEN_WIDTH / 2
    mov r9d, SCREEN_HEIGHT / 2 + 200
    
.done:
    pop rbp
    ret

; Draw constellation connecting lines
DrawConstellationLines:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 48
    
    ; Draw all connections between nodes
    ; Connection data: from_node, to_node pairs
    ; This creates the web pattern
    
    ; Top connections
    mov eax, 0
    mov ebx, 1
    call DrawNodeConnection
    
    mov eax, 1
    mov ebx, 2
    call DrawNodeConnection
    
    mov eax, 0
    mov ebx, 3
    call DrawNodeConnection
    
    mov eax, 2
    mov ebx, 5
    call DrawNodeConnection
    
    ; Middle connections
    mov eax, 3
    mov ebx, 4
    call DrawNodeConnection
    
    mov eax, 4
    mov ebx, 5
    call DrawNodeConnection
    
    mov eax, 1
    mov ebx, 4
    call DrawNodeConnection
    
    ; Bottom connections
    mov eax, 3
    mov ebx, 6
    call DrawNodeConnection
    
    mov eax, 4
    mov ebx, 7
    call DrawNodeConnection
    
    mov eax, 4
    mov ebx, 8
    call DrawNodeConnection
    
    mov eax, 5
    mov ebx, 8
    call DrawNodeConnection
    
    mov eax, 6
    mov ebx, 7
    call DrawNodeConnection
    
    mov eax, 7
    mov ebx, 9
    call DrawNodeConnection
    
    mov eax, 8
    mov ebx, 9
    call DrawNodeConnection
    
    ; Cross connections for web effect
    mov eax, 0
    mov ebx, 4
    call DrawNodeConnection
    
    mov eax, 2
    mov ebx, 4
    call DrawNodeConnection
    
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw connection line between two nodes
; Input: EAX = from node, EBX = to node
DrawNodeConnection:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    
    mov r12d, eax            ; Save from node
    mov r13d, ebx            ; Save to node
    
    ; Get from position
    call GetNodePosition
    mov r14d, r8d            ; From X
    mov r15d, r9d            ; From Y
    
    ; Get to position
    mov eax, r13d
    call GetNodePosition     ; To position in r8d, r9d
    
    ; Draw line using rectangles (simplified)
    ; Calculate differences
    mov eax, r8d
    sub eax, r14d            ; dx
    mov ebx, r9d
    sub ebx, r15d            ; dy
    
    ; Draw horizontal part
    test eax, eax
    jz .draw_vertical
    
    mov r8d, r14d
    mov r9d, r15d
    test eax, eax
    jns .positive_x
    neg eax
    sub r8d, eax
.positive_x:
    mov r10d, eax
    mov r11d, 3
    mov eax, COLOR_YELLOW
    call DrawRectangle
    
.draw_vertical:
    ; Draw vertical part
    test ebx, ebx
    jz .done
    
    mov r8d, r14d
    mov r9d, r15d
    test ebx, ebx
    jns .positive_y
    neg ebx
    sub r9d, ebx
.positive_y:
    mov r10d, 3
    mov r11d, ebx
    mov eax, COLOR_YELLOW
    call DrawRectangle
    
.done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Draw filled node (completed level)
DrawFilledNode:
    push rbp
    mov rbp, rsp
    
    ; Draw based on node type
    cmp ebx, NODE_CORNER
    je .draw_diamond
    cmp ebx, NODE_SPECIAL
    je .draw_triangle
    cmp ebx, NODE_BOSS
    je .draw_hexagon
    
    ; Default hexagon
.draw_hexagon:
    mov r10d, NODE_SIZE
    mov r11d, NODE_SIZE
    call DrawRectangle
    jmp .done
    
.draw_diamond:
    ; Draw diamond shape (simplified as rotated square)
    mov r10d, NODE_SIZE
    mov r11d, NODE_SIZE
    call DrawRectangle
    jmp .done
    
.draw_triangle:
    ; Draw triangle (simplified)
    mov r10d, NODE_SIZE
    mov r11d, NODE_SIZE
    call DrawRectangle
    
.done:
    pop rbp
    ret

; Draw outline node (incomplete level)
DrawOutlineNode:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov ebx, eax             ; Save color
    
    ; Draw border
    mov r10d, NODE_SIZE
    mov r11d, NODE_SIZE
    mov eax, ebx
    call DrawRectangle
    
    ; Draw black interior
    add r8d, 3
    add r9d, 3
    sub r10d, 6
    sub r11d, 6
    mov eax, COLOR_BLACK
    call DrawRectangle
    
    pop rbx
    pop rbp
    ret

; Draw level indicators at bottom
DrawLevelIndicators:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 48
    
    ; Draw three hexagons as indicators
    mov r8d, SCREEN_WIDTH / 2 - 150
    mov r9d, SCREEN_HEIGHT - 100
    
    ; Green hexagon (completed)
    mov r10d, 30
    mov r11d, 30
    mov eax, COLOR_GREEN
    call DrawRectangle
    
    ; Green hexagon 2
    add r8d, 50
    call DrawRectangle
    
    ; Orange hexagon (current)
    add r8d, 50
    mov eax, COLOR_ORANGE
    call DrawRectangle
    
    ; Draw "Level Numbers" text
    mov r8d, SCREEN_WIDTH / 2 + 50
    mov r9d, SCREEN_HEIGHT - 95
    lea rdx, [levelNumbersText]
    mov r11d, COLOR_YELLOW
    mov dword [rsp+32], 2
    call DrawString
    
    add rsp, 48
    pop r12
    pop rbx
    pop rbp
    ret

; Check if a level is completed
; Input: EAX = absolute level index
; Output: AL = 1 if completed, 0 if not
IsLevelCompleted:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov ebx, eax
    shr ebx, 3               ; Divide by 8 to get byte index
    and eax, 7               ; Get bit index
    
    lea rdx, [levelsCompleted]
    movzx ecx, byte [rdx + rbx]
    bt ecx, eax
    setc al
    
    pop rbx
    pop rbp
    ret

; Mark level as completed
; Input: EAX = absolute level index
MarkLevelCompleted:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov ebx, eax
    shr ebx, 3               ; Divide by 8 to get byte index
    and eax, 7               ; Get bit index
    
    lea rdx, [levelsCompleted]
    bts dword [rdx + rbx], eax
    
    pop rbx
    pop rbp
    ret

; Level selection navigation functions
MoveLevelSelectLeft:
    push rbp
    mov rbp, rsp
    
    ; Simple navigation - could be improved with proper connection mapping
    cmp dword [selectedNode], 0
    jle .done
    dec dword [selectedNode]
    
.done:
    pop rbp
    ret

MoveLevelSelectRight:
    push rbp
    mov rbp, rsp
    
    mov eax, LEVELS_PER_GALAXY - 1
    cmp dword [selectedNode], eax
    jge .done
    inc dword [selectedNode]
    
.done:
    pop rbp
    ret

MoveLevelSelectUp:
    push rbp
    mov rbp, rsp
    
    ; Move to appropriate upper node based on current position
    mov eax, [selectedNode]
    cmp eax, 6
    jl .check_middle
    sub dword [selectedNode], 3
    jmp .done
    
.check_middle:
    cmp eax, 3
    jl .done
    sub dword [selectedNode], 3
    
.done:
    pop rbp
    ret

MoveLevelSelectDown:
    push rbp
    mov rbp, rsp
    
    ; Move to appropriate lower node based on current position
    mov eax, [selectedNode]
    cmp eax, 6
    jge .done
    add dword [selectedNode], 3
    cmp dword [selectedNode], LEVELS_PER_GALAXY
    jl .done
    mov dword [selectedNode], LEVELS_PER_GALAXY - 1
    
.done:
    pop rbp
    ret

; Start the selected level
StartLevel:
    push rbp
    mov rbp, rsp
    
    ; Check if level is already completed or if previous level needs to be completed
    ; For now, allow playing any level
    
    ; Initialize level-specific parameters
    mov eax, [selectedNode]
    mov [currentLevel], eax
    
    ; Set level difficulty and requirements
    call SetLevelParameters
    
    ; Start the game
    mov dword [gameState], STATE_PLAYING
    call InitGame
    
    pop rbp
    ret

; Set parameters for current level
SetLevelParameters:
    push rbp
    mov rbp, rsp
    
    ; Base difficulty on galaxy and level
    mov eax, [currentGalaxy]
    imul eax, 10
    add eax, [currentLevel]
    
    ; Set enemies required (increase with level)
    lea ecx, [eax*2 + 10]
    mov [enemiesRequired], ecx
    mov dword [enemiesKilled], 0
    
    ; Adjust spawn rates based on level
    mov ecx, ALIEN_SPAWN_DELAY
    sub ecx, eax
    cmp ecx, 20
    jge .set_alien_timer
    mov ecx, 20
.set_alien_timer:
    mov [alienSpawnTimer], ecx
    
    mov ecx, ASTEROID_SPAWN_DELAY
    sub ecx, eax
    cmp ecx, 30
    jge .set_asteroid_timer
    mov ecx, 30
.set_asteroid_timer:
    mov [asteroidSpawnTimer], ecx
    
    pop rbp
    ret

; Draw victory scene
DrawVictoryScene:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    
    ; Clear screen
    call ClearScreen
    
    ; Draw stars
    call DrawStarfield
    
    ; Check if all galaxies cleared
    mov eax, [currentGalaxy]
    cmp eax, MAX_GALAXIES - 1
    jl .galaxy_complete
    
    ; All galaxies cleared
    mov r9d, 300
    lea rdx, [allClearText]
    mov r11d, COLOR_YELLOW
    mov ecx, 6
    call DrawStringCentered
    jmp .draw_score
    
.galaxy_complete:
    ; Galaxy complete
    mov r9d, 300
    lea rdx, [galaxyCompleteText]
    mov r11d, COLOR_GREEN
    mov ecx, 6
    call DrawStringCentered
    
.draw_score:
    ; Draw total score
    mov r9d, 400
    lea rdx, [finalScoreText]
    mov r11d, COLOR_WHITE
    mov ecx, 4
    call DrawStringCentered
    
    mov eax, [totalScore]
    lea rdi, [rsp+64]
    call IntToString
    
    mov r9d, 450
    lea rdx, [rsp+64]
    mov r11d, COLOR_YELLOW
    mov ecx, 6
    call DrawStringCentered
    
    ; Draw instruction
    mov r9d, 600
    lea rdx, [pressEscText]
    mov r11d, COLOR_CYAN
    mov ecx, 3
    call DrawStringCentered
    
    ; Draw custom cursor on top
    call DrawCustomCursor
    
    ; Update screen
    call UpdateScreen
    
    add rsp, 96
    pop rbp
    ret

; Check for save file existence
CheckSaveFile:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Try to open save file
    lea rcx, [saveFileName]
    mov rdx, GENERIC_READ
    xor r8, r8               ; No sharing
    xor r9, r9               ; No security
    mov dword [rsp+32], OPEN_EXISTING
    mov dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+48], 0    ; No template
    call CreateFileA
    
    cmp rax, INVALID_HANDLE_VALUE
    je .no_save
    
    ; File exists, close it
    mov rcx, rax
    call CloseHandle
    
    mov byte [hasSaveGame], 1
    jmp .done
    
.no_save:
    mov byte [hasSaveGame], 0
    
.done:
    add rsp, 48
    pop rbp
    ret

; Save game progress
SaveGame:
    push rbp
    mov rbp, rsp
    sub rsp, 80
    
    ; Create/open save file
    lea rcx, [saveFileName]
    mov rdx, GENERIC_WRITE
    xor r8, r8               ; No sharing
    xor r9, r9               ; No security
    mov dword [rsp+32], CREATE_ALWAYS
    mov dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+48], 0    ; No template
    call CreateFileA
    
    cmp rax, INVALID_HANDLE_VALUE
    je .error
    
    mov [rsp+64], rax        ; Save file handle
    
    ; Write save data
    ; Write player name
    mov rcx, rax
    lea rdx, [playerName]
    mov r8, MAX_NAME_LENGTH + 1
    lea r9, [rsp+56]         ; Bytes written
    mov qword [rsp+32], 0    ; No overlapped
    call WriteFile
    
    ; Write game state
    mov rcx, [rsp+64]
    lea rdx, [currentGalaxy]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call WriteFile
    
    mov rcx, [rsp+64]
    lea rdx, [selectedDifficulty]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call WriteFile
    
    mov rcx, [rsp+64]
    lea rdx, [totalScore]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call WriteFile
    
    ; Write completed levels array
    mov rcx, [rsp+64]
    lea rdx, [levelsCompleted]
    mov r8, MAX_TOTAL_LEVELS
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call WriteFile
    
    ; Close file
    mov rcx, [rsp+64]
    call CloseHandle
    
.error:
    add rsp, 80
    pop rbp
    ret

; Load game progress
LoadGame:
    push rbp
    mov rbp, rsp
    sub rsp, 80
    
    ; Open save file
    lea rcx, [saveFileName]
    mov rdx, GENERIC_READ
    xor r8, r8               ; No sharing
    xor r9, r9               ; No security
    mov dword [rsp+32], OPEN_EXISTING
    mov dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+48], 0    ; No template
    call CreateFileA
    
    cmp rax, INVALID_HANDLE_VALUE
    je .error
    
    mov [rsp+64], rax        ; Save file handle
    
    ; Read save data
    ; Read player name
    mov rcx, rax
    lea rdx, [playerName]
    mov r8, MAX_NAME_LENGTH + 1
    lea r9, [rsp+56]         ; Bytes read
    mov qword [rsp+32], 0    ; No overlapped
    call ReadFile
    
    ; Calculate name length
    lea rdi, [playerName]
    xor rcx, rcx
.name_len_loop:
    cmp byte [rdi + rcx], 0
    je .name_len_done
    inc rcx
    cmp rcx, MAX_NAME_LENGTH
    jl .name_len_loop
.name_len_done:
    mov [nameLength], ecx
    
    ; Read game state
    mov rcx, [rsp+64]
    lea rdx, [currentGalaxy]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call ReadFile
    
    mov rcx, [rsp+64]
    lea rdx, [selectedDifficulty]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call ReadFile
    
    mov rcx, [rsp+64]
    lea rdx, [totalScore]
    mov r8, 4
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call ReadFile
    
    ; Read completed levels array
    mov rcx, [rsp+64]
    lea rdx, [levelsCompleted]
    mov r8, MAX_TOTAL_LEVELS
    lea r9, [rsp+56]
    mov qword [rsp+32], 0
    call ReadFile
    
    ; Close file
    mov rcx, [rsp+64]
    call CloseHandle
    
    ; Set selected node to first incomplete level in current galaxy
    xor eax, eax
    mov [selectedNode], eax
    
.error:
    add rsp, 80
    pop rbp
    ret