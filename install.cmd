@echo off
setlocal
set "SRC=%~dp0"
set "DEST=C:\Program Files (x86)\Sysinternals\BGInfo"
set "DESKTOP=%PUBLIC%\Desktop"

if not exist "%DEST%" mkdir "%DEST%"

rem --- Fichiers BGInfo (32 et 64 bits) ---
xcopy "%SRC%Bginfo.exe"      "%DEST%\" /Y /I
xcopy "%SRC%Bginfo64.exe"    "%DEST%\" /Y /I

rem --- Lanceur de copie presse-papiers ---
xcopy "%SRC%Lancer-Information.cmd" "%DEST%\" /Y /I
xcopy "%SRC%Copier-BGInfo.ps1"      "%DEST%\" /Y /I

rem --- Icone (copiee a la fois dans DEST et a cote du raccourci) ---
xcopy "%SRC%Information-Session-Utilisateur.ico" "%DEST%\"    /Y /I
xcopy "%SRC%Information-Session-Utilisateur.ico" "%DESKTOP%\" /Y /I

rem --- Raccourci sur le Bureau public (icone en chemin absolu vers DEST) ---
xcopy "%SRC%Information Session Utilisateur.lnk" "%DESKTOP%\" /Y /I

rem --- Configuration registre ---
reg import "%SRC%bginforeg.reg"

endlocal
