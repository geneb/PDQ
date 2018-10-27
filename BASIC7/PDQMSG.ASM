;********** PDQMSG.ASM - returns text for a DOS error message

;Copyright (c) 1989 Ethan Winer
;BC7 conversion 3/90 J. Munro

;syntax - Message$ = PDQMessage$(ErrNum)
;
;where ErrMsg$ receives "File not found", "Path/File Access error", etc.
;
;NOTE: We are using ERROR 127 as "RETURN without GOSUB", to avoid yet another
;error number that is less than 6 (which conflicts with DOS error numbers).
;Also, "Out of stack space" doesn't have a number, so we've given it a value
;of 126.
;
;See ERRDATA.ASM for more information on error number substitutions in P.D.Q.


.Model Medium, Basic
    Extrn StringAssign:Proc  ;this is an internal BASIC 7 routine
    
.Data?
    DescrLen DW  1 Dup (?)   ;this is the output descriptor
    DescrAdr DW  1 Dup (?)
    Output   DB 25 Dup (?)   ;25 is the length of the longest message

.Code

PDQMessage Proc Uses SI DI ES, ErrNum:Ptr

    Mov  SI,ErrNum           ;get the address for ErrNum
    Mov  AX,[SI]             ;put it into AX
    Cmp  AX,127              ;is it an illegal value?
    Jbe  GoodError           ;no, continue
    Mov  AL,127              ;yes, so let it default to "Undefined error"
                             ;  by forcing a "not found" condition
GoodError:
    Neg  AL                  ;make a negative version to search the table

    Mov  CX,Offset EndTable - Offset ErrName   ;how many bytes to search
    Push CS                  ;set ES=CS for searching
    Pop  ES
    Mov  DI,Offset ErrName   ;point DI to the start of the table
    Repne Scasb              ;search for the negative error number
    Mov  SI,DI               ;point SI to the length word in the table

    Push DS                  ;set ES=DS and DS=CS to copy string into DGROUP
    Push CS
    Pop  DS
    Pop  ES

    Lodsb                    ;load the length of the message
    Cbw                      ;convert it to a word
    Mov  CX,AX               ;copy it into CX for moving the string later
    Mov  DI,Offset Output    ;get the output address
    Push ES                  ;push the segment, offset and length of string
    Push DI                  ;  while we have the info
    Push CX                  ;assign the length portion of the descriptor
    Rep  Movsb               ;copy the string there
    Mov  AX,Offset DescrLen
    Push ES                  ;push destination seg:offset, and 0 for length
    Push AX
    Push CX
    Push ES
    Pop  DS                  ;retrieve DS for StringAssign to operate
    Call StringAssign        ;assign the guy already!

Exit:
    Mov  AX,Offset DescrLen  ;show BASIC where the descriptor is located
    Ret                      ;return to BASIC

PDQMessage Endp

;This table may be freely edited to modify the messages, strip out those you
;don't need, or to add new ones.  The first entry in each line below is the
;message number, and the second is the message length.  Notice that we are
;storing the error number as a negative value to facilitate searching for the
;start of a given message.  The only restrictions are that the message number
;must range between 1 and 127, and no message may be longer than the maximum
;length stated by the Output DB value in the .Data? section above.  Also, you
;must not use any high-order ASCII characters (CHR$() values above 127).

    ErrName DB   -4, 11, "Out of data"
            DB   -5, 21, "Illegal function call"
            DB   -7, 13, "Out of memory"
            DB   -9, 22, "Subscript out of range"
            DB  -14, 19, "Out of string space"
            DB  -16, 26, "String formula too complex"
            DB  -52, 15, "Bad file number"
            DB  -53, 14, "File not found"
            DB  -54, 13, "Bad file mode"
            DB  -55, 17, "File already open"
            DB  -61, 12, "Disk is full"
            DB  -62, 14, "Input past end"
            DB  -67, 17, "Directory is full"
            DB  -68, 18, "Device unavailable"
            DB  -71, 14, "Disk not ready"
            DB  -75, 13, "Access denied"
            DB  -76, 14, "Path not found"
            DB  -83, 16, "Buffer too small"
            DB -101, 17, "COMSPEC not found"
            DB -102, 21, "Environment not found"
            DB -103, 22, "ENVIRON string invalid"
            DB -104, 25, "Out of string pool memory"
            DB -105, 24, "Out of environment space"
            DB -111, 24, "Pop-up already installed"
            DB -112, 24, "PopUpHere already called"
            DB -125,  8, "Overflow"
            DB -126, 18, "Out of stack space"
            DB -127, 20, "RETURN without GOSUB"
EndTable Label Byte
            DB       15, "Undefined error"
End
