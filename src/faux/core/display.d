// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/+++/
module faux.core.display;

import sily.vector;

import faux.sdl.lib;

struct DisplayMode {
    uint format = SDL_PIXELFORMAT_UNKNOWN;
    ivec2 size = 0;
    int refreshRate = 0;
    void* driverData = cast(void*) 0;
}
