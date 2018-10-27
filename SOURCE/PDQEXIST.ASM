;********** PDQEXIST.ASM - determines if the named file/file spec is present

;Copyright (c) 1989 Ethan Winer

;Syntax - There = PDQExist%(FSpec$)
;
;  Where FSpec$ holds the file specification, and There receives -1 if it
;  was there, or 0 if it wasn't.


.Model Medium, Basic
.Data
    Extrn P$PDQErr:Word   ;this is in ERRDATA.ASM

.Code

PDQExist Proc, FSpec:Word

    Local Buffer[80]:Byte ;copy the file name here to add a CHR$(0)
    Local DTA[44]:Byte    ;this holds the DTA

    Lea  DX,DTA           ;put address of DTA into DS:DX for set DTA service
    Mov  AH,1Ah           ;set DTA service - creates space for a file name
    Int  21h              ;call DOS

    Mov  AX,FSpec         ;get the address for the file name or specification
    Lea  DX,Buffer        ;get the address for the start of the buffer

;-- This code was extracted from ZEROFILE.ASM because we don't want to call
;   P$FreeTemp (added to ZEROFILE.ASM 3-6-90) when PDQExist is in a Quick Lib.
;
    Cld                    ;all string moves forward
    Push DS                ;ensure that ES = DS for Movsb below
    Pop  ES                ;it's up to our caller to save registers if needed

    Mov  DI,DX             ;copy the buffer address into DI
    Mov  SI,AX             ;get the address for FileName$ descriptor
    Mov  CX,[SI]           ;put its length into CX
    Mov  SI,[SI+02]        ;now DS:SI points to the file name
    Rep  Movsb             ;copy the name to the caller's local stack buffer
    Mov  [DI],CL           ;tack on the zero byte

;-- end of extracted code

    Mov  P$PDQErr,CX      ;clear any previous errors (CX is conveniently 0)
    Mov  BX,CX            ;assume no matching files for now
    
    Mov  CL,00100111b     ;and put the attribute for all files into CL
    Mov  AH,4Eh           ;find first matching file name service
    Int  21h              ;call DOS
    Jc   Exit             ;we were right earlier, it's not there
    Dec  BX               ;it is there, decrement BX to -1 to show that

Exit:
    Mov  AX,BX            ;leave the function output in AX
    Ret

PDQExist Endp
End
