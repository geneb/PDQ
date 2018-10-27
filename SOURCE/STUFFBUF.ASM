;********* STUFFBUF.ASM - stuffs keystrokes into the keyboard buffer

;Copyright (c) 1989 Ethan Winer


;calling syntax - CALL StuffBuf(Argument$)
;
;Where Argument$ is a sequence of up to fifteen keystrokes.
;To put an Enter into the buffer add a CHR$(13) to the end:
;
;    CALL StuffBuf("Hi There" + CHR$(13))
;
;Extended keys must be assigned with a leading CHR$(0).
;This example places "Testing", an up arrow key, and "123" into the buffer:
;
;   CALL StuffBuf("Testing" + CHR$(0) + CHR$(72) + "123"


.Model Medium, Basic
.Code

StuffBuf Proc Uses SI DI, StackArg:Word

    Mov  SI,StackArg    ;get the address of the argument string
    Mov  CX,[SI]        ;put its length into CX
    Jcxz Exit           ;if the length is zero, someone screwed up!
    Mov  SI,[SI+02]     ;get the address of Argument$

    Xor  AX,AX          ;address the keyboard buffer in low memory
    Mov  ES,AX          ;ES = 0
    Mov  DI,41Ah        ;set DI to address the buffer pointer
    Mov  AL,1Eh         ;establish the buffer head to be 41Eh
                        ;  ( + 400h is assumed meaning 1Eh = 41Eh)
    Cli                 ;disable interrupts until we're all done
    Cld                 ;ensure string ops work forward

    Stosw               ;set the head to 41Eh and point to the buffer tail
    Mov  AX,CX          ;put the argument length into AX
    Shl  AX,1           ;multiply times 2 for byte between characters
    Add  AL,1Eh         ;add to the 1Eh buffer start address (AH is now 0)
    Stosw               ;set the tail to 2 * LEN(Argument$)

NextChar:
    Mov  AH,0           ;clear AH to assign a null byte between characters
    Lodsb               ;get the character in Argument$
    Or   AL,AL          ;is it an extended character?
    Jnz  Normal         ;no, handle as usual

    Lodsb               ;get the extended part of the string
    Xchg AL,AH          ;put it into AH and the zero into AL (AH *must* be 0)
    Sub  Byte Ptr ES:[41Ch],2   ;we set the tail too far before, adjust it
    Dec  CX                     ;ditto, so do one less Loop below
    
Normal:
    Stosw               ;put it (and the zero byte) into the buffer
    Loop NextChar       ;loop until done
    Sti                 ;re-enable interrupts

Exit:
    Ret                 ;return to BASIC

StuffBuf Endp
End
