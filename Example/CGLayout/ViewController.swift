//
//  ViewController.swift
//  CGLayout
//
//  Created by k-o-d-e-n on 08/31/2017.
//  Copyright (c) 2017 k-o-d-e-n. All rights reserved.
//

import UIKit
import CGLayout

extension UIView {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
}

extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
        self.numberOfLines = 0
    }
}

class LabelPlaceholder: ViewPlaceholder<UILabel> {
    var font: UIFont?
    var textColor: UIColor?
    override var frame: CGRect {
        didSet { elementIfLoaded?.frame = frame }
    }

    open override func elementDidLoad() {
        super.elementDidLoad()

        element.font = font
        element.textColor = textColor
    }

    convenience init() {
        self.init(frame: .zero)
    }
    convenience init(font: UIFont, textColor: UIColor) {
        self.init()
        self.font = font
        self.textColor = textColor
    }
}

class ViewController: UIViewController {
    var scrollView: UIScrollView { return view as! UIScrollView }
    var elements: [UIView] = []

    lazy var scheme: LayoutScheme = self.buildScheme()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.contentSize.height = view.frame.height
        scrollView.contentSize.width = view.frame.width

        self.elements = (0..<10).map { (i) -> UIView in
            let view = buildView(UIView.self, bg: UIColor(white: CGFloat(i) / 10, alpha: 1))
            view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(view)
            return view
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout()
    }

    private func buildScheme() -> LayoutScheme {
        let borderLayer = CALayer()
        borderLayer.borderWidth = 1
        view.layer.addSublayer(borderLayer)

        let initial: (blocks: [LayoutBlockProtocol], last: UIView?) = ([], nil)
        return LayoutScheme(
            blocks: elements.reduce(into: initial) { (blocks, view) -> Void in
                var constraints: [LayoutConstraintProtocol] = []
                if let last = blocks.last {
                    constraints.append(last.layoutConstraint(for: [.top(.limit(on: .outer))]))
                } else {
                    constraints.append(scrollView.layoutConstraint(for: [.bottom(.limit(on: .inner))]))
                }
                blocks.blocks += [
                    view.layoutBlock(
                        with: Layout(x: .equal, y: blocks.last == nil ? .bottom() : .bottom(between: 0...10), width: .equal, height: .fixed(50)) + .top(0...),
                        constraints: constraints
                    )
                ]
                blocks.last = view
            }.blocks + [
                borderLayer.layoutBlock(constraints: [
                    scrollView.contentLayoutConstraint(for: [.equally])
                ])
            ]
        )
    }
}
