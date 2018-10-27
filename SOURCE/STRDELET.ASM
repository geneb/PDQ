;********* STRDELET.ASM - deletes a string

;Copyright (c) 1989 Ethan Winer

;This routine is called after a temporary string is no longer needed, or an
;existing string has been reassigned.  B$STDL clears the length portion of
;the descriptor to zero, and also marks the string's data as abandoned by
;manipulating the back pointer.  See the file ASSIGN$.ASM for a discussion of
;how this works.  Also see COMPACT.ASM for a discussion of the P$DirtyFlag
;variable that is used below.
;
;NOTE: FIELD.ASM counts on B$STDL returning BX set to the descriptor address.

.Model Medium, Basic
.Data
    Extrn P$DirtyFlag:Word ;this is in PDQDATA.ASM

.Code

STRINGRELEASE Proc         ;this is the same proc, but using the BASIC 7 name
    Nop                    ;this forces CodeView to show the correct name
STRINGRELEASE Endp


B$STDL Proc                ;, Descriptor:Word (this is what's passed to us)

    Mov  BX,SP             ;this is more efficient than the Proc mechanism
    Mov  BX,[BX+04]        ;get the string descriptor address from the stack
    Mov  AX,[BX]           ;then get the string's length
    Or   AX,AX             ;is it already a null string?
    Jz   Exit              ;yes, so we don't have to do anything

    Push SI                ;no, save SI before we trash it below
    Mov  SI,[BX+02]        ;get the address of the string data to abandon
    Cmp  P$DirtyFlag,0     ;have any strings been deleted lately?
    Je   SetDirty          ;no, set the dirty flag to point here
    Cmp  SI,P$DirtyFlag    ;yes, but is this string past the last one?
    Ja   Delete            ;yes, leave P$DirtyFlag where it is

SetDirty:
    Mov  P$DirtyFlag,SI    ;no, the next compaction should start at this
                           ;  string's address
Delete:
    Stc                    ;set the LSB (illegal as a back-pointer address)
    Rcl  AX,1              ;while saving the length in the upper 15 bits
    Mov  [SI-02],AX        ;put the fake length in the back pointer as a flag
    Mov  Word Ptr [BX],0   ;and clear the original length to zero
    Pop  SI                ;retrieve SI

Exit:
    Retf 2                 ;return to caller

B$STDL Endp
End
