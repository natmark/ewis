import Foundation

let standardInput = FileHandle.standardInput
let originalTerm = RawMode.enable(fileHandle: standardInput)

while true {
    var char: UInt8 = 0x00
    if read(standardInput.fileDescriptor, &char, 1) == -1 && errno != EAGAIN {
        StandardError.write("read")
        exit(1)
    }
    let inputString = String(bytes: [char], encoding: .utf8)

    if iscntrl(Int32(char)) == 0 {
        print(inputString ?? "")
    } else {
        print(char)
    }

    if inputString == "q" { break }
}

RawMode.disable(fileHandle: standardInput, originalTerm: originalTerm)
