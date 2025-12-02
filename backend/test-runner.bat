@echo off
echo Installing dependencies...
call npm install

echo.
echo Running tests...
call npm test

echo.
echo Tests completed!
pause
