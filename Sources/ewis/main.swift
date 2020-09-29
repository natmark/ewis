import Foundation

func main() {
    let editor: EditorProtocol = Editor.shared
    let fileURL = URL(fileURLWithPath: "/Users/atsuya-sato/Desktop/rit/rit.gemspec")

    editor.open(fileURL)

    while true {
        editor.refreshScreen()
        editor.processKeyPress()
    }
}

main()
