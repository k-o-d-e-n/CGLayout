//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import CGLayout

let sourceView = UIView(frame: UIScreen.main.bounds)
sourceView.backgroundColor = .black
let stackLayoutGuide = StackLayoutGuide<UIView>()
sourceView.add(layoutGuide: stackLayoutGuide)

// view
let view = UIView()
view.backgroundColor = .lightGray
stackLayoutGuide.addArranged(element: .uiView(view))

// layer
let layer = CALayer()
layer.backgroundColor = UIColor.gray.cgColor
stackLayoutGuide.addArranged(element: .caLayer(layer))

// layout guide
let stack = StackLayoutGuide<UIView>()
stack.scheme.axis = CGRectAxis.vertical
let view2 = UILabel()
view2.backgroundColor = .lightGray
view2.text = "Stack"
let layer2 = CALayer()
layer.backgroundColor = UIColor.gray.cgColor
stack.addArranged(element: .uiView(view2))
stack.addArranged(element: .caLayer(layer2))
stackLayoutGuide.addArranged(element: .layoutGuide(stack))

PlaygroundPage.current.liveView = sourceView

let layout = stackLayoutGuide.layoutBlock()

layout.layout()
