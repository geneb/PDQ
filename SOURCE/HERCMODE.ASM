;********** HERCMODE.ASM - enable SCREEN 3 and SCREEN 0 on a Hercules card

;Copyright 1990 Crescent Software
;written by Jay Munro

;Syntax   CALL HercMode(1)  for page 0 graphics mode (use any non-zero value)
;Syntax   CALL HercMode(0)  for text mode

.Model Medium,BASIC
.Code

HercMode Proc Uses DS SI DI, Mode:Word

    Lea  SI,CS:GTable               ;get address of Graphics data
    Mov  BX,Mode                    ;find out which mode to do
    Cmp  Word Ptr [BX],0            ;if Text, drop through
    Jnz  DoGraphics

    Mov  DX,03Bfh                   ;set configuration switch to
    Mov  AL,0                       ; disable graphics and text mode below
    Out  DX,AL

    Add  SI,12                      ;point to text table
                                    ;load values for clear screen
    Mov  BX,720h                    ;color = 7, char = space
    Mov  CX,2000                    ;2000 characters
    Jmp  Short SetMode

DoGraphics:
    Mov  DX,03Bfh                   ;set configuration switch to allow
    Mov  AL,1                       ;  graphics
    Out  DX,AL

    Xor  BX,BX                      ;clear BX as attribute to clear screen
    Inc  AL                         ;set display mode port to graphics mode (2)
    Mov  CX,4000h                   ;words to clear in graphics memory

SetMode:
    Push AX                         ;save control mode
    Push BX                         ;save clear attribute
    Push CX                         ;save clear count

    Mov  DX,03B8h                   ;set the mode
    Out  DX,AL

    Mov  DX,03B4h                   ;index register
    Mov  CX,12                      ;set loop to do 12 times
    Xor  AH,AH                      ;clear AH to start index at 0
    Push CS                         ;point DS at CS for loop
    Pop  DS

Parms:
    Mov  AL,AH                      ;output index register number
    Out  DX,AL                      ;set it
    Inc  DX                         ;output data register is +1 of index
    Lodsb                           ;get a byte of data
    Out  DX,AL                      ;and send it
    Inc  AH                         ;next value for index
    Dec  DX                         ;set register back to index register
    Loop Parms

    Pop  CX                         ;retrieve buffer length
    Mov  AX,0B000h                  ;video segment into ES
    Mov  ES,AX
    
    Cld                             ;forward moves
    Xor  DI,DI                      ;start at offset 0
    Pop  AX                         ;retrieve attribute to clear with
    Rep  Stosw                      ;store data to clear screen

    Mov  DX,3B8h                    ;mode control register
    Pop  AX                         ;retrieve mode setting
    Add  AL,01000b                  ;add bit to enable screen
    Out  DX,AL                      ;and set it

Exit:
     Ret

HercMode  EndP

;---- Data area for registers
GTable          DB      35h, 2dh, 2eh, 07h
                DB      5bh, 02h, 57h, 57h
                DB      02h, 03h, 00h, 00h

TTable          DB      61h, 50h, 52h, 0fh
                DB      19h, 06h, 19h, 19h
                DB      02h, 0dh, 0bh, 0ch
End
