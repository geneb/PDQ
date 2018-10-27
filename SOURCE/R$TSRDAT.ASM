; R$TSRDAT.ASM - TSR data
;
;  Copyright (c) 1989-1991 Crescent Software
;  Copyright (c) 1989-1991 Schaefer Software, by Robert L. Hummel


;----------------------------------------------------------------------
; Referenced in TSRINST.ASM, DEINSTAL.ASM, ENDTSR.ASM, and R$CORE.ASM
;----------------------------------------------------------------------
PUBLIC  R$DGROUP
PUBLIC  R$ID

;======================================================================
; DSEG is initialized data and part of DGROUP.
;----------------------------------------------------------------------
DGROUP          GROUP       DSEG
DSEG            SEGMENT     WORD    PUBLIC  'DATA'
DSEG            ENDS


RLHSEG          SEGMENT     PARA    PUBLIC  'RLH_CODE'
        ASSUME  CS:RLHSEG
        
        EVEN

R$ID            DB      16 DUP(0)   ;Holds the ID string
R$DGROUP        DW      DGROUP      ;DGROUP segment of this copy

RLHSEG          ENDS
                END
