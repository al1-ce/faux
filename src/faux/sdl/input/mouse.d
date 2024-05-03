// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/+++/
module faux.sdl.input.mouse;

import faux.sdl.lib;

enum MouseButton {
    left = SDL_BUTTON_LEFT,
    right = SDL_BUTTON_RIGHT,
    middle = SDL_BUTTON_MIDDLE,
    forward = SDL_BUTTON_X1,
    back = SDL_BUTTON_X2,
}

