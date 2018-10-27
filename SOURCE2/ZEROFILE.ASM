;******* ZEROFILE.ASM - creates an ASCIIZ string on the stack for DOS services

;Copyright (c) 1989 Crescent Software

;ZeroFile is called with AX holding the FileName$ descriptor address, and DX
;holding the address of a local stack buffer to copy it to.  After the name
;is copied into the buffer, a CHR$(0) is appended to the end (ASCIIZ string)
;and the incoming string is passed to P$FreeTemp for deletion if needed.

;WARNING: Many callers rely on the fact that P$ZeroFile leaves CX set to 0.


.Model Medium, Basic
    Extrn P$FreeTemp:Proc  ;this is in FREETEMP.ASM
    
.Code

P$ZeroFile Proc Uses SI DI ;called with AX=descriptor address, DX=buffer

    Cld                    ;all string moves forward
    Push DS                ;ensure that ES = DS for Movsb below
    Pop  ES                ;it's up to our caller to save registers if needed

    Mov  DI,DX             ;copy the buffer address into DI
    Mov  SI,AX             ;get the address for FileName$ descriptor
    Mov  CX,[SI]           ;put its length into CX

    Cmp  CX,79             ;is the string too long?
    Jbe  @F                ;no, continue
    Mov  CX,79             ;yes, clip it to what will fit

@@:
    Mov  SI,[SI+02]        ;now DS:SI points to the file name
    Rep  Movsb             ;copy the name to the caller's local stack buffer
    Mov  [DI],CL           ;tack on the zero byte

    Push AX                ;pass the incoming descriptor to P$FreeTemp
    Call P$FreeTemp        ;delete it if necessary
    Ret                    ;return to caller

P$ZeroFile Endp
End
