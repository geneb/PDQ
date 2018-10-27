;********** COMPACT.ASM - P.D.Q. routine for string pool "garbage collection"

;Copyright (c) 1989 Ethan Winer

Comment |

The P$DirtyFlag variable below tells if any strings have been deleted since
the last time P$Compact was called.  When P$TempStr is called to make fresh
string memory available, it first looks to see if there is currently enough
to satisfy the requested number of bytes.  If there is, it simply returns a
pointer to where that memory starts.  If not, it calls P$Compact to squash
all of the valid string data downward and then checks again.  Now, here's
where the P$DirtyFlag enters the picture.

If no strings have been deleted since the last time P$Compact was called,
then attempting to compact string space is a waste of time.  Compact clears
P$DirtyFlag each time it cleans up the string pool, and B$STDL sets it to
show that a string has been deleted and a pool compaction would in fact be
beneficial.  Further, starting with P.D.Q. version 2.00 this flag holds the
address of the string lowest in memory that has been deleted.  This way,
P$Compact can quickly skip past the valid data at the bottom of the pool.

Added 10-14-91: After a string is moved P$Compact needs to see if the string
is part of a FIELD file buffer.  But the code to check every string's address
against up to 320 entries in each of 15 tables (P.D.Q. allows as many as 15
files open at once) would slow down the compaction process unacceptably.  To
solve this a method we'll call "soft linking" is used to execute that code
only if FIELD is in use.  By default, a call is made to an empty Ret (return)
instruction that is located in this source file.  This call is made using the
contents of P$FldAddress, which is a two-word variable in the data segment.

If a program has not used the FIELD statement this variable holds its initial
value of the segmented address of the DirtyExit label.  Thus, the code that
is called returns immediately without doing anything.  But when FIELD is used
code in FIELD.ASM replaces the contents of P$FldAddress with the address of a
routine that handles moving the FIELD buffers.  This soft linking therefore
prevents the FIELD code from being added to programs that do not use FIELD,
and also prevents garbage collection from being slowed down when FIELD is not
used.

Also see the comments in the ASSIGN$.ASM source file.

|

.Model Medium, Basic
    Public P$FldAddress     ;so FIELD.ASM can get at it
    
.Data?
    Extrn P$StrPool:Byte    ;this is in STR#####.ASM

.Data
    P$FldAddress DW Offset DirtyExit, Seg P$Compact ;address/segment of Ret
    
    Extrn P$BytesFree :Word ;these are also in STR#####.ASM
    Extrn P$BytesUsed :Word
    Extrn P$DirtyFlag :Word ;this is in PDQDATA.ASM, and it's non-zero if a
                            ;  garbage collection would be beneficial
.Code

P$Compact Proc 

    Cmp  P$DirtyFlag,0      ;will a compaction actually do anything?
    Je   DirtyExit          ;no, so skip this mess

    Cld                     ;ensure that all moves are forward
    Push DS                 ;copy DS into ES for the string moves below
    Pop  ES

    Push BX                 ;Push registers manually (rather than with Uses)
    Push CX                 ;  so we can get out as quickly as possible if
    Push DX                 ;  the "dirty flag" (tested above) indicates that
    Push SI                 ;  a compaction is not needed.
    Push DI
    Push BP

    Mov  DX,Offset P$StrPool ;point DX to the start of the string pool
    Add  DX,P$BytesUsed      ;now DX holds the last valid string pool address

    Mov  SI,P$DirtyFlag   ;point SI to the lowest string that's been deleted
    Dec  SI               ;bump it down to that string's back pointer
    Dec  SI               ;  (two Dec's is faster/less code than Sub SI,2)
    Mov  DI,SI            ;this is our destination address for string moves
    Xor  BP,BP            ;clear the address adjustment accumulator

    Even                  ;align for better performance on 80286 or better
Walk:                     ;walk through the string pool
    Cmp  SI,DX            ;have we reached the end yet?
    Jae  Exit             ;yes, so we're all done
    Mov  BX,[SI]          ;no, get this data's back pointer
    Test BL,1             ;is this an abandoned string?
    Jz   MoveIt           ;no, go copy the data downward in memory

    Shr  BX,1             ;yes, convert the back pointer into the data length
    Inc  BX               ;consider the current back pointer itself 
    Inc  BX               ;since that occupies pool memory too
    Add  SI,BX            ;now SI points to the next higher back pointer
    Add  BP,BX            ;track how many bytes to lower subsequent addresses
    Add  P$BytesFree,BX   ;show that many more bytes free in the string pool
    Sub  P$BytesUsed,BX   ;and that many fewer in use
    Jmp  Short Walk       ;keep searching

    Even                  ;align for better performance on 80286 or better
MoveIt:
    Mov  CX,[BX]          ;this is valid data, get the length from the descr.
    Inc  CX               ;include the two extra bytes for the back pointer
    Inc  CX
    Rep  Movsb            ;slide this string down to lower memory
    Sub  [BX+02],BP       ;adjust its descriptor address downward as required
    Call DWord Ptr P$FldAddress ;handle an active FIELD statement if needed
    Jmp  Short Walk             ;keep plowing through this mess until done

Exit:
    Mov  P$DirtyFlag,0    ;show that the string pool is now "clean"
    Pop  BP               ;retrieve all of the saved registers
    Pop  DI
    Pop  SI
    Pop  DX
    Pop  CX
    Pop  BX

    Even                  ;align for better performance on 80286 or better
DirtyExit:
    Ret                   ;return to caller

P$Compact Endp
End
