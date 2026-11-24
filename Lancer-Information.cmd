@echo off
setlocal

rem Reduction de la fenetre de commande (marche meme si lancee hors raccourci).
rem GetConsoleWindow() renvoie le vrai handle de la fenetre console (MainWindowHandle
rem d'un process console vaut 0, d'ou l'usage de kernel32.GetConsoleWindow).
powershell -NoProfile -Command "$k=Add-Type -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();' -Name k -Namespace K -PassThru; $h=$k::GetConsoleWindow(); $w=Add-Type -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr h,int n);' -Name w -Namespace W -PassThru; $w::ShowWindow($h,2)" >nul 2>&1

rem BGInfo ouvre la popup (fenetre visible) sans bloquer ce lanceur.
start "" "%~dp0Bginfo64.exe" "%~dp0bginfo.bgi" /popup /NOLICPROMPT

rem Copie du rapport dans le presse-papiers (pendant que la popup est ouverte).
timeout /t 1 /nobreak >nul
powershell.exe -NoProfile -STA -File "%~dp0Copier-BGInfo.ps1"
if errorlevel 1 (
    echo Erreur : le rapport n'a pas pu etre copie dans le presse-papiers.
)

rem La fenetre se ferme automatiquement quand l'utilisateur ferme la popup BGInfo.
:waitbginfo
tasklist /fi "imagename eq Bginfo64.exe" | find /i "bginfo64.exe" >nul
if not errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto waitbginfo
)
exit /b 0
