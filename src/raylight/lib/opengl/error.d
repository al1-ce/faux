/+++/
module raylight.lib.opengl.error;

import raylight.log;

void checkglErrors(int L = __LINE__, string F = __FILE__)() {
    GLenum err;
    while ( (err = glGetError()) != GL_NO_ERROR ) {
        switch (err) {
            case GL_INVALID_ENUM: 
                error!(L, F)("OPENGL::ERROR 1280 Invalid enum"); break;
            case GL_INVALID_VALUE: 
                error!(L, F)("OPENGL::ERROR 1281 Invalid value"); break;
            case GL_INVALID_OPERATION: 
                error!(L, F)("OPENGL::ERROR 1282 Invalid operation"); break;
            case GL_STACK_OVERFLOW: 
                error!(L, F)("OPENGL::ERROR 1283 Stack overflow"); break;
            case GL_STACK_UNDERFLOW: 
                error!(L, F)("OPENGL::ERROR 1284 Stack underflow"); break;
            case GL_OUT_OF_MEMORY: 
                error!(L, F)("OPENGL::ERROR 1285 Out of memeory"); break;
            case GL_INVALID_FRAMEBUFFER_OPERATION: 
                error!(L, F)("OPENGL::ERROR 1286 Invalid framebuffer operation"); break;
            default: 
                error!(L, F)("OPENGL::ERROR Unknown error code"); break;
        }
    }
}

