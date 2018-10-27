'********** TRIG.BAS

'Copyright (c) 1991 Bruce Tonkin


DEFINT A-Z

'This file contains routines to calculate double-precision trigonometric,
'log, and exponential functions with P.D.Q. version 3.00 or later.
'
'I PLACE THESE ROUTINES IN THE PUBLIC DOMAIN.  ANYONE MAY USE, ADAPT, OR
'ALTER ANY OF THESE ROUTINES FOR ANY PURPOSE WHATEVER, WITH OR WITHOUT
'ATTRIBUTION.
'
'I do not guarantee or warrant any of the routines, but I have tested and
'verified each routine personally.  Most functions have at least 14 digits
'of accuracy throughout their range, but some such as cos(100) are accurate
'to only 12 or 13 digits for extreme values.
'
'--Bruce Tonkin


DECLARE FUNCTION PDQatn# (x#)       'arc tangent of x#
DECLARE FUNCTION PDQcos# (x#)       'cosine of x#
DECLARE FUNCTION PDQcosh# (x#)      'hyperbolic cosine of x#
DECLARE FUNCTION PDQcot# (x#)       'cotangent of x#
DECLARE FUNCTION PDQcoth# (x#)      'hyperbolic cotangent of x#
DECLARE FUNCTION PDQcsc# (x#)       'cosecant of x#
DECLARE FUNCTION PDQcsch# (x#)      'hyperbolic cosecant of x#
DECLARE FUNCTION PDQexp# (x#)       'exponential of x# (e ^ x#)
DECLARE FUNCTION PDQexp10# (x#)     'base ten exponential of x# (10 ^ x#)
DECLARE FUNCTION PDQlog# (x#)       'natural log of x#
DECLARE FUNCTION PDQlog10# (x#)     'base 10 log of x#
DECLARE FUNCTION PDQpow# (x#, Y#)   'raise x# to the y# power
DECLARE FUNCTION PDQsec# (x#)       'secant of x#
DECLARE FUNCTION PDQsech# (x#)      'hyperbolic secant of x#
DECLARE FUNCTION PDQsin# (x#)       'sine of x#
DECLARE FUNCTION PDQsinh# (x#)      'hyperbolic sine of x#
DECLARE FUNCTION PDQsqr# (x#)       'square root of x#
DECLARE FUNCTION PDQtan# (x#)       'tangent of x#
DECLARE FUNCTION PDQtanh# (x#)      'hyperbolic tangent of x#

CONST pi# = 3.14159265358979# + 3.24D-15
CONST twopi# = 2# * pi#
CONST invtwopi# = 1# / twopi#
CONST e# = 2.71828182845904# + 5.24D-15
CONST log10# = 2.30258509299404# + 5.68D-15
CONST einv# = 1# / e#

FUNCTION PDQatn# (x#) STATIC

  neg = 0: gotit = 0: t# = x#
  IF x# < 0 THEN t# = -x#: neg = -1

  SELECT CASE t#
    CASE IS <= .65#
      z# = t#: v# = t#: w# = z# * z#
      FOR i = 3 TO 99 STEP 8
        v# = v# * w#: z# = z# - v# / i
        v# = v# * w#: z# = z# + v# / (i + 2)
        v# = v# * w#: z# = z# - v# / (i + 4)
        v# = v# * w#: z# = z# + v# / (i + 6)
        IF v# < 1E-15 THEN gotit = -1: EXIT FOR
      NEXT i
    CASE IS > 1.5#
      z# = pi# / 2# - 1# / t#: v# = t#: w# = t# * t#
      FOR i = 3 TO 99 STEP 8
        v# = v# * w#: z# = z# + 1# / (v# * i)
        v# = v# * w#: z# = z# - 1# / (v# * (i + 2))
        v# = v# * w#: z# = z# + 1# / (v# * (i + 4))
        v# = v# * w#: z# = z# - 1# / (v# * (i + 6))
        IF v# > 1E+15 THEN gotit = -1: EXIT FOR
      NEXT i
    CASE ELSE
      q# = t# / (1# + t# * t#): w# = t# * q#: z# = 1#: v# = 1#
      FOR i = 3 TO 99 STEP 8
        v# = (i - 1) * v# * w# / i: z# = z# + v#
        v# = (i + 1) * v# * w# / (i + 2): z# = z# + v#
        v# = (i + 3) * v# * w# / (i + 4): z# = z# + v#
        v# = (i + 5) * v# * w# / (i + 6): z# = z# + v#
        IF v# < 1E-15 THEN gotit = -1: EXIT FOR
      NEXT i
      z# = z# * q#
  END SELECT

  IF NOT gotit THEN
    i = 1: v# = 1# + t# * t#
    DO
      w# = PDQtan#(z#)
      diff# = (w# - t#) / v#
      z# = z# - diff#
      i = i + 1
    LOOP UNTIL ABS(diff#) < 1E-14 OR i > 10
  END IF

  IF neg THEN PDQatn# = -z# ELSE PDQatn# = z#

END FUNCTION

FUNCTION PDQcos# (x#) STATIC

  IF fact = 0 THEN
    DIM invfact#(1 TO 30): invfact#(1) = 1
    FOR i = 2 TO 30: invfact#(i) = invfact#(i - 1) / i: NEXT i
    fact = -1
  END IF

  z# = x# * invtwopi#   'what part of the cosine curve are we talking about?
  z# = ABS(z#)          'cos(-x)=cos(x)
  z# = z# - FIX(z#)     'force to range 0 to 1, and then to 0 to .5
  neg = 0: IF z# > .5# THEN z# = z# - .5#: neg = -1
  z# = z# * twopi#
  u# = z# * z#: w# = u#: k = -1
  temp# = 1# - u# / 2#

  FOR i = 4 TO 30 STEP 2
    w# = w# * u#
    v# = w# * invfact#(i)
    IF k = 1 THEN temp# = temp# - v# ELSE temp# = temp# + v#
    k = -k
    IF PEEK(VARPTR(v#) + 7) < 61 THEN EXIT FOR   'v# < 6.88D-15
  NEXT i

  IF neg THEN PDQcos# = -temp# ELSE PDQcos# = temp#

END FUNCTION

FUNCTION PDQcosh# (x#) STATIC

  PDQcosh# = (PDQexp#(x#) + PDQexp#(-x#)) / 2#

END FUNCTION

FUNCTION PDQcot# (x#) STATIC

  PDQcot# = PDQcos#(x#) / PDQsin#(x#)

END FUNCTION

FUNCTION PDQcoth# (x#) STATIC

  PDQcoth# = PDQcosh#(x#) / PDQsinh#(x#)

END FUNCTION

FUNCTION PDQcsc# (x#) STATIC

  PDQcsc# = 1# / PDQsin#(x#)

END FUNCTION

FUNCTION PDQcsch# (x#) STATIC

  PDQcsch# = 1# / PDQsinh#(x#)

END FUNCTION

FUNCTION PDQexp# (x#) STATIC

  IF fact = 0 THEN
    DIM invfact#(1 TO 17): invfact#(1) = 1
    FOR j = 2 TO 17: invfact#(j) = invfact#(j - 1) / j: NEXT j
    fact = -1
  END IF

  temp# = 1#: neg = 0: t# = x#: IF t# < 0 THEN t# = -t#: neg = -1
  k = FIX(t#): t# = t# - k
  m = 1024: n = 0       'quick way of raising to an integer power

  WHILE m > 0
    IF n THEN temp# = temp# * temp#
    IF m AND k THEN temp# = temp# * e#: n = 1
    m = m \ 2
  WEND

  w# = 1#: v# = t#: z# = t#

  FOR j = 1 TO 17
    w# = w# + v# * invfact#(j)
    v# = v# * z#
  NEXT j

  temp# = temp# * w#: IF neg THEN temp# = 1# / temp#
  PDQexp# = temp#

END FUNCTION

FUNCTION PDQexp10# (x#) STATIC

  PDQexp10# = PDQexp#(log10# * x#)

END FUNCTION

FUNCTION PDQlog# (x#) STATIC

 'IF x# <= 0 THEN ERROR 5       'unREM for error checking

  neg = 0
  t# = x#: IF x# < .5# THEN t# = 1# / x#: neg = -1
  i = 0

  IF before = 0 THEN
    e4# = e# * e# * e# * e#
    e4inv# = 1# / e4#
    before = -1
  END IF

  WHILE t# > e4#
    t# = t# * e4inv#
    i = i + 4
  WEND

  WHILE t# > 1#
    t# = t# * einv#
    i = i + 1
  WEND

  w# = (t# - 1#) / (1# + t#): v# = w# * w#: q# = 0

  FOR k = 3 TO 99 STEP 4
    q# = q# + w# / (k - 2): w# = w# * v#
    q# = q# + w# / k: w# = w# * v#
    IF ABS(w#) < 1E-15 THEN EXIT FOR
  NEXT k

  temp# = i + q# + q#: IF neg THEN temp# = -temp#
  PDQlog# = temp#

END FUNCTION

FUNCTION PDQlog10# (x#) STATIC
 
  PDQlog10# = PDQlog#(x#) / log10#

END FUNCTION

FUNCTION PDQpow# (x#, Y#) STATIC

  PDQpow# = PDQexp#(Y# * PDQlog#(x#))

END FUNCTION

FUNCTION PDQsec# (x#) STATIC

  PDQsec# = 1# / PDQcos#(x#)

END FUNCTION

FUNCTION PDQsech# (x#) STATIC

  PDQsech# = 1# / PDQcosh#(x#)

END FUNCTION

FUNCTION PDQsin# (x#) STATIC

  IF fact = 0 THEN
    DIM invfact#(1 TO 29): invfact#(1) = 1
    FOR i = 2 TO 29: invfact#(i) = invfact#(i - 1) / i: NEXT i
    fact = -1
  END IF

  z# = x# * invtwopi#   'what part of the sine curve are we talking about?
  z# = z# - FIX(z#)     'force to range -1 to 1, then 0 to 1, then to 0 to .5
  neg = 0: IF z# < 0 THEN neg = -1: z# = -z#   'sin(-z) = -sin(z)
  IF z# > .5# THEN z# = z# - .5#: neg = -neg - 1

  z# = z# * twopi#: w# = z# * z#
  temp# = z#: k = 1

  FOR i = 3 TO 29 STEP 2
    z# = z# * w#: k = -k
    v# = z# * invfact#(i)
    IF k = 1 THEN temp# = temp# + v# ELSE temp# = temp# - v#
    IF PEEK(VARPTR(v#) + 7) < 61 THEN EXIT FOR
  NEXT i

  IF neg THEN PDQsin# = -temp# ELSE PDQsin# = temp#

END FUNCTION

FUNCTION PDQsinh# (x#) STATIC

  PDQsinh# = (PDQexp#(x#) - PDQexp#(-x#)) / 2#

END FUNCTION

FUNCTION PDQsqr# (x#) STATIC

  guess# = x#
  k = VARPTR(guess#) + 6

  IF PEEK(k + 1) > 128 THEN ERROR 5

  w = PEEK(k) + 256 * PEEK(k + 1)
  IF w = 0 THEN PDQsqr# = 0#: EXIT FUNCTION

  v = ((w - 16368) \ 2) + 16368
  POKE k, v AND &HFF: POKE k + 1, (v \ 256)

  FOR i = 1 TO 4
    guess# = guess# - (guess# * guess# - x#) / (guess# + guess#)
  NEXT i

  PDQsqr# = guess#

END FUNCTION

FUNCTION PDQtan# (x#) STATIC

  PDQtan# = PDQsin#(x#) / PDQcos#(x#)

END FUNCTION

FUNCTION PDQtanh# (x#) STATIC

  PDQtanh# = PDQsinh#(x#) / PDQcosh#(x#)

END FUNCTION

