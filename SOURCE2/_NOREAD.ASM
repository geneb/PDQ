; _NOREAD.ASM
;----------------------------------------------------------------------
; Copyright (c) 1989,1990 Crescent Software
; Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; This "stub" file is used to turn off the automatic inclusion of the
;  READ/DATA functions in PDQ files.
;----------------------------------------------------------------------
; 3/18/90       .000    Evolved from ENABLERD.ASM.
;----------------------------------------------------------------------
PUBLIC      ENABLEREAD

;======================================================================
; Code segment.
;----------------------------------------------------------------------
CSEG        SEGMENT WORD    PUBLIC  'CODE'
        ASSUME  CS:CSEG

;======================================================================
; EnableRead
;   Copyright (c) 1989,1990 Crescent Software
;   Copyright (c) 1989,1990 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; Used, here, to disable the use of READ/DATA by turning the default
;  EnableRead proc into a NOP.
;----------------------------------------------------------------------
ENABLEREAD  PROC    FAR
        ASSUME  CS:CSEG

            RET     

ENABLEREAD  ENDP

CSEG        ENDS
            END

