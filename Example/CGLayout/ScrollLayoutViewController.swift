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

    var subviews: [LayoutElement] = []
    var scheme: LayoutScheme!

    override func viewDidLoad() {
        super.viewDidLoad()

        let redView = UIView(backgroundColor: .red)
        subviews.append(redView)
        let greenView = UIView(backgroundColor: .green)
        subviews.append(greenView)
        let blueView = UIView(backgroundColor: .blue)
        subviews.append(blueView)
        let contentGuide = LayoutGuide<UIView>(frame: view.bounds.insetBy(dx: -100, dy: -300))
        subviews.append(contentGuide)

        let contentLayer = CALayer()
        contentLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        contentLayer.borderWidth = 1
        view.layer.addSublayer(contentLayer)

        let contentScheme = LayoutScheme(blocks: [
            contentGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(contentGuide.frame.width), height: .fixed(contentGuide.frame.height))),
            redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
            blueView.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(200), height: .fixed(200))),
            greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)),
                                  constraints: [contentGuide.layoutConstraint(for: [LayoutAnchor.left(.align(by: .inner)), LayoutAnchor.bottom(.align(by: .inner))])]),
            contentLayer.layoutBlock()
        ])
        
        scrollLayoutGuide = ScrollLayoutGuide(layout: contentScheme)
        scrollLayoutGuide.contentSize = contentGuide.bounds.size
        scheme = LayoutScheme(blocks: [scrollLayoutGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1)),
                                                                     constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.bottom(.limit(on: .outer))])]),
                                       contentScheme])

        view.add(layoutGuide: scrollLayoutGuide)
        view.add(layoutGuide: contentGuide)
        view.addChildElement(redView)
        view.addChildElement(blueView)
        view.addChildElement(greenView)

        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:))))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout()
    }

    var start: CGPoint = .zero
    var timer: Timer? = nil
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)
        var targetPosition = CGPoint(x: start.x - translation.x, y: start.y - translation.y)
        var nextTargetPosition = targetPosition

        var animated = false
        switch recognizer.state {
        case .began:
            timer?.invalidate()
            timer = nil
            start = scrollLayoutGuide.contentOffset
            targetPosition = start
        case .ended:
            animated = true
        default: break
        }

        if animated {
            let animation = ScrollAnimationDeceleration(scrollGuide: scrollLayoutGuide, velocity: velocity)
            if #available(iOS 10.0, *) {
                timer = Timer(timeInterval: 1/60, repeats: true, block: animation.step)
                RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
            } else {
                // Fallback on earlier versions
            }
        } else {
            scrollLayoutGuide.contentOffset = targetPosition
        }
    }
}

private func rubberBandDistance(_ offset: CGFloat, _ dimension: CGFloat) -> CGFloat {
    let constant: CGFloat = 0.55
    let result: CGFloat = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0 ? -result : result
}
