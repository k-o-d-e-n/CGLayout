//: [Previous](@previous)

import UIKit
import CGLayout
import PlaygroundSupport

extension UIView {
    convenience init(frame: CGRect, backgroundColor: UIColor) {
        self.init(frame: frame)
        self.backgroundColor = backgroundColor
    }
}

public extension UIView {
    func addSubviews<S: Sequence>(_ subviews: S) where S.Iterator.Element: UIView {
        subviews.map {
            $0.backgroundColor = $0.backgroundColor?.withAlphaComponent(0.5)
            return $0
            }.forEach(addSubview)
    }
}
public extension CGRect {
    static func random(in source: CGRect) -> CGRect {
        let o = CGPoint(x: CGFloat(arc4random_uniform(UInt32(source.width))), y: CGFloat(arc4random_uniform(UInt32(source.height))))
        let s = CGSize(width: CGFloat(arc4random_uniform(UInt32(source.width - o.x))), height: CGFloat(arc4random_uniform(UInt32(source.height - o.y))))

        return CGRect(origin: o, size: s)
    }
}

func view(by index: Int, color: UIColor, frame: CGRect) -> UIView {
    let label = UILabel(frame: frame, backgroundColor: color)
    label.text = String(index)
    label.textAlignment = .center
    return label
}

let workspaceView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
workspaceView.backgroundColor = .lightGray
PlaygroundPage.current.liveView = workspaceView

let rect1 = view(by: 1, color: .red,
                 frame: workspaceView.bounds.insetBy(dx: 100, dy: 200))

let inner = LayoutWorkspace.After.align(axis: _RectAxis.horizontal, anchor: _RectAxisAnchor.center)

// cropped
let rect2 = view(by: 2, color: .blue,
                 frame: CGRect(origin: .zero, size: CGSize(width: 250, height: 100)))
// cropped to zero
let rect4 = view(by: 4, color: .yellow,
                 frame: CGRect(x: 40, y: 400, width: 40, height: 40))
// equal
let rect6 = view(by: 6, color: .cyan,
                 frame: CGRect(x: 120, y: 500, width: 40, height: 40))

let outer = LayoutWorkspace.Before.align(axis: _RectAxis.horizontal, anchor: _RectAxisAnchor.center)
// cropped
let rect3 = view(by: 3, color: .green,
                 frame: CGRect(origin: CGPoint(x: 70, y: 200), size: CGSize(width: 50, height: 100)))
// cropped to zero
let rect5 = view(by: 5, color: .magenta,
                 frame: CGRect(x: 120, y: 400, width: 40, height: 40))
// equal
let rect7 = view(by: 7, color: .brown,
                 frame: CGRect(x: 10, y: 450, width: 40, height: 40))

/// comment for show initial state
inner.formConstrain(sourceRect: &rect2.frame, by: rect1.frame)
inner.formConstrain(sourceRect: &rect4.frame, by: rect1.frame)
inner.formConstrain(sourceRect: &rect6.frame, by: rect1.frame)
outer.formConstrain(sourceRect: &rect3.frame, by: rect1.frame)
outer.formConstrain(sourceRect: &rect5.frame, by: rect1.frame)
outer.formConstrain(sourceRect: &rect7.frame, by: rect1.frame)

workspaceView.addSubviews([rect1, rect2, rect3, rect4, rect5, rect6, rect7])

