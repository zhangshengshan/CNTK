:: Copyright (c) Microsoft. All rights reserved.
:: Licensed under the MIT license. See LICENSE.md file in the project root for full license information.

@echo off
setlocal

set USAGE=Usage: ^
Set %%CNTK_EXTERNAL_TESTDATA_SOURCE_DIRECTORY%% for local destination, ^
and (optionally) %%CNTK_EXTERNAL_TESTDATA_REMOTE_DIRECTORY%% for remote source.

if not "%~1" == "" echo Error: This script doesn't take any explicit parameters.&echo %USAGE%&exit /b1

if defined CNTK_EXTERNAL_TESTDATA_SOURCE_DIRECTORY if exist "%CNTK_EXTERNAL_TESTDATA_SOURCE_DIRECTORY%" goto :continue

echo Error: %%CNTK_EXTERNAL_TESTDATA_SOURCE_DIRECTORY%% must point to a local directory to mirror to (absolute path)

:continue

set IMPLICIT_REMOTE=
if not defined CNTK_EXTERNAL_TESTDATA_REMOTE_DIRECTORY set CNTK_EXTERNAL_TESTDATA_REMOTE_DIRECTORY=%~dp0&set IMPLICIT_REMOTE=1
set REMOTEDIR=%CNTK_EXTERNAL_TESTDATA_REMOTE_DIRECTORY%

@REM Cut any trailing backslash
if "%REMOTEDIR:~-1%" == "\" set REMOTEDIR=%REMOTEDIR:~0,-1%

set LOCALDIR=%CNTK_EXTERNAL_TESTDATA_SOURCE_DIRECTORY%
set VERSIONFILE=VERSION

set REMOTEVERSIONPATH=%REMOTEDIR%\%VERSIONFILE%
set LOCALVERSIONPATH=%LOCALDIR%\%VERSIONFILE%

set REMOTEVERSION=-1
if exist "%REMOTEVERSIONPATH%" for /f %%i in ('type "%REMOTEVERSIONPATH%"') do set REMOTEVERSION=%%~i
if "%REMOTEVERSION%" == "-1" if defined IMPLICIT_REMOTE echo Error: implicit remote must have a version, not continuing.&echo %USAGE%&exit /b 1
echo Remote version is %REMOTEVERSION%.

set LOCALVERSION=-1
if exist "%LOCALVERSIONPATH%" for /f %%i in ('type "%LOCALVERSIONPATH%"') do set LOCALVERSION=%%~i
echo Local version is %LOCALVERSION%.

if %REMOTEVERSION% EQU %LOCALVERSION% echo Remote version is equal ^(nothing to do, or neither local nor remote available^)
if %REMOTEVERSION% LSS %LOCALVERSION% (
  echo Remote version is less ^(likely remote is not available^).
)

@REM TODO use to just updated timestamps (will remove): robocopy "%REMOTEDIR%" "%LOCALDIR%" /e /timfix /r:2 /w:60 /fft /xj /z /xf VERSION /a-:R /np /xn /xo
if %REMOTEVERSION% GTR %LOCALVERSION% (
  echo Remote version is greater ^(must copy^)
  @REM Remove local VERSION file and only re-add in case of success.
  if exist "%LOCALVERSIONPATH%" del "%LOCALVERSIONPATH%"
  robocopy "%REMOTEDIR%" "%LOCALDIR%" /mir /r:2 /w:60 /fft /xj /z /xf VERSION /np
  if not errorlevel 8 echo Successful robocopy, copying version&copy "%REMOTEVERSIONPATH%" "%LOCALVERSIONPATH%"
)

set LOCALVERSION=-1
if exist "%LOCALVERSIONPATH%" for /f %%i in ('type "%LOCALVERSIONPATH%"') do set LOCALVERSION=%%i

if "%LOCALVERSION%" == "-1" echo We do not have local ^(or remote^) data, error.&exit /b 1
echo Working with local version %LOCALVERSION%.
