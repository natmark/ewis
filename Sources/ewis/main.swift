import Foundation

func main() {
    let editor: EditorProtocol = Editor.shared
    let fileURL = URL(fileURLWithPath: "/Users/atsuya-sato/Desktop/rit/rit.gemspec")

    editor.open(fileURL)

    editor.setStatusMessage(statusMessage: "HELP: Ctrl-Q = quit")

    while true {
        editor.refreshScreen()
        editor.processKeyPress()
    }
}

main()
