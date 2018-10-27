;****** FLOATS.ASM - shows how to use floating point math in an .asm program

;Copyright (c) 1991 Ethan Winer


Comment |

About Floating Point Math:

Only a few added steps are needed to incorporate floating point math into a
purely assembly language program.  Because the P.D.Q. routines provide 8087
emulator services automatically, you will write floating point code as if you
were certain that an 8087 is installed in the target PC.

The first step is to call P$HookFP at the beginning of your program.  This
routine intercepts the floating point interrupts used by the emulator, using
the same methods as defined by Microsoft.  Thereafter you can freely employ
8087 instructions in your program.  Because the floating points interrupts
have been taken over, it is essential that you make a corresponding call to
P$UnhookFP before your program ends as shown herein.  Finally, you must use
the MASM /e (emulator) switch when assembling.  This tells MASM to identify
all of the places you used an 8087 instruction, so LINK will be able to patch
that code to equivalent interrupts.  If a coprocessor is being used, the code
is patched back to coprocessor instructions at run time.

There are two additional items worth noting:  If you are linking with the
_EMONLY.OBJ stub file or are certain that a coprocessor will not be present,
you do not need to use any Fwait instructions.  Similarly, if you are certain
that a coprocessor will be available you can skip the emulator and calls to
P$Hook/UnhookFP entirely.

One final issue is that you can actually learn how to write floating point
code by looking at what BASIC's BC.EXE compiler does.  For example, to learn
how to multiply two different numeric types, enter a one-line BASIC program
such as this:

    A! = A! * Y#

Then, compile it for CodeView and see what the instructions are.  Here, BASIC
creates this four-instruction sequence, and shows them as CodeView comments:

    FLD  DWORD PTR [A!]     ;load the double word A! to the internal FP stack
    FMUL QWORD PTR [Y#]     ;multiply the stack times the quad word Y#
    FSTP DWORD PTR [A!]     ;store the result to A! and pop the FP stack
    FWAIT                   ;wait until the 8087 is done before continuing

As you can see, all floating point commands begin with the letter "F".  Items
are loaded onto the stack using Fld, and the argument indicates the size and
type.  For example, Fld DWord Ptr [Var] implies that Var is a 4-byte single
precision variable.  Any legal addressing mode may be used, such as DWord Ptr
[BX] or QWord Ptr [BP-12] or a variable's name.  Segment overrides are also
allowable and handled correctly by the emulator.

You can load 2- and 4-byte integer values using the Fild instruction.  Fild
Word Ptr [Var] loads the regular integer Var onto the stack and converts it
to floating point form in the process.  Likewise, Fild DWord Ptr [Var] means
that Var is a long integer.  The "i" in Fild stands for integer.

Values are stored similarly, using the Fst and Fist (integer store) commands.
Finally, note the trailing "P" in the Fstp command as used in this program.
When values are loaded onto the floating point stack, they stay there until
removed explicitly.  If you load a value with Fld or Fild, you should be sure
to use Fstp or Fistp when you are done.  Fst and Fist also store the value,
but they leave it on the floating point stack.

Also note that you can easily convert a value from one form to another merely
by loading it as one type and storing it as another.  For example, to convert
the double precision variable Dbl to a long integer and store it in Lng, you
would use code like this:

    Fld   QWord Ptr [Dbl]       ;Dbl is defined in .Data
    Fistp DWord Ptr [Lng]       ;and so is Lng

If you look at the compiled code that BASIC creates, you will notice that it
calls a routine to perform the store operations.  However, you can just as
easily use Fst, Fist, Fstp, and Fistp, and they will be handled correctly.


Assembly Instructions:

To take advantage of the P.D.Q. floating point emulator, you must assemble
using the /e (emulator) option.  For the smallest size, assemble and link
this program as follows:

   masm floats /e;
   link /ex/noe/far/packc floats startup _noerror, , nul , pdq
   exe2com floats

|

.Model Medium
  Public Main               ;make the main public (must use the name Main)

  Extrn B$FVAL:Proc         ;extracts the VAL() of a string, in B$FVAL.ASM
  Extrn B$CEND:Proc         ;ends the program, in STARTUP.ASM
  Extrn B$PER8:Proc         ;prints a double precision value, in B$PER8.ASM
  Extrn B$PSSD:Proc         ;prints a string w/o CRLF, in PRINT.ASM
  Extrn P$HookFP:Proc       ;in P$HOOKFP.ASM (also see PDQ.ASM header)
  Extrn P$UnhookFP:Proc     ;in UNHOOKFP.ASM
  Extrn PDQInput:Proc       ;input a text string, in PDQINPUT.ASM

  Include MACROS.ASM        ;defines some useful assembly language macros

.Data?
  Output DQ 1 Dup (?)       ;the answer will go here

.Data
  DefStr Prompt$, "Enter a number: "
  DefStr Answer$, "The square of that number is "
  DefStr Number$

.Code

Main Proc

  Call P$HookFP             ;this is needed to enable floating point code

  Mov  AX,Offset Prompt$    ;print the prompt message
  Push AX                   ;pass that on to PRINT
  Call B$PSSD               ;print it without a terminating CRLF

  Mov  AX,Offset Number$    ;access the number in string form
  Push AX                   ;pass it on in advance for VAL below to save code
  Push AX                   ;pass it for PDQInput too now
  Call PDQInput             ;wait for input
  Call B$FVAL               ;convert Number$ to IEEE, pointer returned in AX

  Mov  BX,AX                ;now BX points to the 8-byte value of Number$
  Fld  QWord Ptr [BX]       ;load it onto the floating point stack
  Fmul QWord Ptr [BX]       ;multiply it by itself
  Fstp QWord Ptr [Output]   ;store the result in Output
  Fwait                     ;wait for the 8087 (if installed) to finish
  
  Mov  AX,Offset Answer$    ;print the answer message
  Push AX                   ;pass that on to PRINT
  Call B$PSSD               ;print it without a terminating CRLF

  Push Word Ptr Output+6    ;print the number
  Push Word Ptr Output+4    ;by passing its value on the stack
  Push Word Ptr Output+2
  Push Word Ptr Output
  Call B$PER8               ;PER8 = Print with End-of-line Real 8-byte
  
  Call P$UnhookFP           ;this is mandatory too to clean up
  Call B$CEND               ;bye for now

Main Endp
End
