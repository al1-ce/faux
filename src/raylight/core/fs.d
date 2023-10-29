module raylight.core.fs;

import std.file: read;
import std.conv: to;

/// Returns contents of file
string readFile(string path) {
    return read(path).to!string;
}
