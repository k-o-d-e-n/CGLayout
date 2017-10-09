//: [Previous](@previous)

import UIKit
import CGLayout
import PlaygroundSupport

let sourceView = UIView(frame: UIScreen.main.bounds.insetBy(dx: 200, dy: 200))
sourceView.backgroundColor = .red
let targetView = UIView()
targetView.backgroundColor = .black
sourceView.addSubview(targetView)

PlaygroundPage.current.liveView = sourceView

let layout = targetView.layout { (anchors) in
    anchors.size.equal(to: CGSize(width: 200, height: 40))
    anchors.center.align(by: sourceView.anchors.center)
}

layout.layout()
