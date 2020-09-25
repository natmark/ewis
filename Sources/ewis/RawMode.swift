import Foundation

struct RawMode {
    static func enable(fileHandle: FileHandle) -> termios {
        let structPointer = UnsafeMutablePointer<termios>.allocate(capacity: 1)
        var raw = structPointer.pointee
        structPointer.deallocate()

        if tcgetattr(fileHandle.fileDescriptor, &raw) == -1 {
            StandardError.write("tcgetattr")
            exit(1)
        }

        let original = raw

        raw.c_iflag &= ~(UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON))
        raw.c_oflag &= ~(UInt(OPOST))
        raw.c_cflag |= UInt(CS8)
        raw.c_lflag &= ~(UInt(ECHO | ICANON | IEXTEN | ISIG))

        raw.c_cc.16 = 0 // VMIN
        raw.c_cc.17 = 1 // VTIME

        if tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw) == -1 {
            StandardError.write("tcsetattr")
            exit(1)
        }

        return original
    }

    static func disable(fileHandle: FileHandle, originalTerm: termios) {
        var term = originalTerm
        if tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &term) == -1 {
            StandardError.write("tcsetattr")
            exit(1)
        }
    }
}
