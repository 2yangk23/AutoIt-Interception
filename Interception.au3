#include <WinAPISys.au3>
#include <ScanCodeConstants.au3>

#cs ----------------------------------------------------------------------------

 Wrapper for github.com/oblitum/Interception

 Usage:
  Interception_Create_Context()
  Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_DOWN)
  Sleep(10)
  Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_UP)
  Interception_Destroy_Context()

#ce ----------------------------------------------------------------------------

; InterceptionKeyState
Global Const $INTERCEPTION_KEY_DOWN                 = 0x00
Global Const $INTERCEPTION_KEY_UP                   = 0x01
Global Const $INTERCEPTION_KEY_E0                   = 0x02
Global Const $INTERCEPTION_KEY_E1                   = 0x04
Global Const $INTERCEPTION_KEY_TERMSRV_SET_LED      = 0x08
Global Const $INTERCEPTION_KEY_TERMSRV_SHADOW       = 0x10
Global Const $INTERCEPTION_KEY_TERMSRV_VKPACKET     = 0x20

; InterceptionMouseState
Global Const $INTERCEPTION_MOUSE_LEFT_BUTTON_DOWN   = 0x001
Global Const $INTERCEPTION_MOUSE_LEFT_BUTTON_UP     = 0x002
Global Const $INTERCEPTION_MOUSE_RIGHT_BUTTON_DOWN  = 0x004
Global Const $INTERCEPTION_MOUSE_RIGHT_BUTTON_UP    = 0x008
Global Const $INTERCEPTION_MOUSE_MIDDLE_BUTTON_DOWN = 0x010
Global Const $INTERCEPTION_MOUSE_MIDDLE_BUTTON_UP   = 0x020

Global Const $INTERCEPTION_MOUSE_BUTTON_1_DOWN      = $INTERCEPTION_MOUSE_LEFT_BUTTON_DOWN
Global Const $INTERCEPTION_MOUSE_BUTTON_1_UP        = $INTERCEPTION_MOUSE_LEFT_BUTTON_UP
Global Const $INTERCEPTION_MOUSE_BUTTON_2_DOWN      = $INTERCEPTION_MOUSE_RIGHT_BUTTON_DOWN
Global Const $INTERCEPTION_MOUSE_BUTTON_2_UP        = $INTERCEPTION_MOUSE_RIGHT_BUTTON_UP
Global Const $INTERCEPTION_MOUSE_BUTTON_3_DOWN      = $INTERCEPTION_MOUSE_MIDDLE_BUTTON_DOWN
Global Const $INTERCEPTION_MOUSE_BUTTON_3_UP        = $INTERCEPTION_MOUSE_MIDDLE_BUTTON_UP

Global Const $INTERCEPTION_MOUSE_BUTTON_4_DOWN      = 0x040
Global Const $INTERCEPTION_MOUSE_BUTTON_4_UP        = 0x080
Global Const $INTERCEPTION_MOUSE_BUTTON_5_DOWN      = 0x100
Global Const $INTERCEPTION_MOUSE_BUTTON_5_UP        = 0x200

Global Const $INTERCEPTION_MOUSE_WHEEL              = 0x400
Global Const $INTERCEPTION_MOUSE_HWHEEL             = 0x800

; InterceptionMouseFlag
Global Const $INTERCEPTION_MOUSE_MOVE_RELATIVE      = 0x000
Global Const $INTERCEPTION_MOUSE_MOVE_ABSOLUTE      = 0x001
Global Const $INTERCEPTION_MOUSE_VIRTUAL_DESKTOP    = 0x002
Global Const $INTERCEPTION_MOUSE_ATTRIBUTES_CHANGED = 0x004
Global Const $INTERCEPTION_MOUSE_MOVE_NOCOALESCE    = 0x008
Global Const $INTERCEPTION_MOUSE_TERMSRV_SRC_SHADOW = 0x100

; Structs
Local Const $KEY_STROKE_STRUCT = "struct;ushort code;ushort state;uint information;endstruct"
Local Const $MOUSE_STROKE_STRUCT = "struct;ushort state;ushort flags;short rolling;int x;int y;uint information;endstruct"

; Shift Code Flags
Local Const $SHIFT_CODE_SHIFT_DOWN   = 0x01
Local Const $SHIFT_CODE_CTRL_DOWN    = 0x02
Local Const $SHIFT_CODE_ALT_DOWN     = 0x04
Local Const $SHIFT_CODE_HANKAKU_DOWN = 0x08

Local $DLL_HANDLE = -1
Local $CONTEXT    = -1
Local $DEVICE     = 1 ; Just use first device to send inputs


Func _SendText($text, $delay = 0)
  For $ch In StringToASCIIArray($text)
    _SendCharacter($ch, $delay)
  Next
EndFunc

Func _SendCharacter($ch, $delay = 0)
  Local $aRet = _GetVSC($ch)
  Local $code = $aRet[0]
  Local $shift = BitAND($aRet[1], $SHIFT_CODE_SHIFT_DOWN)

  ; Press Shift
  If $shift Then
    Interception_SendKey($SC_LSHIFT, $INTERCEPTION_KEY_DOWN)
    If @error Then Return SetError(@error, @extended, 0)
    Sleep($delay)
  EndIf

  ; Press Key
  Interception_SendKey($code, $INTERCEPTION_KEY_DOWN)
  If @error Then Return SetError(@error, @extended, 0)
  Sleep($delay)

  ; Release Key
  Interception_SendKey($code, $INTERCEPTION_KEY_UP)
  If @error Then Return SetError(@error, @extended, 0)

  ; Release Shift
  If $shift Then
    Interception_SendKey($SC_LSHIFT, $INTERCEPTION_KEY_UP)
    If @error Then Return SetError(@error, @extended, 0)
  EndIf
EndFunc

; Converts a character into it's scan_code and shift_state
Func _GetVSC($ch)
  ; See: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-vkkeyscana
  Local $aRet = DllCall('user32.dll', 'short', 'VkKeyScanA', 'byte', $ch)
  If @error Then Return SetError(@error, @extended, False)

  Dim $result[2]
  ; Lower byte contains key code
  $result[0] = _WinAPI_MapVirtualKey(BitAND($aRet[0], 0xFF), $MAPVK_VK_TO_VSC)
  ; Higher byte contains modifier state
  $result[1] = BitShift(BitAND($aRet[0], 0xFF00), 8)

  ;ConsoleWrite("CODE: " & Hex($result[0]) & ", STATE: " & Hex($result[1]) & @CRLF)
  return $result
EndFunc

; Initializes the Interception library
Func Interception_Create_Context()
  $DLL_HANDLE = DllOpen("interception.dll")
  If @error Then
    ConsoleWrite("Error opening interception.dll: " & @error)
  EndIf
  Local $aRet = DllCall($DLL_HANDLE, "ptr", "interception_create_context")
  If @error Then
    ConsoleWrite("Error creating context: " & @error)
    Exit
  EndIf
  $CONTEXT = $aRet[0]
EndFunc

; Cleans up the Interception library
Func Interception_Destroy_Context()
  DllCall($DLL_HANDLE, "none:cdecl", "interception_destroy_context", "ptr", $CONTEXT)
  If @error Then
    ConsoleWrite("Error destroying context: " & @error)
    Exit
  EndIf
  DllClose($DLL_HANDLE)
EndFunc

Func Interception_SendKey($code, $state)
  Local $stroke = DllStructCreate($KEY_STROKE_STRUCT)
  DllStructSetData($stroke, "code", $code)
  DllStructSetData($stroke, "state", $state)

  Local $aRet = DllCall($DLL_HANDLE, "int:cdecl", "interception_send", _
    "ptr", $CONTEXT, _
    "int", $DEVICE, _
    "struct*", $stroke, _
    "uint", 1)
  If @error Then Return SetError(@error, @extended, 0)

  Return $aRet[0]
EndFunc