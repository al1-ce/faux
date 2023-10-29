/+++/
module raylight.lib;

import sily.bindbc;

import raylight.log: newline;

public import raylight.lib.sdl;
public import raylight.lib.opengl;

/++
Loads all libraries except OpenGL.
OpenGL is loaded in createWindow after creating SDL context).
On windows libraries loaded from `%WORKDIR%\dll`
+/
bool loadLibraries(int L = __LINE__, string F = __FILE__)() {
    setBindBCLibPath("dll");
    if (!loadLibrarySDL!(L, F)()) return false;
    if (!loadLibrarySDLImage!(L, F)()) return false;
    if (!loadLibrarySDLTTF!(L, F)()) return false;
    // if (!loadLibraryOpenGL!(L, F)()) return false;
    // newline();
    resetBindBCLibPath();
    return true;
}
