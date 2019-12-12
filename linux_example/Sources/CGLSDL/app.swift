import Foundation
import CSDL2
import SDL

import CGLayout

class Application {
    var window: Window?
    var container: ScrollLayoutGuide<Window>?

    init(arguments: Arguments) {
        
    }

    func boot(in systemWindow: SDLWindow) throws {
        let renderer = try SDLRenderer(window: systemWindow)
        let window = Window(renderer: renderer)
        window.backgroundColor = .white

        let redView = View()
        redView.backgroundColor = .red
        let greenView = View()
        greenView.backgroundColor = .green
        let blueView = View()
        blueView.backgroundColor = .blue
        let grayView = View()
        grayView.backgroundColor = Color(red: 230, green: 230, blue: 230, alpha: .max)

        let container = ScrollLayoutGuide<Window>(layout: LayoutScheme(blocks: [
            grayView.layoutBlock(with: .equal),
            redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
            blueView.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(200), height: .fixed(200))),
            greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)))
        ]))
        container.add(to: window)
        container.contentSize = CGSize(width: 800, height: 1500)

        window.addSubview(grayView)
        window.layoutScheme = LayoutScheme(blocks: [
            container.layoutBlock(with: .equal)
        ])
        window.addSubview(greenView)
        window.addSubview(blueView)
        window.addSubview(redView)

        self.window = window
        self.container = container
    }

    func display(in rect: CGRect) throws {
        guard let w = window else { return }

        w.frame = rect /// calls layoutSubviews
        try w.draw(in: rect)
    }

    func keyDidPress(_ event: SDL_KeyboardEvent) {
        let velocity: CGFloat = event.repeat > 0 ? 2 : 1
        switch Int(event.keysym.sym) {
        case SDLK_UP:
            container?.contentOffset.y += velocity
        case SDLK_DOWN:
            container?.contentOffset.y -= velocity
        case SDLK_RIGHT:
            container?.contentOffset.x -= velocity
        case SDLK_LEFT:
            container?.contentOffset.x += velocity
        default:
            print("other key pressed", event)
        }
    }

    var lastWheelEventTimestamp: UInt32 = 0
    func mouseWheel(_ event: SDL_MouseWheelEvent) {
        guard lastWheelEventTimestamp < event.timestamp else { return }
        lastWheelEventTimestamp = event.timestamp

        let x: CGFloat = CGFloat(event.x)
        let y: CGFloat = CGFloat(event.y)
        container?.contentOffset.x += x
        container?.contentOffset.y += y
    }
}
extension Application {
    struct Arguments {

    }
}
