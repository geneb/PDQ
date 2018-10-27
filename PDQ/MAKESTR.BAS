'*********** MAKESTR.BAS - directly creates a custom STR#####.OBJ stub file

'Copyright (c) 1991 Crescent Software
'Written by Paul Passarelli (a man who truly knows his object formats [EW])

'Compile and link this program as follows:
'
'   bc makestr /o;
'   link /nod/noe/ex/packc/far makestr _noval _noread _noerror , , nul, pdq

DEFINT A-Z

'$INCLUDE: 'PDQDECL.BAS'
DECLARE FUNCTION Checksum% (Any$)

PRINT "P.D.Q. MAKESTR utility program"

Size& = PDQValL&(COMMAND$)
DO WHILE Size& < 10 OR Size& > 63000
   LINE INPUT "String Module Size (10 - 63000): "; Size$
   Size& = PDQValL&(Size$)
LOOP

IF Size& MOD 2 THEN             'the string pool size must be an even number
   Size& = Size& + 1
END IF

Num$ = LTRIM$(STR$(Size&))
NumLen = LEN(Num$)

BaseName$ = "STR00000"
MID$(BaseName$, 9 - NumLen, NumLen) = Num$

FileName$ = BaseName$ + ".OBJ"
OPEN FileName$ FOR BINARY AS #1

'----- THEADR
Obj$ = CHR$(128) + MKI$(14)
Obj$ = Obj$ + CHR$(12) + BaseName$ + ".ASM"
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- LNAMES
Obj$ = CHR$(150) + MKI$(48)
Obj$ = Obj$ + CHR$(0) + ""
Obj$ = Obj$ + CHR$(6) + "DGROUP"
Obj$ = Obj$ + CHR$(13) + BaseName$ + "_TEXT"
Obj$ = Obj$ + CHR$(3) + "BSS"
Obj$ = Obj$ + CHR$(4) + "DATA"
Obj$ = Obj$ + CHR$(4) + "CODE"
Obj$ = Obj$ + CHR$(4) + "_BSS"
Obj$ = Obj$ + CHR$(5) + "_DATA"
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- SEGDEF
Obj$ = CHR$(152) + MKI$(7)
Obj$ = Obj$ + CHR$(72) + MKI$(0) + CHR$(3) + CHR$(6) + CHR$(1)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- SEGDEF
Obj$ = CHR$(152) + MKI$(7)
Obj$ = Obj$ + CHR$(72) + MKI$(6) + CHR$(8) + CHR$(5) + CHR$(1)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- SEGDEF
Obj$ = CHR$(152) + MKI$(7)
Obj$ = Obj$ + CHR$(72) + MKI$(CINT(Size&)) + CHR$(7) + CHR$(4) + CHR$(1)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- GRPDEF
Obj$ = CHR$(154) + MKI$(6)
Obj$ = Obj$ + CHR$(2)
Obj$ = Obj$ + CHR$(255) + CHR$(2)
Obj$ = Obj$ + CHR$(255) + CHR$(3)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- PUBDEF
Obj$ = CHR$(144) + MKI$(19)
Obj$ = Obj$ + CHR$(1) + CHR$(2)
Obj$ = Obj$ + CHR$(12) + "P$BYTESSHORT" + MKI$(4) + CHR$(0)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- PUBDEF
Obj$ = CHR$(144) + MKI$(16)
Obj$ = Obj$ + CHR$(1) + CHR$(3)
Obj$ = Obj$ + CHR$(9) + "P$STRPOOL" + MKI$(0) + CHR$(0)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- PUBDEF
Obj$ = CHR$(144) + MKI$(33)
Obj$ = Obj$ + CHR$(1) + CHR$(2)
Obj$ = Obj$ + CHR$(11) + "P$BYTESFREE" + MKI$(2) + CHR$(0)
Obj$ = Obj$ + CHR$(11) + "P$BYTESUSED" + MKI$(0) + CHR$(0)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- COMENT
Obj$ = CHR$(136) + MKI$(4)
Obj$ = Obj$ + CHR$(0) + CHR$(162) + CHR$(1)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- LEDATA
Obj$ = CHR$(160) + MKI$(10)
Obj$ = Obj$ + CHR$(2) + MKI$(0)
Obj$ = Obj$ + CHR$(0) + CHR$(0) + MKI$(CINT(Size&)) + CHR$(0) + CHR$(0)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$


'----- MODEND
Obj$ = CHR$(138) + MKI$(2)
Obj$ = Obj$ + CHR$(0)
Obj$ = Obj$ + CHR$(Checksum%(Obj$))
PUT #1, , Obj$

CLOSE #1

FUNCTION Checksum% (Object$) STATIC

    Sum = 0                     'start with zero
    FOR X = 1 TO LEN(Object$)   'walk through each character in the string
      Sum = Sum - MidChar%(Object$, X)
    NEXT
    Checksum% = Sum AND &HFF    'assign the output from the low byte only

END FUNCTION
