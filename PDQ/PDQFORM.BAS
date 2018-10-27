'*********** PDQFORM.BAS - Scientific format and rounding functions
'
'Copyright (c) 1992 Shaun Blain

DEFINT A-Z
DECLARE FUNCTION SciFormat$ (Amount$, BPt, APt)
DECLARE FUNCTION Round$ (Amount$, ExpKick)

'$INCLUDE: 'PDQDECL.BAS'

DO
  INPUT "Enter a value: ", X$
  IF LEN(X$) = 0 THEN EXIT DO

  LOCATE , 1
  PRINT "Unformatted value = "; X$
  PRINT "Formatted value = "; SciFormat$(X$, 1, 2)
  PRINT USING "BASIC formatted value ##.##^^^^"; VAL(X$)

  PRINT "Formatted value = "; SciFormat$(X$, 2, 3)
  PRINT USING "BASIC formatted value ###.###^^^^"; VAL(X$)
  PRINT

LOOP

FUNCTION Round$ (Passed$, ExpKick) STATIC
'
'Copyright (c) 1992 Shaun Blain
'
' Function to round off a numeric string, and also set it to the
' correct length.
'
' Uses the last number in the string to determine if a number is rounded
' up or left alone. If a number is rounded, the cf (carry flag) is set
' until there is no more to carry. The expkick (exponet kickup) is set when
' a number is padded on the front end due to the carrying process. The expkick
' variable alerts the calling routine that it should increment the exponet
' value by one.
'
' This routine could be considered superfluous, but it makes the whole
' thing easier to understand. <IMHO>
'
   
  Zero$ = "0"
  CF = 0                                  'carry flag
  ExpKick = 0                             'kick up the exponet

  '--- do not mess with the original string
  Amount$ = LTRIM$(RTRIM$(Passed$))
  DPt = INSTR(Amount$, ".")
  TLen = LEN(Amount$) - 1

  '--- check to see if we should round up
  ND = TLen                               'find the next digit
  LD = MidChar(Amount$, TLen + 1) - 48    'obtain the load digit
  IF LD >= 5 THEN CF = -1                 'set carry flag to carry?

  '--- keep looping while the carry flag is set
  DO WHILE CF
    '--- yes, we need to round up

    'check if we need to pad the front end of the string
    IF ND = 0 THEN                        'set the next digit
      ND = 1
      Amount$ = " " + Amount$             'pad the string
      ExpKick = 1                         'set the exponent alert flag
    END IF

    IF LD > 9 THEN                        'load digit > 9?
      CF = -1                             'yes, we will need to carry
      CALL MidCharS(Amount$, ND, 48)      'set current digit to zero
    ELSE
      'load digit < 10 coming in

      'obtain int. value and inc by 1
      TVal = MidChar(Amount$, ND) - 47    'ASCII - 48 + 1
      IF TVal < 0 THEN TVal = 1

      'if the increment value is less then 10, insert it into the string
      IF TVal < 10 THEN
        CALL MidCharS(Amount$, ND, TVal + 48)
        CF = 0                            'no need to carry
      ELSE
        CF = -1                           'one more time through
        CALL MidCharS(Amount$, ND, 48)    'set current digit to zero
      END IF
    END IF
   
    ND = ND - 1                           'decrement next digit
    IF ND = DPt THEN ND = ND - 1          'we don't want the decimal point

    IF ND > 0 THEN
      LD = MidChar(Amount$, ND) - 47      'get next digit from the string
    ELSE
      LD = 1                              'past the beginning, assign a value
    END IF
        
  LOOP
           
    '--- did we have to pad the front of the string?
  IF ExpKick THEN
    T$ = LEFT$(Amount$, DPt) + RIGHT$(Amount$, TLen - DPt)
    T$ = LEFT$(T$, TLen)
    Amount$ = LEFT$(T$, DPt - 1) + "." + RIGHT$(T$, LEN(T$) - DPt + 1)
  END IF

    '--- assign the function value, and insure the proper length
  Round$ = LEFT$(LTRIM$(Amount$), TLen)

END FUNCTION

FUNCTION SciFormat$ (Amount$, BPt, APt) STATIC
'
' Copyright (c) 1992 Shaun Blain
'
' Function to format a numeric string into a scientific format string.
' IE. 0.000006 -> 6.0D-06
'
' Amount$ .... the numeric string to convert
' BPt     .... number of places before the decimal point
' APt     .... number of places after the decimal point

  IF NOT BeenHere THEN                    'do this stuff only once
    BeenHere = -1
    Zero$ = "0"                           'save a little memory
    Plus$ = "+"                           'plus sign
    Minus$ = "-"                          'negative sign
    Pt$ = "."                             'decimal point
    DPt = 0                               'where the decimal point is
  END IF

  TLen = BPt + APt + 2          'total req'd length (apt + bpt + dpt + sign)
    
  'make a copy of the string and clean it up
  TAmount$ = LTRIM$(RTRIM$(Amount$))

  'make sure it is not a null string, if it is, FIX IT!
  IF LEN(TAmount$) = 0 THEN
    Last$ = "0.00"                        'if it is null, we will return zero
    GOSUB QExit                           'this will fix it
  END IF
    
  'obtain the sign of the number
  IF LEFT$(TAmount$, 1) = Plus$ OR LEFT$(TAmount$, 1) = Minus$ THEN
    Sign$ = LEFT$(TAmount$, 1)                     'save the sign
    TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1) 'remove sign from string
  ELSE
    Sign$ = ""                                     'no sign
  END IF


  'trim any leading zeros
  DO WHILE LEFT$(TAmount$, 1) = Zero$
    TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1)
  LOOP

  'find the decimal point
  DPt = INSTR(TAmount$, Pt$)
  IF DPt = 0 THEN                         'this is science, we have to have
    DPt = LEN(TAmount$) + 1               ' a decimal point
    TAmount$ = TAmount$ + Pt$             'even if it does float!
  END IF

  'check that we have a long enough string
  'It is easier to do this way, rather than a lot of calculations below
  IF LEN(TAmount$) < TLen THEN
    DO
      TAmount$ = TAmount$ + Zero$         'if we don't pad the end of the
    LOOP UNTIL LEN(TAmount$) = TLen       ' string with zeros
  END IF
  ALen = LEN(TAmount$)

  '--- now act according to where the decimal point is
  SELECT CASE DPt

    'absolute value is greater than or equal to 1.0
    CASE IS > 1
      'build the output string now
      Cnt = 1                             'char pointer
      DO
        T = MidChar(TAmount$, Cnt) - 48   'get the char
        IF T >= 0 THEN                    'if it is a number
          Work$ = Work$ + LTRIM$(STR$(T)) 'add it to the string
        END IF
        Cnt = Cnt + 1                     'increment the pointer
      LOOP UNTIL LEN(Work$) = BPt         'loop until we have enough in front
                                          ' of the decimal point
               
      Work$ = Work$ + Pt$                 'add the decimal point
      DO
        T = MidChar(TAmount$, Cnt) - 48   'get the next character
        IF T >= 0 THEN                    'if it's not the decimal point
          Work$ = Work$ + LTRIM$(STR$(T)) 'add it to the string
        END IF
        Cnt = Cnt + 1                     'increment the pointer
      LOOP UNTIL LEN(Work$) = TLen        'continue until we have everything
                                          ' we need

      'between 0.0 and 1.0, absolute
      CASE ELSE

        'everything to the right of the decimal point
        CALL MidCharS(TAmount$, 1, 48)

        'trim any leading zeros, hey just like above
        DPt = 0
        DO WHILE LEFT$(TAmount$, 1) = Zero$
          TAmount$ = RIGHT$(TAmount$, LEN(TAmount$) - 1)
          DPt = DPt - 1
        LOOP

        'make sure it is long enough
        IF LEN(TAmount$) < TLen THEN
          DO
            TAmount$ = TAmount$ + Zero$         'pad with zeros as required
          LOOP UNTIL LEN(TAmount$) >= TLen
        END IF

        'now we start building the output string
        Cnt = 1                                 'char pointer
        DO
          T = MidChar(TAmount$, Cnt) - 48       'get the char
          IF T >= 0 THEN                        'if it is a number
            Work$ = Work$ + LTRIM$(STR$(T))     'add it to the string
          END IF
          Cnt = Cnt + 1                     'increment the pointer
        LOOP UNTIL LEN(Work$) = BPt         'loop until we have enough in
                                            ' front of the decimal point
               
        Work$ = Work$ + Pt$                 'add the decimal point
        DO
          T = MidChar(TAmount$, Cnt) - 48   'get the next character
          IF T >= 0 THEN                    'if it's not the decimal point
            Work$ = Work$ + LTRIM$(STR$(T)) 'add it to the string
          END IF
          Cnt = Cnt + 1                     'increment the pointer
        LOOP UNTIL LEN(Work$) = TLen        'continue until we
                                            ' have everything we need
  END SELECT

  '---- now round off the number
  Last$ = Round$(Work$, ExpKick)
  IF ExpKick THEN DPt = DPt + 1           'bump the exponent up one since we
                                          ' had to slide the decimal point
                                          ' to the left

QExit:                                    'used for null strings
  '---- now format the exponent string
  IF Last$ = "0.00" OR DPt = 0 THEN
    Exp$ = "D+00"
  ELSE
    IF DPt > 0 THEN                       'positive exponent
      IF DPt - BPt - 1 >= 0 THEN
        Exp$ = "D+" + LTRIM$(STR$(DPt - BPt - 1))
      ELSE
        Exp$ = "D" + LTRIM$(STR$(DPt - BPt - 1))
      END IF
    ELSE
      Exp$ = "D" + LTRIM$(STR$(DPt))      'negative exponent
    END IF
       
    'pad the exponent string with another zero if necessary
    IF LEN(Exp$) < 4 THEN Exp$ = LEFT$(Exp$, 2) + Zero$ + RIGHT$(Exp$, 1)
  END IF
    
  '---- assign the function's return value
  SciFormat$ = Sign$ + Last$ + Exp$

  'clean up memory
  Sign$ = ""
  Last$ = ""
  Exp$ = ""
  TAmount$ = ""
  Work$ = ""

END FUNCTION
