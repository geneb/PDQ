rem This is a sample batch file for testing the P.D.Q. ASK utility
echo off
echo 1) Lotus 123
echo 2) dBASE IV
echo 3) WordPerfect
echo 4) QuickBASIC
echo ÿ
Ask  Enter your selection: 
IF ERRORLEVEL 4 QB /L
IF ERRORLEVEL 3 WP
IF ERRORLEVEL 2 dBASE
IF ERRORLEVEL 1 123
