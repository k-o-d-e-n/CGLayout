import CSDL2
import SDL
import Foundation

print("All Render Drivers:")
let renderDrivers = SDLRenderer.Driver.all
if renderDrivers.isEmpty == false {
    print("=======")
    for driver in renderDrivers {
        
        do {
            let info = try SDLRenderer.Info(driver: driver)
            print("Driver:", driver.rawValue)
            print("Name:", info.name)
            print("Options:")
            info.options.forEach { print("  \($0)") }
            print("Formats:")
            info.formats.forEach { print("  \($0)") }
            if info.maximumSize.width > 0 || info.maximumSize.height > 0 {
                print("Maximum Size:")
                print("  Width: \(info.maximumSize.width)")
                print("  Height: \(info.maximumSize.height)")
            }
            print("=======")
        } catch {
            print("Could not get information for driver \(driver.rawValue)")
        }
    }
}


func main() throws {
    try SDL.initialize(subSystems: [.video])
    defer { SDL.quit() }
    
    let windowSize = (width: 600, height: 480)
    let window = try SDLWindow(
        title: "CGL+SDL",
        frame: (x: .centered, y: .centered, width: windowSize.width, height: windowSize.height),
        options: [.resizable, .shown]
    )
    let application = Application(arguments: Application.Arguments())
    
    let framesPerSecond = try window.displayMode().refreshRate
    print("Running at \(framesPerSecond) FPS")

    var event = SDL_Event()
    let frameInterval = 1000 / UInt32(framesPerSecond)
    var lastWheelEventTimestamp: UInt32 = 0

    try application.boot(in: window)
    
    while application.isRunning {
        #if os(Linux)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
        #endif

        SDL_PollEvent(&event)
        
        let startTime = SDL_GetTicks()
        let eventType = SDL_EventType(rawValue: event.type)
        
        switch eventType {
        case SDL_QUIT, SDL_APP_TERMINATING:
            application.unboot()
        case SDL_KEYDOWN:
            application.keyDidPress(event.key)
            // print("key_down")
        case SDL_MOUSEWHEEL:
            guard event.wheel.timestamp != lastWheelEventTimestamp else { break }
            lastWheelEventTimestamp = event.wheel.timestamp
            application.mouseWheel(event.wheel)
            // print("mouse_wheel")
        case SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
            application.mouseButton(event.button)
            // print("mouse btn"/* , event.button */)
        case SDL_FINGERUP, SDL_FINGERDOWN, SDL_FINGERMOTION:
            print("finger"/*, event.tfinger*/)
        case SDL_WINDOWEVENT:
            switch SDL_WindowEventID(UInt32(event.window.event)) {
            case SDL_WINDOWEVENT_SHOWN:
                break;
            case SDL_WINDOWEVENT_HIDDEN:
                break;
            case SDL_WINDOWEVENT_EXPOSED:
                break;
            case SDL_WINDOWEVENT_MOVED:
                break;
            case SDL_WINDOWEVENT_RESIZED:
                application.windowDidResize()
                print("window_resized")
            case SDL_WINDOWEVENT_SIZE_CHANGED:
                application.windowDidResize()
                print("window_size_changed")
            case SDL_WINDOWEVENT_MINIMIZED:
                break;
            case SDL_WINDOWEVENT_MAXIMIZED:
                break;
            case SDL_WINDOWEVENT_RESTORED:
                break;
            case SDL_WINDOWEVENT_ENTER:
                break;
            case SDL_WINDOWEVENT_LEAVE:
                break;
            case SDL_WINDOWEVENT_FOCUS_GAINED:
                break;
            case SDL_WINDOWEVENT_FOCUS_LOST:
                break;
            case SDL_WINDOWEVENT_CLOSE:
                break;
            case SDL_WINDOWEVENT_TAKE_FOCUS:
                break;
            case SDL_WINDOWEVENT_HIT_TEST:
                print("clicked")
                break;
            default:
                break;
            }
        default:
            break
        }
        
        if application.needsDisplay {
            let size = window.size
            let rect = CGRect(x: 0, y: 0, width: CGFloat(size.width), height: CGFloat(size.height))
            try application.display(in: rect)
        }
        
        // sleep to save energy
        let frameDuration = SDL_GetTicks() - startTime
        if frameDuration < frameInterval {
            SDL_Delay(frameInterval - frameDuration)
        }
    }
}

do { try main() }
catch let error as SDLError {
    print("Error: \(error.debugDescription)")
    exit(EXIT_FAILURE)
}
catch {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}