// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/// Mouse input
module faux.input.mouse;

import faux.input.event;

public import faux.sdl.input.mouse: MouseButton;

alias mouseMotion = getMouseRelativeMotion;

alias mousePosition = getMouseWindowPosition;

bool mouseButtonPressed(MouseButton p_key){
    return getMouseButtonState(p_key) == KeyState.pressed;
}

bool mouseButtonDown(MouseButton p_key){
    return getMouseButtonState(p_key) == KeyState.pressed ||
           getMouseButtonState(p_key) == KeyState.down;
}

bool mouseButtonReleased(MouseButton p_key){
    return getMouseButtonState(p_key) == KeyState.released;
}

bool mouseButtonUp(MouseButton p_key){
    return getMouseButtonState(p_key) == KeyState.released ||
           getMouseButtonState(p_key) == KeyState.up;
}

//
// import rl = raylib;
//
// import sily.vector;
//
// import faux.raytype;
//
// /// Returns mouse position in window
// ivec2 mousePosition() {
//     return cast(ivec2) rl.GetMousePosition().rayType;
// }

// // Input-related functions: mouse
// bool IsMouseButtonPressed(int button);                  // Check if a mouse button has been pressed once
// bool IsMouseButtonDown(int button);                     // Check if a mouse button is being pressed
// bool IsMouseButtonReleased(int button);                 // Check if a mouse button has been released once
// bool IsMouseButtonUp(int button);                       // Check if a mouse button is NOT being pressed
// int GetMouseX(void);                                    // Get mouse position X
// int GetMouseY(void);                                    // Get mouse position Y
// Vector2 GetMousePosition(void);                         // Get mouse position XY
// Vector2 GetMouseDelta(void);                            // Get mouse delta between frames
// void SetMousePosition(int x, int y);                    // Set mouse position XY
// void SetMouseOffset(int offsetX, int offsetY);          // Set mouse offset
// void SetMouseScale(float scaleX, float scaleY);         // Set mouse scaling
// float GetMouseWheelMove(void);                          // Get mouse wheel movement for X or Y, whichever is larger
// Vector2 GetMouseWheelMoveV(void);                       // Get mouse wheel movement for both X and Y
// void SetMouseCursor(int cursor);                        // Set mouse cursor
