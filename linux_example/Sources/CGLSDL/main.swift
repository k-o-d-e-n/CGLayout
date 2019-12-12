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
    var isRunning = true
    
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

    var frame = 0
    var event = SDL_Event()
    var needsDisplay = true

    try application.boot(in: window)
    
    while isRunning {
        SDL_PollEvent(&event)
        
        // increment ticker
        frame += 1
        let startTime = SDL_GetTicks()
        let eventType = SDL_EventType(rawValue: event.type)
        
        switch eventType {
        case SDL_QUIT, SDL_APP_TERMINATING:
            isRunning = false
        case SDL_KEYDOWN:
            application.keyDidPress(event.key)
            needsDisplay = true
        case SDL_MOUSEWHEEL:
            application.mouseWheel(event.wheel)
            needsDisplay = true
        case SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
            print("mouse btn", event.button)
        case SDL_FINGERUP, SDL_FINGERDOWN, SDL_FINGERMOTION:
            print("finger", event.tfinger)
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
                needsDisplay = true
                break;
            case SDL_WINDOWEVENT_SIZE_CHANGED:
                needsDisplay = true
                break;
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
        
        if needsDisplay {
            let size = window.size
            let rect = CGRect(x: 0, y: 0, width: CGFloat(size.width), height: CGFloat(size.height))
            try application.display(in: rect)
            
            needsDisplay = false
        }
        
        // sleep to save energy
        let frameDuration = SDL_GetTicks() - startTime
        if frameDuration < 1000 / UInt32(framesPerSecond) {
            SDL_Delay((1000 / UInt32(framesPerSecond)) - frameDuration)
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
