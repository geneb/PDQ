;********* ABSOLUTE.ASM - PDQ replacement for BASIC's CALL ABSOLUTE routine

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
.Data
    Extrn B$Seg: Word       ;this is in PDQDATA.ASM

.Code

Absolute Proc

    Pop  AX                 ;get the return address for the BASIC program
    Pop  DX                 ;and the caller's return segment too
    Pop  BX                 ;this holds the address of the address to call
    Push DX                 ;show the callee the segment to return to
    Push AX                 ;and the return address
    Push B$Seg              ;we're calling the segment defined by DEF SEG
    Push [BX]               ;and the address pointed to by BX
    Ret                     ;jump to the routine via a Ret, leaving the BASIC
                            ;  return address and parameters on the stack
Absolute Endp
End
