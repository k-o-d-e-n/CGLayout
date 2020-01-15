//
//  scroll.layoutGuide.cglayout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 21/06/2018.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

/// Version - Pre Alpha

// MARK: ScrollLayoutGuide

/// Layout guide that provides interface for scrolling content
open class ScrollLayoutGuide<Super: LayoutElement>: LayoutGuide<Super> {
    private var layout: LayoutBlockProtocol

    /// Designed initializer
    ///
    /// - Parameter layout: Layout defined scrollable content
    public required init(layout: LayoutBlockProtocol) {
        self.layout = layout
        super.init(frame: .zero)
    }

    /// Point that defines offset for content origin
    open var contentOffset: CGPoint { set { bounds.origin = newValue } get { return bounds.origin } }
    /// Size of content
    open var contentSize: CGSize = .zero
    open var contentInset: EdgeInsets = .zero {
        didSet {
            if oldValue != contentInset {
                let x = contentInset.left - oldValue.left
                let y = contentInset.top - oldValue.top

                contentOffset = CGPoint(x: contentOffset.x - x, y: contentOffset.y - y)
            }
        }
    }

    override public var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x - contentOffset.x, y: frame.origin.y - contentOffset.y), size: contentSize) }
    /// Performs layout for subelements, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    override open func layout(in rect: CGRect) {
        super.layout(in: rect)
        layout.layout(in: rect)
    }

    /// Defines rect for content that will be visible in this guide space.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    override open func contentRect(forFrame frame: CGRect) -> CGRect {
        //        var contentRect = bounds
        //        let lFrame = layoutBounds
        //        let snapshotFrame = CGRect(x: lFrame.origin.x, y: lFrame.origin.y, width: max(contentRect.width, frame.width), height: max(contentRect.height, frame.height))
        //        contentRect.size = layout.snapshot(for: snapshotFrame).snapshotFrame.distance(from: frame.origin)
        //        return contentRect
        var bounds = frame; bounds.origin = contentOffset
        return bounds
    }
}
public extension ScrollLayoutGuide {
    func decelerate(start: CGPoint, translation: CGPoint?, velocity: CGPoint) -> ScrollAnimationDeceleration<Super>? {
        guard let translation = translation else {
            return ScrollAnimationDeceleration(scrollGuide: self, velocity: velocity, bounces: true)
        }
        var targetPosition = contentOffset
        let newBoundsOriginX: CGFloat = start.x - translation.x
        let minBoundsOriginX: CGFloat = 0.0
        let maxBoundsOriginX: CGFloat = contentSize.width - bounds.size.width
        let constrainedBoundsOriginX: CGFloat = max(minBoundsOriginX, min(newBoundsOriginX, maxBoundsOriginX))
        let rubberBandedX: CGFloat = rubberBandDistance(newBoundsOriginX - constrainedBoundsOriginX, bounds.width)
        targetPosition.x = constrainedBoundsOriginX + rubberBandedX
        let newBoundsOriginY: CGFloat = start.y - translation.y
        let minBoundsOriginY: CGFloat = 0.0
        let maxBoundsOriginY: CGFloat = contentSize.height - bounds.size.height
        let constrainedBoundsOriginY: CGFloat = max(minBoundsOriginY, min(newBoundsOriginY, maxBoundsOriginY))
        let rubberBandedY: CGFloat = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, bounds.height)
        targetPosition.y = constrainedBoundsOriginY + rubberBandedY
        self.contentOffset = targetPosition

        return nil
    }
}
public extension ScrollLayoutGuide {
    /// Convinience initializer for adjustable layout elements.
    /// Initializes layout guide with layout block constrained to calculated size of element.
    ///
    /// - Parameters:
    ///   - contentItem: Item that defines content
    ///   - direction: Scroll direction
    convenience init<Item: AdjustableLayoutElement>(contentItem: Item, direction: ScrollDirection) {
        self.init(layout: contentItem.layoutBlock(with: Layout.equal, constraints: [contentItem.adjustLayoutConstraint(for: direction.constraints)]))
    }
}
/// Defines limiters for content of scroll layout guide.
public struct ScrollDirection: OptionSet {
    public
    var rawValue: Int
    public
    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .horizontal
        case 2: self = .vertical
        default:
            self = .both
        }
    }

    let constraints: [Size]

    init(constraints: [Size], rawValue: Int) {
        self.constraints = constraints
        self.rawValue = rawValue
    }

    public static var horizontal: ScrollDirection = ScrollDirection(constraints: [.width()], rawValue: 1)
    public static var vertical: ScrollDirection = ScrollDirection(constraints: [.height()], rawValue: 2)
    public static var both: ScrollDirection = ScrollDirection(constraints: [.height(), .width()], rawValue: 0)
}


private func rubberBandDistance(_ offset: CGFloat, _ dimension: CGFloat) -> CGFloat {
    let constant: CGFloat = 0.55
    let result: CGFloat = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0 ? -result : result
}

func LinearInterpolation(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return t * end + (1 - t) * start
    }
}

func QuadraticEaseOut(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return LinearInterpolation(t: t * (2 - t), start: start, end: end)
//        return start - (t * (2 - t)) * (start - end)
    }
}

protocol ScrollAnimation {
    var beginTime: TimeInterval { get set }
}

struct ScrollAnimationDecelerationComponent {
    var decelerateTime: TimeInterval
    var position: CGFloat
    var velocity: CGFloat
    var returnTime: TimeInterval
    var returnFrom: CGFloat
    var bounced: Bool
    var bouncing: Bool

    mutating func bounce(t: TimeInterval, to: CGFloat) -> Bool {
        if bounced && returnTime != 0 {
            let returnBounceTime: TimeInterval = min(1, ((t - returnTime) / returnAnimationDuration))
            self.position = QuadraticEaseOut(t: CGFloat(returnBounceTime), start: returnFrom, end: to)
            return returnBounceTime == 1
        }
        else if abs(to - position) > 0 {
            let F: CGFloat = Spring(velocity: velocity, position: position, restPosition: to, tightness: springTightness, dampening: springDampening)

            let oldVelocity = self.velocity
            self.velocity += F * CGFloat(physicsTimeStep)
//            print("v:", velocity, oldVelocity)
            let oldPosition = self.position
            self.position += -velocity * CGFloat(physicsTimeStep)
//            print("p:", oldPosition, self.position)
            self.bounced = true
            if abs(velocity - oldVelocity) < 0.5 {
                self.returnFrom = position
                self.returnTime = t
            }
            return false
        }
        else {
            return true
        }
    }

    mutating func animateBounce(_ offset: inout CGFloat, begin beginTime: TimeInterval, to targetOffset: CGFloat) {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        bouncing = true
        decelerateTime = beginTime
        while bouncing && currentTime >= decelerateTime {
            bouncing = !bounce(t: decelerateTime, to: targetOffset)
            decelerateTime += physicsTimeStep
            offset = position
        }
    }
}

private let minimumBounceVelocityBeforeReturning: CGFloat = 100
private let returnAnimationDuration: TimeInterval = 0.6
private let physicsTimeStep: TimeInterval = 1 / 60.0
private let springTightness: CGFloat = 0.3
private let springDampening: CGFloat = 15

private func Clamp(v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return (v < min) ? min : (v > max) ? max : v
}

private func ClampedVelocty(v: CGFloat) -> CGFloat {
    let V: CGFloat = 500
    return Clamp(v: v, min: -V, max: V)
}

private func Spring(velocity: CGFloat, position: CGFloat, restPosition: CGFloat, tightness: CGFloat, dampening: CGFloat) -> CGFloat {
    let d: CGFloat = position - restPosition
    return (-tightness * d) - (dampening * velocity) / 1
}

extension ScrollLayoutGuide {
    func _confinedContentOffset(_ contentOffset: CGPoint) -> CGPoint {
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        var contentOffset = contentOffset
        if (contentSize.width - contentOffset.x) < scrollerBounds.size.width {
            contentOffset.x = contentSize.width - scrollerBounds.size.width
        }
        if (contentSize.height - contentOffset.y) < scrollerBounds.size.height {
            contentOffset.y = contentSize.height - scrollerBounds.size.height
        }
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)
        if contentSize.width <= scrollerBounds.size.width {
            contentOffset.x = 0
        }
        if contentSize.height <= scrollerBounds.size.height {
            contentOffset.y = 0
        }
        return contentOffset
    }
    func _setRestrainedContentOffset(_ offset: CGPoint) {
        var offset = offset
        let confinedOffset: CGPoint = _confinedContentOffset(offset)
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        if !(/*alwaysBounceHorizontal && */contentSize.width <= scrollerBounds.size.width) {
            offset.x = confinedOffset.x
        }
        if !(/*alwaysBounceVertical && */contentSize.height <= scrollerBounds.size.height) {
            offset.y = confinedOffset.y
        }
        contentOffset = offset
    }
}

public class ScrollAnimationDeceleration<Item: LayoutElement>: ScrollAnimation {
    private var x: ScrollAnimationDecelerationComponent
    private var y: ScrollAnimationDecelerationComponent
    private var lastMomentumTime: TimeInterval
    private(set) weak var scrollGuide: ScrollLayoutGuide<Item>!
    var beginTime: TimeInterval = Date.timeIntervalSinceReferenceDate

    let timeInterval: CGFloat = 1/60
    let startVelocity: CGPoint

    public var bounces: Bool
    public init(scrollGuide sg: ScrollLayoutGuide<Item>, velocity v: CGPoint, bounces: Bool) {
        self.scrollGuide = sg

        self.bounces = bounces
        self.startVelocity = v
        self.lastMomentumTime = beginTime
        self.x = ScrollAnimationDecelerationComponent(
            decelerateTime: beginTime,
            position: scrollGuide.contentOffset.x,
            velocity: startVelocity.x,
            returnTime: 0,
            returnFrom: 0,
            bounced: false,
            bouncing: false
        )
        self.y = ScrollAnimationDecelerationComponent(
            decelerateTime: beginTime,
            position: scrollGuide.contentOffset.y,
            velocity: startVelocity.y,
            returnTime: 0,
            returnFrom: 0,
            bounced: false,
            bouncing: false
        )
        if x.velocity == 0 {
            x.bounced = true
            x.returnTime = beginTime
            x.returnFrom = x.position
        }
        if y.velocity == 0 {
            y.bounced = true
            y.returnTime = beginTime
            y.returnFrom = y.position
        }
    }

    /// Returns true if animation completed
    public func step() -> Bool {
        func stopIfNeeded() -> Bool {
            return abs(x.velocity) <= 0.001 && abs(y.velocity) <= 0.001
        }
        guard let guide = scrollGuide else {
            return true
        }

        let offset = guide.contentOffset
        x.position = offset.x
        y.position = offset.y
        if bounces {
            let confinedOffset = guide._confinedContentOffset(guide.contentOffset)
            if (x.position < 0 || x.position > guide.contentSize.width - guide.frame.width) {
                x.position = offset.x
                x.animateBounce(&guide.contentOffset.x, begin: beginTime, to: confinedOffset.x)
            } else if !x.bounced {
                x.position += -x.velocity * timeInterval
                guide.contentOffset.x = x.position
            }
            if (y.position < 0 || y.position > guide.contentSize.height - guide.frame.height) {
                y.position = offset.y
                y.animateBounce(&guide.contentOffset.y, begin: beginTime, to: confinedOffset.y)
            } else if !y.bounced {
                y.position += -y.velocity * timeInterval
                guide.contentOffset.y = y.position
            }
            beginTime = y.decelerateTime
        } else {
            x.position += -x.velocity * timeInterval
            y.position += -y.velocity * timeInterval
            guide._setRestrainedContentOffset(CGPoint(x: x.position, y: y.position))
        }

        lastMomentumTime = Date.timeIntervalSinceReferenceDate
        let friction: CGFloat = 0.96
        let drag: CGFloat = pow(pow(friction, 60), CGFloat(lastMomentumTime - beginTime))
        if !x.bouncing {
            x.velocity = startVelocity.x * drag
        }
        if !y.bouncing {
            y.velocity = startVelocity.y * drag
        }
        return stopIfNeeded()
    }
}
