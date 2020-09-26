import Foundation

class Editor {
    enum EditorError: Error {
        case couldNotGetWindowSize
        case couldNotGetCursorPosition
    }

    struct ScreenMatrix {
        var raw: UInt16
        var column: UInt16
        static var zero: ScreenMatrix = .init(raw: 0, column: 0)
    }

    static let shared = Editor()
    private var standardInput: FileHandle
    private var standardOutput: FileHandle
    private var term: termios
    private var screenSize: ScreenMatrix = .zero

    init() {
        standardInput = FileHandle.standardInput
        standardOutput = FileHandle.standardOutput
        term = RawMode.enable(fileHandle: standardInput)
        do {
            screenSize = try getWindowSize()
        } catch {
            exitFailure("getWindowSize")
            fatalError()
        }
    }

    func getWindowSize() throws -> ScreenMatrix {
        var ws = winsize()
        if ioctl(standardOutput.fileDescriptor, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0 {
            if !writeCommand(standardOutput: standardOutput, command: .moveCursorToBottomTrailing) {
                throw EditorError.couldNotGetWindowSize
            }
            return try getCursorPosition()
        } else {
            return ScreenMatrix(raw: ws.ws_row, column: ws.ws_col)
        }
    }

    func getCursorPosition() throws -> ScreenMatrix {
        var buffer: [UInt8] = Array(repeating: 0x00, count: 32)

        if !writeCommand(standardOutput: standardOutput, command: .getCursorPosition) {
            throw EditorError.couldNotGetCursorPosition
        }

        for i in 0..<buffer.count - 1 {
            var char: UInt8 = 0x00
            read(standardInput.fileDescriptor, &char, 1)

            if read(standardInput.fileDescriptor, &buffer[i], 1) != 1 { break }
            if buffer[i] == Character("R").key { break }
        }

        if buffer[0] != 0x1b || buffer[1] != Character("[").uint8Value {
            throw EditorError.couldNotGetCursorPosition
        }

        if
            let matrix = String(bytes: buffer.dropFirst(2), encoding: .utf8)?.trimmingCharacters(in: .controlCharacters).split(separator: ";"),
            matrix.count == 2,
            let raw = UInt16(String(matrix[0])),
            let column = UInt16(String(matrix[1])) {
            return .init(raw: raw, column: column)
        } else {
            throw EditorError.couldNotGetCursorPosition
        }
    }

    func drawRows() {
        for index in 0..<screenSize.raw {
            write(standardOutput: standardOutput, string: "~")

            if index < screenSize.raw - 1 {
                write(standardOutput: standardOutput, string: "\r\n")
            }
        }
    }

    func refreshScreen() {
        /*
         ref: ANSI Escape Sequence
         http://www.asthe.com/chongo/tech/comp/ansi_escapes.html
         */
        writeCommand(standardOutput: standardOutput, command: .eraseInDisplay)
        writeCommand(standardOutput: standardOutput, command: .repositionTheCursor)

        drawRows()

        writeCommand(standardOutput: standardOutput, command: .repositionTheCursor)
    }

    func processKeyPress() {
        let char = readKey()

        switch char {
        case Config.quitKey:
            refreshScreen()
            RawMode.disable(fileHandle: standardInput, originalTerm: term)
            exit(EXIT_SUCCESS)
        default: break
        }
    }

    @discardableResult
    private func readKey() -> UInt8 {
        var char: UInt8 = 0x00

        while true {
            let nread = read(standardInput.fileDescriptor, &char, 1)
            if nread == 1 { break }
            if nread == -1 && errno != EAGAIN {
                exitFailure("tcsetattr")
            }
        }

        return char
    }
}
