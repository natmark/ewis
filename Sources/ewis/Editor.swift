import Foundation

protocol EditorProtocol {
    func refreshScreen()
    func processKeyPress()
    func open(_ fileURL: URL)
}

class Editor: EditorProtocol {
    enum EditorError: Error {
        case couldNotGetWindowSize
        case couldNotGetCursorPosition
    }

    struct ScreenMatrix {
        var row: Int
        var column: Int
        static var zero: ScreenMatrix = .init(row: 0, column: 0)
    }

    static let shared = Editor()
    private var standardInput: FileHandle
    private var standardOutput: FileHandle
    private var term: termios
    private var screenSize: ScreenMatrix = .zero
    private var cursorPosition: Point = .zero
    private var content: [String] = []
    private var contentOffset: Point = .zero

    private var cursoredLine: String? {
        if cursorPosition.y >= content.count { return nil }
        return content[cursorPosition.y]
    }

    private init() {
        standardInput = FileHandle.standardInput
        standardOutput = FileHandle.standardOutput
        term = RawMode.enable(standardInput: standardInput)
        do {
            screenSize = try getWindowSize()
        } catch {
            exitFailure("getWindowSize")
            fatalError()
        }
    }

    func open(_ fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            content = String(data: data, encoding: .utf8)?
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .newlines).appending("\0") }
                ?? []
        } catch {
            exitFailure("Could not open \(fileURL.absoluteString)")
        }
    }

    func refreshScreen() {
        updateContentOffset()
        let bufferWriter = BufferWriter(standardOutput: standardOutput)

        bufferWriter.append(command: .enterResetMode)
        bufferWriter.append(command: .repositionTheCursor)
        drawRows(bufferWriter: bufferWriter)
        bufferWriter.append(command: .moveCursor(
            point: Point(x: cursorPosition.x - contentOffset.x + 1,
                         y: cursorPosition.y - contentOffset.y + 1)
            )
        )
        bufferWriter.append(command: .enterSetMode)
        bufferWriter.flush()
    }

    func processKeyPress() {
        let char = readKey()

        if char == UInt(Character("q").controlKey) {
            refreshScreen()
            RawMode.disable(standardInput: standardInput, originalTerm: term)
            exit(EXIT_SUCCESS)
        }

        if let editorKey = EditorKey(rawValue: char) {
            switch editorKey {
            case .arrowUp:
                moveCursor(arrowKey: .up)
            case .arrowDown:
                moveCursor(arrowKey: .down)
            case .arrowRight:
                moveCursor(arrowKey: .right)
            case .arrowLeft:
                moveCursor(arrowKey: .left)
            case .pageUp:
                moveCursor(arrowKey: .up)
            case .pageDown:
                moveCursor(arrowKey: .down)
            case .home:
                cursorPosition = Point(x: 0, y: cursorPosition.y)
            case .end:
                cursorPosition = Point(x: screenSize.column, y: cursorPosition.y)
            case .delete: break // TODO
            }
        }
    }

    private func updateContentOffset() {
        contentOffset.y = min(contentOffset.y, cursorPosition.y)
        contentOffset.x = min(cursorPosition.x, contentOffset.x)
        if cursorPosition.y >= contentOffset.y + screenSize.row {
            contentOffset.y = cursorPosition.y - screenSize.row + 1
        }
        if cursorPosition.x >= contentOffset.x + screenSize.column {
            contentOffset.x = cursorPosition.x - screenSize.column + 1
        }
    }

    private func getWindowSize() throws -> ScreenMatrix {
        var ws = winsize()
        if ioctl(standardOutput.fileDescriptor, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0 {
            if !writeCommand(standardOutput: standardOutput, command: .moveCursorToBottomTrailing) {
                throw EditorError.couldNotGetWindowSize
            }
            return try getCursorPosition()
        } else {
            return ScreenMatrix(row: Int(ws.ws_row), column: Int(ws.ws_col))
        }
    }

    private func getCursorPosition() throws -> ScreenMatrix {
        var buffer: [UInt8] = Array(repeating: 0x00, count: 32)

        if !writeCommand(standardOutput: standardOutput, command: .getCursorPosition) {
            throw EditorError.couldNotGetCursorPosition
        }

        for i in 0..<buffer.count - 1 {
            if read(standardInput.fileDescriptor, &buffer[i], 1) != 1 { break }
            if buffer[i] == Character("R").key { break }
        }

        if buffer.count > 2 && (buffer[0] != Character("\u{1b}").uint8Value || buffer[1] != Character("[").uint8Value) {
            throw EditorError.couldNotGetCursorPosition
        }

        if
            let matrix = String(bytes: buffer.dropFirst(2), encoding: .utf8)?.trimmingCharacters(in: .controlCharacters).replacingOccurrences(of: "R", with: "").split(separator: ";"),
            matrix.count == 2,
            let row = Int(String(matrix[0])),
            let column = Int(String(matrix[1])) {
            return .init(row: row, column: column)
        } else {
            throw EditorError.couldNotGetCursorPosition
        }
    }

    private func drawRows(bufferWriter: BufferWriter) {
        for index in 0..<screenSize.row {
            let fileRow = Int(index) + Int(contentOffset.y)
            if fileRow >= content.count {
                if content.count == 0 && index == screenSize.row / 3 {
                    // Show welcome message
                    let versionString = "ewis -- version \(Version.current.value)"
                    let welcomeMessage = String(versionString.prefix(min(versionString.count, Int(screenSize.column))))
                    let padding = (Int(screenSize.column) - welcomeMessage.count) / 2
                    if padding > 0 {
                        bufferWriter.append(text: "~")
                        for _ in 0..<padding - 1 {
                            bufferWriter.append(text: " ")
                        }
                    }
                    bufferWriter.append(text: welcomeMessage)
                } else {
                    bufferWriter.append(text: "~")
                }
            } else {
                let line = content[Int(fileRow)]
                let length = min(max(0, line.count - contentOffset.x), screenSize.column)

                if line.count <= contentOffset.x {
                    bufferWriter.append(text: "\0")
                } else {
                    let startIndex = line.index(line.startIndex, offsetBy: contentOffset.x)
                    let endIndex = line.index(startIndex, offsetBy: length)

                    bufferWriter.append(text: String(line[startIndex..<endIndex]))
                }
            }

            bufferWriter.append(command: .eraseInLine)

            if index < screenSize.row - 1 {
                bufferWriter.append(text: "\r\n")
            }
        }
    }

    private func moveCursor(arrowKey: ArrowKey) {
        switch arrowKey {
        case .left:
            if cursorPosition.x > 0 {
                cursorPosition = Point(x: cursorPosition.x - 1, y: cursorPosition.y)
            } else if cursorPosition.y > 0 {
                cursorPosition = Point(x: cursorPosition.x, y: cursorPosition.y - 1)
                if let cursoredLine = cursoredLine {
                    cursorPosition = Point(x: cursoredLine.count, y: cursorPosition.y)
                }
            }
        case .right:
            if let cursoredLine = cursoredLine {
                if cursorPosition.x < cursoredLine.count {
                    cursorPosition = Point(x: cursorPosition.x + 1, y: cursorPosition.y)
                } else if cursorPosition.x == cursoredLine.count {
                    cursorPosition = Point(x: 0, y: cursorPosition.y + 1)
                }
            }
        case .up:
            if cursorPosition.y > 0 {
                cursorPosition = Point(x: cursorPosition.x, y: cursorPosition.y - 1)
            }
        case .down:
            if cursorPosition.y < content.count - 1 {
                cursorPosition = Point(x: cursorPosition.x, y: cursorPosition.y + 1)
            }
        }

        cursorPosition.x = min(cursorPosition.x, cursoredLine?.count ?? 0)
    }

    @discardableResult
    private func readKey() -> UInt {
        var char: UInt8 = 0x00

        while true {
            let nread = read(standardInput.fileDescriptor, &char, 1)
            if nread == 1 { break }
            if nread == -1 && errno != EAGAIN {
                exitFailure("tcsetattr")
            }
        }

        if char == Character("\u{1b}").uint8Value {
            var seq: [UInt8] = Array(repeating: 0x00, count: 3)

            if read(standardInput.fileDescriptor, &seq[0], 1) != 1 {
                return UInt(Character("\u{1b}").uint8Value)
            }
            if read(standardInput.fileDescriptor, &seq[1], 1) != 1 {
                return UInt(Character("\u{1b}").uint8Value)
            }

            if seq[0] == Character("[").uint8Value {
                if seq[1] >= Character("0").uint8Value && seq[1] <= Character("9").uint8Value {
                    if read(standardInput.fileDescriptor, &seq[2], 1) != 1 {
                        return UInt(Character("\u{1b}").uint8Value)
                    }
                    if seq[2] == Character("~").uint8Value {
                        switch seq[1] {
                        case Character("1").uint8Value:
                            return EditorKey.home.rawValue
                        case Character("3").uint8Value:
                            return EditorKey.delete.rawValue
                        case Character("4").uint8Value:
                            return EditorKey.end.rawValue
                        case Character("5").uint8Value:
                            return EditorKey.pageUp.rawValue
                        case Character("6").uint8Value:
                            return EditorKey.pageDown.rawValue
                        case Character("7").uint8Value:
                            return EditorKey.home.rawValue
                        case Character("8").uint8Value:
                            return EditorKey.end.rawValue

                        default: break
                        }
                    }
                } else {
                    switch seq[1] {
                    case Character("A").uint8Value:
                        return EditorKey.arrowUp.rawValue
                    case Character("B").uint8Value:
                        return EditorKey.arrowDown.rawValue
                    case Character("C").uint8Value:
                        return EditorKey.arrowRight.rawValue
                    case Character("D").uint8Value:
                        return EditorKey.arrowLeft.rawValue
                    case Character("H").uint8Value:
                        return EditorKey.home.rawValue
                    case Character("F").uint8Value:
                        return EditorKey.end.rawValue
                    default: break
                    }
                }
            } else if seq[0] == Character("O").uint8Value {
                switch seq[1] {
                case Character("H").uint8Value:
                    return EditorKey.home.rawValue
                case Character("F").uint8Value:
                    return EditorKey.end.rawValue
                default: break
                }
            }

            return UInt(Character("\u{1b}").uint8Value)
        } else {
            return UInt(char)
        }
    }
}
