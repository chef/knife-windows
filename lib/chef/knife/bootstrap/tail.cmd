@echo off
set shown=0
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