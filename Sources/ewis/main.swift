import Foundation

func main() {
    while true {
        Editor.shared.refreshScreen()
        Editor.shared.processKeyPress()
    }
}

main()
