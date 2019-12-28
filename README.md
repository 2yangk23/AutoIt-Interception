# AutoIt-Interception
AutoIt3 wrapper for [oblitum/Interception](https://github.com/oblitum/Interception)

This allows you to send keystrokes to DirectX games which sometimes listen to keyboard drivers directly. This is done by sending the key events directly to driver level so the game picks it up. (This is also why it requires installing the driver)

# Driver Installation
Follow instructions at http://oblita.com/interception.html

# Usage
```au3
#include <Interception.au3>

Interception_Create_Context()

_SendText("Hello World!")
Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_DOWN)
Interception_SendKey($SC_RETURN, $INTERCEPTION_KEY_UP)
_SendText("Bye!")

Interception_Destroy_Context()
```
