;********* LINE.ASM - PDQ replacement for BASIC's LINE routine

;LINE.ASM  Copyright (c) 1992  Thomas G. Hanlin III



   Extrn P$Plot: far        ; in PLOT.ASM


.Model Medium, Basic

.Data

   Extrn b$ForeColor: Byte  ;default color   in COLORDAT.ASM
   Extrn P$GXPOS1: Word     ;X1 coordinate   in POINTS.ASM
   Extrn P$GYPOS1: Word     ;Y1 coordinate   in POINTS.ASM
   Extrn P$GXPOS2: Word     ;X2 coordinate   in POINTS.ASM
   Extrn P$GYPOS2: Word     ;Y2 coordinate   in POINTS.ASM

   UnitDX    dw ?           ;X change
   UnitDY    dw ?           ;Y change
   DotCount  dw ?           ;length count
   ErrTrack  dw ?           ;error tracker
   Pattrn    dw ?           ;line pattern
   ColrW     label word     ;so we can access color with push/pop
   Colr      db ?           ;line color



.Code



B$LINE   Proc Uses SI DI, Color:Word, Pattern:Word, Box:Byte
    Mov  AX,Pattern         ;pattern
    Mov  Pattrn,AX
    Mov  AX,Color           ;color
    Cmp  AX,0FFFFh          ;use default?
    Jne  GotColor           ;  no...
    Mov  AL,b$ForeColor

GotColor:
    Mov  Colr,AL
    Cmp  Box,1              ;box frame?
    Jz   BoxFrame           ;  yep, go do it
    Cmp  Box,2              ;filled box?
    Jz   BoxFill            ;  yep, go do it

    Push P$GXPos1           ;it's a line-- draw it
    Push P$GYPos1
    Push P$GXPos2
    Push P$GYPos2
    Push Pattrn
    Push AX
    Call Line

Done:
    Mov  AX,P$GXPos2        ;update default X
    Mov  P$GXPos1,AX
    Mov  AX,P$GYPos2        ;update default Y
    Mov  P$GYPos1,AX
    Ret                     ;return to caller

BoxFill:
    Mov  CX,P$GXPos1
    Mov  DX,P$GYPos1
    Mov  SI,P$GXPos2
    Mov  DI,P$GYPos2
    Cmp  DX,DI
    Jbe  BoxFill1
    Xchg DX,DI

BoxFill1:
    Mov  BX,DI
    Sub  BX,DX
    Inc  BX
    Mov  DX,DI

BoxFill2:
    Push AX                 ;save regs
    Push BX
    Push CX
    Push DX
    Push CX                 ;put parms on stack
    Push DX
    Push SI
    Push DI
    Push Pattrn
    Push ColrW
    Call Line               ;draw a line
    Pop  DX                 ;restore regs
    Pop  CX
    Pop  BX
    Pop  AX
    Dec  DX
    Dec  DI
    Dec  BX                 ;are we done?
    Jnz  BoxFill2           ;  no, go for another line
    Jmp  Done               ;  yep, exit

BoxFrame:
    Push P$GXPOS1
    Push P$GYPOS1
    Push P$GXPOS2
    Push P$GYPOS1
    Push Pattrn
    Push ColrW
    Call Line               ;draw line from top left to top right

    Push P$GXPOS1
    Push P$GYPOS2
    Push P$GXPOS2
    Push P$GYPOS2
    Push Pattrn
    Push ColrW
    Call Line               ;draw line from bottom left to bottom right

    Push P$GXPOS1
    Push P$GYPOS2
    Push P$GXPOS1
    Push P$GYPOS1
    Push Pattrn
    Push ColrW
    Call Line               ;draw line from bottom left to top left

    Push P$GXPOS2
    Push P$GYPOS2
    Push P$GXPOS2
    Push P$GYPOS1
    Push Pattrn
    Push ColrW
    Call Line               ;draw line from bottom right to top right

    Jmp  Done               ;  go exit
B$LINE   EndP



Line     Proc Near      ;draw line: (x0,y0,x1,y1,pattern,color)
    Push BP
    Mov  BP,SP
    Push SI
    Push DI
    Mov  AX,[BP+10]         ;calculate ABS(X1 - X0)
    Sub  AX,[BP+14]
    Cwd
    Xor  AX,DX
    Sub  AX,DX
    Xchg AX,SI              ;SI = ABS(X1 - X0) = DeltaX
    Mov  AX,[BP+8]          ;calculate ABS(Y1 - Y0)
    Sub  AX,[BP+12]
    Cwd
    Xor  AX,DX
    Sub  AX,DX
    Xchg AX,DI              ;DI = ABS(Y1 - Y0) = DeltaY

    Mov  CX,[BP+14]         ;X0
    Mov  DX,[BP+12]         ;Y0
    Mov  BX,[BP+6]          ;Pattern
    Mov  AL,[BP+4]          ;Color

    Or   SI,SI              ;is it a dot?
    Jz   CheckDot           ;  maybe-- check further
    Or   DI,DI              ;is it a horizontal line?
    Jnz  DiagLine           ;  nope, diagonal-- go do it

HorizLine:
    Cmp  CX,[BP+10]         ;X0 > X1 ?
    Mov  BP,-1
    Ja   HorizLine1         ;  yep, draw it right to left
    Neg  BP

HorizLine1:
    Rol  BX,1               ;draw dot?
    Jz   HorizLine2         ;  no...
    Call P$Plot

HorizLine2:
    Add  CX,BP
    Dec  SI
    Jnz  HorizLine1
    Jmp  LineDone

CheckDot:
    Or   DI,DI              ;is it a vertical line
    Jnz  VertLine           ;  yep, special case
    Call P$Plot             ;single dot-- we're done!
    Jmp  LineDone

VertLine:
    Cmp  DX,[BP+8]          ;Y0 > Y1 ?
    Mov  BP,-1
    Ja   VertLine1          ;  yep, draw it bottom to top
    Neg  BP

VertLine1:
    Rol  BX,1               ;draw dot?
    Jz   VertLine2          ;  no...
    Call P$Plot

VertLine2:
    Add  DX,BP
    Dec  DI
    Jnz  VertLine1
    Jmp  LineDone

LineDone:
    Pop  DI
    Pop  SI
    Pop  BP
    Ret  12

DiagLine:
    Rol  BX,1
    Jnc  DiagLine0
    Call P$Plot

DiagLine0:
    Mov  UnitDX,1
    Cmp  CX,[BP+10]         ;X0 < X1 ?
    Jb   DiagLine1          ;  yep, got it
    Neg  UnitDX

DiagLine1:
    Mov  UnitDY,1
    Cmp  DX,[BP+8]          ;Y0 < Y1 ?
    Jb   DiagLine2          ;  yep, got it
    Neg  UnitDY

DiagLine2:
    Cmp  SI,DI              ;gentle slope?
    Jb   SteepSlope         ;  no, do steep slope

GentleSlope:
    Mov  AX,DI              ;calculate error track
    Shl  AX,1
    Sub  AX,SI
    Mov  ErrTrack,AX
    Mov  DotCount,SI

GentleSlope1:
    Add  CX,UnitDY
    Cmp  ErrTrack,0         ;time for line correction?
    Jl   GentleSlope2       ;  nope, keep tracking the amount of error
    Mov  AX,DI
    Sub  AX,SI
    Shl  AX,1
    Add  DX,UnitDX
    Jmp  GentleSlope3

GentleSlope2:
    Mov  AX,DI
    Shl  AX,1

GentleSlope3:
    Add  ErrTrack,AX
    Rol  BX,1
    Jnc  GentleSlope4
    Mov  AL,[BP+4]
    Call P$Plot

GentleSlope4:
    Dec  DotCount
    Jnz  GentleSlope1
    Jmp  LineDone

SteepSlope:
    Mov  AX,SI              ;calculate error track
    Shl  AX,1
    Sub  AX,DI
    Mov  ErrTrack,AX
    Mov  DotCount,DI

SteepSlope1:
    Add  DX,UnitDY
    Cmp  ErrTrack,0         ;time for line correction?
    Jl   SteepSlope2        ;  nope, keep tracking error
    Mov  AX,SI
    Sub  AX,DI
    Shl  AX,1
    Add  CX,UnitDX
    Jmp  SteepSlope3

SteepSlope2:
    Mov  AX,SI
    Shl  AX,1

SteepSlope3:
    Add  ErrTrack,AX
    Rol  BX,1
    Jnc  SteepSlope4
    Mov  AL,[BP+4]
    Call P$Plot

SteepSlope4:
    Dec  DotCount
    Jnz  SteepSlope1
    Jmp  LineDone
Line     EndP
End
