//
//  ScrollLayoutViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 15/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

class ScrollLayoutViewController: UIViewController {
    var scrollLayoutGuide: ScrollLayoutGuide<UIView>!

    var subviews: [LayoutItem] = []
    var scheme: LayoutScheme!

    override func viewDidLoad() {
        super.viewDidLoad()

        let redView = UIView(backgroundColor: .red)
        subviews.append(redView)
        let greenView = UIView(backgroundColor: .green)
        subviews.append(greenView)
        let contentGuide = LayoutGuide<UIView>(frame: view.bounds.insetBy(dx: -100, dy: -300))
        subviews.append(contentGuide)

        let contentScheme = LayoutScheme(blocks: [
            contentGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(contentGuide.frame.width), height: .fixed(contentGuide.frame.height))),
            redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
            greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)),
                                  constraints: [contentGuide.layoutConstraint(for: [LayoutAnchor.Left.align(by: .inner), LayoutAnchor.Bottom.align(by: .inner)])])
        ])
        
        scrollLayoutGuide = ScrollLayoutGuide(layout: contentScheme)
        scheme = LayoutScheme(blocks: [scrollLayoutGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1)),
                                                                     constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.Bottom.limit(on: .outer)])]),
                                       contentScheme])

        view.add(layoutGuide: scrollLayoutGuide)
        view.add(layoutGuide: contentGuide)
        view.addSublayoutItem(redView)
        view.addSublayoutItem(greenView)

        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:))))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout()
    }

    var start: CGPoint = .zero
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        var targetPosition = CGPoint(x: start.x - translation.x, y: start.y - translation.y)
        var nextTargetPosition = targetPosition

        var animated = false
        switch recognizer.state {
        case .began:
            start = scrollLayoutGuide.contentOffset
            targetPosition = start
        case .ended:
            animated = true
            let position = targetPosition
            targetPosition.x = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
            targetPosition.y = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))

            var velocity = recognizer.velocity(in: recognizer.view)
            velocity.x.negate()
            velocity.y.negate()

            if (targetPosition.x != position.x) {
                velocity.x = 0
            }
            if (targetPosition.y != position.y) {
                velocity.y = 0
            }

            targetPosition.x += (velocity.x * 0.3)
            targetPosition.y += (velocity.y * 0.3)

            nextTargetPosition.x = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
            nextTargetPosition.y = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))
        default: break
        }

//        print(scrollLayoutGuide.contentOffset)
        if targetPosition.x < 0 || targetPosition.x > scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width {
            let constrainedX = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
            targetPosition.x = constrainedX + rubberBandDistance(offset: targetPosition.x - constrainedX, dimension: scrollLayoutGuide.bounds.width)
        }
        if targetPosition.y < 0 || targetPosition.y > scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height {
            let constrainedY = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))
            targetPosition.y = constrainedY + rubberBandDistance(offset: targetPosition.y - constrainedY, dimension: scrollLayoutGuide.bounds.height)
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { self.scrollLayoutGuide.contentOffset = targetPosition }) { _ in
                if targetPosition != nextTargetPosition {
                    UIView.animate(withDuration: 0.2, animations: { self.scrollLayoutGuide.contentOffset = nextTargetPosition })
                }
            }
        } else {
            scrollLayoutGuide.contentOffset = targetPosition
        }
    }
}

func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
    let constant: CGFloat = 0.55
    let result = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0 ? -result : result;
}
