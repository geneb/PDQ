;********* BIOSINP2.ASM - enhanced version of BIOSInput

;Copyright (c) 1991 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support

;This is an enhanced version of BIOSInput that recognizes the Home, End, Ins,
;and Del keys, and also accepts Row and Column parameters.  Unlike BIOSInput,
;BIOSInput2 restores the cursor size and location to what it had been before
;the call.  If declared as a function as shown below, you can also determine
;the last key that was pressed when BIOSInput2 was exited.
;
;syntax:
; DECLARE FUNCTION BIOSInput2%(Work$, BYVAL Row%, BYVAL Column%, BYVAL Colr%)
; Work$ = "This is a default response."
; EditColor% = 112
; Row% = 1: Column% = 20
; LastKey = BIOSInput2%(Work$, BYVAL Row%, BYVAL Column%, BYVAL EditColor%)


.Model Medium, Basic
    Extrn P$FixStr:Proc         ;this handles far strings (FIXSTR.ASM)
    Extrn B$LOCT   :Proc        ;this locates the cursor (LOCATE.ASM)
    Extrn BIOSInkey:Proc        ;use this to get keystrokes (BIOSINKY.ASM)
    Extrn CursorOn :Proc        ;this turns on the cursor (CURSOR.ASM)
    Extrn CursorSave:Proc       ;this is in CURSORSR.ASM
    Extrn CursorRest:Proc       ;so is this
    Extrn CursorSize:Proc       ;this is in CSRSIZE.ASM
    Extrn PDQPrint :Proc        ;this prints the text (PDQPRINT.ASM)

.Data
    Extrn P$MonSeg:Word         ;this is in MONSETUP.ASM

.Data?
    CurCol   DW 1 Dup (?)       ;this remembers the current column
    SaveCsr  DW 2 Dup (?)       ;this saves the original cursor information
    CsrTop   DW 1 Dup (?)       ;top line of cursor
    CsrBot   DW 1 Dup (?)       ;bottom line of cursor
    InsState DB 1 Dup (?)       ;this tracks when we're in Insert mode

.Code

BIOSInput2 Proc, Work:Word, Row:Word, Column:Word, Color:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Call CursorSave         ;save the current cursor context
    Mov  SaveCsr,AX
    Mov  SaveCsr+2,DX

    Mov  InsState,0         ;force the Insert status off initially, REM this
                            ;  out to preserve the state between calls

    Mov  BX,Work            ;get the address for Work$
    Mov  CX,[BX]            ;put its length into CX
    Mov  SI,[BX+02]         ;and its address into SI
    Dec  CX                 ;adjust to zero-based for comparisons below
    Jns  @F                 ;the length was not zero, continue
    Jmp  Exit               ;we can't enter a null string, exit now!

@@:
    Mov  AX,Column          ;initialize CurCol to the specified column
    Mov  CurCol,AX

    Call PDQPrintMe         ;print the string, init P$MonSeg for below
    Xor  BX,BX              ;this tracks where we are in the string, it
                            ;  is zero-based for indexing using [BX+SI]

    Mov  CsrTop,6           ;assume we have a color display
    Mov  CsrBot,7
    Cmp  P$MonSeg,0B800h    ;well, do we?
    Je   UpDate             ;yes, so the cursor size is correct
    Mov  Byte Ptr CsrTop,11 ;no, use parameters appropriate for monochrome
    Mov  Byte Ptr CsrBot,12 ;Byte Ptr saves a few bytes here

Update:
    Push BX                 ;these must be saved when in the QB editor
    Push CX
    Call PDQLocateMe        ;locate the cursor to the current position
    Call PDQPrintMe         ;print the entire string
    Call SizeMe             ;set the appropriate cursor size
    Pop  CX
    Pop  BX

KeyLoop:
    Push BX                 ;save BX because BIOSInkey trashes it
    Call BIOSInkey          ;get a keypress
    Pop  BX                 ;get BX back again
    Or   AX,AX              ;anything there?
    Jz   KeyLoop            ;no, wait until they press something

    Js   @F                 ;it's an extended key, filter through the tests
    Jmp  RegKey             ;it's a regular key

@@:
    Cmp  AL,-75             ;is it a left arrow?
    Jne  TryRight           ;no, see if it's a right arrow

DoLeft:
    Or   BX,BX              ;yes, but are we already at the left column?
    Je   KeyLoop            ;yes, so ignore the request
    Dec  CurCol             ;no, show that we're one column to the left
    Dec  BX                 ;reflect that in BX too
    Jmp  Update             ;update the cursor and go again

TryRight:
    Cmp  AL,-77             ;is it a right arrow?
    Jne  TryInsert          ;no, see if it's the Insert key

DoRight:
    Cmp  BX,CX              ;are we at the end of the field?
    Je   UpDate             ;yes, so ignore the arrow key
    Inc  CurCol             ;no, show that we went a column to the right
    Inc  BX                 ;adjust BX too
    Jmp  Update             ;update the cursor and go again

TryInsert:
    Cmp  AL,-82             ;is it the Insert key?
    Jne  TryDelete          ;no, see if it's the Delete key

DoInsert:
    Not  InsState           ;yes, toggle the Insert status
    Cmp  InsState,0         ;and set the zero flag accordingly
    Mov  AL,6               ;assume we're going from insert to normal
    Je   @F                 ;yes, that is correct
    Neg  AL                 ;no, Insert just flipped to -1

@@:
    Add  Byte Ptr CsrTop,AL ;apply size correction to the low byte only
    Jmp  Update             ;update the cursor and go again

TryDelete:
    Cmp  AL,-83             ;is it the Delete key?
    Jne  TryHome            ;no, see if it's the Home key

DoDelete:
    Push BX                 ;save BX before we trash it

@@:
    Mov  AL,[BX+SI+1]       ;grab the subsequent character
    Mov  [BX+SI],AL         ;and place it into the current position
    Cmp  BX,CX              ;how are we doing?
    Jae  DoneDelete         ;just fine thanks!
    Inc  BX                 ;consider the next character
    Jmp  @B                 ;and keep looping

DoneDelete:
    Mov  Byte Ptr [BX+SI]," "   ;clear the last character
    Pop  BX
    Jmp  Update             ;and go again

TryHome:
    Cmp  AL,-71             ;is it the Home key?
    Jne  TryEnd             ;no, see if it's the End key

DoHome:
    Mov  AX,Column          ;reset to the first column
    Mov  CurCol,AX
    Xor  BX,BX              ;clear BX to show we're at the start again
    Jmp  Update             ;and continue

TryEnd:
    Cmp  AL,-79             ;is it the End key?
    Jne  KeyLoop            ;no, so ignore it
;   Jne  Exit               ;use this line instead of the one above to
                            ;  exit if it's a non-recognized extended key

DoEnd:                      ;note special tests for first and last characters
    Mov  AX,CX              ;first set CurCol to the end of the string
    Sub  AX,BX              ;see how far we are from the end
    Add  CurCol,AX          ;now CurCol shows we're at the end
    Mov  BX,CX              ;and so does BX

@@:
    Cmp  Byte Ptr [BX+SI]," "   ;are we sitting on a blank?
    Jne  DoneEnd                ;no, so we're at the end now
    Dec  CurCol             ;yes, slide back one position
    Dec  BX
    Jnz  @B                 ;if we're not at the beginning keep checking

DoneEnd:
    Cmp  BX,CX              ;is the field completely full?
    Je   @F                 ;yes, so we're all done
    Or   BX,BX              ;are we at the very beginning?
    Jnz  BumpOne            ;no, bump ahead one
    Cmp  Byte Ptr [SI]," "  ;is the first character a blank?
    Je   @F                 ;yes, so don't skip ahead

BumpOne:
    Inc  CurCol             ;no, slide forward one position
    Inc  BX

@@:
    Jmp  Update             ;update the cursor and go again

RegKey:
    Cmp  AL,13              ;no, but is it Enter?
    Je   Exit               ;yes, so we're all done
    Cmp  AL,27              ;is it Escape?
    Je   Exit               ;yes, leave

    Cmp  AL,8               ;was it a back space?
    Jne  @F                 ;no, continue
    Or   BX,BX              ;yes, but are we already at the beginning?
    Jz   @F                 ;yes, so skip ahead and ignore
    Dec  BX                 ;no, show we went back a character
    Dec  CurCol
    Jmp  DoDelete           ;and let the Delete key code handle it!

@@:
    Cmp  AL," "             ;is it a control key?
    Jae  @F                 ;no, handle it
    Jmp  KeyLoop            ;yes, ignore it

@@:
    Cmp  InsState,0         ;are we in Insert mode?
    Jz   NotInsert          ;no, so simply assign the character to the string

    Mov  DX,BX              ;save a copy of BX in DX so we know where to stop
    Mov  BX,CX              ;prepare to slide characters right, start at end
    Push AX                 ;save the current character

@@:
    Cmp  BX,DX              ;are we done?
    Je   DoneInsert         ;yes, assign the current character and loop again
    Mov  AL,[BX+SI-1]       ;load the character to the left of this one
    Mov  [BX+SI],AL         ;and store it in the current position
    Dec  BX                 ;consider the previous character pair
    Jmp  @B                 ;until done

DoneInsert:
    Pop  AX                 ;retrieve the current character

NotInsert:
    Mov  [BX+SI],AL         ;insert the character into the string
    Jmp  DoRight            ;and let "Dudley" do the work (get it?)

Exit:
    Push AX                 ;save the returned key code for a moment
    Mov  AX,Offset SaveCsr  ;restore the cursor context
    Push AX
    Call CursorRest
    Pop  AX                 ;this lets BIOSInput2 return the last key
    Ret                     ;return to BASIC

;----- subroutines

PDQPrintMe:                 ;this handles printing
    Push BX                 ;save BX because PDQPrint trashes it
    Push CX                 ;same for CX
    Push SI                 ;and for SI too
    Push Work               ;push the incoming descriptor address
    Lea  AX,Row             ;and the row and column information
    Push AX
    Lea  AX,Column
    Push AX
    Lea  AX,Color           ;and finally the color
    Push AX
    Call PDQPrint           ;print the string
    Pop  SI                 ;restore the registers
    Pop  CX
    Pop  BX
    Retn                    ;force a near return from this procedure

PDQLocateMe:
    Mov  AX,1               ;show LOCATE that there's a Row parameter
    Push AX
    Push Row                ;pass the row to locate to
    Push AX                 ;show that there's a Column parameter
    Push CurCol             ;pass the column to locate to
    Mov  AX,4               ;tell LOCATE that 4 parameters preceded
    Push AX                 ;pass that
    Call B$LOCT             ;locate the cursor
    Retn                    ;force a near return from this procedure

SizeMe:
    Push BX                 ;save BX and CX because CursorSize trashe 'em
    Push CX
    Mov  AX,Offset CsrTop   ;force the correct cursor size
    Push AX
    Mov  AX,Offset CsrBot
    Push AX
    Call CursorSize
    Pop  CX
    Pop  BX
    Retn

BIOSInput2 Endp
End
