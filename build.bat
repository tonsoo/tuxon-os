@echo off
setlocal EnableDelayedExpansion

REM Exit immediately if a command exits with a non-zero status.
REM In batch, this is often handled by checking ERRORLEVEL after each command.

echo Building Docker image...
docker build -t tuxon-os .
IF %ERRORLEVEL% NEQ 0 (
    echo Docker build failed!
    exit /b %ERRORLEVEL%
)

echo Creating output directory...
REM Use /s and /q to suppress prompts if output directory already exists
mkdir output >NUL 2>NUL
REM Check if mkdir command failed (e.g., due to permissions)
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to create output directory!
    exit /b %ERRORLEVEL%
)

echo Running Docker container...
docker run --rm ^
  -v "%CD%\output:/output" ^
  tuxon-os bash ./inner-build.sh
IF %ERRORLEVEL% NEQ 0 (
    echo Docker run failed!
    exit /b %ERRORLEVEL%
)

echo ✅ Build process completed successfully!
endlocal