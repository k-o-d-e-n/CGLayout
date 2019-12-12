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
}
extension View: ElementInLayoutTime {
    var inLayoutTime: ElementInLayoutTime { return self }
    var layoutBounds: CGRect { return bounds }
    var superLayoutBounds: CGRect { return superElement?.layoutBounds ?? .zero }

    func removeFromSuperElement() {
        (superElement as? View)?._removeSubview(self)
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
