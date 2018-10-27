;********** ASSIGN.ASM - PDQ replacements for BASIC's B$ASSN and B_ASSN

;Copyright (c) 1989 Ethan Winer

;These routines assign fixed-length and TYPE variables.


.Model Medium, Basic
    Extrn B$LDFS: Proc    ;this is in FLEN2STR.ASM
    Extrn B$SASS: Proc    ;this is in ASSIGN$.ASM
    Extrn B$LSET: Proc    ;this is in LSET.ASM

.Code

STRINGASSIGN Proc         ;this is the same too, but for BASIC 7
    Nop                   ;this forces CodeView to show the correct name
STRINGASSIGN Endp         ;fall through


B_ASSN Proc
;   Jmp  Short B$ASSN     ;this seems to be the same as B$ASSN, fall through
B_ASSN Endp


B$ASSN Proc Uses SI DI ES, FromStr:DWord, FromLen:Word, ToStr:DWord, ToLen:Word

    ;---- obtain the incoming parameter addresses
    Les  SI,FromStr       ;get the segmented address for the source string
    Mov  BX,ES            ;save ES in BX for a moment
    Mov  CX,FromLen       ;get the source length
    Les  DI,ToStr         ;get the segmented address for the destination
    Mov  AX,ToLen         ;and its length too

    ;---- determine which variable(s) are fixed-length, and which is longer
    Jcxz FromReg          ;if CX is zero, then the source is a regular string
    Or   AX,AX            ;see if the destination is a fixed-length string
    Jz   ToReg            ;and if AX is zero, the destination is "regular"
    Sub  AX,CX            ;both are fixed-length, see which is longer
    Jnc  ToLonger         ;the destination is longer
    Mov  CX,ToLen         ;the source is, clip CX to the destination length
    Xor  AX,AX            ;and zero out AX

ToLonger:
    ;---- the destination variable is longer
    Push DS               ;save DS while we perform an LSET
    Mov  DS,BX            ;load DS with the source string segment
    Cld                   ;make string ops forward
    Rep  Movsb            ;then copy the string
    Mov  CX,AX            ;get the remaining length in the destination
    Mov  AL,32            ;and fill it with blank spaces
    Rep  Stosb            ;pad to the end of the string
    Pop  DS               ;retrieve DS
    Jmp  Short Exit       ;all done

ToReg:
    ;---- the destination is a conventional (not fixed-length) string
    Push BX               ;we're coming from a fixed-length string
    Push SI               ;show B$LDFS where the source string is located
    Push CX               ;so it can create a temporary descriptor
    Call B$LDFS           ;B$LDFS returns the address of that descriptor

    Push AX               ;now show B$SASS where the temporary descriptor is
    Push DI               ;and where the destination string is
    Call B$SASS           ;let B$SASS do all the hard stuff
    Jmp  Short Exit       ;all done

FromReg:
    ;---- the source string is conventional, the destination is fixed-length
    Push SI               ;show LSET where the source string is coming from
    Push ES               ;pass on the destination segment
    Push DI               ;and its address
    Push AX               ;and its length
    Call B$LSET           ;let LSET do the work

Exit:
    Ret                   ;return to BASIC

B$ASSN Endp
End
