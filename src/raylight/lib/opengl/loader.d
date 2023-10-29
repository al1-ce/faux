module raylight.lib.opengl.loader;

import std.conv: to;

import bindbc.opengl;

import sily.bindbc;

import raylight.log;

/// Must be called after creating OpenGL context (i.e SDL_GL_CreateContext() or sfWindow_create()).
bool loadLibraryOpenGL(int L = __LINE__, string F = __FILE__)() {
    bool ret = loadBindBCLib!(bindbc.opengl, GLSupport, loadOpenGL, glSupport, "OpenGL", L, F)(getLogFile());
    if (ret) {
        info!(L, F)("Supported OpenGL context: '", openGLContextVersion, "'"); 
        info!(L, F)("Loaded OpenGL context: '", loadedOpenGLVersion, "'");
    }
    return ret;
}














