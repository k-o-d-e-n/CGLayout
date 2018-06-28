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

let layout = targetView.block { (anchors) in
    anchors.width.equal(to: 200)
    anchors.height.equal(to: 40)
    anchors.centerX.align(by: sourceView.layoutAnchors.centerX)
    anchors.centerY.align(by: sourceView.layoutAnchors.centerY)
}

layout.layout()
