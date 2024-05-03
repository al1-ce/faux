// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

module faux.core.fs;

import std.file: read;
import std.conv: to;

/// Returns contents of file
string readFile(string path) {
    return read(path).to!string;
}
