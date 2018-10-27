'********** EXE2COM.BAS - shrinks a program by reducing its .EXE header size

'Copyright (c) 1989 Crescent Software
'  hard stuff by Robert L. Hummel


DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DEF FNCheckSumStr% (Work$)              'calculates a checksum for a string
  STATIC Length, Temp                   'local variables
  Length = LEN(Work$)                   'use LEN() once for smaller code
  Tmp = 0                               'clear the accumulator
  FOR X = 0 TO (Length AND &HFFFE) - 1 STEP 2   'walk through the byte pairs
    Tmp = Tmp + PDQPeek2%(SADD(Work$) + X)      'and accumulate the checksum
  NEXT                                          'handle an odd byte if needed
  IF Length AND 1 THEN Tmp = Tmp + ASC(RIGHT$(Work$, 1))
  FNCheckSumStr% = Tmp                          'assign the function's output
END DEF

FileName$ = COMMAND$                    'get the .EXE file name, no extension

OPEN FileName$ + ".EXE" FOR BINARY AS #1        'open the input file
IF ERR THEN                                     'make sure it was there
   BEEP                                         'oops
   PRINT "Error opening file."
   PRINT "Usage: EXE2COM FILENAME - do not enter an extension"
   END
END IF

Length& = LOF(1)                        'remember the input file length
GET #1, , Signature                     'read the first two bytes in the file

IF Signature <> &H5A4D THEN             'the header must be &H5A4D ("MZ") or
  PRINT FileName$; " is not a valid .EXE file." 'it's not a real .EXE file
  END
END IF

GET #1, , LastPageSize
GET #1, , FilePages

GET #1, , NReloc        'Number of relocation items in header
GET #1, , HdrParas      'Length of header in 16-byte paragraphs

SEEK #1, &H18 + 1
GET #1, , ROffset       'Offset from start of file of first relocation item

'----------------------------------------------------------------------
' Figure out how many bytes can be saved by compressing the file.  Add four
' bytes per relocation item to the offset of the relocation items, round up
' to the next largest paragraph, and subtract from the header size.  If
' WasteBytes = 0, print a message saying that the file size can't be reduced.
'----------------------------------------------------------------------
NullBytes = (16 * HdrParas) - (ROffset + 4 * NReloc)
WasteBytes = NullBytes - NullBytes MOD 16

IF WasteBytes = 0 THEN
  PRINT "File is already converted."
  END
END IF

OPEN FileName$ + ".COM" FOR OUTPUT AS #2        'create the output file

'----------------------------------------------------------------------
' Calculate the new values for the parameters that must be changed:
' LastPageSize, FilePages, HdrParas, and CheckSum.
'----------------------------------------------------------------------
NewFilePages = FilePages
NewLastPageSize = LastPageSize - WasteBytes

IF NewLastPageSize <= 0 THEN
   NewFilePages = NewFilePages - 1
   NewLastPageSize = NewLastPageSize + 512
END IF

NewHdrParas = HdrParas - WasteBytes \ 16

'----------------------------------------------------------------------
' Print out a summary of the action.
'----------------------------------------------------------------------
PRINT
PRINT "Analysis Of File: "; FileName$
PRINT "  There are "; NReloc; " relocation items."
PRINT
PRINT , "Was", "Now"
PRINT "Header    ", HdrParas * 16, NewHdrParas * 16
PRINT "File Size ", Length&, Length& - WasteBytes
PRINT "Image Size", CLNG(FilePages) * 512 + LastPageSize,
PRINT CLNG(NewFilePages) * 512 + NewLastPageSize
PRINT
PRINT WasteBytes; " bytes were saved by EXE2COM."
PRINT
PRINT "Writing output file ...";

'----------------------------------------------------------------------
' To create a new, reduced version of the file, follow these easy steps.
'----------------------------------------------------------------------
'CheckSum = 0   'Initialize the new checksum counter (not really needed)

SEEK #1, 1      'Position the input file to the beginning

'----------------------------------------------------------------------
' 1. Transfer the .EXE signature into the first word of the file.
'    Calculate the checksum as we progress through the file.
'----------------------------------------------------------------------
GET #1, , DW
CheckSum = CheckSum + DW
PUT #2, , DW

'----------------------------------------------------------------------
' 2. Write the next four words of file information to the new file.
'----------------------------------------------------------------------
PUT #2, , NewLastPageSize       '2-3
PUT #2, , NewFilePages          '4-5
PUT #2, , NReloc                '6-7
PUT #2, , NewHdrParas           '8-9
CheckSum = CheckSum + NewLastPageSize + NewFilePages + NReloc + NewHdrParas

'----------------------------------------------------------------------
' 3. The next four words are MinAlloc, MaxAlloc, InitialSS and InitialSP.
'    Transfer them, but set MaxAlloc = MinAlloc to allow shelling.
'----------------------------------------------------------------------
SEEK #1, &HA + 1        'Source to offset 0Ah

GET #1, , DW            'MinAlloc...
CheckSum = CheckSum + DW
PUT #2, , DW

PUT #2, , DW            '...same as MaxAlloc
CheckSum = CheckSum + DW
GET #1, , DW            'Keep file position the same

GET #1, , DW            'InitialSS
CheckSum = CheckSum + DW
PUT #2, , DW

GET #1, , DW            'InitialSP
CheckSum = CheckSum + DW
PUT #2, , DW

'----------------------------------------------------------------------
' 4. The next word is the checksum result. Use a 0 in the calculation.
'    This will be put in later.
'----------------------------------------------------------------------
GET #1, , DW            'Ignore old checksum
PUT #2, , DW            'New checksum will eventually go here

'----------------------------------------------------------------------
' 5. Move the remaining significant bytes of the header.  This is where
'    the actual size reduction takes place.
'----------------------------------------------------------------------
Temp$ = SPACE$(NewHdrParas * 16 - &H14)
GET #1, , Temp$
PUT #2, , Temp$
CheckSum = CheckSum + FNCheckSumStr%(Temp$)

'----------------------------------------------------------------------
' 6. Now position the source file to the end of the header (the start
'    of the load module), and transfer the load portion of the file.
'----------------------------------------------------------------------
SEEK #1, HdrParas * 16 + 1
LoadSize& = Length& - HdrParas * 16

DO
  Temp$ = INPUT$(4096, #1)
  PUT #2, , Temp$
  CheckSum = CheckSum + FNCheckSumStr%(Temp$)
LOOP WHILE LEN(Temp$)

'----------------------------------------------------------------------
' Write the new checksum back to the file.
'----------------------------------------------------------------------
SEEK #2, &H12 + 1
DW = NOT CheckSum
PUT #2, , DW

'CLOSE                          'not really necessary

