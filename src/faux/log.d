// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

// Logging utils
module faux.log;

import std.stdio: writeln;

import core.stdc.stdlib: exit, EXIT_FAILURE;

/// Logs error and terminates application
noreturn fatal(T...)(T message) { writeln("Error: ", message); exit(EXIT_FAILURE); }
/// Logs error in format of `Error: message`
void error(T...)(T message) { writeln("Error: ", message); }
/// Logs info in format of `Info: message`
void info(T...)(T message) { debug writeln("Info: ", message); }
/// Logs note/trace in format of `Note: message`
void note(T...)(T message) { debug writeln("Note: ", message); }
/// Logs warning in format of `Warning: message`
void warning(T...)(T message) { debug writeln("Warning: ", message); }
/// Logs trace in format of `message`
void trace(T...)(T message) { debug writeln(message); }

// TODO: log into file

// import std.stdio: File;
//
// import sily.logger;
//
// public import sily.logger: LogLevel;
//
// private __gshared Log _logger;
//
// /// Sets File faux's logger
// void setLogFile(File f) {
//     _logger.logFile = f;
// }
// /// Ditto
// void setLogFile(string f) {
//     _logger.logFile = f;
// }
//
// /// Sets logger to flush file after each log
// void setLogAlwaysFlush(bool doFlush = true) {
//     _logger.alwaysFlush = doFlush;
// }
//
// /// Enable/Disable log formatting
// void setLogFormatting(bool doFormatting) {
//     _logger.formattingEnabled = doFormatting;
// }
//
// /// Enable/Disable simple output
// void setLogSimple(bool doSimple) {
//     _logger.simpleOutput = doSimple;
// }
//
// Log getLogFile() {
//     return _logger;
// }
//
// /// Logs message with faux logger
// void message(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.off, line, file)(args); }
// /// Ditto
// void trace(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.trace, line, file)(args); }
// /// Ditto
// void info(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.info, line, file)(args); }
// /// Ditto
// void warning(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.warning, line, file)(args); }
// /// Ditto
// void error(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.error, line, file)(args); }
// /// Ditto
// void critical(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.critical, line, file)(args); }
// /// Ditto
// void fatal(int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(LogLevel.fatal, line, file)(args); }
// /// Ditto
// void log(LogLevel ll = LogLevel.trace, int line = __LINE__, string file = __FILE__, S...)(S args)
//     { _logger.log!(ll, line, file)(args); }
//
// /// Creates new line (br)
// void newline() { _logger.newline(); }
//
// /// Writes raw message to log
// void logRaw(S...)(S args) { _logger.logRaw(args); }
//
// /// Logs a line
// void logLine(dchar c = '-') {
//     import sily.array;
//     _logger.logRaw(fill(c, 47));
// }

