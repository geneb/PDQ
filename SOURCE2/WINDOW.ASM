;********* WINDOW.ASM - windowed "quick print" routine

;Copyright (c) 1991 Ethan Winer

;Syntax:
;
;  CALL WindowInit(BYVAL ULRow, BYVAL ULCol, BYVAL LRRow, BYVAL LRCol)
;  CALL WindowPrint(Text$)
;  CALL WindowPrintCR(Text$)
;  CALL WindowCLS
;  CALL WindowLocate(BYVAL Row, BYVAL Column)
;  CurrentRow = WindowRow%  'function
;  CurrentCol = WindowCol%  'function


;To create the Quick Library version assemble this file like this:
;
;   CD \pdq
;   MASM \pdq\source\window, windoqlb.obj /dqlb ;
;
;And to make the far strings (DONOTUSE.LIB) Quick Library version do this:
;
;   CD \pdq\basic7
;   MASM \pdq\source\window /dqlb /dpds ;


.Model Medium, Basic
    Extrn P$MonSetup:Proc   ;this is in MONSETUP.ASM

    Public _ULCol, _LRCol   ;so WindowPrintW can read these

IFDEF PDS
    Extrn StringInfo:Proc   ;required for far strings in BC7
ENDIF

.Data
IFNDEF QLB
    Extrn P$Color:Byte      ;this is in COLORDAT.ASM
ENDIF

    Extrn P$CGAPort:Word    ;these are in MONSETUP.ASM
    Extrn P$MonSeg:Word

    Extrn P$PrintWidth:Word ;this is in PDQPWIDE.ASM

IFDEF PDS
    StringSeg DW 0          ;saves the far string segment in BASIC PDS
ENDIF
    
    _LRCol DB 79            ;these hold the current window corners
    _LRRow DB 24            ;note that these values are zero-based for speed
    _ULCol DB 0             ;  and code size
    _ULRow DB 0
    
    CursorCol DB 0          ;these remember the current cursor position
    CursorRow DB 0          ;and they're zero-based too
                            ;these are physical screen values, not virtual

    DoCR DW 0               ;this flags if an end-of-line is to be printed
    
.Code

WindowPrint Proc            ;enter here to print without a "CRLF"
    Xor  CX,CX              ;clear CX to flag that this is WindowPrint
    Db   3Dh                ;fake the Mov CX,SP below to a bogus compare
WindowPrint Endp


WindowPrintCR Proc          ;enter here to print with a CRLF
   Mov  CX,SP               ;force CX to non-zero (SP can't possibly be zero)
WindowPrintCR Endp          ;in either case, fall into the code below


_WindowPrint Proc Uses SI DI, Work$

    Mov  DoCR,CX            ;remember which procedure they called

IFDEF PDS                   ;if this is the PDS far strings version
    Mov  SI,Work$           ;get the address for the descriptor to Work$
    Call StringInfo         ;this returns the address in AX, the length in CX
    Mov  SI,AX              ;load first character address of Image$
    Mov  StringSeg,DX       ;and save the string segment
ELSE
    Mov  BX,Work$           ;get the address for the descriptor to Work$
    Mov  CX,[BX]            ;first get the length
    Mov  SI,[BX+02]         ;load the data address for Work$
ENDIF

    Mov  AL,CursorRow           ;get the current row
    Mul  Byte Ptr P$PrintWidth  ;multiply to get the correct base row address

    Mov  DI,Word Ptr CursorCol  ;now get the current column
    And  DI,0FFh                ;throw away the row in the high part of DI
    Shl  DI,1               ;multiply times 2 to consider the attribute byte
    Add  DI,AX              ;now DI holds the correct screen address

    Call P$MonSetUp         ;query the installed video adapter type
    Cld                     ;ensure that all string ops are forward
    
    Mov  DX,P$CGAPort       ;load the CGA port address for the In below
    Mov  ES,P$MonSeg        ;load the current video segment
    
IFNDEF QLB                  ;if we're not making the Quick Library version
    Mov  AH,P$Color         ;load the current color setting
ELSE
    Mov  AH,112             ;otherwise use inverse (black on white)
ENDIF

    Jcxz CheckCRLF          ;it's a null string, but see if they called
                            ;  WindowPrintCR to kick out a CRLF

    ;--- this is the main print processing loop
Do:
IFDEF PDS                   ;for the far strings version setup DS
    Mov  DS,StringSeg
ENDIF

    Or   DL,DL              ;are we doing monochrome or EGA/VGA?
    Je   Mono               ;yes, go do it

No_Retrace:
    In   AL,DX              ;get the video status byte
    Test AL,1               ;test just the horizontal retrace bit
    Jnz  No_Retrace         ;if doing a retrace, wait until it's not
    Cli                     ;disable interrupts until done writing to screen

Retrace:
    In   AL,DX              ;get the status byte again
    Test AL,1               ;are we currently doing a retrace?
    Jz   Retrace            ;no wait until we are

Mono:
    Lodsb                   ;load a character from Work$
    Stosw                   ;store the character and the color in AH
    Sti                     ;re-enable interrupts

IFDEF PDS                   ;for the far strings version restore DS
    Push SS
    Pop  DS
ENDIF

    Inc  CursorCol          ;show that we printed another character
    Mov  AL,_LRCol          ;load the right column boundary
    Cmp  CursorCol,AL       ;is this the last character in the row?
    Jbe  EndDo              ;no, continue printing

DoCRLF:
    Mov  AL,_ULCol          ;yes, reset the current column to the left edge
    Mov  CursorCol,AL

    Inc  CursorRow          ;show that we bumped to the next row
    Add  DI,P$PrintWidth    ;point DI to the next row
    Mov  BL,_LRCol          ;but that's too far -- move to the left edge
    Sub  BL,_ULCol          ;calculate the difference between LRCol and ULCol
    Inc  BL                 ;that inevitable fudge factor...
    Mov  BH,0               ;clear BH so we can use all of BX with DI
    Shl  BX,1               ;times two to account for the attribute bytes
    Sub  DI,BX              ;now DI points to the left edge on the next row
    
    Mov  AL,_LRRow          ;load the right row boundary
    Cmp  CursorRow,AL       ;is this the bottom line in the window?
    Jbe  EndDo              ;no, continue printing

    Dec  CursorRow          ;yes, undo the decrement
    Sub  DI,P$PrintWidth    ;and undo the adjustment to DI

    Push AX                 ;save the registers we're about to trash
    Push CX
    Push DX

    Mov  CX,Word Ptr _ULCol ;load the appropriate registers
    Mov  DX,Word Ptr _LRCol ;two at a time
    Mov  AX,601h            ;service 6 in AH, scroll up one line in AL
    
IFNDEF QLB                  ;if we're not making the Quick Library version
    Mov  BH,P$Color         ;specify the color to clear to when scrolling
ELSE
    Mov  BH,112             ;otherwise use inverse (black on white)
ENDIF

    Push BP                 ;some old BIOSes trash BP
    Int  10h                ;let the BIOS do the work
    Pop  BP

    Pop  DX                 ;restore the registers
    Pop  CX
    Pop  AX

EndDo:
    Loop Do                 ;until done

CheckCRLF:
    Cmp  DoCR,CX            ;is DoCR zero? (CX is known zero after the Loop)
    Je   @F                 ;yes, so jump ahead and skip the "CRLF" business
    Mov  DoCR,CX            ;no, clear the DoCR flag so we don't loop forever
    Inc  CX                 ;force the Loop above to fall through later
    Jmp  Short DoCRLF       ;jump back into the code to bump to the next row

@@:
    Call _SetCursor         ;finally, update the physical cursor position

Exit:
    Ret                     ;return to BASIC

_WindowPrint Endp



WindowInit Proc             ;ULRow:Word, ULCol:Word, LRRow:Word, LRCol:Word

    Push SI                 ;save the registers we'll use
    Push DI

    Mov  SI,SP              ;address the stack directly
    Add  SI,8               ;bump past return address, segment, saved SI & DI
    Mov  DI,Offset _LRCol   ;copy to the local variables

    Cld                     ;read the parameters forward
    Push DS                 ;set ES = DS for Stosb below
    Pop  ES

    Lodsw                   ;get LRCol
    Dec  AX                 ;adjust to zero-based
    Stosb                   ;and store it locally

    Lodsw                   ;get LRRow
    Dec  AX                 ;as above
    Stosb

    Lodsw                   ;get ULCol
    Dec  AX
    Stosb

    Lodsw                   ;get ULRow
    Dec  AX
    Stosb

    ;--- ensure the cursor is located within the new window boundaries
    Mov  AL,_ULRow          ;get the current upper row limit
    Cmp  AL,CursorRow       ;are we above the highest row?
    Ja   @F                 ;yes, handle that

    Mov  AL,_LRRow          ;get the current lower row limit
    Cmp  AL,CursorRow       ;are we below the lowest row?
    Jae  DoneRow            ;no, skip ahead

@@:
    Mov  CursorRow,AL       ;force the cursor into the window

DoneRow:
    Mov  AL,_ULCol          ;get the current left column limit
    Cmp  AL,CursorCol       ;are we before the left-most row?
    Ja   @F                 ;yes, handle that

    Mov  AL,_LRRow          ;get the current right column limit
    Cmp  AL,CursorCol       ;are we after the right-most row?
    Jbe  DoneCol            ;no, skip ahead

@@:
    Mov  CursorCol,AL       ;force the cursor into the window

DoneCol:
    Call _SetCursor         ;set the physical cursor position

    Pop  DI                 ;pop these manually
    Pop  SI
    Retf 8                  ;return far manually popping eight parameters

WindowInit Endp



WindowCLS Proc              ;clear the window and home the cursor

    Mov  CX,Word Ptr _ULCol ;load the appropriate registers
    Mov  DX,Word Ptr _LRCol ;two at a time

    Mov  Word Ptr CursorCol,CX  ;set CursorCol and CursorRow while the
                                ;the values are at hand

    Mov  AX,600h            ;service 6 in AH, 0 lines (clear) in AL
    
IFNDEF QLB                  ;if we're not making the Quick Library version
    Mov  BH,P$Color         ;specify the color to clear to when clearing
ELSE
    Mov  BH,112             ;otherwise use inverse (black on white)
ENDIF

    Push BP                 ;some old BIOSes trash BP
    Int  10h                ;let the BIOS do the work
    Pop  BP

    Call _SetCursor         ;set the cursor position

    Ret                     ;return to BASIC

WindowCLS Endp



WindowLocate Proc, Row:Word, Column:Word  ;position the cursor in the window

    Mov  AX,Row             ;get the desired row to locate to
    Dec  AX                 ;adjust to zero-based
    Add  AL,_ULRow          ;adjust to virtual coordinates

    Cmp  AL,_ULRow          ;are they trying to locate higher than the top?
    Jae  @F                 ;no, continue
    Mov  AL,_ULRow          ;yes, force the location within the window
    
@@:
    Cmp  AL,_LRRow          ;are they trying to locate lower than the bottom?
    Jbe  @F                 ;no, continue
    Mov  AL,_LRRow          ;yes, force the location within the window

@@:
    Mov  CursorRow,AL       ;save the result

    Mov  AX,Column          ;now do the same for the column
    Dec  AX
    Add  AL,_ULCol

    Cmp  AL,_ULCol          ;are they trying to locate before the left edge?
    Jae  @F                 ;no, continue
    Mov  AL,_ULCol          ;yes, force the location within the window

@@:
    Cmp  AL,_LRCol          ;are they trying to locate past the right edge?
    Jbe  @F                 ;no, continue
    Mov  AL,_LRCol          ;yes, force the location within the window

@@:
    Mov  CursorCol,AL

    Call _SetCursor         ;set the physical cursor position
    Ret                     ;return to BASIC

WindowLocate Endp



WindowRow Proc              ;returns the current window row (like CSRLIN)

    Mov  AL,CursorRow       ;get the current row
    Sub  AL,_ULRow          ;convert from a physical row to a virtual row
    Inc  AL                 ;convert from zero-based to one-based
    Mov  AH,0               ;return a full word in AX
    Ret                     ;return to BASIC

WindowRow Endp



WindowCol Proc              ;returns the current window column (like POS(0))

    Mov  AL,CursorCol       ;get the current column
    Sub  AL,_ULCol          ;convert from a physical column to a virtual one
    Inc  AL                 ;convert from zero-based to one-based
    Mov  AH,0               ;return a full word in AX
    Ret                     ;return to BASIC

WindowCol Endp



_SetCursor Proc Near        ;internal, moves the cursor to the correct place

    Mov  DX,Word Ptr CursorCol  ;load both variables into DX in one operation
    Mov  AH,2                   ;BIOS video set cursor service
    Mov  BH,0                   ;we're working on text page zero
    Push BP                     ;some old BIOSes trash BP
    Int  10h                    ;call the BIOS to position the cursor
    Pop  BP
    Ret                     ;return to caller (near)

_SetCursor Endp
End
