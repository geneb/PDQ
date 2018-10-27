;********** PDQPARSE.ASM - parses delimited PATH and "DATA" items

;Copyright (c) 1989 Ethan Winer
; 11/3/92  Thomas G. Hanlin III   added far string support


;syntax: This$ = PDQParse$(Work$)              'to read a string
;        ThisInt = PDQValI%(PDQParse$(Work$))  'to read an integer
;        CALL PDQRestore                       'to reset for reading anew
;        CALL SetDelimitChar(Char)             'to use other than ";"


.Model Medium, Basic
    Extrn P$FixStr:Proc     ;this is in FIXSTR.ASM
    Public P$NextChar, P$DelimitChar

.Data?
    DescLen  DW 1 Dup(?)  ;this is the output descriptor length
    DescAdr  DW 1 Dup(?)  ;and this is the output descriptor address

.Data
    P$NextChar DW 0       ;this is the next character to be read (minus 1)
    P$DelimitChar DB ";"  ;this is the default delimiter

.Code

PDQParse Proc Uses SI, Work:Word

    Push Work             ;if it's a far string literal, make it a near string
    Call P$FixStr         ;
    Mov  Work,AX          ;

    Mov  SI,Work          ;get the descriptor address for Work$
    Mov  CX,[SI]          ;get its length
    Mov  SI,[SI+02]       ;and its address
    Cld                   ;ensure that string loads are forward

    Xor  BX,BX            ;this accumulates the length of the function output
    Jcxz Exit             ;they slipped us a null string, get out now
    Add  SI,P$NextChar    ;bump SI to the current READ location in Work$
    Sub  CX,P$NextChar    ;we'll consider that many fewer characters too
    Js   Exit             ;we're past the end, bail out and return a null

TrimLoop:                 ;trim leading blanks and tabs
    Jcxz Exit             ;we ran out of string, exit
    Lodsb                 ;get the current character in the string
    Dec  CX               ;and show the string being one character shorter
    Inc  P$NextChar       ;and update P$NextChar for subsequent calls

    Cmp  AL,32            ;is it a blank space?
    Je   TrimLoop         ;yes, "eat" it up
    Cmp  AL,9             ;is it a Tab character?
    Je   TrimLoop         ;yes, so eat that too

    Dec  SI               ;Lodsb took us far into the string, back up one
    Inc  CX               ;ditto for CX
    Mov  DescAdr,SI       ;assign the output descriptor address

ReadLoop:
    Lodsb                 ;get the next character
    Cmp  AL,P$DelimitChar ;is it a delimiter that marks the end of this item?
    Je   Exit             ;yes, so we're all done
    Inc  BX               ;no, show the output string being one longer
    Loop ReadLoop         ;and keep reading until done

Exit:
    Mov  DescLen,BX          ;assign the function output length
    Add  P$NextChar,BX       ;adjust P$NextChar to the correct spot for later
    Mov  AX,Offset DescLen   ;show BASIC where the output descriptor is
    Ret                      ;return to BASIC

PDQParse Endp
End
