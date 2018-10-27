;********** MID$.ASM - PDQ replacement for BASIC's B$FMID routine

;Copyright (c) 1989 Ethan Winer


;This routine provides the function form of MID$.


.Model Medium, Basic
    Extrn P$MakeTemp:Proc ;this is in MAKETEMP.ASM
    Extrn P$FreeTemp:Proc ;this is in FREETEMP.ASM

.Data?
    DescrLen DW 1 Dup (?) ;this is the P$FMid output descriptor
    DescrAdr DW 1 Dup (?)

.Code

P$FMid Proc               ;this is called from the statement form of MID$
    Mov  BL,1             ;flag that we were called from the MID$ statement
    Db   3Dh              ;fake the Mov below into a phony Cmp instruction
P$FMid Endp


B$FMID Proc               ;this is called when you use BASIC's MID$ function
    Mov  BL,0             ;flag to create a new string later in the routine
B$FMID Endp


B$BMid Proc Uses SI DI, StrArg:Word, MidArg:Word, NumChars:Word

    Mov  SI,StrArg        ;get address of StrArg$
    Mov  AX,[SI]          ;put its length into AX
    Mov  SI,[SI+02]       ;now SI points to the start of StrArg$

    Mov  CX,MidArg        ;load CX with MidArg and see if it's zero
    Jcxz Done             ;it is, return a null rather than make an error
    Cmp  CX,AX            ;but is MidArg past the end of the string?
    Jbe  Okay             ;no, so use the MidArg character count now in CX

MakeNull:
    Xor  CX,CX            ;yes, return a null string
    Jmp  Short Done       ;and bail out

Okay:
    Dec  CX               ;fudge since length is based at one, address at zero
    Mov  DX,CX            ;save the offset in DX, so we can apply it later
    Sub  AX,CX            ;calculate MidArg fewer characters to work with

    Mov  CX,NumChars      ;now see how many characters they want to use
    Cmp  CX,AX            ;are they asking for too many characters?
    Jbe  Done             ;no, use the NumChars argument now in CX
    Mov  CX,AX            ;yes, so use only as many as AX says there are

Done:
    Or   BL,BL            ;were we called from the MID$ function?
    Jz   MakeTemp         ;no, so go make the temporary output string
    Mov  DescrLen,CX      ;yes, create the function output descriptor
    Add  SI,DX            ;point SI that much farther into the string
    Mov  DescrAdr,SI      ;now DescrAdr holds the correct starting address
    Mov  AX,Offset DescrLen  ;show where the output descriptor is located
    Jmp  Short Exit          ;and skip ahead to exit

MakeTemp:
    Call P$MakeTemp       ;claim temporary space in the string pool
    Mov  SI,StrArg        ;get address of StrArg$ again in case it moved
    Push SI               ;show P$FreeTemp where the string is for later
    Mov  SI,[SI+02]       ;now SI points to the start of StrArg$
    Add  SI,DX            ;point that much farther into the string
    Rep  Movsb            ;copy the characters into the string pool

    Mov  AX,BX            ;show where the output descriptor is
    Call P$FreeTemp       ;delete the source string if necessary

Exit:
    Ret                   ;return to caller

B$BMid Endp
End
