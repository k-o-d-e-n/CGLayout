//: Playground - noun: a place where people can play

import UIKit
import CGLayout
import PlaygroundSupport

let layout = Layout(x: .left(15), y: .top(15), width: .scaled(0.5), height: .fixed(20))
let sourceView = UIView(frame: UIScreen.main.bounds.insetBy(dx: 200, dy: 200))
sourceView.backgroundColor = .red
let targetView = UIView(frame: CGRect(x: 20, y: 400, width: 200, height: 40))
targetView.backgroundColor = .black
sourceView.addSubview(targetView)

layout.apply(for: targetView)

PlaygroundPage.current.liveView = sourceView
