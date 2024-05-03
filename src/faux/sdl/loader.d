// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/+++/
module faux.sdl.loader;

import bindbc.sdl;

import faux.log;

// TODO: windows dlls
// TODO: image and ttf?

/// Loads SDL library
void loadLibrarySDL() {
    SDLSupport sdlReturn = loadSDL();
    if (sdlReturn != sdlSupport) {
        if (sdlReturn == SDLSupport.noLibrary) {
            fatal("Missing library. Failed to load SDL library");
        } else
        if (sdlReturn == SDLSupport.badLibrary) {
            fatal("Bad library. Failed to load SDL library");
        } else {
            fatal("Unknown error. Failed to load SDL library");
        }
    }

    info("SDL library successfully loaded");
}

// import bindbc.sdl;
//
// import sily.bindbc;
//
// import faux.log;
//
// // static if (bindSDL) {
// /// Loads SDL Window library
// bool loadLibrarySDL(int L = __LINE__, string F = __FILE__)() {
//     return loadBindBCLib!(bindbc.sdl, SDLSupport, loadSDL, sdlSupport, "SDL2", L, F)(getLogFile());
// }
// // }
//
// /// Loads SDL Image library
// bool loadLibrarySDLImage(int L = __LINE__, string F = __FILE__)() {
//     return loadBindBCLib!(bindbc.sdl, SDLImageSupport, loadSDLImage, sdlImageSupport, "SDL2 Image", L, F)(getLogFile());
// }
//
// /// Loads SDL TTF library
// bool loadLibrarySDLTTF(int L = __LINE__, string F = __FILE__)() {
//     return loadBindBCLib!(bindbc.sdl, SDLTTFSupport, loadSDLTTF, sdlTTFSupport, "SDL2 TTF", L, F)(getLogFile());
// }


