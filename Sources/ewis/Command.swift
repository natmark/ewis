import Foundation

/*
 ref: ANSI Escape Sequence
 http://www.asthe.com/chongo/tech/comp/ansi_escapes.html
 */
enum Command {
    case moveCursorToBottomTrailing
    case getCursorPosition
    case eraseInDisplay
    case eraseInLine
    case repositionTheCursor
    case enterSetMode
    case enterResetMode
    case moveCursor(point: CGPoint)

    var rawValue: String {
        switch self {
        case .moveCursorToBottomTrailing:
            return "\u{1b}[999C\u{1b}[999B"
        case .getCursorPosition:
            return "\u{1b}[6n"
        case .eraseInDisplay:
            return "\u{1b}[2J"
        case .eraseInLine:
            return "\u{1b}[K"
        case .repositionTheCursor:
            return "\u{1b}[H"
        case .enterSetMode:
            return "\u{1b}[?25h"
        case .enterResetMode:
            return "\u{1b}[?25l"
        case .moveCursor(let point):
            return "\u{1b}[\(Int(point.y));\(Int(point.x))H"
        }
    }
}
