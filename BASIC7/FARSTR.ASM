;String Info  - returns length, segment and address of Far strings
;      saving all trashed registers
;Copyright (c) 1989 Crescent Software
;written by Jay Munro
;
;Usage -  Call StringInfo
;               Input
;               DS:SI = local address for string descriptor
;
;               Output
;               AX = offset of string data
;               DX = segment of string data
;               CX = length of string data
;

.Model Medium,BASIC
     Extrn  StringAssign:proc
     Extrn  StringAddress:Proc     ;BC 7's routines to get far strings info
     Extrn  StringLength:Proc      ;  supplied by Microsoft

.Data
        Public NullSpace
        NullSpace DW ?
        
.Code

StringInfo Proc

      Push SI                 ;save these regs
      Push DI                 ;
      Push BX                 ;
      Push ES                 ;
      Pushf                   ; and flags too

      Push ES                 ;save ES again since we need it up ahead
      Push SI                 ;push incoming string descriptor address
      Call StringAddress      ;call to get address

      Pop  ES                 ;retrieve ES for next call to StringLength
      Push AX                 ;save offset returned from StringAddress
      Push DX                 ;  and segment returned from StringAddress

      Push SI                 ;push incoming string descriptor address
      Call StringLength       ;now go for the length
      Mov  CX,AX              ;LEN(string) is in AX, so put it into CX
                              ;  to return
      Pop  DX                 ;get back saved segment
      Pop  AX                 ;and address

      Popf                    ;retrieve flags and saved registers
      Pop  ES
      Pop  BX
      Pop  DI
      Pop  SI

Exit:
      Ret                     ;and return

StringInfo EndP


;MakeString
;Makes a string descriptor for qbx

Comment / Expects :
 Incoming registers
    DX = Segment of source Data
    AX = Offset of source Data
    CX = Length of source Data
    DS = Segment of destination (string descriptor)
    DI = Offset of destination
    BX = Length of destination (0 for variable-length string)

  Outgoing registers
    DS:[DI] is filled in with string descriptor
/


MakeString Proc Uses DS ES
     ;Check for null
     Jcxz    NullStringAssign ;trap for zero length string 5/1991 JM
     Push    DX              ;push segment of source string
     Push    AX              ;push offset of source string

DoString:
     Push    CX              ;push length if fixed-length
     Push    DS              ;push segment of destination for descriptor
     Push    DI              ;push offset of destination for descriptor
     Push    BX              ;push length of destination
     Call    Stringassign    ;go assign string
     Ret

NullStringAssign:
    Push    SS               ;in case DS is pointing somewhere else...
    Lea     AX,NullSpace
    Push    AX
    Jmp     Short DoString


MakeString  EndP
End
