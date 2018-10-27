;********* GETTEMP.ASM - returns the next available temporary descriptor

;Copyright (c) 1989 Ethan Winer


;This routine retrieves the next available temporary descriptor using a
;"round-robin" approach.  The code that is commented out checks to ensure
;that the next available temporary string descriptor is in fact available.
;To the best of my knowledge, the next available descriptor will *always* be
;available.  BC will not create a situation where more than 20 temporary
;strings are active at one time.

.Model Medium, Basic
.Data
    NextUp DW 0                 ;this remembers the next available descriptor
    Extrn P$PDQErr:Word         ;this is in ERRORDAT.ASM
    Extrn P$TempDesc:Word       ;this is in TEMPDESC.ASM

.Code

P$GetTemp Proc

    Mov  AX,NextUp              ;get the next available descriptor number
    Mov  BX,Offset P$TempDesc   ;point at the first temporary descriptor
    Add  BX,AX                  ;now BX points at the next one that's free

;   Cmp  Word Ptr [BX],0        ;it *is* available, isn't it?
;   Je   GoodTemp               ;yes, continue
;   Mov  Byte Ptr P$PDQErr,16   ;assign a "String formula too complex" error

GoodTemp:
    Add  AL,4                   ;point to the next descriptor in the table
    Cmp  AL,80                  ;did we go past the end?
    Jb   Exit                   ;no, this is the next available descriptor
    Xor  AX,AX                  ;yes, reset the next one to be the first one

Exit:
    Mov  NextUp,AX              ;replace NextUp with the correct value
    Ret                         ;return to caller with BX holding the address

P$GetTemp Endp
End
