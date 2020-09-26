import Foundation

extension StringProtocol {
    var uint8Value: [UInt8] { Array(self.utf8) }
}
