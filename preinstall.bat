echo "install apt for windows ..."
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" Set-ExecutionPolicy AllSigned
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" Set-ExecutionPolicy Bypass
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" "C:%HoMePath%\Downloads\LAMWAutoRunScripts-master\getMingw.ps1"
echo "please install mingw wizard"
C:\mingw-get-setup
echo "now installing basic Mingw "
C:\Mingw\bin\mingw-get update
C:\Mingw\bin\mingw-get install msys-wget-bin  mingw32-base-bin mingw-developer-toolkit-bin msys-base-bin msys-zip-bin --reinstall
SETX /M PATH "%PATH%;C:\MinGW\msys\1.0\bin"
pause