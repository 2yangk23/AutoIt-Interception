#include <Interception.au3>

Interception_Create_Context()

_SendText("Hello World!")
Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_DOWN)
Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_UP)
_SendText("Bye!")

Interception_Destroy_Context()
