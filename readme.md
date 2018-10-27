On October 26th, 2018 I purchased the software assets of Full Moon Software.
Full Moon Software used to be known as Crescent Software.  They produced a line
of excellent development libraries for MS-DOS.  The supported environments were
QuickBASIC 4.x, Microsoft Professional Development System v7.x, and Visual 
Basic for DOS.

The idea behind obtaining these products was to release them to the public
domain to ensure that people could still access these things in the future.
While most developers will have no use for these products in a modern 
develoment environment, they still have value as an example of "how it was 
done" back in the heyday of x86 DOS development. 

The software in this repository hasn't been modified from how I received it 
from Ethan Winer, the original author.  While all the source files carry some 
kind of Copyright notice, the software is now in the public domain.

The contents of the installation floppies will be uploaded to the Internet
Archive soon and when the manuals are scanned, they'll be uploaded there
as well.  I'll update this readme file with a link to the manual scan when
it's available.

The original distribution disk files are available here:

http://annex.retroarchive.org/crescent/PDQDISK.ZIP


Gene Buckle, October 27th, 2018

I've attached the text from Full Moon Software's catalog description of 
P.D.Q. below.

-------------------------------------------------------------------------------
P.D.Q.(tm)
==========

A Revolutionary Concept in High-Level Languages
-----------------------------------------------

No one would dispute the value of a program that is small and fast. Compiler 
vendors, such as Microsoft(r) and Borland(r), are constantly refining their 
products to improve the performance and size of your programs. Unfortunately, 
no high-level language even comes close to creating programs as efficient as 
those written in assembly language. That is, until now.
     This remarkable library lets you write programs that are extremely fast 
and compact, using a high-level language you already know. Unlike C, Pascal, 
or regular compiled BASIC, P.D.Q. can produce a "Hello world" program with a 
stand-alone .EXE file size of less than 900 bytes. Real programs that perform 
useful tasks may be written in less than 2,000 bytes. For example, P.D.Q. 
includes a sample setup program for Epson(r) printers with an .EXE file size 
of 1,900 bytes. Programs produced by P.D.Q. are typically half the size of an 
equivalent written in C. P.D.Q. is truly the closest you'll get to a pure 
assembler program, but without having to code in assembly language.
     The primary purpose of P.D.Q. is for writing small to medium-sized 
applications, where program size and execution speed are critical. A wealth of 
string, DOS, and BIOS services are provided, along with full support for 
modern programming constructs. Best of all, TSR programming and interrupt 
handling are built into the P.D.Q. library. You can create complete memory-
resident applications in just minutes, instead of days or even weeks. TSR 
capabilities are added by using four simple subroutine calls. The P.D.Q. 
routines then handle all the details of memory allocation, the DOS "busy 
flag," deinstallation, and so forth. A P.D.Q. program can even intercept 
multiple interrupts if needed, with separate program entry points for each. 
Without doubt, P.D.Q. is the most exciting concept in high-level languages to 
come along in years.

AS EASY AS BASIC

P.D.Q. is a replacement linking library for use with Microsoft's QuickBASIC, 
PDS, and VB/DOS compilers. You simply compile your programs with BC.EXE as 
usual and then link it with the P.D.Q. library file. By completely rewriting 
the BASIC language library, we were able to greatly improve the efficiency of 
the resultant code. All of the "hand-holding" BASIC normally adds to every 
program has been removed, leaving only the essential elements. Therefore, you 
can be productive immediately, without having to struggle to learn a new 
language.
     We also overhauled BASIC's convoluted method of handling DOS errors. 
Where conventional BASIC requires you to first define an error handler and 
then set up an ON ERROR trap to jump there, P.D.Q. lets you simply test the 
success or failure of the most recent DOS operation, as this short program 
fragment illustrates:

     OPEN "ACCOUNTS.DAT" FOR INPUT AS #1
     IF ERR = 53 THEN PRINT "Sorry, file not found."

THE SPIRIT OF PERFORMANCE

Our goal in designing P.D.Q. was to place code size and execution speed above 
all other considerations. Many programmers mistakenly believe that compiled 
languages are inherently large and slow, but nothing could be further from the 
truth. In many cases, Microsoft's BASIC compilers generate object code as 
efficient as a human hand-coding in assembly language. The real difficulty 
with most compilers is the way their language libraries are implemented. By 
taking an entirely new approach to language design, P.D.Q. can create programs 
that are nearly as small and fast as those written in assembly language.
     Like most compilers, Microsoft BASIC translates simple program statements 
directly to the equivalent machine-code. For example, X% = X% + 1 is compiled 
by BASIC to INC WORD PTR [X%]. However, more complex commands, such as OPEN, 
MID$, and CLS, generate calls to the BASIC language library. And that's where 
P.D.Q. comes in. All of the BASIC language routines in the P.D.Q. library are 
extremely efficient and have been optimized to the fewest number of bytes and 
machine clock cycles.

BUT ISN'T THAT WHAT C IS FOR?

One of the promises of C was to provide smaller and faster programs, in 
exchange for additional programming effort. If you were willing to step down 
to a lower level language, nearer to assembler, the compiler would reciprocate 
by generating a more efficient program. But this simply isn't true--current C 
compilers offer little if any improvement over compiled BASIC. In fact, 
compared to P.D.Q. C is just another slow and bloated high-level language! 
Further, many people will agree that C programs are notoriously difficult to 
write, and even harder to debug. By contrast, P.D.Q. is as easy as BASIC 
because it is BASIC, while providing a level of performance clearly superior 
to C. And everyone knows that performance is what programming is all about.

HOW WE DID IT

In order to achieve such impressive file sizes and high performance, we did 
have to make some compromises. Many of BASIC's advanced math and graphics 
statements are not supported, and in some cases a slight amount of additional 
programming effort is required. However, all of BASIC's powerful string 
handling features are available, and dozens of useful language extensions are 
also provided. In all, 165 BASIC statements and keywords are supported. Please 
remember that P.D.Q. is intended mainly as an alternative to writing in 
assembly language, and as such it is extremely powerful and easy to use.
     Even without BASIC's most advanced features, many useful and varied 
programs may be written using P.D.Q. These include DOS utilities, TSR printer 
drivers, pop-up calculators and help programs, DOS shells, screen capture 
utilities, and Install programs. Many such examples are included with P.D.Q. 
along with full source code.

SEEING IS BELIEVING

The benchmark timings below were made on a 386-25 computer but slowed down to 
8 MHz. to obtain repeatable results. A RAM disk was used for the read/write 
timings. All file sizes are in bytes, and all times are in seconds.
     The NumOff utility turns the NumLock key off, and the Hello program 
simply prints "Hello"--these show the effective minimum program size for each 
language system. Note that the P.D.Q. Hello program includes the entire 
dynamic string management portion of the runtime library. The DOS filter 
program accepts input from STDIN, capitalizes it and strips the high bit from 
each character, and sends the result through STDOUT.
     The Epson Setup program is a menu-driven utility that sends escape codes 
for various printer settings. The TSR version can be popped up over any text-
mode program, and it saves and restores the underlying screen. Finally, the 
.EXE file size program is a clone of Peter Norton's 9k original FS.COM 
utility. It reads all files whose names match a given specification, adds up 
their sizes, and also verifies if they will fit onto a selected target drive. 
Like Norton's, our version also takes the target cluster size into account 
when determining if the files will fit.
     For the long integer multiply test, 150 multiplications were performed in 
a loop 1,000 times. Please note that the Turbo C programs were compiled using 
the Small Model, which produces .COM files. Also note that we have optimized 
long integer operations for size rather than speed. Finally, a bug in the sort 
routine provided with QuickC is responsible for its poor showing in that 
category.

  +--------------------------------------------------------------------------+
  |                       .EXE FILE SIZE COMPARISONS                         |
  |                      P.D.Q.     QC 2.0     TC 2.0     TP 5.5     QB 4.5  |
  |                      ------     ------     ------     ------     ------  |
  | NumOff Utility          418      2,371        990      2,845     10,325  |
  | Hello Program           754      5,363      3,958      3,260     12,798  |
  | DOS Filter            1,482      5,345      4,970      3,443     19,523  |
  | Epson Setup           2,228      7,837      8,030      8,014     35,877  |
  | TSR Epson Setup       4,800       n/a        n/a        n/a        n/a   |
  | File Size Program     4,956     10,537      7,814      8,809     19,650  |
  |                                                                          |
  |    Of all the popular language compilers, P.D.Q. clearly provides the    |
  |    smallest .EXE file sizes.                                             |
  +--------------------------------------------------------------------------+


  +--------------------------------------------------------------------------+
  |                           TIMING COMPARISONS                             |
  |                              P.D.Q.   QC 2.0   TC 2.0   TP 5.5   QB 4.5  |
  |                              ------   ------   ------   ------   ------  |
  | Long Integer Multiply         2.64      2.31     2.25     7.52     3.02  |
  | Long Integer Multiply (386)   2.20      2.31     2.25     7.52     3.02  |
  | Sort 3,000 10-byte Strings    0.60    144.89     1.54     0.99     1.92  |
  | Print 3,000 70-byte Strings   0.88      1.15     1.04     3.52     2.04  |
  | Write 500 80-byte Records     0.33      0.33     0.66     0.44     0.38  |
  | Read 500 80-byte Records      0.27      0.27     0.27     0.49     0.28  |
  |                                                                          |
  |    As you can see, P.D.Q. is more than competitive with the fastest      |
  |    language compilers.                                                   |
  +--------------------------------------------------------------------------+


WHAT'S INCLUDED

P.D.Q. is supplied as two library files--PDQ.LIB is intended for use with any 
IBM PC or compatible computer, and PDQ386.LIB is a 386-specific version for 
use with 386 or later processors.
     Dozens of useful language extensions are provided, including memory 
allocation; DOS critical error trapping; block memory moves; a string array 
sort; a complete set of TSR extensions with optional swapping to EMS or disk; 
output through STDERR; access to the parent environment, and much more. Many 
examples and complete utilities are included, as well as a comprehensive 
owner's manual. The manual documents every BASIC internal routine and shows 
how to use P.D.Q. as a toolbox for use with assembly language. This remarkable 
product has revolutionized BASIC programming and has received countless 
outstanding reviews. The original 1.0 version was awarded Byte Magazine's User 
Choice Award for language of the year in 1990.
     As with all our products, full source code is provided at no additional 
cost, so you can see how the routines were designed and even modify them if 
you want. We genuinely want you to understand how our libraries work and be 
able to learn from them. All of our products are reasonably priced and include 
free technical assistance, but they are licensed for use by only one person 
using one computer at a time. Royalty payments are not required when our 
routines are incorporated into your compiled applications. However, you may 
not distribute our source, object, or library files. If your customers need to 
rebuild your program, they will need their own copy of our product(s).

     "The talk of the programming community...is P.D.Q. Hot stuff for sure."
     --John Dvorak, PC Magazine, 11/89

     "Every BASIC programmer ought to have P.D.Q.--the speed and code size
     will amaze you." --Jerry Pournelle, Byte Magazine, 2/90

     "If you want your programs to look like they were coded in assembly
     language, or if you want to learn about BASIC's innards, you'll find
     P.D.Q. a useful and powerful addition to your toolbox." --Phil Weber,
     BASICPro Magazine, 4/93

     "I feel sure the approach taken [in P.D.Q.] is the approach the whole
     industry will follow in the future." --Bruce Tonkin, Dr. Dobb's Journal,
     12/89

     "The combination of TSR ability and small code makes P.D.Q. a contender
     for language development of choice." --Jeff Angus, Computer Language,
     12/89

     "I think P.D.Q. will likely become one of the best selling add-ons of all
     time." --Jim Pyle, PCM Magazine, 2/90

     "You can write TSR code without having to worry about the technicalities.
     I like P.D.Q." --Hardin Brothers, PC Resource, 3/90

THE BOTTOM LINE

P.D.Q. costs only $149 and works with QuickBASIC 4.x, PDS 7.x, and VB/DOS. Add 
$8 for UPS ground shipping to US addresses only (no P.O. boxes); Connecticut 
residents must add 6.0% sales tax or show proof of tax-exempt status when 
ordering. Please call us for overnight and foreign shipping costs. We accept 
checks, MasterCard, and VISA. We do accept purchase orders, but they must be 
accompanied by full payment.

P.D.Q.(tm) is a trademark of Crescent Software, Inc.
