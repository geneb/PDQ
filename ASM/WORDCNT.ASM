;********** WORDCNT.ASM - counts the words and lines in a plain text file

;Copyright (c) 1991 Ethan Winer

;Usage:
;
;   WORDCNT filename
;
;Assemble and link as follows:
;
;   MASM wordcnt ;
;   LINK wordcnt startup , , nul , pdq ;
;   EXE2COM wordcnt


.Model Medium               ;all P.D.Q. programs are medium model
    Public Main             ;make the main public (must use the name Main)

.Data
    Extrn P$PSPSeg:Word     ;this is in PDQDATA.ASM, used to read COMMAND$

    Lines  DW 0             ;tracks the number of text lines
    
    Title$ DB "WordCount 1.0, Copyright (c) 1991 Ethan Winer", 13, 10, "$"
    Words$ DB " words found", 13, 10, "$"
    Lines$ DB " text lines$"
    Error$ DB "File not found$"

.Data?
    Buffer DB 4096 Dup (?)  ;the file is read here in portions

.Code

Main Proc

    ;--- print the opening title
    Mov  DX,Offset Title$
    Mov  AH,9
    Int  21h

    ;--- retrieve the DOS command line (this code adapted from COMMAND$.ASM)
    Mov  DS,P$PSPSeg        ;get the PSP segment that was saved at startup
    Mov  CL,DS:[80h]        ;get the length of the command line arguments
    Xor  CH,CH              ;clear CH so we can use all of CX
    Mov  SI,81h             ;point SI to the beginning of the command tail
    Mov  BX,CX              ;now [BX+SI] points to the CHR$(13) at the end
    Mov  [BX+SI],CH         ;force it to an ASCIIZ string in place

EatLoop:                    ;eat any leading "white space"
    Lodsb                   ;get the current character in the command tail
    Cmp  AL," "             ;is it a blank space?
    Je   @F                 ;yes, go eat it up
    Cmp  AL,9               ;no, but is it a tab character?
    Jne  EatDone            ;no, so we're done skipping over the white space

@@:
    Loop EatLoop            ;show the tail being one shorter and continue

EatDone:
    ;--- attempt to open the file
    Mov  DX,SI              ;show DOS where the name is (in the PSP)
    Dec  DX                 ;Lodsb took us one too far, back up a character
    Mov  AX,3D00h           ;open the file for input only
    Int  21h                ;let DOS do the real work
    Push SS                 ;restore DS from SS
    Pop  DS
    Jnc  @F                 ;no carry, no error

BadFile:
    Mov  DX,Offset Error$   ;print "File not found"
    Mov  AH,9               ;through DOS
    Int  21h

    Mov  AX,4C01h           ;quit with errorlevel = 1
    Int  21h

@@:
    Mov  BX,AX              ;copy the file handle DOS returned to BX
    Mov  DX,Offset Buffer   ;show DOS where to place the file contents
    Sub  DI,DI              ;we'll use DI as the word counter
    Mov  AL,0               ;initialize the "previous character" flag

    ;--- this is the main reading loop (the outer loop that reads the file)
Outer:
    Push AX                 ;save the previously read character
    Mov  CX,4096            ;tell DOS to read a 4K chunk
    Mov  AH,3Fh             ;specify the DOS Read service
    Int  21h                ;read the file into the buffer
    
    Mov  CX,AX              ;now CX holds the number of bytes that were read
    Pop  AX                 ;and now AL holds the last character
    Jcxz Done               ;all done, go report what happened
    Mov  SI,DX              ;prepare to scan the buffer

    ;--- this inner loop scans the buffer for space, tab, or CRLF characters
Inner:
    Mov  AH,AL              ;save last character to weed out repeating delims
    Lodsb                   ;get a character
    Cmp  AL," "             ;is it a space or a control character?
    Jbe  @F                 ;yes, bump the word count if this is not part of
                            ;  a repeating string of control characters
Continue:
    Loop Inner              ;no, keep looking
    Jmp  Short Outer        ;then go on to the next portion of the file

@@:
    Cmp  AL,10              ;is it a line feed?
    Je   Continue           ;yes, ignore it
    
    Cmp  AL,13              ;is it a carriage return?
    Jne  @F                 ;no, continue
    Inc  Lines              ;yes, show that we have another line
    
@@:
    Cmp  AH," "             ;no, but was the previous character a delimiter?
    Jbe  Continue           ;yes, so ignore this one
    Inc  DI                 ;this is a valid delimiter, bump the word count
    Jmp  Short Continue     ;and continue

    ;--- all done, display the results and end
Done:
   ;Mov  AH,3Eh             ;close the file whose handle is still in BX
   ;Int  21h                ;not really needed because DOS closes all files
    
    Mov  AX,DI              ;pass the count value on to Jeff's routine
    Call PrintAX            ;print it

    Mov  DX,Offset Words$   ;print " words found"
    Mov  AH,9
    Int  21h

    Mov  AX,Lines           ;pass the line count value on too
    Call PrintAX            ;print it

    Mov  DX,Offset Lines$   ;print " text lines"
    Mov  AH,9
    Int  21h

    Mov  AX,4C00h           ;quit with errorlevel = 0
    Int  21h

Main Endp



PrintAX Proc Near           ;prints integer value in AX, from Jeff Prosise's
                            ;  DOS 5 Techniques and Utilities by ZD-Press

    Mov  BX,10              ;keep dividing by 10 until all digits are printed
    Sub  CX,CX              ;use CX as the digit counter

@@:
    Inc  CX                 ;there's another one
    Sub  DX,DX              ;clear the high word for dividing
    Div  BX                 ;divide by 10
    Push DX                 ;save the remainder
    Or   AX,AX              ;are we done?
    Jnz  @B                 ;no, continue

@@:
    Pop  DX                 ;pop off the digits one by one
    Add  DL,"0"             ;convert to an ASCII digit
    Mov  AH,2               ;DOS output service
    Int  21h                ;print the digit
    Loop @B                 ;loop until done
    Ret

PrintAX Endp
End
