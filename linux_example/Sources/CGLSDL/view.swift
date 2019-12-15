import Foundation
import CGLayout
import SDL
import CSDL2

struct Color {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}
extension Color {
    static var white: Color { return Color(red: .max, green: .max, blue: .max, alpha: .max) }
    static var black: Color { return Color(red: 0, green: 0, blue: 0, alpha: .max) }
    static var red: Color { return Color(red: .max, green: 0, blue: 0, alpha: .max) }
    static var green: Color { return Color(red: 0, green: .max, blue: 0, alpha: .max) }
    static var blue: Color { return Color(red: 0, green: 0, blue: .max, alpha: .max) }

    func sdlColor(format: SDLPixelFormat) -> SDLColor {
        return SDLColor(
            format: format,
            red: red, green: green, blue: blue, alpha: alpha
        )
    }
}

class View: LayoutElement {
    var frame: CGRect = .zero {
        didSet { bounds = CGRect(origin: .zero, size: frame.size) }
    }
    var bounds: CGRect = .zero {
        didSet(oldValue) {
            if oldValue != bounds {
                layoutSubviews()
            }
        }
    }
    weak var superElement: LayoutElement?
    var subviews: [View] = []
    var isHidden: Bool = false
    var isFirstResponder: Bool { return false }
    var backgroundColor: Color?
    var layoutScheme: LayoutScheme?

    var _cachedTexture: SDLTexture?

    func draw(in rect: CGRect, use renderer: SDLRenderer) throws -> SDLTexture? {
        guard !isHidden else { return nil }
        guard let surfaceTexture = _cachedTexture else {
            let surface = try SDLSurface(rgb: (0, 0, 0, 0), size: (width: 1, height: 1), depth: 32)
            if let c = self.backgroundColor {
                let color = SDLColor(
                    format: try SDLPixelFormat(format: .argb8888),
                    red: c.red, green: c.green, blue: c.blue, alpha: c.alpha
                )
                try surface.fill(color: color)
            }
            let surfaceTexture = try SDLTexture(renderer: renderer, surface: surface)
            try surfaceTexture.setBlendMode([.alpha])

            self._cachedTexture = surfaceTexture
            
            return surfaceTexture
        }
        return surfaceTexture
    }

    func layoutSubviews() {
        layoutScheme?.layout(in: layoutBounds)
    }

    func addSubview(_ subview: View) {
        subviews.append(subview)
        subview.superElement = self
    }

    func _removeSubview(_ subview: View) {
        subview.superElement = nil
        subviews.removeAll(where: { $0 === subview })
    }

    func hitTest(_ point: CGPoint) -> View? {
        guard bounds.contains(point) else { return nil }
        for view in subviews {
            if let v = view.hitTest(CGPoint(x: point.x - view.frame.minX, y: point.y - view.frame.minY)) {
                return v
            }
        }
        return interactionBegan(point) ? self : nil
    }

    func interactionBegan(_ point: CGPoint) -> Bool {
        return false
    }
}
extension View: ElementInLayoutTime {
    var inLayoutTime: ElementInLayoutTime { return self }
    var layoutBounds: CGRect { return bounds }
    var superLayoutBounds: CGRect { return superElement?.layoutBounds ?? .zero }

    func removeFromSuperElement() {
        (superElement as? View)?._removeSubview(self)
    }
}

class Button: View {
    let onInteraction: (Button, CGPoint) -> Void

    init(_ onInteraction: @escaping (Button, CGPoint) -> Void) {
        self.onInteraction = onInteraction
    }

    override func interactionBegan(_ point: CGPoint) -> Bool {
        onInteraction(self, point)
        return true
    }
}

protocol TextInput {
    func keyDidPressed(_ event: String)
}

class TextField: View, TextInput {
    private var symbols: [View] = []
    private(set) var _isFirstResponder: Bool = false
    override var isFirstResponder: Bool { return _isFirstResponder }
    override var bounds: CGRect {
        didSet {
            if let c = cursor, oldValue.height != bounds.height {
                c.frame.size.height = bounds.height
            }
        }
    }
    private(set) var text: String = "" {
        didSet { _textDidChanged(with: text, in: (0..<text.count)) }
    }
    private(set) var cursorPosition: Int = 0

    weak var cursor: View?

    override func draw(in rect: CGRect, use renderer: SDLRenderer) throws -> SDLTexture? {
        try text.enumerated().forEach { i, char in
            let offset = CGFloat(i * 10)
            try renderer.fill(
                rect: SDL_Rect(
                    x: Int32(frame.minX + offset), y: Int32(frame.minY),
                    w: 10, h: Int32(bounds.height)
                )
            )
        }
        if let c = cursor {
            try renderer.setDrawColor(red: 0x00, green: 0x00, blue: 0x00, alpha: 0xFF)
            try renderer.fill(
                rect: SDL_Rect(
                    x: Int32(c.frame.minX + frame.minX + (text.count * 10)), y: Int32(c.frame.minY + frame.minY),
                    w: Int32(1), h: Int32(bounds.height)
                )
            )
        }
        return nil//try super.draw(in: rect, use: renderer)
    }

    override func interactionBegan(_ point: CGPoint) -> Bool {
        guard isFirstResponder else {
            becomeFirstResponder()
            return true
        }
        if let c = cursor {
            cursorPosition = min(Int(point.x / 10), text.count)
            c.frame.origin.x = CGFloat(cursorPosition * 10)
        }
        return true
    }

    func becomeFirstResponder() {
        guard !_isFirstResponder else { return }
        _isFirstResponder = true

        let cursor = View()
        addSubview(cursor)
        self.cursor = cursor
    }

    func resignFirstResponder() {
        _isFirstResponder = false
        cursor?.removeFromSuperElement()
    }

    func keyDidPressed(_ event: String) {
        let index = text.index(text.startIndex, offsetBy: cursorPosition)
        text.insert(contentsOf: event, at: index)
        _textDidChanged(with: event, in: (cursorPosition..<cursorPosition + event.count))
        cursorPosition += event.count
    }

    func _textDidChanged(with newText: String, in range: Range<Int>) {
        
    }
}

class Window: View {
    override weak var superElement: LayoutElement? {
        set {}
        get { return nil }
    }
    let renderer: SDLRenderer

    init(renderer: SDLRenderer) {
        self.renderer = renderer
    }

    func draw(in rect: CGRect) throws {
        _ = try draw(in: rect, use: renderer)
    }

    override func draw(in rect: CGRect, use renderer: SDLRenderer) throws -> SDLTexture? {
        try renderer.setDrawColor(red: 0xFF, green: 0xFF, blue: 0xFF, alpha: 0xFF)
        try renderer.clear()
        try subviews.forEach({ view in
            if let texture = try view.draw(in: frame, use: renderer) {
                try renderer.copy(
                    texture,
                    destination: SDL_Rect(
                        x: Int32(view.frame.minX), y: Int32(view.frame.minY),
                        w: Int32(view.frame.width), h: Int32(view.frame.height)
                    )
                )
            }
        })

        renderer.present()
        return nil
    }
}
