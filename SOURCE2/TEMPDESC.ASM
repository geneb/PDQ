;********* TEMPDESC.ASM - table of 20 temporary string descriptors

;Copyright (c) 1989 Ethan Winer


.Model Medium, Basic
    Public P$TempDesc           ;the temporary string descriptors

.Data
    Even                        ;all string descriptors MUST be word aligned
    P$TempDesc DD 20 Dup(0)     ;this is 20 temporary string descriptors

.Code

End
