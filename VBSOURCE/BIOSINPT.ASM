;********* BIOSINPT.ASM - PDQ "minimal" editor routine

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support

;This is similar to PDQInput, except it supports an editing color parameter,
;and uses the BIOS for input.  Therefore, input may not be redirected, though
;it may be used in TSR programs.  The left and right arrow keys are recognized
;for navigating within the field, however Ins and Delete are not implemented.
;
;syntax:  Work$ = "This is a default response."
;         EditColor = 112
;         CALL BIOSInput(Work$, EditColor)


.Model Medium, Basic
    Extrn P$FixStr:Proc         ;this handles far strings (FIXSTR.ASM)
    Extrn B$CSRL   :Proc         ;gets the current cursor row (CSRLIN.ASM)
    Extrn B$FPOS   :Proc         ;and this gets the current column (POS0.ASM)
    Extrn B$LOCT   :Proc         ;this locates the cursor (LOCATE.ASM)
    Extrn BIOSInkey:Proc         ;use this to get keystrokes (BIOSINKY.ASM)
    Extrn CursorOn :Proc         ;this turns on the cursor (CURSOR.ASM)
    Extrn PDQPrint :Proc         ;this prints the text (PDQPRINT.ASM)

.Data?
    CurRow   DW 1 Dup(?)         ;this receives the current cursor row
    CurCol   DW 1 Dup(?)         ;and this receives the current column
    OldCol   DW 1 Dup(?)         ;this remembers the original column

.Code

BIOSInput Proc Uses SI, Work:Word, Color:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  BX,Work                 ;get the address for Work$
    Mov  CX,[BX]                 ;put its length into CX
    Mov  SI,[BX+02]              ;and its address into SI
    Jcxz Exit                    ;can't enter a null string, exit
    Dec  CX                      ;adjust to zero-based for comparisons below

    Push CX                      ;save CX because CSRLIN and POS(0) trash it
    Call B$CSRL                  ;get the current cursor coordinates
    Mov  CurRow,AX               ;and save them internally
    Push AX                      ;satisfy POS(0)'s need for a dummy parameter
    Call B$FPOS
    Mov  CurCol,AX
    Mov  OldCol,AX
    Call CursorOn                ;force the cursor on
    Pop  CX                      ;retrieve CX
    Xor  BX,BX                   ;this tracks where we are in the string, it
                                 ;  is zero-based for indexing using [SI+BX]
Update:
    Push BX                      ;these must be saved when in the QB editor
    Push CX
    Call PDQLocateMe             ;locate the cursor to the current position
    Call PDQPrintMe              ;print the entire string
    Pop  CX
    Pop  BX

KeyLoop:
    Push BX                      ;save BX because BIOSInkey trashes it
    Call BIOSInkey               ;get a keypress
    Pop  BX                      ;get BX back again
    Or   AX,AX                   ;anything there?
    Jz   KeyLoop                 ;no, wait until they press something

    Jns  RegKey                  ;if it's not negative, it's a regular key
    Cmp  AL,-75                  ;is it a left arrow?
    Jne  TryRight                ;no, see if it's a right arrow

DoLeft:
    Or   BX,BX                   ;yes, but are we already at the left column?
    Je   KeyLoop                 ;yes, so ignore the request
    Dec  CurCol                  ;no, show that we're one column to the left
    Dec  BX                      ;reflect that in BX too
    Jmp  Short Update            ;update the cursor and go again

TryRight:
    Cmp  AL,-77                  ;is it a right arrow?
    Jne  KeyLoop                 ;no, so ignore it

DoRight:
    Cmp  BX,CX                   ;are we at the end of the field?
    Je   UpDate                  ;yes, so ignore the arrow key
    Inc  CurCol                  ;no, show that we went a column to the right
    Inc  BX                      ;adjust BX too
    Jmp  Short Update            ;update the cursor and go again

RegKey:
    Cmp  AL,13                   ;is it Enter?
    Je   Exit                    ;yes, so we're all done
    Cmp  AL,27                   ;is it Escape?
    Je   Exit                    ;yes, leave
;   Cmp  AL,3                    ;is it Ctrl-C?  } unREM these if you want
;   Je   Exit                    ;yes, leave     } to exit upon Ctrl-C

    Cmp  BX,CX                   ;are we at the end of the field?
    Ja   KeyLoop                 ;yes, so ignore the key
    Cmp  AL,8                    ;was it a back space?
    Je   DoLeft                  ;yes, let the left-arrow code handle it

    Mov  [SI+BX],AL              ;insert the character into the string
    Jmp  Short DoRight           ;and let "Dudley" do the work (get it?)

Exit:
    Ret                          ;return to BASIC



PDQPrintMe:                      ;this handles printing
    Push BX                      ;save BX because PDQPrint trashes it
    Push CX                      ;same for CX
    Push SI                      ;and for SI too
    Push Work                    ;push the incoming descriptor address
    Mov  AX,Offset CurRow        ;and the row and column information
    Push AX
    Mov  AX,Offset OldCol
    Push AX
    Push Color                   ;and finally the color
    Call PDQPrint                ;print the string
    Pop  SI                      ;restore the registers
    Pop  CX
    Pop  BX
    Retn                         ;force a near return from this procedure

PDQLocateMe:
    Mov  AX,1                    ;show LOCATE that there's a Row parameter
    Push AX
    Push CurRow                  ;pass the row to locate to
    Push AX                      ;show that there's a Column parameter
    Push CurCol                  ;pass the column to locate to
    Mov  AX,4                    ;tell LOCATE that 4 parameters preceded
    Push AX                      ;pass that
    Call B$LOCT                  ;locate the cursor
    Retn                         ;force a near return from this procedure

BIOSInput Endp
End
