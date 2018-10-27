rem This is a sample batch file for creating swapping TSR programs
bc %1 /o;
link /ex/nod/noe/seg:250 popswap %1 %2 %3 _noval _noread _noerror,, nul, pdq;
del %1.obj
