;********** FIELD.ASM - P.D.Q. replacements for BASIC's B$FLDP and B$FIEL

;Copyright (c) 1991 Ethan Winer


Comment |

PROGRAMMING NOTES:

    þ When B$STDL is called this routine takes advantage of the fact that
      BX is returned holding the descriptor address of the deleted string.
      A note to that effect is now in B$STDL to prevent future surprises.

    þ P$FldDesc is a table of 15 string descriptors kept in FIELD2.ASM.
      The entries in P$FldDesc are string descriptors that identify the
      actual FIELD buffers which are stored in the string pool.  Fifteen
      entries are provided--one for each possible open random access file.
      Each entry comprises four bytes.

    þ P$FldSegs is a table of far memory segments, and this table is defined
      in FIELD2.ASM.  Each time a file is newly fielded, far (DOS) memory is
      claimed to hold a table of up to 320 string descriptor addresses.  Once
      a string has been assigned to a FIELD buffer, it may not be deleted by
      the normal means.  Therefore, code in this file and in FIELD2.ASM must
      scan that table to know which strings are currently fielded, and thus
      must be deleted directly rather than with the B$STDL routine.  Each of
      the entries is an integer word (two bytes).

      Up to 15 far memory segments may be claimed, and each holds a table of
      up to 320 string descriptor addresses.  When P$CloseField in FIELD2.ASM
      is called by CLOSE or RESET, each descriptor address is retrieved in
      turn, and the length portion of the string descriptor at that address
      is forced to zero.  Then the segment holding the table of descriptor
      addresses is released back to DOS, and finally the FIELD buffer itself
      is freed with a call to B$STDL.

    þ If the P$FldDesc and P$FldSegs tables were kept in this file, programs
      that use CLOSE would drag in both the tables and the code in this file.
      By storing them externally, the tables and the code in FIELD2.ASM can
      be stubbed out using the _NOFIELD.OBJ stub file.

    þ The CurPointer table tracks where within the FIELD buffer the next
      string is to be placed.  Each entry is two bytes in length.


MORE NOTES:

    When FIELD is used BASIC creates a sequence of separate calls.  The first
    call is to B$FLDP (Field Prepare) and it simply registers the file number
    that subsequent calls to B$FIEL will operate on.  Then, for each variable
    that is listed a call is made to B$FIEL.  Two parameters are passed in
    each call to B$FIEL: the length and the string's descriptor address.

    Given that no other FIELD statements are active for any other files,
    consider the following statements:

        OPEN FileName$ FOR RANDOM AS #2 LEN = 45
        FIELD #2, 10 AS A$, 15 AS B$, 20 AS C$

    These statements set up the variables and tables in memory like this:

        CurNumber  ->  2
        CurPointer ->  0  x  0  0  0  0  0  0  0  0  0  0  0  0  0
        P$FldDesc  ->  0  x  0  0  0  0  0  0  0  0  0  0  0  0  0
        P$FldSegs  ->  0  x  0  0  0  0  0  0  0  0  0  0  0  0  0
        SPACE$(45) ->  AAAAAAAAAABBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCC
        ES:[0]     ->  descriptor addresses for A$, B$, and then C$

    When the initial call to B$FLDP is made B$FLDP sets CurNumber to 2, so
    subsequent items in the FIELD list will be associated with the correct
    file.  B$FLDP also sets CurPointer(2) to zero; as items are added with
    subsequent calls to B$FIEL this pointer is incremented to reflect the
    current position in the buffer.  When B$FIEL is called with the address
    of A$ and a length of 10, CurPointer(2) is set to 9 (most of the entries
    in these tables are zero-based).  After the second call passing B$ and
    its length of 15 CurPointer(2) holds 24, and after the third call with
    C$ and the length 20 CurPointer(2) holds 44.

    The actual FIELD buffer is created by calling BASIC's STRING$ routine.
    The temporary string that is returned is then assigned permanently to
    the descriptor at P$FldDesc(2).  Again, (2) indicates that P$FldDesc,
    like CurPointer, is an array with one element for each of P.D.Q.'s 15
    possible open files.  Although only one buffer string is shown in the
    table above, as many as 15 buffers may be active at one time.

    The P$FldSegs array holds a table of far memory segments.  As each new
    string is added to the list, its descriptor address is saved in this far
    memory segment.  Since up to 320 different strings can be used for each
    of the 15 files, using far memory potentially saves 320 * 15 * 2 = 9600
    bytes of near DGROUP memory.

    In each far segment is a table of addresses for all of the string
    descriptors associated with this FIELD buffer.  B$FIEL needs to know
    which strings are already in the buffer so it can handle the same string
    being used in more than one FIELD statement (but only with the same file
    number).  Why does this matter?  Because the fielded strings must be null
    before they are added to the buffer.  But a different method is needed to
    erase strings if they are currently fielded as opposed to conventionally
    assigned.

    When B$FIEL is adding a new string to a FIELD buffer, it gets the far
    segment associated with that file from P$FldSegs(2).  Once the segment
    is known it is placed in the ES register whenever the segment needs to
    be accessed.  As each new string is added to the list, code in B$FIEL
    searches the table to see if the string is already in the buffer.  If not
    it is added to the next available location.  This is necessary because
    code like the following is commonly used to field a file with a string
    array and a parallel array of lengths:

        Pad = 0
        FOR X = 1 TO NumFields
          ThisLength = Lengths(X)
          FIELD #1, Pad AS Dummy$, ThisLength AS Buffer$(X)
          Pad = Pad + ThisLength
        NEXT

    In this case Dummy$ is used repeatedly with the same FIELD statement,
    and B$FIEL must be able to handle it correctly.


YET MORE NOTES:

    The P$FldCompact routine is actually part of the garbage collection (heap
    compaction) process.  When the string pool is compacted string data is
    moved in memory, copying currently active strings on top of the abandoned
    strings no longer in use.  But strings that point into a FIELD buffer do
    not employ the usual back-pointer mechanism.  P$FldCompact is added only
    to programs that actually use FIELD, and the code in P$FldCompact handles
    compacting the FIELD file buffers.

    Also see the comments in COMPACT.ASM for a brief discussion of the "soft
    linking" technique used here to avoid adding the field compaction code to
    programs that do not use FIELD.

End Comment |


.Model Medium, Basic
    Extrn B$SASS:Proc       ;this is in ASSIGN$.ASM
    Extrn B$STDL:Proc       ;this is in STRDELET.ASM
    Extrn B$STRI:Proc       ;this is in STRING$.ASM
    Extrn P$DoError:Proc    ;this is in DOERROR.ASM

    MaxDesc Equ 320         ;the maximum descriptors for each FIELD buffer
                            ;note that MaxDesc is also defined in FIELD2.ASM
                            ;MaxDesc must be evenly divisible by 16
.Data
    Extrn P$FldAddress:Word ;this is in COMPACT.ASM
    Extrn P$PDQErr:Word     ;this is in ERRDATA.ASM
    Extrn P$RecordTbl:Word  ;this is in FHANDLES.ASM
    Extrn P$FldDesc:Word    ;this is in FIELD2.ASM
    Extrn P$FldSegs:Word    ;this is in FIELD2.ASM

    CurNumber  DW 0         ;remembers the BASIC file number, the data is
                            ;  zero-based and times 2 (file 7 is 6 * 2 = 12)
                            
    CurPointer DW 15 Dup(0) ;tracks where FIELD is adding items, each entry
                            ;  tracks one BASIC file number, the data is
                            ;  zero-based (0 points to the first position)
.Code

B$FLDP Proc Uses SI, FileNum:Word  ;this is called to prepare for a new FIELD

    Xor  AX,AX              ;first clear ERR
    Mov  P$PDQErr,AX

    Mov  AL,6               ;assume a "Bad file number" error (AH is known 0)
    Mov  BX,FileNum         ;get the file number we're fielding
    Dec  BX                 ;make it zero-based for indexing the record table
    Js   ErrExit            ;it was zero or impossibly high, report the error
    Cmp  BX,14              ;not zero, but is it greater than 15 (0-based)?
    Ja   ErrExit            ;yes, and that's no good either

    Mov  AL,54              ;assume a "Bad file mode" error
    Shl  BX,1               ;times two because the table is words
    Mov  AX,P$RecordTbl[BX] ;load AX with the file's record length
    Or   AX,AX              ;has a record length been registered?
    Jz   ErrExit            ;no, so again this is an error

    Mov  P$FldAddress,Offset P$FldCompact ;set P$Compact to call P$FldCompact
    Mov  P$FldAddress+2,Seg P$FldCompact  ; so strings in a FIELD buffer will
                                          ; be handled correctly

    Mov  SI,BX              ;copy BX to SI for 4-word addressing of P$FldDesc
    Shl  SI,1               ;times two because each descriptor is four bytes
    Cmp  P$FldDesc[SI],0    ;is this the first call to FIELD for this file?
    Jne  @F                 ;no, skip the initialization stuff
    Push BX                 ;yes, save the zero/word-based BASIC file number

    Push AX                 ;tell STRING$ how long the buffer is to be
    Mov  AX,32              ;and specify a string of CHR$(32) blank spaces
    Push AX
    Call B$STRI             ;STRING$ returns a descriptor address in AX

    Add  SI,Offset P$FldDesc;now BX points to the correct descriptor
    Push AX                 ;pass the result from STRING$ on to B$SASS
    Push SI                 ;assign the spaces permanently to the local copy
    Call B$SASS

    Mov  BX,(MaxDesc * 2) / 16  ;the number of 16-byte paragraphs needed
    Mov  AH,48h             ;service 48h claims DOS memory
    Int  21h                ;call DOS to do the real work
    Pop  BX                 ;retrieve the zero/word-based BASIC file number
    Jnc  GoodAlloc          ;no error allocating DOS memory
    Mov  AX,7               ;oops, register Error 7, "Out of memory"
    Jmp  Short ErrExit      ;  and get out

GoodAlloc:
    Mov  ES,AX              ;no error, save the segment we got in ES
    Mov  P$FldSegs[BX],AX   ;and in the segment table too
    
    Xor  AX,AX              ;clear the memory we just claimed to all zeros
    Mov  DI,AX              ;DOS segments always start at address zero
    Mov  CX,MaxDesc         ;clear room for the 2-byte descriptor addresses
    Cld                     ;clear in the forward direction
    Rep  Stosw              ;clear CX number of words

@@:
    Mov  CurPointer[BX],0   ;clear the pointer for later use by B$FIEL (CX=0)
    Mov  CurNumber,BX       ;and save the data pointer for later

Exit:
    Ret                     ;return to BASIC

ErrExit:
    Call P$DoError          ;handle the error as needed
    Jmp  Short Exit         ;and exit now

B$FLDP Endp




B$FIEL Proc Uses SI DI, StringLen:Word, String:Word

    Mov  SI,CurNumber       ;get the BASIC file number we're now processing,
                            ;  which is already set up as a table offset

    Mov  BX,String          ;get the string's descriptor address
    Cmp  Word Ptr [BX],0    ;is it now null?
    Je   FieldIt            ;yes, skip ahead and add it to the FIELD buffer

    Mov  AX,[BX+02]         ;no, get the data address for the string
    Mov  DI,SI              ;copy SI to DI for 4-word addressing of P$FldDesc
    Shl  DI,1               ;times 2 because each descriptor is four bytes
    Mov  DX,P$FldDesc[DI+2] ;get this FIELD buffer's data address
    Cmp  AX,DX              ;is this string's data below the FIELD buffer?
    Jb   @F                 ;yes, so it can't be in the buffer now

    Add  DX,P$FldDesc[DI]   ;add the FIELD buffer's length
    Cmp  AX,DX              ;is the data above the FIELD buffer?
    Jae  @F                 ;yes, so it can't be in the buffer either

   ;this next line is not really necessary and is shown for clarity only
   ;Mov  Word Ptr [BX],0    ;this string is in the buffer, clear it manually
    Jmp  Short FieldIt      ;then skip over the call to B$STDL

@@:
    Push BX                 ;pass the string's descriptor address on
    Call B$STDL             ;and delete it the usual way before adding
                            ;  it to the FIELD buffer

FieldIt:
    Mov  ES,P$FldSegs[SI]   ;now ES holds the far memory segment

    Mov  AX,BX              ;see if this descriptor address is already known
    Xor  DI,DI              ;start searching at address zero
    Cld                     ;search forward
    Mov  CX,MaxDesc         ;search up to MaxDesc words
    Repne Scasw             ;do the search
    Jz   @F                 ;we already have this one in the list, skip over
    
    Xor  AX,AX              ;not found, find next available slot and add it
    Mov  DI,AX              ;start at address zero
    Mov  CX,MaxDesc
    Repne Scasw             ;do the search, DI ends up one -past- the entryÄ¿
    Jnz  Overflow           ;zero not found, all of the entries are filled! ³
    Mov  ES:[DI-02],BX      ;add this descriptor address to the table       ³
         ;      ÀÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
@@:
    Mov  AX,StringLen       ;get the new string length (Length AS ....)
    Mov  [BX],AX            ;and force the string to that length

    Mov  DI,SI              ;copy SI to DI for 4-word addressing of P$FldDesc
    Shl  DI,1               ;times 2 because each descriptor is four bytes
    Mov  DX,P$FldDesc[DI+2] ;get this FIELD buffer's data address
    Add  DX,CurPointer[SI]  ;bump to where -this- string starts
    Mov  [BX+02],DX         ;assign the string's new address
    Add  CurPointer[SI],AX  ;and this is the new FIELD buffer pointer

    Mov  AX,CurPointer[SI]  ;check for a "FIELD overflow" error
    Cmp  AX,P$FldDesc[DI]   ;is CurPointer greater than LEN(FieldBuffer$)?
    Jna  @F                 ;no so we're okay

OverFlow:
    Mov  AX,50              ;yes, create the appropriate error number

ErrExit:
    Call P$DoError          ;and register it
    
@@:
    Ret                     ;return to BASIC

B$FIEL Endp



P$FldCompact Proc               ;compact a string in use as a FIELD buffer
;
;-- This procedure enters with the descriptor address in BX, and the number
;   of bytes the string has already been adjusted downward by in BP.

    Cmp  BX,Offset P$FldDesc    ;is this string's descriptor below the table?
    Jb   Exit                   ;yes, so it can't be a FIELD buffer
    Cmp  BX,Offset P$FldDesc + 14 * 4   ;is it above the table?
    Ja   Exit                           ;yes, so it can't be there either

    Push BX                     ;save the registers we'll be using
    Push CX
    Push SI
    Push ES
    
    Sub  BX,Offset P$FldDesc    ;now BX holds (file number - 1) * 4
    Shr  BX,1                   ;find the corresponding descriptors segment
    Mov  ES,P$FldSegs[BX]       ;load that segment into ES

    ;-- Walk through the FIELD buffer descriptors for this file and adjust
    ;   their data to the new, lower address in the string pool.
    ;
    Sub  SI,SI                  ;start at the first descriptor in the list
    Mov  CX,MaxDesc             ;search up to 320 table entries
    
@@:
    Mov  BX,ES:[SI]             ;get this descriptor address
    Or   BX,BX                  ;are we all done?
    Jz   Done                   ;yes, leave
    Sub  Word Ptr [BX+02],BP    ;no, show that the data is at a lower address
    Inc  SI                     ;point to the next descriptor
    Inc  SI                     ;(two Inc's is better than Add SI,2)
    Loop @B                     ;and keep on checking

Done:
    Pop  ES                     ;restore the registers we used
    Pop  SI
    Pop  CX
    Pop  BX
    
Exit:
    Ret                         ;return to P$Compact

P$FldCompact Endp
End
