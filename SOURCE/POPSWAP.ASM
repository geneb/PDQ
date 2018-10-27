;======================================================================
; POPSWAP.ASM
;   Copyright (c) 1991 Crescent Software
;   Copyright (c) 1991 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 1. This object file must appear first on the link line.
;----------------------------------------------------------------------
; 9/18/91   .000    Makes DOSSEG ordering put this first.
;                   Satisfies pseudo-error message.
; 9/24/91   .001    Add vector table, RHSEG.
; 10/10/91  .002    Add R$PROGID data.
; 10/13/91  .003    Move data to R$SWAP.ASM.
;======================================================================
PUBLIC  YOU_MUST_LINK_POPSWAP_FIRST

;======================================================================
; This segment is forced to be loaded directly after the PSP.
;----------------------------------------------------------------------
RLHSEG      SEGMENT PARA    PUBLIC  'RLH_CODE'
    YOU_MUST_LINK_POPSWAP_FIRST EQU 0
RLHSEG      ENDS

;======================================================================
; This segment is forced to be second.
;----------------------------------------------------------------------
RHSEG       SEGMENT PARA    PUBLIC  'RH_CODE'
RHSEG       ENDS

        END
