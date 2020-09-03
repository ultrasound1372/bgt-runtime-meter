; MIT License
; 
; Copyright (c) 2019 Colton Hill
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

#pragma compile(FileDescription, A program to detect and log bgt runtime errors)
#include "process.au3"
#include <WinAPIProc.au3>
#include <date.au3>
$program="bgt.exe"
if FileExists("rmprogram.txt") then
$fhp=FileOpen("rmprogram.txt",0)
$program=FileRead($fhp)
FileClose($fhp)
beep(2000,50)
endif
;Runtime meter initialized. Now begin probing.
While 1
if WinExists("BGT Runtime Error")==1 then
;we've found a runtime error. Let's get the window handle and try to read the error text.
$wh=winGetHandle("BGT Runtime Error")
beep(500,500)
WinActivate($wh)
$thing=ControlGetText($wh,"",65535)
if $thing="" then
$thing=WinGetText($wh)
EndIf
;get the process location
$PID=WinGetProcess($wh)
$APIPATH = _WinAPI_EnumProcessModules ($PID)
$PName = _ProcessGetName ($PID)
$FullPath = _ProcessGetLocation($PID)
$Test = StringReplace ($FullPath,$PName,"")
$folder = StringTrimRight ($Test,1)
if $FullPath <> "" then
$program=$FullPath
EndIf
;if the location check worked, we now have the path of an executable to be rerun.
$ShouldClip=0
if ControlCommand($wh,"",6,"IsEnabled")=1 then
;this is a yes/no dialog, click yes to copy the stack trace.
ControlClick($wh,"",6)
$ShouldClip=1
ElseIf ControlCommand($wh,"",2,"IsEnabled")=1 then
;this is a special runtime error with an okay button, no stack trace available.
ControlClick($wh,"",2)
else
;don't know what this is, just kill it.
ProcessClose($PID)
EndIf
sleep(500) ;give it time to exit fully and copy the stack trace if it was going to do that.
$thing1="no stack trace available"
if $ShouldClip <> 0 then
$thing1=ClipGet()
EndIf
;log the error. Append to the end of runtimes.txt, overwrite latest_runtime.txt
$fh=FileOpen($folder&"/runtimes.txt",1)
FileWrite($fh,_now()&@crlf&$PName&@crlf&$thing&@crlf&$thing1&@crlf)
FileClose($fh)
$fh=FileOpen($folder&"/latest_runtime.txt",2)
FileWrite($fh,_now()&@crlf&$PName&@crlf&$thing&@crlf&$thing1&@crlf)
FileClose($fh)
beep(1000,100)
if FileExists($folder&"/runtime_notify.exe") then
run($folder&"/runtime_notify.exe")
EndIf
run($program)
beep(1500,100)
EndIf
sleep(200)
WEnd
;found this handy function on the autoit forums
Func _ProcessGetLocation($iPID)
Local $aProc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', BitOR(0x0400, 0x0010), 'int', 0, 'int', $iPID)
If $aProc[0] = 0 Then Return SetError(1, 0, '')
Local $vStruct = DllStructCreate('int[1024]')
DllCall('psapi.dll', 'int', 'EnumProcessModules', 'hwnd', $aProc[0], 'ptr', DllStructGetPtr($vStruct), 'int', DllStructGetSize($vStruct), 'int_ptr', 0)
Local $aReturn = DllCall('psapi.dll', 'int', 'GetModuleFileNameEx', 'hwnd', $aProc[0], 'int', DllStructGetData($vStruct, 1), 'str', '', 'int', 2048)
If StringLen($aReturn[3]) = 0 Then Return SetError(2, 0, '')
Return $aReturn[3]
EndFunc