@if "%1"=="" goto Help

@if "%2"=="" goto NoOpts
@if "%2"=="/" goto CodeView
@if "%2"=="s" goto SmallDOS

:CodeView
masm %1 /zi;
link /noe/co %1 startup , , nul , \pdq\pdq;
cv %1
@goto Done

:SmallDOS
masm %1;
link /ex/noe/far/packc %1 startup , , nul , \pdq\smalldos \pdq\pdq;
exe2com %1
@goto Done

:NoOpts
masm %1;
link /ex/noe/far/packc %1 startup , , nul , \pdq\pdq;
@goto Done

:Help
@echo Enter the name of the file to assemble and link, followed by an
@echo Optional "action" parameter.  Using "/" for the action tells this
@echo batch file to assemble and link for CodeView, and then run
@echo CodeView.  Using "s" means to link with SMALLDOS.LIB and also
@echo create a "packed file" and run EXE2COM.  The following example
@echo shows how to assemble ASK.ASM with SMALLDOS:
@echo ÿ
@echo      c ask s

:Done
