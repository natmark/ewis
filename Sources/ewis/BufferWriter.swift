import Foundation

class BufferWriter {
    var standardOutput: FileHandle
    var buffer: String = ""

    init(standardOutput: FileHandle) {
        self.standardOutput = standardOutput
    }

    func append(text: String) {
        buffer += text
    }

    func append(command: Command) {
        buffer += command.rawValue
    }

    @discardableResult
    func flush() -> Bool {
        let status = write(standardOutput: standardOutput, string: buffer)
        buffer = ""
        return status
    }
}
