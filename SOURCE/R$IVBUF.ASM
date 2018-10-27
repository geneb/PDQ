;======================================================================
; R$IVBUF.ASM
;  Copyright (c) 1991 Crescent Software
;  Copyright (c) 1991 Schaefer Software, by Robert L. Hummel
;----------------------------------------------------------------------
; 11/15/91  .000    Split from R$SWAP.ASM
;----------------------------------------------------------------------
;
;By default this file creates a swap buffer of only 1K in size, to
;minimize the size of the resident kernel.  To create a 4K buffer
;assemble this file using the MASM /d switch as follows:
;
;   masm r$ivbuf /dswap4k , _swap4k ;
;
;This creates a new stub file named _SWAP4K.OBJ that provides a 4K
;swap buffer.  A 4K buffer increases the resident size by 3K, but in
;exchange it speeds up disk swapping by a factor of five or more.
;
;Also see the comments in R$PDQ.EQU for more about the relationship between
;the various equate constants and data items defined here.


PUBLIC R$IVBUF
PUBLIC R$SWAPLEN

RLHSEG SEGMENT PARA PUBLIC 'RLH_CODE'
IFDEF SWAP4K
  R$BUFLEN EQU 4 * 400H ;use a 4K buffer if /D SWAP4K was used
ELSE
  R$BUFLEN EQU 400H     ;else use the 1K default
ENDIF
  R$SWAPLEN DW R$BUFLEN / 16
  R$IVBUF DD R$BUFLEN / 16 DUP (65626F52H, 4C207472H, 7548202EH, 6C656D6DH)
RLHSEG ENDS


RHSEG SEGMENT PUBLIC 'RH_CODE'
RHSEG ENDS
END
