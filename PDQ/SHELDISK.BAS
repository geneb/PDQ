'********** SHELDISK.BAS - demonstrates the P.D.Q. Shell2Disk function

'Copyright (c) 1993 Crescent Software, Inc.


DEFINT A-Z

'The link syntax is the same as for swapping TSR programs in that you must
'list POPSWAP.OBJ as the first object file, which then means you should also
'specify an explicit output file name to avoid it being named POPSWAP.EXE:
'
'  LINK /NOD POPSWAP SHELDISK, SHELDISK.EXE, NUL, [BASIC7] PDQ;
'
'Because Shell2Disk is a function you must declare it before you can use it.
'
DECLARE FUNCTION Shell2Disk% (SwapFile$, Child$, CmdTail$)
'
'SwapFile$ holds the program while it is swapped out of memory.  You should
'always give the full pathname and also make sure that the file resides on a
'non-removable (fixed) disk.  If you use a file name like "TEMP.SWP" and the
'shelled program changes directories, the internal swapping subroutine won't
'be able to open the file when it tries to restore the original program.
'
SwapFile$ = "C:\SHELDISK.SWP"
'
'Child$ holds the name of the file that you want to execute.  This name may
'not contain leading, trailing, or embedded blanks.  You must make sure the
'program can be found by specifying the full path and program name INCLUDING
'the extension.  Only .COM and .EXE programs can be shelled-to directly.  To
'execute either a batch file or an internal DOS command use "COMMAND.COM" for
'the program name, and "/C [xxx]" for the CmdTail$ argument, where [xxx] is
'the DOS command or batch file name.  See the description for CmdTail$ below.
'
Child$ = "C:\COMMAND.COM"
'
'CmdTail$ holds the remainder of the command line that you want to pass to
'the child program.  Note that the command tail begins at the first character
'after the program name and by default doesn't include any spaces.  However,
'in the command line "EDIT FILE.EXT" the command tail is " FILE.EXT" and many
'programs expect that space to be included.  Therefore, we recommend that you
'also include an extra leading space in the CmdTail$ argument:
'
CmdTail$ = " /C DIR /W"
'
'Result% is the exit code returned by the child. It's the same value that you
'test with the batch ERRORLEVEL statement.  A separate code that indicates
'the success or failure of the SHELL process is returned in ERR:
'
Result% = Shell2Disk%(SwapFile$, Child$, CmdTail$)
PRINT "Return code: "; Result%
PRINT "Error code : "; ERR
'
'
'IMPORTANT NOTE FOR VB/DOS USERS: When using Shell2Disk with VB/DOS you must
'use string variables for all of the arguments (as shown in this demo).  You
'cannot use quoted string literals for any of the arguments.  That is, where
'the following example would work with QuickBASIC and PDS, it will NOT work
'when using VB/DOS:
'
'Result% = Shell2Disk%("C:\SHELDISK.SWP", "C:\COMMAND.COM", " /C DIR /W")

