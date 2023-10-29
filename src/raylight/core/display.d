/+++/
module raylight.core.display;

import sily.vector;

import raylight.lib.sdl.sdl;

struct DisplayMode {
    uint format = SDL_PIXELFORMAT_UNKNOWN;
    ivec2 size = 0;
    int refreshRate = 0;
    void* driverData = cast(void*) 0;
}
