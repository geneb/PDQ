'============================================================================
'=  SysInfo (Everything you ever wanted to know...)                         =
'=  by Jonathan Zuck                                                        =
'=  Copyright 1990, User Friendly, Inc.                                     =
'=                                                                          =
'=     bc sysinfo /o;                                                       =
'=     link /nod /noe sysinfo _noval _noread , , nul , pdq                  =
'=     exe2com sysinfo                                                      =
'=                                                                          =
'============================================================================

DEFINT A-Z
'$INCLUDE: 'PDQDECL.BAS'

DIM Registers AS RegType

'Note: Code begins on line 162 (Search for "****")

'++++++++++++++++++++++++ Function Code Begins Here +++++++++++++++++++++++++

'Functions in SysInfo.BAS:
'FNEquipment% -- Sets the following variables regarding sys config:
'                PPorts   -- Total Parallel Ports
'                SPorts   -- Total Serial Ports
'                Floppies -- Total Number of Floppy Drives
'                VMode    -- Initial Video Mode at boot
'                CPros    -- Co-processor installed (-1), not (0)
'                Game     -- Game adapter installed (-1), not (0)
'FNBaseRam%   -- Total K of Base memory as reported by the BIOS
'FNExtended%  -- Total K of Extended memory as reported by the BIOS
'FNPSPAddr%   -- Address of the Program Segment Prefix (used by others)
'FNFreeRAM%   -- Total K of available memory NOT including current prog
'                Uses method used in CHKDSK and gets same value, sometimes
'                different from Norton's SI program.
'FNGetDrive%  -- Returns default disk drive (A=0, B=1, etc.)
'FNSetDrive%  -- Changes default disk drive
'                Normally this is 5 (E) but can be increased with
'                LASTDRIVE = H (or whatever) in CONFIG.SYS
'FNDriveInfo% -- Sets following variables about selected drive:
'                TotalBytes& -- Total Disk Space
'                FreeBytes&  -- Total Available Disk Space
'                FNDriveInfo% = -1 if invalid drive
'FNValidDrv%  -- Tells if a given drive is valid
'FNRemovable% -- Does specified drive support removable media ( -1 if yes)
'FNRemote%    -- Is specified drive local or remote network drive (-1 if remote)
'FNMachineID% -- Sets the following variables about a network station:
'                MName   -- Station Name ("N/A" if no network)
'                MNumber -- Station Number (0 of no network)
'                FNMachineID% = 0 if NO network, else -1

DEF FNEquipment%
    Interrupt &H11, Registers       'Int 11 devoted to equip check
    'The rest is checking the 12 bits of AX by masking
    PPorts = PDQShr%(Registers.AX AND &HC000, 14)
    SPorts = (Registers.AX AND &HE00) \ 512
    Floppies = (Registers.AX AND &HC0) \ 64 + 1
    VMode = (Registers.AX AND &H30) \ 16
    CPros = (Registers.AX AND 2) \ 2
    Game = (Registers.AX AND &H1000) \ 4096
END DEF

DEF FNBaseRAM%                          'Using BIOS returns in K
    Interrupt &H12, Registers           'Int 12 devoted
    FNBaseRAM% = Registers.AX           'Set the function, easy!
END DEF

DEF FnExtended%
'   Registers.AX = &H8800               'Service 88h in AH, 0 in AL
'   Interrupt &H15, Registers           'Returns a negative number for none
'   IF Registers.AX > 0 THEN            '! This code doesn't work, despite
'      FNExtended% = Registers.AX       '! what every technical manual says!
'   ELSE                                '! The code below does work; it reads
'      FNExtended% = 0                  '! the memory past 1mb from CMOS RAM.
'   END IF
    FnExtended% = 0                     'assume no extended memory
    IF GetCPU% >= 286 THEN              'we need at least a '286 to do this
       OUT 112, 23                      'ask for the value at CMOS address 23
       LoByte = INP(113)                'read that value
       OUT 112, 24                      'now get the high byte at address 24
       HiByte = INP(113)
       FnExtended% = LoByte + 256 * HiByte  'multiply to get total K
    END IF
END DEF

DEF FNPSPAddr&                          'This is stored in PDQ but can't get
    Registers.AX = &H6200               'it w/o assembler
    Interrupt &H21, Registers           'This is basically the address of
    FNPSPAddr& = Registers.BX           'your program in memory
END DEF

DEF FNFreeRAM&                          'Available memory not counting us
    PSP& = FNPSPAddr&                   'Where are we?
    Interrupt &H12, Registers           'Total Memory in KBytes
    MemSize& = Registers.AX * 64&       'Adjust to PSP units, subtract SYSINFO
    FNFreeRAM& = ((MemSize& - PSP& + 1&) * 16&) \ 1000
END DEF


DEF FNGetDrive%                          'A=0, B=1, etc.
    Registers.AX = &H1900                'DOS Service for getting default
    Interrupt &H21, Registers            'Result in AL
    FNGetDrive% = Registers.AX AND 255
END DEF

DEF FNSetDrive% (Drive)                 'This one has no errors
    Registers.AX = &HE00                'Service for set-drive
    Registers.DX = Drive                'Drive in DL
    Interrupt &H21, Registers
END DEF

DEF FNDriveInfo% (Drive)            'This one has error checking, yeah!
    FNDriveInfo% = 0                'Assume drive OK
    Registers.AX = &H3600           'Drive info service
    Registers.DX = Drive + 1        '0 here means default drive! (A=1, etc.)
    Interrupt &H21, Registers
    ClusterSize& = Registers.AX * Registers.CX
    TotalBytes& = Registers.DX * ClusterSize&       'These are the important
    FreeBytes& = Registers.BX * ClusterSize&        '  values
    IF Registers.AX = &HFFFF THEN FNDriveInfo% = -1 'Oops -- bad drive!
END DEF

DEF FNValidDrv% (Drive)
    SaveDrive = FNGetDrive%             'first save the current drive
    Dummy = FNSetDrive(Drive)           'now try to set the specified one
    IF FNGetDrive% = Drive THEN         'did it take?
       FNValidDrv% = -1                 'yes
    ELSE
       FNValidDrv% = 0                  'no
    END IF
    Dummy = FNSetDrive%(SaveDrive)      'restore the original in any case
END DEF

DEF FNRemovable% (Drive)                'Floppy drives, Bernoulli's etc.
    Registers.AX = &H4408               'Changeable block service
    Registers.BX = Drive + 1            'Again, 0 here means default!
    Interrupt &H21, Registers
    FNRemovable% = Registers.AX - 1     '-1 for Removable, 0 for not
END DEF

DEF FNRemote% (Drive)                   'Redirected network drive
    FNRemote% = 0                       'Assume it's local
    Registers.AX = &H4409               'Service 44 in AH, function 9 in AL
    Registers.BX = Drive + 1            '0 here again means default drive
    Interrupt &H21, Registers
    IF Registers.DX AND 4096 THEN       'DX contains the info in bit 12
      FNRemote% = -1
    END IF
END DEF

DEF FNMachineID%                        'For networks
    FNMachineID% = -1                   'Assume existence of NETBIOS
    DIM MName AS STRING * 16            'Will hold Machine Name
    Registers.AX = &H5E00               'Service 5Eh, function 0
    Registers.DX = VARPTR(MName)        'Point to our receptacle
    Interrupt &H21, Registers
    IF Registers.Flags AND 1 THEN       'Carry flag means no NETBIOS
       LSET MName = "N/A"               'Set some answers and bail
       MNumber = 0
       FNMachineID% = 0
       EXIT DEF
    END IF
    CH = Registers.CX \ 256             'check CH to see if named
    IF CH = 0 THEN                      'NETBIOS present but this one
       LSET MName = "Un-named"          '  is in left field, bail again
       MNumber = 0
       EXIT DEF
    END IF
    MNumber = Registers.CX AND 255      'If we make it here set the number
                                        'MName is already set
END DEF

'+++++++++++++++++++++++ End of Function Code +++++++++++++++++++++++++++++++

'*********************** Start of Program Code ******************************

'Get ego requirements out of the way first...

CLS
PRINT SPC(22); "SysInfo! (c) 1990 User Friendly, Inc."
PRINT SPC(18); "อออออออออออออออออออออออออออออออออออออออออออออ"
PRINT
PRINT "   DOS Version: "; Dollar$(CLNG(DOSVer%))    'Neat huh?

'Get Installed Equipment
LOCATE 4, 46
PRINT "CPU Installed: 80"; LTRIM$(STR$(GetCPU%))
Dummy = FNEquipment%
PRINT "Parallel Ports:"; PPorts
PRINT "  Serial Ports:"; SPorts
PRINT " Floppy Drives:"; Floppies

LOCATE 5, 38
PRINT "Coprocessor Installed: ";
IF CPros THEN PRINT "Yes" ELSE PRINT "No"   '1 = installed, 0=not

LOCATE 6, 40
PRINT "Game port Installed: ";
IF Game THEN PRINT "Yes" ELSE PRINT "No"    'Ditto

LOCATE 7, 46
PRINT "Initial Video: ";
SELECT CASE VMode                           'The values returned by the func
   CASE 1
     PRINT "40x25, text, color"
   CASE 2
     PRINT "80x25, text, color"
   CASE 3
     PRINT "80x25, text, mono"
   CASE ELSE
     PRINT
END SELECT
PRINT

TotalMemory = FNBaseRAM%
PRINT "Total K Base Memory:"; TotalMemory

RamFree& = FNFreeRAM&
PRINT "   Available Memory:"; RamFree&

ExtendedMem = FnExtended%
PRINT "   Total K Extended:"; ExtendedMem
PRINT


'Drive statistics
DefDrive = FNGetDrive%                        'Get default drive number
CurDrive$ = CHR$(DefDrive + 65)               'Convert to uppercase letter
PRINT "   Current Drive: "; CurDrive$

PRINT "Available drives: ";
FOR X = 0 TO 25                               'print all valid drive letters
    IF FNValidDrv%(X) THEN PRINT CHR$(X + 65); SPC(1);
NEXT
PRINT
IF DOSVer% >= 310 THEN                        'this test requires DOS 3.10
  PRINT "* = remote drive: ";
  FOR X = 0 TO 25                             'print all valid drive letters
    IF FNValidDrv%(X) THEN
      IF FNRemote%(X) THEN
        PRINT "* ";
      ELSE
        PRINT "  ";
      END IF
    END IF
  NEXT
  PRINT
END IF
PRINT

SDrive$ = UCASE$(COMMAND$)                    'What drive do we want to test
IF SDrive$ = "" THEN NoDrive = -1 ELSE NoDrive = 0
IF NoDrive THEN SDrive$ = CurDrive$           'No choice? Use default drive
PRINT "  Selected Drive: "; SDrive$;
IF NoDrive THEN PRINT " (Default, you may designate a drive on the command line.)";
PRINT

Selected = ASC(SDrive$) - 65                  'Convert back to a number
Errer = FNDriveInfo%(Selected)                'love my spelling?
IF Errer THEN
   PRINT "     Invalid Drive Specification!"
   END
END IF
PRINT "Total Disk Space:"; TotalBytes&
PRINT " Free Disk Space:"; FreeBytes&

PRINT "       Removable: ";
Remove = FNRemovable%(Selected)               'Can we take it with us?
IF Remove THEN PRINT "Yes" ELSE PRINT "No"

PRINT "          Remote: ";                   'Is it in our machine?
Remote = FNRemote(Selected)
IF Remote THEN PRINT "Yes" ELSE PRINT "No"
PRINT

Network = FNMachineID%
'Even if there is NETBIOS, the machine may not be named for some reason
PRINT "Network Station Name: "; RTRIM$(MName);
'IF Network THEN                              'You may want this conditional
   LOCATE CSRLIN, 40
   PRINT "Station Number: "; MNumber
'END IF

