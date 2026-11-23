@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-SadM1CompetenceLabel.ps1"
echo.
if errorlevel 1 echo A alteracao nao foi concluida. Copie a mensagem acima e envie no chat.
pause
