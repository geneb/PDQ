'*********** INCENV.BAS - increases the size of the -current- environment

'Written by and Copyright (c) 1992 Daniel LEMYE (SOFT PLUS, Brussels) and
'  Ethan Winer

'This file contains a combined demo and subroutine.  Therefore, you will copy
'the IncEnv subprogram from this file into your own program, or perhaps to a
'separate file which is then loaded as a module.
'
'Call IncEnv passing to it the desired new size of the program's copy of the
'environment.  If you use a value of zero for NewSize, then the current size
'of the environment is returned in NewSize as a result.
'
'IncEnv requires DOS 3.0 or later.  It doesn't work in QB/QBX.

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

Q$ = CHR$(34)

IF DOSVer% < 300 THEN
  PRINT "This program requires DOS 3.0 or later"
  END
END IF

'Size = 0                       'this isn't really necessary
CALL IncEnv(Size)               'get the current environment size
PRINT "The current environment size is"; Size; "bytes"
GOSUB CheckError

'this should fail due to insufficient environment memory
ENVIRON ("STUFF=11111111111111111111111111111111111111111111111111111111111")
IF ERR = 105 THEN
  PRINT "As expected we got an "; Q$; "Out of environment space"; Q$; " error"
  ERROR 0                       'clear ERR so CheckError won't end
END IF

Size = 2000                     'now set the new size to 2000 bytes
CALL IncEnv(Size)
GOSUB CheckError

Size = 0                        'get the size again to prove it worked
CALL IncEnv(Size)               'Size is initially set to zero
GOSUB CheckError
PRINT "The environment size is now"; Size; "bytes"

'this should now work
ENVIRON ("STUFF=11111111111111111111111111111111111111111111111111111111111")
GOSUB CheckError

PRINT "It worked!  Here's the result of setting STUFF:"
PRINT
PRINT ENVIRON$("STUFF")

END

CheckError:
IF ERR THEN
  PRINT PDQMessage$(ERR)
  END
END IF
RETURN

SUB IncEnv (NewSize) STATIC

   DIM Regs AS RegType
   SaveSeg = GetSeg%                'save the current DEF setting (optional)
 
   Regs.AX = &H6200                 'service &H62 returns the PSP segment
   CALL Interrupt(&H21, Regs)       'call DOS to do the hard stuff
   
   PspSeg = Regs.BX                 'this is the PSP seg
   DEF SEG = PspSeg                 'we need to PEEK this segment
   EnvSeg = PDQPeek2%(&H2C)         'address &H2C = environment segment
   DEF SEG = EnvSeg - 1             'this is the Memory Control Block segment
   
   IF PEEK(0) <> 77 THEN            'a valid MCB always begins with "M"
     ERROR 102                      'force an "Environment not found" error
     EXIT SUB
   END IF
   
   CurSize = PDQPeek2%(3) * 16      'get the current size of the environment
   IF NewSize = 0 THEN              'is the caller requesting this info?
     NewSize = CurSize              'yes, so return that
     EXIT SUB                       'and leave
   END IF
   
   NewSeg = AllocMem%(NewSize)      'allocate memory for the new environment
   IF ERR THEN EXIT SUB             'exit leaving ERR intact

   CALL BlockCopy(EnvSeg, Zero, NewSeg, Zero, NewSize) 'copy old env. to new
   DEF SEG = PspSeg                 'we need to POKE this segment
   CALL PDQPoke2(&H2C, NewSeg)      'address &H2C = environment segment

   DEF SEG = SaveSeg                'restore original DEF setting (optional)

END SUB

