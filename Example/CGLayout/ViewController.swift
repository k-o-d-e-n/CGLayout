//
//  ViewController.swift
//  CGLayout
//
//  Created by k-o-d-e-n on 08/31/2017.
//  Copyright (c) 2017 k-o-d-e-n. All rights reserved.
//

import UIKit
import CGLayout

// TODO: Add UIScrollView

class ViewController: UIViewController {
    var subviews: [UIView] = []
    let pulledView: UIView = UIView()
    lazy var itemLayout = Layout(alignmentV: .bottom(10), fillingV: .constantly(50),
                                 alignmentH: .left(15), fillingH: .boxed(.init(left: 15, right: 20)))
    lazy var latestItemLayout = Layout(vertical: (.top(10), .boxed(.init(top: 10, bottom: 10))),
                                       horizontal: (.left(15), .constantly(30)))
    lazy var pulledLayout = Layout(alignmentV: .top(10), fillingV: .boxed(UIEdgeInsets.Vertical(top: 10, bottom: 10)),
                                   alignmentH: .left(15), fillingH: .boxed(.init(left: 15, right: 10)))
    lazy var bottomConstraint = LayoutAnchor.Bottom.limit(on: .inner)
    lazy var rightConstraint = LayoutAnchor.Right.limit(on: .outer)

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var preview: UIView?
        let constrainedRect = CGRect(origin: .zero, size: CGSize(width: 200, height: 0))
        subviews[0..<7].forEach { subview in
            let constraints: [ConstraintItem] = preview.map { [($0.frame, bottomConstraint), (constrainedRect, rightConstraint)] } ?? []
            itemLayout.apply(for: subview, use: constraints)
            preview = subview
        }
        let lastPreview = preview
        subviews[7..<10].forEach { subview in
            let constraints: [ConstraintItem] = [(lastPreview!.frame, bottomConstraint), (constrainedRect, rightConstraint)]
            let constraint: [ConstraintItem] = preview === lastPreview ? [] : [(preview!.frame, rightConstraint)]
            latestItemLayout.apply(for: subview, use: constraints + constraint)
            preview = subview
        }

        let topConstraint: LayoutAnchor.Top = traitCollection.verticalSizeClass == .compact ? .pull(from: .outer) : .limit(on: .outer)
        let topRect = CGRect(x: 0, y: 0, width: 0, height: 300)
        let rightRect = CGRect(x: self.view.bounds.width - 300, y: 0, width: 300, height: 0)

        pulledLayout.apply(for: pulledView, use: [(topRect, LayoutAnchor.Bottom.limit(on: .outer)), (rightRect, LayoutAnchor.Left.limit(on: .outer)),
                                                  (subviews[1].frame, LayoutAnchor.Left.limit(on: .outer)), (subviews.first!.frame, topConstraint)])
    }
}
