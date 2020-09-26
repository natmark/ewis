import Foundation

/*
 ref: ANSI Escape Sequence
 http://www.asthe.com/chongo/tech/comp/ansi_escapes.html
 */
enum Command: String {
    case moveCursorToBottomTrailing = "\u{1b}[999C\u{1b}[999B"
    case getCursorPosition = "\u{1b}[6n"
    case eraseInDisplay = "\u{1b}[2J"
    case repositionTheCursor = "\u{1b}[H"
}
