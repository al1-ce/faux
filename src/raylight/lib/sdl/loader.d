/+++/
module raylight.lib.sdl.loader;

import bindbc.sdl;

import sily.bindbc;

import raylight.log;

// static if (bindSDL) {
/// Loads SDL Window library
bool loadLibrarySDL(int L = __LINE__, string F = __FILE__)() {
    return loadBindBCLib!(bindbc.sdl, SDLSupport, loadSDL, sdlSupport, "SDL2", L, F)(getLogFile());
}
// }

/// Loads SDL Image library
bool loadLibrarySDLImage(int L = __LINE__, string F = __FILE__)() {
    return loadBindBCLib!(bindbc.sdl, SDLImageSupport, loadSDLImage, sdlImageSupport, "SDL2 Image", L, F)(getLogFile());
}

/// Loads SDL TTF library
bool loadLibrarySDLTTF(int L = __LINE__, string F = __FILE__)() {
    return loadBindBCLib!(bindbc.sdl, SDLTTFSupport, loadSDLTTF, sdlTTFSupport, "SDL2 TTF", L, F)(getLogFile());
}


