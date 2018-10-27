;********* FREETEMP.ASM - frees a string if it is "temporary"

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Extrn B$STDL:   Proc     ;this is in STRDELET.ASM
    
.Data
    Extrn P$TempDesc: Word   ;this is in TEMPDESC.ASM, and it holds all of
                             ;  the temporary descriptors used in P.D.Q.
.Code

P$FreeTemp Proc Uses AX BX, Address:Word

    Mov  BX,Offset P$TempDesc;get the address for the temporary descriptors
    Cmp  Address,BX          ;is the incoming string below that?
    Jb   Exit                ;yes, so we can ignore it
    Add  BX,76               ;point to the last temporary descriptor
    Cmp  Address,BX          ;is the incoming string above it?
    Ja   Exit                ;yes, ignore that as well
    Push Address             ;no, pass the address on to B$STDL
    Call B$STDL              ;and go delete it

Exit:
    Ret                      ;return to caller

P$FreeTemp Endp
End
