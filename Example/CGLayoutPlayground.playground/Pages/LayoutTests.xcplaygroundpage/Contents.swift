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

let scaleView = UIView()
scaleView.backgroundColor = .gray
let scaledView = UIView()
scaledView.backgroundColor = .green
let scaled2View = UIView()
scaled2View.backgroundColor = .lightGray
sourceView.addSubview(scaled2View)
sourceView.addSubview(scaledView)
sourceView.addSubview(scaleView)

let scheme = LayoutScheme(blocks: [
    scaleView.layoutBlock(
        with: Layout(x: .center(), y: .center(), width: .fixed(50), height: .fixed(50))
    ),
    scaledView.layoutBlock(
        with: Layout(x: .left(-10), y: .top(-10), width: .boxed(-20), height: .boxed(-20)),
        constraints: [
            scaleView.layoutConstraint(for: [
                .size(.width()), .size(.height()), .center(.align(by: .center))
            ])
        ]
    ),
    scaled2View.layoutBlock(
        with: Layout(x: .left(multiplier: -0.25), y: .top(multiplier: -0.25), width: .scaled(1.5), height: .scaled(1.5)),
        constraints: [
            scaledView.layoutConstraint(for: [
                .size(.width()), .size(.height()), .center(.align(by: .center))
            ])
        ]
    )
])

scheme.layout()

PlaygroundPage.current.liveView = sourceView
