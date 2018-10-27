;********** UBOUND.ASM - PDQ replacements for BASIC's B$UBND and B$LBND

;Copyright (c) 1989 Ethan Winer


;These routines rely on information contained in the BASIC array descriptor.
;An array descriptor contains information about the array, such as its size
;and type, starting segment and address, and so forth.  When a subroutine is
;called with an array argument and the array is given with empty parentheses,
;the descriptor address is passed instead of the address of one of the array
;elements.  The information contained herein is not documented by Microsoft,
;mostly because it is subject to change at any time.  The table below shows
;the structure of an array descriptor, and it was graciously provided to us
;by Jim Mack.
;
;Notice the Adjusted Offset entry in the array descriptor below.  Even though
;the segmented address where the array data begins is the first entry in the
;descriptor, it is valid only when the first element number in the array is
;zero (DIM Array(0 TO n)).  To achieve the fastest performance possible when
;retrieving or assigning a given element, the Adjusted Offset is calculated
;at DIM time to compensate for an LBOUND other than 0.  For example, when an
;integer array is dimensioned starting at element 1, the Adjusted Offset is
;set to point two bytes before the actual starting address of the data.  This
;way, the compiler can take the specified element number, multiply that times
;two (each element comprises two bytes), and then add that to the Adjusted
;Offset to immediately point at the correct element in memory.  Otherwise,
;additional code would be needed to subtract the LBOUND value each time the
;array is accessed.  Since the array's LBOUND is simply constant information,
;it would be wasteful to calculate that repeatedly at run time.  Also notice
;that the Adjusted Offset calculation is correspondingly more complex when
;dealing with multi-dimensional arrays.
;
; Offset    Size          Description
; ======   ======   ========================================================
;   00       04     Segmented address where the array data begins in memory.
;   04       02     Far Heap Descriptor.  In regular QuickBASIC this holds
;                   the address of the next (subsequent) Far Heap Descriptor.
;                   This is not used in P.D.Q.
;   06       02     p/o the FHD above, the number of data bytes in the array.
;                   For dynamic string arrays it is the total number of bytes
;                   occupied by all of the string descriptors using 4 bytes
;                   per element.  For huge arrays it is instead the number of
;                   16-byte paragraphs.  Paragraphs are used when the program
;                   is compiled using /ah, regardless of whether the array
;                   size actually exceeds 64K.
;   08       01     The number of dimensions in the array.
;   09       01     The array type and storage method as follows:
;                       Bit 0 set means it's a far (non-DGROUP) array.
;                       Bit 1 set means it's a huge (/ah) array.
;                       Bit 6 set means it's a STATIC array.
;                       Bit 7 set means it's a string array.
;   0A       02     Adjusted Offset (folded subscript-constant information).
;   0C       02     Length in bytes of each array element.
;   0E       02     Number of elements in the LAST subscript.  (UB - LB + 1)
;   10       02     Number of the first element in that subscript (LBOUND).
;   12       02     Number of elements in the SECOND FROM LAST subscript.
;   14       02     Number of the first array element in that subscript.
;    .       02     Repeat as necessary,
;    .       02     until the FIRST subscript is reached.
;
;Also see the comments in the DIM.ASM source file.


.Model Medium, Basic
.Code

B$LBND Proc               ;this is the entry point for LBOUND
    Xor  CX,CX            ;clear CX to flag that this is LBOUND, not UBOUND
    Db   3Dh              ;this fakes the Mov CX,SP below to a bogus compare
B$LBND Endp


B$UBND Proc               ;this is the entry point for UBOUND
   Mov  CX,SP             ;force CX to non-zero (SP can't possibly be zero)
B$UBND Endp               ;in either case, fall into the code below


B$BothBound Proc, Array:Word, Subscript:Word    ;this handles both BOUNDs

    Mov  BX,Array         ;get the address for the incoming array descriptor
    Mov  DX,Subscript     ;and the value of the subscript they want info on
    Sub  DL,[BX+08]       ;subtract from that the number of array dimensions
    Neg  DL               ;revert to a positive value
    Shl  DX,1             ;times four to get the offset into that subscript
    Shl  DX,1
    Add  BX,DX            ;now BX points to the correct subscript information
    Mov  AX,[BX+10h]      ;get the first element number
    Jcxz Exit             ;if CX is zero then they wanted the LBOUND, so exit
    Add  AX,[BX+0Eh]      ;they want the UBOUND, add the number of elements
    Dec  AX               ;less 1 since UBOUND = LBOUND + NumberOfElements - 1

Exit:
    Ret                   ;return to BASIC

B$BothBound Endp
End
