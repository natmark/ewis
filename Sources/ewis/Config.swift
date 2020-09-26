import Foundation

struct Config {
    static var quitKey: UInt8 = Character("q").controlKey
    static var allowLeft: UInt8 = Character("a").key
    static var allowRight: UInt8 = Character("d").key
    static var allowUp: UInt8 = Character("w").key
    static var allowDown: UInt8 = Character("s").key
}
