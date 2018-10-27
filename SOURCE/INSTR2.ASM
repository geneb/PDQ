;********** INSTR2.ASM - PDQ replacement for BASIC's B$INS2 routine

;Copyright (c) 1989 Ethan Winer

;This is called when you use INSTR with two arguments:
;
;   X = INSTR(Source$, Search$)


.Model Medium, Basic
    Extrn B$INS3:Proc     ;this is in INSTR.ASM
    
.Code

B$INS2 Proc, Source:Word, Search:Word

    Mov  AX,1             ;make a 1 to start at the beginning
    Push AX
    Push Source           ;pass the remaining parameters on to B$INS3
    Push Search
    Call Far Ptr B$INS3   ;let B$INS3 do the tough stuff
    Ret                   ;return to BASIC

B$INS2 Endp
End
