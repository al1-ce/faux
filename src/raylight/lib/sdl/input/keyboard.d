/+++/
module raylight.lib.sdl.input.keyboard;

import raylight.lib.sdl.sdl;

alias KeyboardKey = Key;

enum Key {
    // LETTERS
    a = SDL_SCANCODE_A,
    b = SDL_SCANCODE_B,
    c = SDL_SCANCODE_C,
    d = SDL_SCANCODE_D,
    e = SDL_SCANCODE_E,
    f = SDL_SCANCODE_F,
    g = SDL_SCANCODE_G,
    h = SDL_SCANCODE_H,
    i = SDL_SCANCODE_I,
    j = SDL_SCANCODE_J,
    k = SDL_SCANCODE_K,
    l = SDL_SCANCODE_L,
    m = SDL_SCANCODE_M,
    n = SDL_SCANCODE_N,
    o = SDL_SCANCODE_O,
    p = SDL_SCANCODE_P,
    q = SDL_SCANCODE_Q,
    r = SDL_SCANCODE_R,
    s = SDL_SCANCODE_S,
    t = SDL_SCANCODE_T,
    u = SDL_SCANCODE_U,
    v = SDL_SCANCODE_V,
    w = SDL_SCANCODE_W,
    x = SDL_SCANCODE_X,
    y = SDL_SCANCODE_Y,
    z = SDL_SCANCODE_Z,
    
    // // NUMBERS
    // key0 = SDL_SCANCODE_0,
    d1 = SDL_SCANCODE_1,
    d2 = SDL_SCANCODE_2,
    d3 = SDL_SCANCODE_3,
    d4 = SDL_SCANCODE_4,
    d5 = SDL_SCANCODE_5,
    d6 = SDL_SCANCODE_6,
    d7 = SDL_SCANCODE_7,
    d8 = SDL_SCANCODE_8,
    d9 = SDL_SCANCODE_9,
    
    // FUNCTION KEYS
    f1 = SDL_SCANCODE_F1,
    f2 = SDL_SCANCODE_F2,
    f3 = SDL_SCANCODE_F3,
    f4 = SDL_SCANCODE_F4,
    f5 = SDL_SCANCODE_F5,
    f6 = SDL_SCANCODE_F6,
    f7 = SDL_SCANCODE_F7,
    f8 = SDL_SCANCODE_F8,
    f9 = SDL_SCANCODE_F9,
    f10 = SDL_SCANCODE_F10,
    f11 = SDL_SCANCODE_F11,
    f12 = SDL_SCANCODE_F12,
    f13 = SDL_SCANCODE_F13,
    f14 = SDL_SCANCODE_F14,
    f15 = SDL_SCANCODE_F15,
    f16 = SDL_SCANCODE_F16,
    f17 = SDL_SCANCODE_F17,
    f18 = SDL_SCANCODE_F18,
    f19 = SDL_SCANCODE_F19,
    f20 = SDL_SCANCODE_F20,
    f21 = SDL_SCANCODE_F21,
    f22 = SDL_SCANCODE_F22,
    f23 = SDL_SCANCODE_F23,
    f24 = SDL_SCANCODE_F24,
    
    // NUMBER ROW (1ST ROW)
    esc = SDL_SCANCODE_ESCAPE,
    grave = SDL_SCANCODE_GRAVE,
    minus = SDL_SCANCODE_MINUS,
    equals = SDL_SCANCODE_EQUALS,
    backspace = SDL_SCANCODE_BACKSPACE,
    
    // 2ND ROW
    tab = SDL_SCANCODE_TAB,
    leftBracket = SDL_SCANCODE_LEFTBRACKET,
    rightBracket = SDL_SCANCODE_RIGHTBRACKET,
    backslash = SDL_SCANCODE_BACKSLASH,

    // 3RD ROW
    capsLock = SDL_SCANCODE_CAPSLOCK,
    semicolon = SDL_SCANCODE_SEMICOLON,
    apostrophe = SDL_SCANCODE_APOSTROPHE,
    enter = SDL_SCANCODE_RETURN,

    // 4RTH ROW
    leftShift = SDL_SCANCODE_LSHIFT,
    comma = SDL_SCANCODE_COMMA,
    period = SDL_SCANCODE_PERIOD,
    slash = SDL_SCANCODE_SLASH,
    rightShift = SDL_SCANCODE_RSHIFT,

    // BOTTOM ROW
    leftControl = SDL_SCANCODE_LCTRL,
    application = SDL_SCANCODE_APPLICATION,
    leftAlt = SDL_SCANCODE_LALT,
    space = SDL_SCANCODE_SPACE,
    rightAlt = SDL_SCANCODE_RALT,
    leftGUI = SDL_SCANCODE_LGUI,
    rightGUI = SDL_SCANCODE_RGUI,
    rightControl = SDL_SCANCODE_RCTRL,

    // KEYPAD
    left = SDL_SCANCODE_LEFT,
    right = SDL_SCANCODE_RIGHT,
    up = SDL_SCANCODE_UP,
    down = SDL_SCANCODE_DOWN,

    // HOME
    home = SDL_SCANCODE_HOME,
    end = SDL_SCANCODE_END,
    pageUp = SDL_SCANCODE_PAGEUP,
    pageDown = SDL_SCANCODE_PAGEDOWN,
    insert = SDL_SCANCODE_INSERT,
    del = SDL_SCANCODE_DELETE,

    // SCROLL LOCK
    scrollLock = SDL_SCANCODE_SCROLLLOCK,
    printScreen = SDL_SCANCODE_PRINTSCREEN,
    pause = SDL_SCANCODE_PAUSE
    
    // TODO NUMPAD
}

