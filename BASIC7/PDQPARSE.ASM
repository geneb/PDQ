;********** PDQPARSE.ASM - parses delimited PATH and "DATA" items

;Copyright (c) 1989 Ethan Winer
;BC7 conversion 3/90 J.Munro

;syntax: This$ = PDQParse$(Work$)              'to read a string
;        ThisInt = PDQValI%(PDQParse$(Work$))  'to read an integer
;        CALL PDQRestore                       'to reset for reading anew
;        CALL SetDelimitChar(Char)             'to use other than ";"


.Model Medium, Basic
    Public P$NextChar, P$DelimitChar

    Extrn StringAddress:Proc    ;these are internal QBX routines
    Extrn StringLength:Proc
    Extrn StringAssign:Proc
    
.Data?
    DescLen  DW 1 Dup(?)  ;this is the output descriptor length
    DescAdr  DW 1 Dup(?)  ;and this is the output descriptor address

.Data
    P$NextChar DW 0       ;this is the next character to be read (minus 1)
    P$DelimitChar DB ";"  ;this is the default delimiter
    P$NullSpace DW 0

.Code

PDQParse Proc Uses ES SI, Work:Word

    Push ES
    Mov  SI,Work          ;get the descriptor address for Work$
    Push SI
    Call StringLength     ;get its length
    Mov  CX,AX
    Xor  BX,BX            ;this accumulates the length of the function output
    Pop  ES
    Jcxz Exit             ;they slipped us a null string, get out now
    Push SI
    Call StringAddress
    Mov  SI,AX
    Add  SI,P$NextChar    ;bump SI to the current READ location in Work$
    Sub  CX,P$NextChar    ;we'll consider that many fewer characters too
    Js   Exit             ;we're past the end, bail out and return a null
    Mov  ES,DX            ;point ES at stringsegment

TrimLoop:                 ;trim leading blanks and tabs
    Jcxz Exit             ;we ran out of string, exit
    Mov  AL,ES:[SI]       ;get the current character in the string
    Inc  SI
    Dec  CX               ;and show the string being one character shorter
    Inc  P$NextChar       ;and update P$NextChar for subsequent calls

    Cmp  AL,32            ;is it a blank space?
    Je   TrimLoop         ;yes, "eat" it up
    Cmp  AL,9             ;is it a Tab character?
    Je   TrimLoop         ;yes, so eat that too

    Dec  SI               ;Lodsb took us far into the string, back up one
    Inc  CX               ;ditto for CX
    Mov  DX,SI            ;assign the output descriptor address

ReadLoop:
    Mov  AL,ES:[SI]       ;get the next character
    Inc  SI
    Cmp  AL,P$DelimitChar ;is it a delimiter that marks the end of this item?
    Je   Exit             ;yes, so we're all done
    Inc  BX               ;no, show the output string being one longer
    Loop ReadLoop         ;and keep reading until done

Exit:
    Add  P$NextChar,BX       ;adjust P$NextChar to the correct spot for later
    Or   BX,BX
    Jz   NullOne
    Push ES                  ;push segment of string
    Push DX                  ;push offset into it
    Push BX                  ;assign the function output length

DoString:
    Push DS                  ;push segment of descriptor
    Mov  AX,Offset DescLen   ;show BASIC where the output descriptor is
    Push AX
    Xor  AX,AX
    Push AX
    Call StringAssign
    Mov  AX,Offset DescLen   ;show BASIC where the output descriptor is
    Ret                      ;return to BASIC

NullOne:
    Push DS                    ;push segment of nullspace
    Mov  AX,Offset P$NullSpace ; and address
    Push AX
    Push BX                    ;and since BX is 0, push it for a len of 0
    Jmp  Short DoString

PDQParse Endp
End
