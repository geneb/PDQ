;******** PDQPWIDE.ASM - screen width data for use by PDQPrint and PDQCPrint

;Copyright (c) 1990 Ethan Winer


.Model Medium, Basic
    Public P$PrintWidth
    
.Data
    P$PrintWidth DW 160     ;default to an 80-column screen width, use a
                            ;  full word to handle 132 columns (264 bytes)
End
