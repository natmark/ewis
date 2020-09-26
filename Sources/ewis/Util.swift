import Foundation

func exitFailure(_ errorMessage: String) {
    Editor.shared.refreshScreen()
    StandardError.write(errorMessage)
    exit(EXIT_FAILURE)
}

@discardableResult
func writeCommand(standardOutput: FileHandle, command: Command) -> Bool {
    return write(standardOutput.fileDescriptor, command.rawValue, command.rawValue.uint8Value.count) == command.rawValue.uint8Value.count
}

@discardableResult
func write(standardOutput: FileHandle, string: String) -> Bool {
    return write(standardOutput.fileDescriptor, string, string.uint8Value.count) == string.uint8Value.count
}
