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

        let contentLayer = CALayer()
        contentLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        contentLayer.borderWidth = 1
        view.layer.addSublayer(contentLayer)

        let contentScheme = LayoutScheme(blocks: [
            contentGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(contentGuide.frame.width), height: .fixed(contentGuide.frame.height))),
            redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
            greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)),
                                  constraints: [contentGuide.layoutConstraint(for: [LayoutAnchor.Left.align(by: .inner), LayoutAnchor.Bottom.align(by: .inner)])]),
            contentLayer.layoutBlock()
        ])
        
        scrollLayoutGuide = ScrollLayoutGuide(layout: contentScheme)
        scrollLayoutGuide.contentSize = contentGuide.bounds.size
        scheme = LayoutScheme(blocks: [scrollLayoutGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1)),
                                                                     constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.Bottom.limit(on: .outer)])]),
                                       contentScheme])

        view.add(layoutGuide: scrollLayoutGuide)
        view.add(layoutGuide: contentGuide)
        view.addSublayoutItem(redView)
        view.addSublayoutItem(greenView)

//        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:))))
        commonInitForCustomScrollView()
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
//            let position = targetPosition
//            targetPosition.x = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
//            targetPosition.y = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))
//
//            velocity.x.negate()
//            velocity.y.negate()
//
//            if (targetPosition.x != position.x) {
//                velocity.x = 0
//            }
//            if (targetPosition.y != position.y) {
//                velocity.y = 0
//            }
//
//            targetPosition.x += (velocity.x * 0.3)
//            targetPosition.y += (velocity.y * 0.3)
//
//            nextTargetPosition.x = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
//            nextTargetPosition.y = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))
        default: break
        }

//        print(scrollLayoutGuide.contentOffset)
//        if targetPosition.x < 0 || targetPosition.x > scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width {
//            let constrainedX = min(scrollLayoutGuide.contentSize.width - scrollLayoutGuide.frame.width, max(0, targetPosition.x))
//            targetPosition.x = constrainedX + rubberBandDistance(offset: targetPosition.x - constrainedX, dimension: scrollLayoutGuide.bounds.width)
//        }
//        if targetPosition.y < 0 || targetPosition.y > scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height {
//            let constrainedY = min(scrollLayoutGuide.contentSize.height - scrollLayoutGuide.frame.height, max(0, targetPosition.y))
//            targetPosition.y = constrainedY + rubberBandDistance(offset: targetPosition.y - constrainedY, dimension: scrollLayoutGuide.bounds.height)
//        }
        if animated {
//            UIView.animate(withDuration: 0.3, animations: { self.scrollLayoutGuide.contentOffset = targetPosition }) { _ in
//                if targetPosition != nextTargetPosition {
//                    UIView.animate(withDuration: 0.2, animations: { self.scrollLayoutGuide.contentOffset = nextTargetPosition })
//                }
//            }
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

    class CSCDynamicItem: NSObject, UIDynamicItem {
        var center: CGPoint
        private(set) var bounds: CGRect
        var transform: CGAffineTransform = .identity

        override init() {
            // Sets non-zero `bounds`, because otherwise Dynamics throws an exception.
            bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
            center = CGPoint(x: 0.5, y: 0.5)
        }
    }

    var animator: UIDynamicAnimator!
    var dynamicItem: CSCDynamicItem!
    func commonInitForCustomScrollView() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        animator = UIDynamicAnimator(referenceView: view)
        dynamicItem = CSCDynamicItem()
    }

    var contentSize: CGSize {
        return scrollLayoutGuide.contentSize
    }

    var bounds: CGRect {
        set { scrollLayoutGuide.bounds = newValue; _setBounds(newValue) }
        get { return scrollLayoutGuide.bounds }
    }

    func _setBounds(_ bounds: CGRect) {
        if (outsideBoundsMinimum() || outsideBoundsMaximum()) && ((decelerationBehavior != nil) && self.springBehavior == nil) {
            let target: CGPoint = anchor()
            let springBehavior = UIAttachmentBehavior(item: dynamicItem, attachedToAnchor: target)
            // Has to be equal to zero, because otherwise the bounds.origin wouldn't exactly match the target's position.
            springBehavior.length = 0
            // These two values were chosen by trial and error.
            springBehavior.damping = 1
            springBehavior.frequency = 2
            animator.addBehavior(springBehavior)
            self.springBehavior = springBehavior
        }
        if !outsideBoundsMinimum() && !outsideBoundsMaximum() {
            lastPointInBounds = bounds.origin
        }
    }

    weak var decelerationBehavior: UIDynamicItemBehavior?
    weak var springBehavior: UIAttachmentBehavior?
    var lastPointInBounds = CGPoint.zero

    var startBounds: CGRect!
    func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        switch panGestureRecognizer.state {
        case .began:
            startBounds = self.bounds
            animator.removeAllBehaviors()
        case .changed:
            var translation: CGPoint = panGestureRecognizer.translation(in: view)
            var bounds: CGRect = startBounds
            if !scrollHorizontal {
                translation.x = 0.0
            }
            if !scrollVertical {
                translation.y = 0.0
            }
            let newBoundsOriginX: CGFloat = bounds.origin.x - translation.x
            let minBoundsOriginX: CGFloat = 0.0
            let maxBoundsOriginX: CGFloat = contentSize.width - bounds.size.width
            let constrainedBoundsOriginX: CGFloat = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX))
            let rubberBandedX: CGFloat = rubberBandDistance(newBoundsOriginX - constrainedBoundsOriginX, self.bounds.width)
            bounds.origin.x = constrainedBoundsOriginX + rubberBandedX
            let newBoundsOriginY: CGFloat = bounds.origin.y - translation.y
            let minBoundsOriginY: CGFloat = 0.0
            let maxBoundsOriginY: CGFloat = contentSize.height - bounds.size.height
            let constrainedBoundsOriginY: CGFloat = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY))
            let rubberBandedY: CGFloat = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, self.bounds.height)
            bounds.origin.y = constrainedBoundsOriginY + rubberBandedY
            self.bounds = bounds
        case .ended:
            var velocity: CGPoint = panGestureRecognizer.velocity(in: view)
            velocity.x = -velocity.x
            velocity.y = -velocity.y
            if !scrollHorizontal || outsideBoundsMinimum() || outsideBoundsMaximum() {
                velocity.x = 0
            }
            if !scrollVertical || outsideBoundsMinimum() || outsideBoundsMaximum() {
                velocity.y = 0
            }
            dynamicItem.center = self.bounds.origin
            let decelerationBehavior = UIDynamicItemBehavior(items: [dynamicItem])
            decelerationBehavior.addLinearVelocity(velocity, for: dynamicItem)
            decelerationBehavior.resistance = 2.0
            decelerationBehavior.action = { [unowned self] in
                // IMPORTANT: If the deceleration behavior is removed, the bounds' origin will stop updating. See other possible ways of updating origin in the accompanying blog post.
                var bounds: CGRect = self.bounds
                bounds.origin = self.dynamicItem.center
                self.bounds = bounds
            }
            animator.addBehavior(decelerationBehavior)
            self.decelerationBehavior = decelerationBehavior
        default:
            break
        }
    }

    var scrollVertical: Bool {
        return contentSize.height > bounds.height
    }

    var scrollHorizontal: Bool {
        return contentSize.width > bounds.width
    }

    var maxBoundsOrigin: CGPoint {
        return CGPoint(x: contentSize.width - bounds.size.width, y: contentSize.height - bounds.size.height)
    }

    func outsideBoundsMinimum() -> Bool {
        return bounds.origin.x < 0.0 || bounds.origin.y < 0.0
    }

    func outsideBoundsMaximum() -> Bool {
        let maxBoundsOrigin: CGPoint = self.maxBoundsOrigin
        return bounds.origin.x > maxBoundsOrigin.x || bounds.origin.y > maxBoundsOrigin.y
    }

    func anchor() -> CGPoint {
        let bounds: CGRect = self.bounds
        let maxBoundsOrigin: CGPoint = self.maxBoundsOrigin
        let deltaX: CGFloat = lastPointInBounds.x - bounds.origin.x
        let deltaY: CGFloat = lastPointInBounds.y - bounds.origin.y
        // solves a system of equations: y_1 = ax_1 + b and y_2 = ax_2 + b
        let a: CGFloat = deltaY / deltaX
        let b: CGFloat = lastPointInBounds.y - lastPointInBounds.x * a
        let leftBending: CGFloat = -bounds.origin.x
        let topBending: CGFloat = -bounds.origin.y
        let rightBending: CGFloat = bounds.origin.x - maxBoundsOrigin.x
        let bottomBending: CGFloat = bounds.origin.y - maxBoundsOrigin.y
        // Updates anchor's `y` based on already set `x`, i.e. y = f(x)
        let solveForY: (inout CGPoint) -> Void = { (_ anchor: inout CGPoint) -> Void in
            // Updates `y` only if there was a vertical movement. Otherwise `y` based on current `bounds.origin` is already correct.
            if deltaY != 0 {
                anchor.y = a * anchor.x + b
            }
        }
        // Updates anchor's `x` based on already set `y`, i.e. x =  f^(-1)(y)
        let solveForX: (inout CGPoint) -> Void = { (_ anchor: inout CGPoint) -> Void in
            if deltaX != 0 {
                anchor.x = (anchor.y - b) / a
            }
        }
        var anchor: CGPoint = bounds.origin
        if bounds.origin.x < 0.0 && leftBending > topBending && leftBending > bottomBending {
            anchor.x = 0
            solveForY(&anchor)
        } else if bounds.origin.y < 0.0 && topBending > leftBending && topBending > rightBending {
            anchor.y = 0
            solveForX(&anchor)
        } else if bounds.origin.x > maxBoundsOrigin.x && rightBending > topBending && rightBending > bottomBending {
            anchor.x = maxBoundsOrigin.x
            solveForY(&anchor)
        } else if bounds.origin.y > maxBoundsOrigin.y {
            anchor.y = maxBoundsOrigin.y
            solveForX(&anchor)
        }
        return anchor
    }

}

private func rubberBandDistance(_ offset: CGFloat, _ dimension: CGFloat) -> CGFloat {
    let constant: CGFloat = 0.55
    let result: CGFloat = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0 ? -result : result
}
