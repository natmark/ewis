import Foundation
import ArgumentParser

struct Ewis: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ewis",
        abstract: "Editor written in Swift",
        version: Version.current.value,
        shouldDisplay: true,
        helpNames: [.long, .short]
    )

    @Argument(help: "edit specified file")
    var filePath: String

    mutating func run() throws {
        let editor: EditorProtocol = Editor.shared

        editor.open(URL(fileURLWithPath: filePath))

        editor.setStatusMessage(statusMessage: "HELP: Ctrl-Q = quit")

        while true {
            editor.refreshScreen()
            editor.processKeyPress()
        }
    }
}

Ewis.main()
