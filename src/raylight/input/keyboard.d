/// Keyboard input
module raylight.input.keyboard;

import std.conv: to;
import std.string: toStringz;

import raylight.input.event;

public import raylight.lib.sdl.input.keyboard: Key;
public import raylight.lib.sdl.sdl: SDL_GetClipboardText, SDL_SetClipboardText;

bool keyPressed(Key p_key){ 
    return getKeyState(p_key) == KeyState.pressed;
}

bool keyDown(Key p_key){ 
    return getKeyState(p_key) == KeyState.pressed ||
           getKeyState(p_key) == KeyState.down;
}

bool keyReleased(Key p_key){ 
    return getKeyState(p_key) == KeyState.released;
}

bool keyUp(Key p_key){ 
    return getKeyState(p_key) == KeyState.released ||
           getKeyState(p_key) == KeyState.up;
}

Key lastKey() {
    return getLastKeyPressed();
}

string clipboard() {
    return SDL_GetClipboardText().to!string;
}

void clipboard(string text) {
    SDL_SetClipboardText(text.toStringz());
}

//
// import rl = raylib;
//
// /// Keyboard keys
// alias Key = rl.KeyboardKey;
//
// /// Is key pressed
// bool isDown(Key key) {
//     return rl.IsKeyDown(key);
// }
//
// /// Is key not pressed
// bool isUp(Key key) {
//     return rl.IsKeyUp(key);
// }
//
// /// Is key just pressed
// bool isPressed(Key key) {
//     return rl.IsKeyPressed(key);
// }
//
// /// Is key released
// bool isReleased(Key key) {
//     return rl.IsKeyReleased(key);
// }
//
// int getKeyPressed() {
//     return rl.GetKeyPressed();
// }
//
// int getCharPressed() {
//     return rl.GetCharPressed();
// }
//
