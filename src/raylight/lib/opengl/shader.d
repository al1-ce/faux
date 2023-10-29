module raylight.lib.opengl.shader;

import std.string: toStringz;
import std.conv;
import std.stdio: writefln;

import sily.vector;
import sily.matrix;
import sily.color;

import raylight.lib.opengl.opengl;
// TODO: filesystem
import raylight.core.fs;

struct Shader {
    private uint _vertex;
    private uint _fragment;

    private uint _program;

    private bool _isLinked = false;

    this(string vertexPath, string fragmentPath) {

        string v = readFile(vertexPath);
        string f = readFile(fragmentPath);

        writefln("Info: Loaded vertex shader from '%s'.", vertexPath);
        writefln("Info: Loaded fragment shader from '%s'.", fragmentPath);

        linkFromString(v, f);
    }

    // TODO make shader caching to reduce memory usage on similar shaders

    // LINK https://learnopengl.com/code_viewer_gh.php?code=includes/learnopengl/shader.h

    void linkFromString(string vertex, string fragment) {
        int success;

        _vertex = compileShader(vertex, GL_VERTEX_SHADER);
        glGetShaderiv(_vertex, GL_COMPILE_STATUS, &success);
        if (!success) throwShaderCompileError(_vertex);

        writefln("Info: Vertex shader '%d' compiled successfully.", _vertex);

        _fragment = compileShader(fragment, GL_FRAGMENT_SHADER);
        glGetShaderiv(_fragment, GL_COMPILE_STATUS, &success);
        if (!success) throwShaderCompileError(_fragment);

        writefln("Info: Fragment shader '%d' compiled successfully.", _fragment);

        _program = glCreateProgram();
        glAttachShader(_program, _vertex);
        glAttachShader(_program, _fragment);
        glLinkProgram(_program);

        glGetProgramiv(_program, GL_LINK_STATUS, &success);
        if (!success) throwProgramLinkError(_program);

        writefln("Info: Shader program '%d' linked successfully.", _vertex);

        glDeleteShader(_vertex);
        glDeleteShader(_fragment);

        writefln("");

        _isLinked = true;
    }

    private void throwShaderCompileError(uint shader) {
        char[512] infoLog;
        int len;
        glGetShaderInfoLog(shader, 512, &len, infoLog.ptr);
        writefln("Error: Shader compilation failed.\n%s", infoLog[0..len]);
        throw new Error("Shader compilation fail.");
    }

    private void throwProgramLinkError(uint program) {
        char[512] infoLog;
        int len;
        glGetProgramInfoLog(program, 512, &len, infoLog.ptr);
        writefln("Error: Shader program linking failed.\n%s", infoLog[0..len]);
        throw new Error("Shader program linking fail.");
    }

    private uint compileShader(string source, GLenum type) {
        auto f = source.toStringz;
        const int fv = source.length.to!int;

        uint sh = glCreateShader(type);
        glShaderSource(sh, 1, &f, &fv);
        glCompileShader(sh);

        return sh;
    }

    uint getUniformLocation(string name) {
        if (!checkIsLinked) return 0;
        return glGetUniformLocation(_program, name.toStringz);
    }

    void set() {
        if (!checkIsLinked) return;

        glUseProgram(_program);
    }

    void reset() {
        glUseProgram(0);
    }

    uint program() {
        if (!checkIsLinked) return 0;
        return _program;
    }

    void dispose() {
        if (!checkIsLinked) return;
        glDeleteProgram(_program);
    }

    bool checkIsLinked() {
        if (!_isLinked) {
            writefln("Error: Failed to use shader program. Shader '%d' is not linked", _program);
            return false;
        }
        return true;
    }

    // static Shader defaultShader() {
    //     if (_defaultShader is null) {
    //         _defaultShader = new Shader("res/default/shader/default.vs", "res/default/shader/default.fs");
    //     }
    //     return _defaultShader;
    // }

    void setBool(string name, bool value) {
        glUniform1i(getUniformLocation(name), value.to!int);
    }

    void setInt(string name, int value) {
        glUniform1i(getUniformLocation(name), value);
    }

    void setFloat(string name, float value) {
        glUniform1f(getUniformLocation(name), value);
    }

    void setVec2(string name, vec2 value) {
        glUniform2fv(getUniformLocation(name), 1, value.data.ptr);
    }

    void setVec2(string name, float x, float y) {
        glUniform2f(getUniformLocation(name), x, y);
    }

    void setVec3(string name, vec3 value) {
        glUniform3fv(getUniformLocation(name), 1, value.data.ptr);
    }

    void setVec3(string name, float x, float y, float z) {
        glUniform3f(getUniformLocation(name), x, y, z);
    }

    void setVec4(string name, vec4 value) {
        glUniform4fv(getUniformLocation(name), 1, value.data.ptr);
    }

    void setVec4(string name, float x, float y, float z, float w) {
        glUniform4f(getUniformLocation(name), x, y, z, w);
    }

    // TODO make vec4 & col interchangeable
    void setCol(string name, Color value) {
        glUniform4fv(getUniformLocation(name), 1, value.arrayof.ptr);
    }

    void setCol(string name, float r, float g, float b, float a) {
        glUniform4f(getUniformLocation(name), r, g, b, a);
    }

    // void setMat2(string name, Matrix2f value) {
    //     glUniformMatrix2fv(getUniformLocation(name), 1, GL_FALSE, value.asArray1D.ptr);
    // }

    // void setMat3(string name, Matrix3 value) {
    //     glUniformMatrix3fv(getUniformLocation(name), 1, GL_FALSE, value.asArray1D.ptr);
    // }

    void setMat4(string name, mat4 value) {
        glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, value.glbuffer.ptr);
        // glUniformMatrix4fv(getUniformLocation(name), 1, GL_FALSE, value.getM[0].ptr);
    }

    void setDrawMode(DrawMode mode) {
        setInt("uDrawMode", mode);
    }

    static enum DrawMode {
        normal, black, depth, normalMap
    }
}
