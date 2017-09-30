//
//  ViewController.swift
//  CGLayout
//
//  Created by k-o-d-e-n on 08/31/2017.
//  Copyright (c) 2017 k-o-d-e-n. All rights reserved.
//

import UIKit
import CGLayout

class LabelPlaceholder: ViewPlaceholder<UILabel> {
    var font: UIFont?
    var textColor: UIColor?
    override var frame: CGRect {
        didSet { itemIfLoaded?.frame = frame }
    }

    open override func itemDidLoad() {
        super.itemDidLoad()

        item.font = font
        item.textColor = textColor
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
    var subviews: [UIView] = []
    let pulledView: UIView = UIView()
    let centeredView: UIView = UIView()
    let navigationBarBackView = UIView()
    let subview = UIView()

    lazy var stackScheme: StackLayoutScheme = { [unowned self] in
        var stack = StackLayoutScheme { Array(self.subviews[0..<7]) }
        stack.axis = .vertical
        stack.direction = .toLeading
        stack.itemLayout = Layout(x: .left(215), y: .bottom(10), width: .boxed(235), height: .fixed(50))

        return stack
    }()
    lazy var stackLayoutGuide: StackLayoutGuide<UIView> = {
        let stack = StackLayoutGuide<UIView>(frame: .zero)
        stack.scheme.axis = .vertical
        stack.scheme.itemLayout = Layout(x: .left(5), y: .top(5), width: .boxed(10), height: .fixed(20))

        return stack
    }()
    lazy var substackLayoutGuide: StackLayoutGuide<UIView> = {
        let stack = StackLayoutGuide<UIView>(frame: .zero)
        stack.scheme.axis = .horizontal
        stack.scheme.itemLayout = Layout(x: .left(2), y: .top(2), width: .fixed(20), height: .boxed(2))

        return stack
    }()
    lazy var latestItemLayout = Layout(vertical: (.top(10), .boxed(20)),
                                       horizontal: (.left(15), .fixed(30)))
    lazy var pulledLayout = Layout(x: .left(15), y: .top(10),
                                   width: .boxed(25), height: .boxed(20))
    lazy var bottomConstraint = LayoutAnchor.Bottom.limit(on: .inner)
    lazy var rightConstraint = LayoutAnchor.Right.limit(on: .outer)

    lazy var labelPlaceholder: LabelPlaceholder = LabelPlaceholder(font: .systemFont(ofSize: 24), textColor: .red)

    override func viewDidLoad() {
        super.viewDidLoad()

        subviews = (0..<10).map { i -> UIView in
            let view = UIView()
            view.backgroundColor = UIColor(white: (1 - (1 / max(0.5,CGFloat(i)))), alpha: 1 / max(0.5,CGFloat(i)))
            return view
        }
        subviews.forEach(view.addSubview)
        view.addSubview(pulledView)
        pulledView.backgroundColor = .red
        view.addSubview(centeredView)
        centeredView.backgroundColor = .yellow
        view.addSubview(navigationBarBackView)
        navigationBarBackView.backgroundColor = .black
        subview.backgroundColor = .red
        pulledView.addSubview(subview)

        view.add(layoutGuide: labelPlaceholder)
        pulledView.add(layoutGuide: stackLayoutGuide)
        stackLayoutGuide.addArrangedItem(UIView(backgroundColor: .brown))
        stackLayoutGuide.addArrangedItem(UIView(backgroundColor: .yellow))
        stackLayoutGuide.addArrangedItem(CALayer(backgroundColor: .green))
        stackLayoutGuide.addArrangedItem(substackLayoutGuide)
        substackLayoutGuide.addArrangedItem(UIView(backgroundColor: .brown))
        substackLayoutGuide.addArrangedItem(CALayer(backgroundColor: .yellow))
        substackLayoutGuide.addArrangedItem(UIView(backgroundColor: .green))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let constrainedRect = CGRect(origin: .zero, size: CGSize(width: 200, height: 0))
        stackScheme.layout()
        var preview = self.subviews[0..<7].last
        let lastPreview = self.subviews[0..<7].last
        subviews[7..<10].forEach { subview in
            let constraints: [ConstrainRect] = [(lastPreview!.frame, bottomConstraint), (constrainedRect, rightConstraint)]
            let constraint: [ConstrainRect] = preview === lastPreview ? [] : [(preview!.frame, rightConstraint)]
            latestItemLayout.apply(for: subview, use: constraints + constraint)
            preview = subview
        }

        let topConstraint: LayoutAnchor.Top = traitCollection.verticalSizeClass == .compact ? .pull(from: .outer) : .limit(on: .outer)

        labelPlaceholder.layoutBlock(with: Layout(x: .right(), y: .top(), width: .scaled(0.6), height: .fixed(100)), constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.Bottom.align(by: .outer)])]).layout()

        pulledLayout.apply(for: pulledView, use: [((topLayoutGuide as! UIView).frame, LayoutAnchor.Bottom.limit(on: .outer)), (labelPlaceholder.frame, LayoutAnchor.Left.limit(on: .outer)),
                                                  (subviews[1].frame, LayoutAnchor.Left.limit(on: .outer)), (subviews.first!.frame, topConstraint)])
        Layout.equal.apply(for: stackLayoutGuide)

        let centeredViewLayout = centeredView.layoutBlock(with: Layout(x: .center(), y: .bottom(), width: .fixed(20), height: .fixed(30)),
                                 constraints: [subviews[7].layoutConstraint(for: [LayoutAnchor.Center.align(by: .center)])])

        // layout using only constraints and constrain to view (UINavigationController.view) from other hierarchy space. 
        navigationBarBackView.layoutBlock(with: Layout.equal, constraints: [navigationController!.navigationBar.layoutConstraint(for: [LayoutAnchor.equal])]).layout()

        let subviewLayout = subview.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(50), height: .fixed(1)),
                            constraints: [centeredView.layoutConstraint(for: [LayoutAnchor.equal])])
        let subviewScheme = LayoutScheme(blocks: [centeredViewLayout, subviewLayout])
        let snapshotSubview = subviewScheme.snapshot(for: view.bounds)
        subviewScheme.apply(snapshot: snapshotSubview)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        labelPlaceholder.item.text = "Placeholder label"
    }
}

extension UIView {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
}
