/++
Module to handle input events. Please use dedicated submodules of `raylight.input`
for input handling unless you need more control over it.
+/
module raylight.input.event;

import std.traits;
import std.algorithm;
import std.range;
import std.conv;

import sily.vector;

import raylight.lib.sdl.sdl;
import raylight.input.mouse;
import raylight.input.keyboard;

/// Keyboard key states
private KeyState[Key] _keyStates;
/// Key to SDL_SCANCODE conversion
private Key[int] _keyConv;
/// Last key pressed
private Key _lastKey;

static this() {
    foreach (skey; EnumMembers!Key) {
        _keyStates[skey] = KeyState.up;
    }
    
    foreach (skey; EnumMembers!Key) {
        _keyConv[skey.to!int] = skey;
    }
}

/++
Returns direct key state.
Please use methods from `raylight.input.keyboard` instead
+/
KeyState getKeyState(Key key) {
    return _keyStates[key];
}

/// Returns Key from SDL_SCANCODE
Key getKeySDL(int p_code) {
    return _keyConv[p_code];
}

/++
Returns last key pressed.
Please use `raylight.input.keyboard.lastKey()` instead
+/
Key getLastKeyPressed() {
    return _lastKey;
}

/// Direct mouse button states
private KeyState[MouseButton] _mbStates;
/// MouseButton to SDL_BUTTON conversion
private MouseButton[int] _mbConv;

/// Mouse relative motion
private ivec2 _mouseMotion;
/// Mouse position on window
private ivec2 _mousePosition;

static this() {
    foreach (skey; EnumMembers!MouseButton) {
        _mbStates[skey] = KeyState.up;
    }
    
    foreach (skey; EnumMembers!MouseButton) {
        _mbConv[skey.to!int] = skey;
    }

    _mouseMotion = ivec2(0, 0);
    _mousePosition = ivec2(0, 0);
}

/++
Returns direct mouse button state.
Please use methods from `raylight.input.mouse` instead
+/
KeyState getMouseButtonState(MouseButton button) {
    return _mbStates[button];
}

/++
Returns direct mouse position in window.
Please use methods from `raylight.input.mouse` instead
+/
ivec2 getMouseWindowPosition() {
    return _mousePosition;
}

/++
Returns direct relative mouse motion.
Please use methods from `raylight.input.mouse` instead
+/
ivec2 getMouseRelativeMotion() {
    return _mouseMotion;
}

/// Returns Key from SDL_SCANCODE
MouseButton getMouseButtonSDL(int p_code) {
    return _mbConv[p_code];
}

/// Future struct for specific event handling, i.e SDL_QUIT
struct InputEvent {
    // TODO: InputEvent
}

/// Key state
enum KeyState {
    pressed,
    down, 
    released, 
    up
}

/// Polls input events and updates key states
void pollInputEvents() {
    SDL_Event e;

    foreach (skey; _keyStates.keys) {
        if (_keyStates[skey] == KeyState.pressed) _keyStates[skey] = KeyState.down;
        if (_keyStates[skey] == KeyState.released) _keyStates[skey] = KeyState.up;
    }
    
    foreach (skey; _mbStates.keys) {
        if (_mbStates[skey] == KeyState.pressed) _mbStates[skey] = KeyState.down;
        if (_mbStates[skey] == KeyState.released) _mbStates[skey] = KeyState.up;
    }
    
    _mouseMotion.x = 0;
    _mouseMotion.y = 0;

    while (SDL_PollEvent(&e)) {
        switch (e.type) {
            case SDL_KEYDOWN:
                Key key = getKeySDL(e.key.keysym.scancode);
                // TODO fire up key repeat event
                _lastKey = key;
                if (_keyStates[key] == KeyState.down) break;
                _keyStates[key] = KeyState.pressed;
            break; 
            case SDL_KEYUP:
                Key key = getKeySDL(e.key.keysym.scancode);
                _keyStates[key] = KeyState.released;
            break; 
            case SDL_MOUSEBUTTONDOWN:
                MouseButton key = getMouseButtonSDL(e.button.button);
                _mbStates[key] = KeyState.pressed;
                // TODO emit event on e.button.clicks == 2
            break; 
            case SDL_MOUSEBUTTONUP:
                MouseButton key = getMouseButtonSDL(e.button.button);
                _mbStates[key] = KeyState.released;
            break; 
            case SDL_MOUSEMOTION:
                _mouseMotion.x = e.motion.xrel;
                _mouseMotion.y = e.motion.yrel;
                _mousePosition.x = e.motion.x;
                _mousePosition.y = e.motion.y;
            break; 
            case SDL_MOUSEWHEEL:
                if(e.wheel.y> 0) { // scroll up
                    // TODO scroll up
                } else 
                if(e.wheel.y < 0) { // scroll down
                    // TODO scroll down
                }

                if(e.wheel.x > 0) { // scroll right
                    // TODO scroll right
                } else 
                if(e.wheel.x < 0) { // scroll left
                    // TODO scroll left
                }
            break;
            // Close application button
            case SDL_QUIT:
                // Window.setRequestedClose(true);
            break;
            default:
                //
        }
    }
}

// SDL_Event e;
// while (SDL_PollEvent(&e))
// {
//     if (e.type == SDL_WINDOWEVENT
//         && e.window.event == SDL_WINDOWEVENT_CLOSE)
//     {
//         // ... Handle window close for each window ...
//         // Note, you can also check e.window.windowID to check which
//         // of your windows the event came from.
//         // e.g.:
//         if (SDL_GetWindowID(myWindowA) == e.window.windowID)
//         {
//             // ... close window A ...
//         }
//     }
// }


