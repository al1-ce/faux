# Contributing Guidelines

#### Bug reporting 

Open an issue at [GitHub issue tracker](https://github.com/artificial-studio/faux/issues). Before doing that, ensure the bug was not already reported or fixed in `master` branch. Describe a problem and, if necessary, provide minimal code needed to reproduce it.

<!-- Note that macOS compatibility issues are not considered bugs. Faux uses OpenGL and doesn't support macOS where OpenGL is deprecated. -->
<!-- TODO: add note about Vulkan macOS (Molten?) -->

#### Bug fixing 

Open a new GitHub pull request with your patch. Provide a description of the problem and solution. Follow our [code style](#code-style-and-standards).

#### Implementing new features

New code should at least:
* work under Windows and POSIX systems and provide platform-agnostic API
<!-- * support x86 and x86_64 targets -->
* support x64 targets
<!-- * use OpenGL 4.6 and GLSL 4.60 (core profile) -->
* use [Vulkan](https://code.dlang.org/packages/erupted) as graphics API
* use [SDL](https://code.dlang.org/packages/bindbc-sdl) as hardware API
* use [sily](https://github.com/al1-ce/sily) for game math and some of I/O operations when possible. If there is no required operation please open an issue or create a pull request
* use [clib](https://github.com/al1-ce/clib) for nogc containers
* follow our [code style](#code-style-and-standards)
* not violate copyright/licensing. When adapting third-party code, make sure that it is compatible with [GNU GPL 3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

Adding new external dependencies should be avoided as much as possible.

#### Branching strategy

`master` branch is a development branch for the next release. When release is ready, `master` branch will be pushed into `release` branch and release will be made from it.

#### Code style and standards 

Faux mostly follows [D style](https://dlang.org/dstyle.html). Essential rules are the following:
* Use spaces instead of tabs. Each indentation level is 4 spaces
* There's always a space after control statements (`if`, `while`, `for`, etc...)
* Opening curly bracket should be on a **same** line
* Functions and variables should be in `camelCase`
* Classes, structs and enums should be in `PascalCase`
* Module names should be in lowercase
* `if () else if ()` can be split as `if () else\n if ()`
* If method or function is used as property parenthesis can be dropped
* Prefer explicitly importing methods instead of importing whole module when only several methods from this module are needed. Exception is when imported module declares only one thing (i.e vector and aliases for it)
* Also prefer explicitly importing sub-modules. I.e `import std.algorithm.searching;` instead of `import std.algorithm;`
* If you're using library that Faux is using and it has import in format of `faux.LIBNAME.lib` prefer it over directly importing that library. I.e use `import faux.sdl.lib;` instead of `import bindbc.sdl`
* Imports are ordered separated by single space. First normal, then static and finally public:
    1. std
    2. core
    3. faux.LIBNAME.lib (publicly imports LIBNAME)
    4. faux.vk.lib (publicly imports Vulkan bindings with Erupted)
    5. sily
    6. clib
    7. other libraries 
    8. faux
* Preferred order of declarations for classes or structs is:
    1. Public properties and one-line setters/getters
    2. Private properties
    3. Constructors
    4. Public methods
    5. Private methods
* Name prefixes are:
    - ` ` - none for any kind of properties except ones below (`public static const int normalProperty`)
    - `_` - for private/protected properties (`private int _privateProperty`)
    - `s_` - for private/protected static properties (`private static int s_staticInt`)
    - `t_` - for private/protected thread static properties (`private shared int t_staticInt`)
    - `_` - as postfix when name is a keyword (`bool bool_`)
* Function signature preferred to be in order:
    1. attributes (@property)
    2. visibility (public, private...), `public` can be dropped since everything is default public
    3. isStatic (static)
    4. misc
    5. isOverride (override)
    6. type qualifiers and type (int, bool...)
    7. name and params
    8. attributes (const, nothrow, pure, @nogc, @safe)
    9. i.e `@property private static override int myMethod(int* ptr) @safe @nogc nothrow {}`
* Interfaces must be prefixed with `I`, i.e. `IEntity`
* When declaring properties, methods, etc... visibility modifier can be dropped in favor of global visibility modifier, i.e `private:`. This type of declaration is valid but should be avoided since it's considered implicit
    - Example:
    ```
    class MyClass {
        public:
        int myPublicInt;
        string myPublicString;
        
        private:
        int myPrivateInt;

        public:
        int myPublicIntMethod() {}
        ...
    }
    ```
* Always describe symbols with ddoc unless name is self-descriptive (for properties)
* **Avoid exceptions at all costs.** Prefer status return checks and if needed to return nullable use `std.typecons: Nullable;` or `clib.optional: optional;` or if needed to return multiple values consider putting then in custom struct
* Include copyright line at top of source file or in `.reuse/dep5` for resource files or meta files
* Copyright line is subject to change!

Example of how a module would look like when adhering to those rules:
```d
// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

/++
Custom faux module.
Currently an example of style to use in faux engine source
code.
+/
module faux.custom;

import std.stdio: stdout, stdin, writeln;

import core.stdc: FILE;

import faux.sdl.lib; // note: used instead of import bindbc.sdl;
import faux.vk.lib; // note: used instead of import erupted;

import sily.vector;
import sily.terminal: isatty;

import clib.optional;

import faux.logger;
import faux.render.engine;

static import bindbc.loader;

public import sily.matrix;

/// Prints if std is a tty
void funcName() {
    if (stdout.isatty) {
        trace("STDOUT is a tty");
    } else
    if (stdin.isatty) {
        trace("STDIN is a tty");
    } else {
        trace("None are tty")
    }
}

/// CustomStruct isCustom type enum
enum CustomEnum {
    enumKey1,
    enumKey2
}

/// Structure to do custom things for faux
struct CustomStruct {
    /// Is custom struct
    CustomEnum isCustom;
    /// Struct index
    static int index;
    
    private int _privateIndex;
    private shared bool t_isInit;
    
    /// Returns private name
    @property string getName() const {
        return privateName();
    }

    /// Ditto
    private string privateName() const {
        return "my private name";
    }
}
```

