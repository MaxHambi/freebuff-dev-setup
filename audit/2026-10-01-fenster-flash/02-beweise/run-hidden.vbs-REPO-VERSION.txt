' run-hidden.vbs - startet ein PowerShell-Skript gaenzlich ohne sichtbares Fenster.
' Wrapper-Fix (2026-10-01): Es werden ALLE Argumente (1..n) angehaengt und
' gequoted weitergereicht. Vorher ging nur WScript.Arguments(0) durch, sodass
' Flags wie der bindende "-Apply" des Watchdog-Tasks verloren gingen.
'
' Aufruf: wscript.exe //B //Nologo run-hidden.vbs "<skript.ps1>" [weitere Argumente]
'
' Warum wscript und nicht direkt powershell.exe: PowerShell ist eine
' Konsolenanwendung; Windows erzeugt das conhost-Fenster bevor der Schalter
' -WindowStyle Hidden verarbeitet wird (sichtbarer Flash bei Scheduled Tasks).
' WScript.Shell.Run mit 0 = SW_HIDE startet den Kindprozess ab dem ersten
' Befehl ohne Fenster. Das Original lag als Vorlage in der Runtime unter
' %USERPROFILE%\.tools\maintenance\ und wird jetzt im Repo gepflegt.
Option Explicit
Dim sh, cmd, i
If WScript.Arguments.Count < 1 Then WScript.Quit 1
Set sh = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & WScript.Arguments(0) & """"
For i = 1 To WScript.Arguments.Count - 1
	cmd = cmd & " """ & WScript.Arguments(i) & """"
Next
' 0 = SW_HIDE (kein Fenster ab Prozessstart), True = warten (Task bleibt
' "Running" solange das Skript laeuft; ExecutionTimeLimit des Tasks greift).
sh.Run cmd, 0, True
