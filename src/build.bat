@echo off
ca65 -t apple2 -o dee.o dee.s
if errorlevel 1 exit /b 1

ld65 -C dee.cfg -o DEE.SYSTEM dee.o
if errorlevel 1 exit /b 1