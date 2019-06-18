import gui
import wnim


proc main() =
    panel.wEventSize do():
        gui.layout()
    gui.layout()
    gui.frame.center()
    gui.frame.show()
    gui.app.mainLoop()


when isMainModule:
    main()