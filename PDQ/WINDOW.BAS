'********* WINDOW.BAS - demonstrates the P.D.Q. window managing routines

'Copyright (c) 1991 Ethan Winer

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

CLS                             'start with a clean slate
COLOR 12, 7                     'bright red on white
CALL PDQPrint(STRING$(2000, 197), 1, 1, 12 + 16)    '12 + 16 = red on blue
                                
LOCATE , , 1                    'turn on the cursor
CALL WindowInit(5, 5, 17, 37)   'set the window size
CALL WindowCLS                  'clear the window
CALL WindowLocate(3, 5)         'position the cursor at 3,5 within the window

COLOR 15, 2                     'print the numbers in bright white on green
                                ' (the color is honored only after compiling)
FOR X = 85 TO 180
  CALL WindowPrint(STR$(X))     'this shows how the window scrolls
  IF X MOD 10 = 0 THEN          'every ten numbers issue a carriage return
    CALL WindowPrintCR("")      'by calling WindowPrintCR with a null string
  END IF
  CALL Pause(1)                 'this gives you a chance to see it working
NEXT

CALL PDQPrint("Press a key to continue this demo  ", 25, 1, 15 + 2 * 16)
LOCATE 25, 35: WHILE BIOSInkey% = 0: WEND
CALL PDQPrint(STRING$(35, 197), 25, 1, 12 + 16) 'restore the screen

Tmp$ = "This demonstrates how to employ word-wrapping in the P.D.Q. Window "
Tmp$ = Tmp$ + "manager.  The WindowPrintW routine is similar to the regular"
Tmp$ = Tmp$ + " WindowPrint routine, except it breaks the string down into"
Tmp$ = Tmp$ + " individual words and prints each without splitting a word "
Tmp$ = Tmp$ + "in the middle.  As described in this program's comments, "
Tmp$ = Tmp$ + "BASIC's current COLOR setting is not honored while you are "
Tmp$ = Tmp$ + "developing a program in the QB editor."

CALL WindowCLS                  'first clear the window
CALL WindowPrintW(Tmp$)         'then print the text with word-wrapping

