//: [Previous](@previous)

import UIKit
import CGLayout
import PlaygroundSupport

let sourceView = UIView(frame: UIScreen.main.bounds.insetBy(dx: 200, dy: 200))
sourceView.backgroundColor = .red
let targetView = UIView(frame: CGRect(x: 20, y: 400, width: 200, height: 40))
targetView.backgroundColor = .black
sourceView.addSubview(targetView)

PlaygroundPage.current.liveView = sourceView

sourceView.anchors.bottom.move(in: &targetView.frame, to: sourceView.frame.maxY)
sourceView.anchors.top.offset(rect: &targetView.frame, by: (sourceView.frame, sourceView.anchors.top))
