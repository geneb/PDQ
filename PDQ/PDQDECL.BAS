'********** PDQDECL.BAS - include file for P.D.Q. subroutines and functions

'Copyright (c) 1989 Ethan Winer


'Some of the DECLARE statements below are REMarked out.  The ones that add
'BASIC 7 capabilities to QuickBASIC (CHDRIVE, DIR$, and CURDIR$) cause an
'error when using BASIC 7.  Therefore, unREM them only if you are using QB.
'
'In some cases a subroutine or function can be declared in more than one way.
'For example, the PDQCompare function lets you pass the SEG address of TYPE
'variables, or an explicit segment and address using the BYVAL modifier.  We
'have assumed you are more likely to use the BYVAL version; if not, simply
'REM out that one and reinstate the SEG version.


'---- this TYPE is used by CALL INTERRUPT and the various P.D.Q. TSR routines
TYPE RegType
     AX        AS INTEGER
     BX        AS INTEGER
     CX        AS INTEGER
     DX        AS INTEGER
     BP        AS INTEGER
     SI        AS INTEGER
     DI        AS INTEGER
     Flags     AS INTEGER
     DS        AS INTEGER
     ES        AS INTEGER
     SS        AS INTEGER
     SP        AS INTEGER
     BusyFlag  AS INTEGER
     Address   AS INTEGER
     Segment   AS INTEGER
     ProcAdr   AS INTEGER
     ProcSeg   AS INTEGER
     IntNum    AS INTEGER
END TYPE

'---- subprogram declarations
DECLARE SUB BIOSInput (Work$, EditColor%)
'DECLARE FUNCTION BIOSInput% (Work$, EditColor%)
DECLARE SUB BlockCopy (FromSeg%, FromAdr%, ToSeg%, ToAdr%, NumBytes AS ANY)
DECLARE SUB BreakOff ()
DECLARE SUB BreakOn ()
DECLARE SUB BufOut (FileName$, Text$, Terminator$)
DECLARE SUB CallOldInt (Registers AS RegType)
'DECLARE SUB CHDRIVE ALIAS "B$CHDR" (Drive$)
DECLARE SUB ColorRest (Colr%)
DECLARE SUB CritErrOff ()
DECLARE SUB CritErrOn ()
DECLARE SUB CursorOff ()
DECLARE SUB CursorOn ()
DECLARE SUB CursorRest (Value&)
DECLARE SUB CursorSize (TopLine%, BotLine%)
DECLARE SUB DisableFP ()
DECLARE SUB EnableFP ()
DECLARE SUB EndLevel (ErrorLevel%)
DECLARE SUB EndTSR (ID$)
DECLARE SUB EnvOption (OptionCode%)
DECLARE SUB Flush CDECL
DECLARE SUB Get1Type (Segment%, Element%, Length%, TypeVar AS ANY)
DECLARE SUB GotoOldInt (Registers AS RegType)
DECLARE SUB HookFP ()
DECLARE SUB HookInt0 (Action%)
DECLARE SUB IncEnv (NewSize%)
DECLARE SUB IntEntry1 ()
DECLARE SUB IntEntry2 (Registers AS RegType, Action%)
DECLARE SUB Interrupt (IntNumber%, Registers AS ANY)
DECLARE SUB InterruptX (IntNumber%, Registers AS ANY)
DECLARE SUB MidCharS (Work$, BYVAL Position%, BYVAL Char%)
DECLARE SUB NoSnow (SnowFlag%)
DECLARE SUB Pause (Ticks%)
DECLARE SUB PDQInput (Work$)
DECLARE SUB PDQPoke2 (Address%, Value%)
DECLARE SUB PDQPrint (Work$, Row%, Column%, Colr%)
DECLARE SUB PDQCPrint (Work$, Row%, Column%)
DECLARE SUB PDQRandomize (NewSeed%)
DECLARE SUB PDQRestore ()
DECLARE SUB PDQSetMonSeg (NewSegment%)
DECLARE SUB PDQSetWidth (NewWidth%)
DECLARE SUB PDQSound (Frequency%, Duration%)
DECLARE SUB PointIntHere (Registers AS RegType)
DECLARE SUB PopDown ()
DECLARE SUB PopUpHere (HotKey%, ID$)
DECLARE SUB RedimAbsolute (Array() AS ANY, BYVAL LBnd%, BYVAL UBnd%, BYVAL NewSeg%)
DECLARE SUB ReleaseEnv ()
DECLARE SUB ResetKeyboard ()
DECLARE SUB ReturnFromInt (Registers AS RegType)
DECLARE SUB Set1Byte (Segment%, Element%, Value%)
DECLARE SUB Set1Long (Segment%, Element%, Value&)
DECLARE SUB Set1Type (Segment%, Element%, Length%, TypeVar AS ANY)
DECLARE SUB Set1Word (Segment%, Element%, Value%)
DECLARE SUB SetDelimitChar (Char%)
DECLARE SUB Sort (BYVAL Address%, NumEls%, Direction%)
DECLARE SUB Sort2 (BYVAL Address%, NumEls%, Direction%)
DECLARE SUB StuffBuf (Work$)
DECLARE SUB TSRFileOff ()
DECLARE SUB TSRFileOn ()
DECLARE SUB UnhookFP ()
DECLARE SUB UnhookInt0 ()
DECLARE SUB WindowCLS ()
DECLARE SUB WindowInit (BYVAL ULRow, BYVAL ULCol, BYVAL LRRow, BYVAL LRCol)
DECLARE SUB WindowLocate (BYVAL Row, BYVAL Column)
DECLARE SUB WindowPrint (Work$)
DECLARE SUB WindowPrintW (Work$)
DECLARE SUB WindowPrintCR (Work$)

'---- function declarations
DECLARE FUNCTION AllocMem% (NumBytes AS ANY)
DECLARE FUNCTION BIOSInkey% ()
DECLARE FUNCTION BIOSInput2% (Work$, BYVAL Row%, BYVAL Column%, BYVAL Colr%)
'DECLARE SUB BIOSInput2 (Work$, BYVAL Row%, BYVAL Column%, BYVAL EditColor%)
DECLARE FUNCTION BreakHit% ()
DECLARE FUNCTION BufIn$ (FileName$, Done%)
'DECLARE FUNCTION BufIn% (FileName$, Done%)
DECLARE FUNCTION ColorSave% ()
'DECLARE FUNCTION CURDIR$ ALIAS "B$FCD1" (Drive$)
DECLARE FUNCTION CursorSave& ()
DECLARE FUNCTION DeInstallTSR% (DGroup%, ID$)
'DECLARE FUNCTION DIR$ ALIAS "B$FDR1" (Spec$)
DECLARE FUNCTION Dollar$ (LongInt&)
DECLARE FUNCTION DOSBusy% ()
DECLARE FUNCTION DOSVer% ()
DECLARE FUNCTION FUsing$ (Number$, Image$)
DECLARE FUNCTION Get1Byte% (Segment%, Element%)
DECLARE FUNCTION Get1Word% (Segment%, Element%)
DECLARE FUNCTION Get1Long& (Segment%, Element%)
DECLARE FUNCTION GetCPU% ()
DECLARE FUNCTION GetSeg% ()
DECLARE FUNCTION MidChar% (Work$, Position%)
DECLARE FUNCTION PDQCompare% (BYVAL Seg1%, BYVAL Adr1%, BYVAL Seg2%, BYVAL Adr2%, NumBytes AS ANY)
'DECLARE FUNCTION PDQCompare% (SEG Type1 AS ANY, SEG Type2 AS ANY, NumBytes AS ANY)
DECLARE FUNCTION PDQMonitor% ()
DECLARE FUNCTION PDQExist% (FileSpec$)
DECLARE FUNCTION PDQInkey% ()
DECLARE FUNCTION PDQMessage$ (ErrNum%)
DECLARE FUNCTION PDQParse$ (Work$)
DECLARE FUNCTION PDQPeek2% (Address%)
DECLARE FUNCTION PDQRand% (Limit AS ANY)
DECLARE FUNCTION PDQShl% (BYVAL Value%, BYVAL Places%)
DECLARE FUNCTION PDQShr% (BYVAL Value%, BYVAL Places%)
DECLARE FUNCTION PDQTimer& ()
DECLARE FUNCTION PDQValI% (Number$)
DECLARE FUNCTION PDQValL& (Number$)
DECLARE FUNCTION PoolOkay% ()
DECLARE FUNCTION PopDeinstall% (DGroup%, ID$)
DECLARE FUNCTION PopRequest% (Flag%, Ticks2Try%)
DECLARE FUNCTION Power& (Mantissa%, Exponent%)
DECLARE FUNCTION Power2& (Exponent%)
DECLARE FUNCTION ReleaseMem% (Segment%)
DECLARE FUNCTION SeekLoc& (RecNumber%, RecLength%)
DECLARE FUNCTION StringShort% ()
DECLARE FUNCTION StringUsed% ()
DECLARE FUNCTION Swap2Disk% (FileName$, ProgramID%)
DECLARE FUNCTION Swap2EMS% (ProgramID%)
DECLARE FUNCTION SwapCode%
DECLARE FUNCTION TestHotKey% (ScanCode%)
DECLARE FUNCTION TSRInstalled% (ID$)
DECLARE FUNCTION UnHookInt% (Registers AS RegType, DGroup%)
DECLARE FUNCTION WindowRow% ()
DECLARE FUNCTION WindowCol% ()

