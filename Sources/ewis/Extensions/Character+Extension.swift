import Foundation

extension Character {
    var uint8Value: UInt8 {
        guard let asciiValue = String(self).uint8Value.first else {
            fatalError()
        }
        return asciiValue
    }

    var controlKey: UInt8 {
        return UInt8(uint8Value) & 0x1f
    }

    var key: UInt8 {
        return uint8Value
    }
}
