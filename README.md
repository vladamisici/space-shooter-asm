# Space Shooter (x64 Assembly)

A simple Win32/GDI-based written in NASM for Windows x64 


## Features

- movement and shooting  
- Bullet pooling with cooldown  
- GDI-drawing of rectangles for all graphics  

## Build & Run

```bash
nasm -f win64 space_shooter.asm -o space_shooter.obj
golink /entry:Start kernel32.dll user32.dll gdi32.dll space_shooter.obj
space_shooter.exe
