/++
Window creation and manipulation utils
+/
module raylight.core.window;

import std.string : toStringz;
import std.conv : to;
import std.algorithm.mutation: remove;

import sily.vector;
import sily.bindbc;

import raylight.log;
import raylight.lib.sdl.sdl;
import raylight.lib.sdl.loader;
import raylight.lib.opengl.opengl;
import raylight.lib.opengl.loader;
import raylight.input.event;
import raylight.core.display;

private int _winCounter = 0;
private Window*[] _windows;

alias WindowHandle = SDL_Window*;
alias GlContext = SDL_GLContext;

/// Returns window that currently has an input grab (capture) enabled
WindowHandle getGrabbedWindow() {
    return SDL_GetGrabbedWindow();
}

/// Returns SDL handle from ID
WindowHandle getHandleFromID(uint id) {
    return SDL_GetWindowFromID(id);
}

/// Returns window reference from ID
Window* getWindowFromID(uint id) {
    for(int i = 0; i < _windows.length; ++i) {
        if (_windows[i].id == id) return _windows[i];
    }

    warning("Unknown window ID ", id, ", returning NULL");
    return null;
}

/// Returns window reference from SDL handle
Window* getWindowFromHandle(WindowHandle handle) {
    for(int i = 0; i < _windows.length; ++i) {
        if (_windows[i].handle == handle) return _windows[i];
    }

    warning("Unknown window handle ", handle, ", returning NULL");
    return null;
}

/++
Structs representing a window.
Example:
---
Window win;
win.create(ivec2(1280, 720), "My window");
while (true) {
    win.pollInputEvents();
    /// ...input handing
    if (closeRequested) break;
    /// Render
    win.swapBuffer();
}
win.close();
---
+/
struct Window {
    // import cfg = raylight.config;
    // import raylight.input.keyboard: Key;
    //
    // /// Sets exit key (ESC by default)
    // void setExitKey(int key) {
    //     SetExitKey(key);
    // }

    // /// Ditto
    // void setExitKey(Key key) {
    //     setExitKey(cast(int) key);
    // }

    private uint _id = 0;

    /// Private init tracking
    private bool _isInit = false;

    /// Private cursor lock tracking
    private bool _cursorLocked = false;

    private WindowHandle _window;
    private GlContext _context;

    /// Returns SDL window handle
    @property WindowHandle handle() { return _window; }


    /// Opens new window
    bool create(int L = __LINE__, string F = __FILE__)(int width, int height, string title) {
        // if (!loadLibrarySDL!(L, F)()) return false;

        if (_winCounter == 0) {
            // TODO: I forgot what exactly I need with zero window, probably that:
            // TODO: Pull out PC info (OS, cpu, gpu), maybe put into loadlibraries
            // TODO: set default log location to temp/appname/latest.log
            // LINK: https://learn.microsoft.com/en-us/windows/win32/sysinfo/getting-hardware-information
            // LINK: https://gist.github.com/caiorss/2527d1402ea1469f67fba9ab172f05e5
            // logRaw("");
        }

        // TODO: window to hold events, aka private `Queue!Event _events`

        newline();
        // logLine('=');

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);

        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

        _window = SDL_CreateWindow(
            title.toStringz,
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            width,
            height,
            SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL
        );

        if (_window == null) {
            error!(L, F)("Could not create Window: ", SDL_GetError());
            return false;
        } else {
            _id = this.id();
            info!(L, F)("SDL Window ID:", _id, " created");
        }

        _context = SDL_GL_CreateContext(_window);

        info!(L, F)("Loading OpenGL for Window ID:", _id);
        setBindBCLibPath("dll");
        if (!loadLibraryOpenGL!(L, F)()) return false;
        resetBindBCLibPath();

        info!(L, F)("Window ID:", _id, " successfully initialised");
        // logLine('=');
        // newline();
        _isInit = true;
        ++_winCounter;
        _windows ~= &this;
        return true;
    }
    /// Ditto
    void create(int L = __LINE__, string F = __FILE__)(ivec2 size, string title) {
        create!(L, F)(size.x, size.y, title);
    }

    // /// Should window close (window close button been pressed)
    // bool shouldClose() {
    //     return WindowShouldClose();
    // }
    // /// Ditto
    // alias closeRequested = shouldClose;

    /// Closes window and resets config flags
    void close(int L = __LINE__, string F = __FILE__)() {
        SDL_GL_DeleteContext(_context);
        SDL_DestroyWindow(_window);
        SDL_Quit();
        info!(L, F)("Successfully closed window ID:", _id);
        _isInit = false;
        _id = 0;
        _windows.remove!(a => a == &this);
        // cfg.stateReset();
    }

    /// Has window initialised successfully
    bool isReady() {
        return _isInit;
    }
    /// Checks if window is fullscreen
    bool fullscreen() {
        return (SDL_GetWindowFlags(_window) & SDL_WINDOW_FULLSCREEN) > 0;
    }

    /// Set fullscreen mode
    void fullscreen(bool state) {
        SDL_SetWindowFullscreen(_window, state);
    }

    // /// Toggle fullscreen mode
    // void fullscreenToggle() {
    //     ToggleFullscreen();
    // }
    //
    /// Is window hidden
    bool hidden() {
        return !((SDL_GetWindowFlags(_window) & SDL_WINDOW_SHOWN) > 0);
    }

    /// Hides window
    void hide() {
        SDL_HideWindow(_window);
    }

    /// Shows window
    void show() {
        SDL_ShowWindow(_window);
    }

    /// Restores size and position of min/maximised window
    void restore() {
        SDL_RestoreWindow(_window);
    }

    /// Is window minimised
    bool minimised() {
        return (SDL_GetWindowFlags(_window) & SDL_WINDOW_MINIMIZED) > 0;
    }
    /// Ditto
    alias minimized = minimised;

    /// Minimises window
    void minimise() {
        SDL_MinimizeWindow(_window);
    }
    /// Ditto
    alias minimize = minimise;

    /// Is window maximised
    bool maximised() {
        return (SDL_GetWindowFlags(_window) & SDL_WINDOW_MAXIMIZED) > 0;
    }
    /// Ditto
    alias maximized = maximised;

    /// Maximises window
    void maximise() {
        SDL_MaximizeWindow(_window);
    }
    /// Ditto
    alias maximize = maximise;

    /// Is window focused
    // bool focused() {
    //     return IsWindowFocused();
    // }

    /// Enables/disables window resizing
    void setResizable(bool state) {
        SDL_SetWindowResizable(_window, state ? 1 : 0);
    }

    /// Has window been resized
    // bool resized() {
    //     return IsWindowResized();
    // }

    /// Focused window without bringing on top, please use `raise()` instead
    void setInputFocus() {
        SDL_SetWindowInputFocus(_window);
    }

    /// Focuses window and brings it on top
    void raise() {
        SDL_RaiseWindow(_window);
    }
    /// Ditto
    alias focus = raise;

    /// Toggles if window should be always on top
    void alwaysOnTop(bool enabled) {
        SDL_SetWindowAlwaysOnTop(_window, enabled);
    }

    /// Toggles border on window (does nothing on fullscreen window)
    void setBorder(bool enabled) {
        SDL_SetWindowBordered(_window, enabled);
    }

    /// Set window icon
    void setIcon(SDL_Surface image) {
        SDL_SetWindowIcon(_window, &image);
    }

    /// Returns Window Flags mask
    uint flags() {
        return SDL_GetWindowFlags(_window);
    }

    /// Set window title
    void title(string title) {
        SDL_SetWindowTitle(_window, title.toStringz);
    }

    string title() {
        return to!string(SDL_GetWindowTitle(_window));
    }

    /// Returns display mode
    DisplayMode displayMode() {
        SDL_DisplayMode m;
        SDL_GetWindowDisplayMode(_window, &m);
        return DisplayMode(m.format, ivec2(m.w, m.h), m.refresh_rate, m.driverdata);
    }

    /// Sets display mode, returns 0 on success
    int displayMode(DisplayMode mode) {
        SDL_DisplayMode m = SDL_DisplayMode(mode.format, mode.size.x, mode.size.y, mode.refreshRate, mode.driverData);
        return SDL_SetWindowDisplayMode(_window, &m);
    }

    /// TODO: alias SDL window flags (SDL_WINDOWPOS...)
    /// Move window to position (or SDL_WINDOWPOS_CENTERED)
    void position(int[2] pos...) {
        SDL_SetWindowPosition(_window, pos[0], pos[1]);
    }

    /// Return current window position
    ivec2 position() {
        ivec2 v;
        SDL_GetWindowPosition(_window, &(v.x), &(v.y));
        return v;
    }

    /// Sets window size
    void size(int[2] _size...) {
        SDL_SetWindowSize(_window, _size[0], _size[1]);
    }

    /// Returns current window size
    ivec2 size() {
        ivec2 v;
        SDL_GetWindowSize(_window, &(v.x), &(v.y));
        return v;
    }

    /// Returns current window size in pixels
    ivec2 sizePixels() {
        ivec2 v;
        SDL_GetWindowSizeInPixels(_window, &(v.x), &(v.y));
        return v;
    }

    /// Returns minimium size of window's client area
    ivec2 minimumSize() {
        ivec2 v;
        SDL_GetWindowMinimumSize(_window, &(v.x), &(v.y));
        return v;
    }

    /// Returns minimium size of window's client area
    ivec2 maximumSize() {
        ivec2 v;
        SDL_GetWindowMaximumSize(_window, &(v.x), &(v.y));
        return v;
    }

    /// Sets minimium size of window's client area
    void minimumSize(ivec2 _size) {
        SDL_SetWindowMinimumSize(_window, _size.x, _size.y);
    }

    /// Sets minimium size of window's client area
    void maximumSize(ivec2 _size) {
        SDL_SetWindowMaximumSize(_window, _size.x, _size.y);
    }

    /// Sets window width
    void width(int w) {
        size(w, height());
    }

    /// Returns window width
    int width() {
        return size().x;
    }

    /// Sets window height
    void height(int h) {
        size(width(), h);
    }

    /// Returns window height
    int height() {
        return size().y;
    }

    // /// Get render surface width
    // int renderWidth() {
    //     return GetRenderWidth();
    // }
    //
    // /// Get render surface height
    // int renderHeight() {
    //     return GetRenderHeight();
    // }

    // /// Get render surface size
    // ivec2 renderSize() {
    //     return ivec2(renderWidth(), renderHeight());
    // }

    // TODO: move to display
    // /// Returns DPI scale
    // ivec2 scaleDPI() {
    //     raylib.Vector2 v = GetWindowScaleDPI();
    //     return ivec2(cast(int) v.x, cast(int) v.y);
    // }

    // LINK: https://stackoverflow.com/questions/41745492/sdl2-how-to-position-a-window-on-a-second-monitor
    // TODO: rename to moveToDisplay
    // /// Move window to monitor
    // void moveToMonitor(int monitor) {
    //     SetWindowMonitor(monitor);
    // }

    /// Sets/Gets window opacity
    void opacity(float _opacity) {
        SDL_SetWindowOpacity(_window, _opacity);
    }
    /// Ditto
    float opacity() {
        float ptr;
        SDL_GetWindowOpacity(_window, &ptr);
        return ptr;
    }

    /// Returns SDL surface associated with window
    SDL_Surface* surface() {
        return SDL_GetWindowSurface(_window);
    }

    /// Sets window as a modal for `p_parent`
    int setModalFor(WindowHandle p_parent) {
        return SDL_SetWindowModalFor(_window, p_parent);
    }
    /// Ditto
    int setModalFor(ref Window p_parent) {
        return setModalFor(p_parent.handle);
    }

    /// Returns window ID
    uint id() {
        return SDL_GetWindowID(_window);
    }

    /// Returns pixel format
    uint pixelFormat() {
        return SDL_GetWindowPixelFormat(_window);
    }

    /// Set/get mouse confinement of a window
    int mouseRect(ivec4 rect) {
        return SDL_SetWindowMouseRect(_window, new SDL_Rect(rect.x, rect.y, rect.z, rect.w));
    }
    /// Ditto
    ivec4 mouseRect() {
        const SDL_Rect* rp = SDL_GetWindowMouseRect(_window);
        if (rp is null) return ivec4(0);
        SDL_Rect r = *rp;
        return ivec4(r.x, r.y, r.w, r.h);
    }

    /++
    Confines mouse and keyboard input to only this window.
    It is preferred to use `setMouseCapture` instead
    +/
    void setInputCapture(bool state) {
        SDL_SetWindowGrab(_window, state ? 1 : 0);
    }

    /// Confines mouse input to only this window
    void setMouseCapture(bool state) {
        SDL_SetWindowMouseGrab(_window, state ? 1 : 0);
    }
    /// Ditto
    void lockCursor() { setMouseCapture(true); }
    /// Ditto
    void unlockCursor() { setMouseCapture(false); }

    /// Confines keyboard input to only this window
    void setKeyboardCapture(bool state) {
        SDL_SetWindowKeyboardGrab(_window, state ? 1 : 0);
    }

    /// Returns true is mouse is grabbed (confined to window)
    bool isMouseCaptured() {
        return SDL_GetWindowMouseGrab(_window) != 0;
    }
    /// Ditto
    alias cursorLocked = isMouseCaptured;

    /// Returns true is keyboard is grabbed (confined to window)
    bool isKeyboardCaptured() {
        return SDL_GetWindowKeyboardGrab(_window) != 0;
    }

    // TODO: SDL_GetShapedWindowMode
    // TODO: SDL_SetWindowHitTest

    /// Flashes window briefly
    void flash() {
        SDL_FlashWindow(_window, SDL_FLASH_BRIEFLY);
    }

    /// Flashes window until focused
    void flashUntilFocused() {
        SDL_FlashWindow(_window, SDL_FLASH_UNTIL_FOCUSED);
    }

    /// Cancels flashing
    void flashCancel() {
        SDL_FlashWindow(_window, SDL_FLASH_CANCEL);
    }

    /// Returns current window size in pixels
    ivec4 borderSize() {
        ivec4 v;
        SDL_GetWindowBordersSize(_window, &(v.x), &(v.y), &(v.z), &(v.w));
        return v;
    }

    /// Returns index of window's display (monitor)
    int displayIndex() {
        return SDL_GetWindowDisplayIndex(_window);
    }

    // /++
    // Enables / diables event waiting on render.finish / render.finishRender.
    // Params:
    //     enabled = true - wait for events, no polling, false - no wait, auto polling
    // +/
    // void eventWaiting(bool enabled) {
    //     if (enabled) {
    //         EnableEventWaiting();
    //     } else {
    //         DisableEventWaiting();
    //     }
    // }

    /// Polls window events. This method is required to be called only once on main window
    void pollInputEvents() {
        .pollInputEvents();
    }

    void bindAsRenderTarget() {
        SDL_GL_MakeCurrent(_window, _context);
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        glViewport(0, 0, width, height);
    }

    /// Swaps render buffer (renders GL buffer to screen)
    void swapBuffer() {
        glUseProgram(0);
        glBindVertexArray(0);
        glBindTexture(GL_TEXTURE_2D, 0);
        glDisable(GL_BLEND);

        SDL_GL_SwapWindow(_window);
    }

    /// Copies window surface to screen (use `swapBuffer` for GL render)
    void updateSurface() {
        SDL_UpdateWindowSurface(_window);
    }

    void setRelativeMouseMode(bool enabled) {
        SDL_SetRelativeMouseMode(enabled ? 1 : 0);
    }

    bool getRelativeMouseMode() {
        return SDL_GetRelativeMouseMode().to!bool;
    }

    void setMousePosition(int[2] pos ...) {
        SDL_WarpMouseInWindow(_window, pos[0], pos[1]);
    }

    void setMousePositionScreen(int[2] pos ...) {
        SDL_WarpMouseGlobal(pos[0], pos[1]);
    }

    /// Waits for `sec` seconds
    void delay(int msec = 1) {
        SDL_Delay(msec);
    }
    /// Ditto
    alias wait = delay;

    /// Returns window data value associated with name
    void* getData(string name) {
        return SDL_GetWindowData(_window, name.toStringz);
    }

    /++
    Sets window data value
    Returns: Previous value
    +/
    void* setData(string name, void* data) {
        return SDL_SetWindowData(_window, name.toStringz, data);
    }

    // TODO: cursor functions
    /// Shows cursor
    void showCursor() {
        SDL_ShowCursor(SDL_ENABLE);
    }

    /// Hides cursor
    void hideCursor() {
        SDL_ShowCursor(SDL_DISABLE);
    }

    /// Returns is cursor hidden
    bool cursorHidden() {
        return SDL_ShowCursor(SDL_QUERY) != 0;
    }

    // /// Is cursor hovering over window (not same as focused)
    // bool cursorOnWindow() {
    //     return IsCursorOnScreen();
    // }
    //
    // /// Takes screenshot (filename extension defines format)
    // void takeScreenshot(string filename) {
    //     TakeScreenshot(filename.toStringz);
    // }


    // TODO: move to somewhere
    /// Opens URL with default browser
    void openURL(string url) {
        SDL_OpenURL(url.toStringz);
    }


}
