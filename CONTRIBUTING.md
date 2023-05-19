# Contributing Guidelines

####  Bug reporting 

Open an issue at [GitHub issue tracker](https://github.com/artificial-studio/raylight/issues). Before doing that, ensure the bug was not already reported or fixed in `master` branch. Describe a problem and, if necessary, provide minimal code needed to reproduce it.

Note that macOS compatibility issues are not considered bugs. Raylight uses OpenGL and doesn't support macOS where OpenGL is deprecated.

####  Bug fixing 

Open a new GitHub pull request with your patch. Provide a description of the problem and solution. Follow our [code style](#code-style-and-standards).

#### Implementing new features

New code should at least:
* work under Windows and POSIX systems and provide platform-agnostic API
* support x86 and x86_64 targets
* use OpenGL 4.6 and GLSL 4.60 (core profile)
* use [sily](https://github.com/al1-ce/sily-dlang) or it's sister-libraries for game math and some of I/O operations when possible. If there is no required operation please open an issue or create a pull request
* follow our [code style](#code-style-and-standards)
* not violate copyright/licensing. When adapting third-party code, make sure that it is compatible with [GNU GPL 3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

Adding new external dependencies should be avoided as much as possible.

#### Branching strategy

`master` branch is a development branch for the next release. When release is ready, `master` branch will be pushed into `release` branch and release will be made from it.

####  Code style and standards 

Raylight mostly follows [D style](https://dlang.org/dstyle.html). Essential rules are the following:
* Use spaces instead of tabs. Each indentation level is 4 spaces
* Opening curly bracket should be on a **same** line
* Functions and variables should be in `camelCase`
* Types, constants and enums should be in `PascalCase`
* Module names should be in lowercase.

