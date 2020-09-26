import Foundation

struct RawMode {
    static func enable(fileHandle: FileHandle) -> termios {
        let structPointer = UnsafeMutablePointer<termios>.allocate(capacity: 1)
        var raw = structPointer.pointee
        structPointer.deallocate()

        if tcgetattr(fileHandle.fileDescriptor, &raw) == -1 {
            exitFailure("tcgetattr")
        }

        let original = raw

        // termios(3)
        // https://man7.org/linux/man-pages/man3/termios.3.html
        raw.c_iflag &= ~(UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON))
        raw.c_oflag &= ~(UInt(OPOST))
        raw.c_cflag |= UInt(CS8)
        raw.c_lflag &= ~(UInt(ECHO | ICANON | IEXTEN | ISIG))

        raw.c_cc.16 = 0 // VMIN
        raw.c_cc.17 = 1 // VTIME

        if tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw) == -1 {
            exitFailure("tcsetattr")
        }

        return original
    }

    static func disable(fileHandle: FileHandle, originalTerm: termios) {
        var term = originalTerm
        if tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &term) == -1 {
            exitFailure("tcsetattr")
        }
    }
}
