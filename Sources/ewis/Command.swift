import Foundation

/*
 ref: ANSI Escape Sequence
 http://www.asthe.com/chongo/tech/comp/ansi_escapes.html
 */
enum Command: String {
    case moveCursorToBottomTrailing = "\u{1b}[999C\u{1b}[999B"
    case getCursorPosition = "\u{1b}[6n"
    case eraseInDisplay = "\u{1b}[2J"
    case eraseInLine = "\u{1b}[K"
    case repositionTheCursor = "\u{1b}[H"
    case enterSetMode = "\u{1b}[?25h"
    case enterResetMode = "\u{1b}[?25l"
}
