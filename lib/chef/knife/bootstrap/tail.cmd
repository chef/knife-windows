@echo off
set shown=0
REM This next line switches the codepage to prevent running into a 'Out of memory' bug
REM in more.com on  Windows 2008 (and maybe newer) systems.
chcp 437 > nul 2>&1
:tail
if NOT EXIST "%1" (
  IF NOT %shown%==0 goto :eof
  goto tail
)
for /f "tokens=1 delims=*" %%l in ('findstr /R /V "^$" %1 ^| more +%shown%') DO (
  echo %%l
  set /A shown=shown+1
)
goto tail