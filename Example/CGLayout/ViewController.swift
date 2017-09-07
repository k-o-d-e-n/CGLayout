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
        didSet { viewIfLoaded?.frame = frame }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.font = font
        view.textColor = textColor
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

/// Example extending
extension Layout.Filling.Horizontal {
    static var equal: Layout.Filling.Horizontal { return .build(Layout.equal) }
}

class ViewController: UIViewController {
    var subviews: [UIView] = []
    let pulledView: UIView = UIView()
    let centeredView: UIView = UIView()
    let navigationBarBackView = UIView()

    lazy var itemLayout = Layout(x: .left(15), y: .bottom(10), width: .boxed(35), height: .fixed(50))
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

        view.add(layoutGuide: labelPlaceholder)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var preview: UIView?
        let constrainedRect = CGRect(origin: .zero, size: CGSize(width: 200, height: 0))
        subviews[0..<7].forEach { subview in
            let constraints: [ConstrainRect] = preview.map { [($0.frame, bottomConstraint), (constrainedRect, rightConstraint)] } ?? []
            itemLayout.apply(for: subview, use: constraints)
            preview = subview
        }
        let lastPreview = preview
        subviews[7..<10].forEach { subview in
            let constraints: [ConstrainRect] = [(lastPreview!.frame, bottomConstraint), (constrainedRect, rightConstraint)]
            let constraint: [ConstrainRect] = preview === lastPreview ? [] : [(preview!.frame, rightConstraint)]
            latestItemLayout.apply(for: subview, use: constraints + constraint)
            preview = subview
        }

        let topConstraint: LayoutAnchor.Top = traitCollection.verticalSizeClass == .compact ? .pull(from: .outer) : .limit(on: .outer)

        labelPlaceholder.layoutBlock(with: Layout(x: .right(), y: .top(), width: .scaled(0.6), height: .fixed(100)), constraints: [(topLayoutGuide as! UIView).constraintItem(for: [LayoutAnchor.Bottom.align(by: .outer)])]).layout()

        pulledLayout.apply(for: pulledView, use: [((topLayoutGuide as! UIView).frame, LayoutAnchor.Bottom.limit(on: .outer)), (labelPlaceholder.frame, LayoutAnchor.Left.limit(on: .outer)),
                                                  (subviews[1].frame, LayoutAnchor.Left.limit(on: .outer)), (subviews.first!.frame, topConstraint)])

        centeredView.layoutBlock(with: Layout(x: .center(), y: .bottom(), width: .fixed(20), height: .fixed(30)),
                                 constraints: [subviews[7].constraintItem(for: [LayoutAnchor.Center.align(by: .center)])]).layout()

        // layout using only constraints and constrain to view (UINavigationController.view) from other hierarchy space. 
        navigationBarBackView.layoutBlock(with: Layout.equal, constraints: [navigationController!.navigationBar.constraintItem(for: [LayoutAnchor.equal])]).layout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        labelPlaceholder.view.text = "Placeholder label"
    }
}
