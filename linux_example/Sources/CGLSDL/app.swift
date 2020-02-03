import Foundation
import CSDL2
import SDL

import CGLayout

class Application {
    var window: Window?
    private(set) var isRunning: Bool = false
    private(set) var needsDisplay: Bool = true
    private var firstResponder: View?

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

        let closeButton = Button({ [weak self] btn, point in
            self?.unboot()
        })
        closeButton.backgroundColor = .black

        let textField = TextField()
        textField.backgroundColor = .blue

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
            closeButton.layoutBlock(with: Layout(x: .right(), width: .fixed(20), height: .fixed(20))),
            textField.layoutBlock(with: Layout(x: .center(), width: .scaled(0.3), height: .fixed(20))),
            container.layoutBlock(with: .equal)
        ])
        window.addSubview(greenView)
        window.addSubview(blueView)
        window.addSubview(redView)
        window.addSubview(closeButton)
        window.addSubview(textField)

        self.window = window
        self.container = container
        self.isRunning = true
    }

    func unboot() {
        self.isRunning = false
    }

    func display(in rect: CGRect) throws {
        guard needsDisplay, let w = window else { return }

        w.frame = rect /// calls layoutSubviews
        try w.draw(in: rect)
        needsDisplay = false
    }

    func windowDidResize() {
        needsDisplay = true
    }

    func keyDidPress(_ event: SDL_KeyboardEvent) {
        let velocity: CGFloat = event.repeat > 0 ? 2 : 1
        let key = Int(event.keysym.sym)
        switch key {
        case SDLK_UP:
            container?.contentOffset.y += velocity
        case SDLK_DOWN:
            container?.contentOffset.y -= velocity
        case SDLK_RIGHT:
            container?.contentOffset.x -= velocity
        case SDLK_LEFT:
            container?.contentOffset.x += velocity
        default:
            if let fr = firstResponder as? TextInput, let scalar = Unicode.Scalar(key) {
                let char = String(scalar)
                print(char)
                fr.keyDidPressed(char)
            }
        }
        needsDisplay = true
    }

    var timer: Timer?
    func mouseWheel(_ event: SDL_MouseWheelEvent) {
        guard let c = container else { return }

        let x: CGFloat = CGFloat(event.x)
        let y: CGFloat = CGFloat(event.y) * (event.direction == SDL_MOUSEWHEEL_FLIPPED.rawValue ? -1 : 1)
        c.contentOffset.x += x
        c.contentOffset.y += y
        if let animation = c.decelerate(start: c.contentOffset, translation: nil, velocity: CGPoint(x: CGFloat(-event.x * 150), y: CGFloat(event.y * 250))) {
            timer?.invalidate()
            timer = Timer(timeInterval: 1/60, repeats: true, block: { [weak self] timer in
                if animation.step() {
                    timer.invalidate()
                }
                self?.needsDisplay = true
            })
            RunLoop.current.add(timer!, forMode: .default)
        } else {
            needsDisplay = true
        }
    }

    func mouseButton(_ event: SDL_MouseButtonEvent) {
        guard let w = window else { return }
        let point = CGPoint(x: CGFloat(event.x), y: CGFloat(event.y))
        if let v = w.hitTest(point) {
            if v.isFirstResponder {
                firstResponder = v
            }
        }
    }
}
extension Application {
    struct Arguments {

    }
}
