#RequireAdmin
#Include <NtProcess2.au3>
#Include <Misc.au3>

$RSSAimTraining = "RSS Aim Training.exe"

Global $dwPointerBase, $valX, $valY, $scanPtrBase, $Window_

$dwHandle = OpenProcess(0x1F0FFF, 0, ProcessExists($RSSAimTraining))
$dwBaseAddress = _MemoryModuleGetBaseAddress(ProcessExists($RSSAimTraining),$RSSAimTraining)
Global $hDLL = DllOpen("user32.dll")
$IsGameStarted = 0xC5764
$X = 0x58
$Y = 0x5C
$AimSpeed = 1
SetupMemory()


While 1
	If _IsPressed("43", $hDLL) Then ; C key
		If IsGameStarted() = 1 Then
			If WinExists("Default Game") Then ; Window calculation start
				$Window_ = "Default Game"
			ElseIf WinExists("Twitch Game") Then
				$Window_ = "Twitch Game"
			EndIf
			$wInfo = WinGetPos($Window_); Window calculation end
			MouseMove($wInfo[0] + GetX() + 23, $wInfo[1] + GetY() + 48, $AimSpeed); aiming to calculated window plus point
			;you can improve it if you want, i just wanted to show you basics
		EndIf
	EndIf
WEnd


Func SetupMemory()
$scanPtrBase = FindPattern($dwHandle, "A1........568B7508576A00",false,$dwBaseAddress)
$dwPtrBase = "0x" & Hex($scanPtrBase + 0x1,8)
$Location = "0x" & Hex(NtReadVirtualMemory($dwHandle,$dwPtrBase,"dword"),8)
$dwPointerBase = "0x" & Hex(Execute($Location - $dwBaseAddress),8)
EndFunc

Func GetX()
	$PointerBase = NtReadVirtualMemory($dwHandle, $dwBaseAddress + $dwPointerBase, "dword")
	$xLv1 = NtReadVirtualMemory($dwHandle, $PointerBase + 0x0, "dword")
	$xLv2 = NtReadVirtualMemory($dwHandle, $xLv1 + 0x0, "dword")
	$valX = NtReadVirtualMemory($dwHandle, $xLv2 + $X, "dword")
	Return $valX
EndFunc

Func GetY()
	$PointerBase = NtReadVirtualMemory($dwHandle, $dwBaseAddress + $dwPointerBase, "dword")
	$yLv1 = NtReadVirtualMemory($dwHandle, $PointerBase + 0x0, "dword")
	$yLv2 = NtReadVirtualMemory($dwHandle, $yLv1 + 0x0, "dword")
	$valY = NtReadVirtualMemory($dwHandle, $yLv2 + $Y, "dword")
	Return $valY
EndFunc

Func IsGameStarted()
	$Game = NtReadVirtualMemory($dwHandle, $dwBaseAddress + $IsGameStarted, "dword")
	Return $Game
EndFunc

Func  _MemoryModuleGetBaseAddress($iPID , $sModule)
    If  Not  ProcessExists ($iPID) Then  Return  SetError (1 , 0 , 0)

    If  Not  IsString ($sModule) Then  Return  SetError (2 , 0 , 0)

    Local    $PSAPI=DllOpen ("psapi.dll")

    ;Get Process Handle
    Local    $hProcess
    Local    $PERMISSION=BitOR (0x0002, 0x0400, 0x0008, 0x0010, 0x0020) ; CREATE_THREAD, QUERY_INFORMATION, VM_OPERATION, VM_READ, VM_WRITE

    If  $iPID>0 Then
        Local  $hProcess=DllCall ("kernel32.dll" , "ptr" , "OpenProcess" , "dword" , $PERMISSION , "int" , 0 , "dword" , $iPID)
        If  $hProcess [ 0 ] Then
            $hProcess=$hProcess [ 0 ]
        EndIf
    EndIf

    ;EnumProcessModules
    Local    $Modules=DllStructCreate ("ptr[1024]")
    Local    $aCall=DllCall ($PSAPI , "int" , "EnumProcessModules" , "ptr" , $hProcess , "ptr" , DllStructGetPtr ($Modules), "dword" , DllStructGetSize ($Modules), "dword*" , 0)
    If  $aCall [ 4 ]>0 Then
        Local    $iModnum=$aCall [ 4 ] / 4
        Local    $aTemp
        For  $i=1 To  $iModnum
            $aTemp= DllCall ($PSAPI , "dword" , "GetModuleBaseNameW" , "ptr" , $hProcess , "ptr" , Ptr(DllStructGetData ($Modules , 1 , $i)) , "wstr" , "" , "dword" , 260)
            If  $aTemp [ 3 ]=$sModule Then
                DllClose ($PSAPI)
                Return  Ptr(DllStructGetData ($Modules , 1 , $i))
            EndIf
        Next
    EndIf

    DllClose ($PSAPI)
    Return  SetError (-1 , 0 , 0)

EndFunc